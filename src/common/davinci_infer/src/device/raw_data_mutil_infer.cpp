/*
 * License: Copyright (c) Huawei Technologies Co., Ltd. 2012-2019. All rights reserved.
 * Description: 多输入裸数据推理
 * Date: 2019-09-29 10:45:26
 * LastEditTime: 2019-09-30 18:17:54
 */

#include <unistd.h>
#include <thread>
#include <vector>
#include <fstream>
#include <algorithm>
#include <iostream>
#include <string>
#include <sstream>

#include "hiaiengine/c_graph.h"
#include "hiaiengine/ai_memory.h"
#include "hiaiengine/api.h"
#include "hiaiengine/data_type.h"

#include "inc/raw_data_mutil_infer.h"
#include "inc/error_code.h"
#include "inc/sample_data.h"
#include "inc/sample_status.h"
#include "inc/util.h"
#include "inc/common.h"

using namespace std;
using hiai::AIConfig;
using hiai::AIModelDescription;

RawDataMutilInferEngine::~RawDataMutilInferEngine()
{
    // Release the pre-allocated memory of outData.
    for (auto buffer : outData_) {
        if (buffer != nullptr) {
            hiai::HIAIMemory::HIAI_DFree(buffer);
            buffer = nullptr;
        }
    }
}

HIAI_StatusT RawDataMutilInferEngine::Init(
    const hiai::AIConfig& config, const std::vector<hiai::AIModelDescription>& model_desc)
{
    HIAI_ENGINE_LOG(this, HIAI_OK, "RawDataMutilInferEngine Init");

    if (ai_model_manager_ == nullptr) {
        ai_model_manager_ = make_shared<hiai::AIModelManager>();
    }
    // 获取配置参数
    config_.clear();
    vector<AIModelDescription> modelDescVec;
    for (auto item : config.items()) {
        ModelMgr mm;
        mm.modelName = item.name();
        mm.modelPath = item.value();
        HIAI_ENGINE_LOG("[config parser] modelName: %s, modelPath: %s", mm.modelName.c_str(), mm.modelPath.c_str());
        for (auto subItem : item.sub_items()) {
            if ("model_height" == subItem.name()) {
                mm.modelHei = Util::Str2Num(subItem.value());
            }
            if ("model_width" == subItem.name()) {
                mm.modelWid = Util::Str2Num(subItem.value());
            }
            if ("scale" == subItem.name()) {
                mm.scale = Util::Str2Float(subItem.value());
            }
            if ("batchsize" == subItem.name()) {
                mm.batchsize = Util::Str2Num(subItem.value());
                bs_file_ = mm.batchsize;
            }
        }
        config_[item.name()] = mm;
        AIModelDescription modelDesc;
        HIAI_ENGINE_LOG("config parser modelName: %s", item.name().c_str());
        modelDesc.set_name(item.name());
        modelDesc.set_path(item.value());
        modelDescVec.push_back(modelDesc);
    }

    // 初始化多个模型
    hiai::AIStatus ret = ai_model_manager_->Init(config, modelDescVec);
    if (ret != hiai::SUCCESS) {
        HIAI_ENGINE_LOG(this, HIAI_AI_MODEL_MANAGER_INIT_FAIL, "hiai ai model manager init failed");
        return HIAI_AI_MODEL_MANAGER_INIT_FAIL;
    }
    if (neural_buffer_img_ == nullptr) {
        neural_buffer_img_ = std::shared_ptr<hiai::AINeuralNetworkBuffer>(new hiai::AINeuralNetworkBuffer());
    }

    HIAI_ENGINE_LOG(this, HIAI_OK, "RawDataMutilInferEngine init success");
    return HIAI_OK;
}

HIAI_StatusT RawDataMutilInferEngine::BatchInfer(
    vector<shared_ptr<MutilInputData>>& imgData, const string& modelName, FeatMapsData& outData)
{
    HIAI_ENGINE_LOG("RawDataMutilInferEngine::BatchInfer");
    if (imgData.empty()) {
        return HIAI_AI_MODEL_MANAGER_PROCESS_FAIL;
    }

    // debug
    for (int i = 0; i < imgData.size(); ++i) {
        vector<InputTensor> tensors = imgData[i]->inputs;
        HIAI_ENGINE_LOG("input_tensor_num: %d", tensors.size());
        for (int j = 0; j < tensors.size(); ++j) {
            stringstream ss;
            ss << j;
            string tensorName;
            ss >> tensorName;
            string savePath = "tensor_" + tensorName;
            savePath += ".bin";
            HIAI_ENGINE_LOG("input_tensor_size: %d", tensors[j].size);
            Util::WriteBinFile(savePath.c_str(), tensors[j].data.get(), tensors[j].size);
        }
    }

    errno_t err = EOK;
    std::vector<std::shared_ptr<hiai::IAITensor>> inDataVec;

    // Allocate the Out memory, allocate it in advance.
    std::vector<hiai::TensorDimension> inputTensorDim;
    std::vector<hiai::TensorDimension> outputTensorDim;
    HIAI_StatusT ret = ai_model_manager_->GetModelIOTensorDim(modelName, inputTensorDim, outputTensorDim);
    if (ret != hiai::SUCCESS) {
        HIAI_ENGINE_LOG(this, HIAI_AI_MODEL_MANAGER_INIT_FAIL, "hiai ai model manager init fail");
        return HIAI_AI_MODEL_MANAGER_INIT_FAIL;
    }
    for (uint32_t index = 0; index < inputTensorDim.size(); index++) {
        HIAI_ENGINE_LOG(HIAI_IDE_ERROR,
            "index %d, name %s",
            index,
            inputTensorDim[index].name.c_str());
    }
    if (inputTensorDim[0].n != bs_file_) {
        HIAI_ENGINE_LOG(HIAI_IDE_ERROR,
            "batchsize is not the sampel! om batchsize:%d, config file:%d",
            inputTensorDim[0].n,
            bs_file_);
        return HIAI_AI_MODEL_MANAGER_PROCESS_FAIL;
    }
    batchsize_ = inputTensorDim[0].n;

    HIAI_ENGINE_LOG("model batchsize: %d", batchsize_);
    HIAI_ENGINE_LOG("inputTensorDim size: %d, outputTensorDim size: %d", inputTensorDim.size(), outputTensorDim.size());

    // allocate OutData in advance
    HIAI_StatusT hiai_ret = HIAI_OK;
    for (uint32_t index = 0; index < outputTensorDim.size(); index++) {
        TensorDimension td = outputTensorDim[index];
        outData.dim.push_back(td);
        HIAI_ENGINE_LOG("outputTensor name: %s, index: %d, w:%d, h:%d, c:%d, n:%d, size:%d",
            outputTensorDim[index].name.c_str(),
            index,
            outputTensorDim[index].w,
            outputTensorDim[index].h,
            outputTensorDim[index].c,
            outputTensorDim[index].n,
            outputTensorDim[index].size);
        hiai::AITensorDescription outputTensorDesc = hiai::AINeuralNetworkBuffer::GetDescription();
        uint8_t* buffer = nullptr;
        hiai_ret = hiai::HIAIMemory::HIAI_DMalloc(outputTensorDim[index].size, (void*&)buffer, DMALLOC_TIMEOUT);
        if (hiai_ret != HIAI_OK || buffer == nullptr) {
            HIAI_ENGINE_LOG(HIAI_IDE_ERROR, "HIAI_DMalloc failed");
            continue;
        }
        shared_ptr<hiai::IAITensor> outputTensor =
            hiai::AITensorFactory::GetInstance()->CreateTensor(outputTensorDesc, buffer, outputTensorDim[index].size);
        outData.data.push_back(outputTensor);
        outData.cnt++;
    }

    // filling the batch data to the input
    // 遍历每一个输入tensor的size
    vector<InputTensor> tensors = imgData[0]->inputs;
    vector<shared_ptr<uint8_t>> inData(tensors.size());
    // k为第几个输入tensor
    for (int k = 0; k < tensors.size(); ++k) {
        uint32_t batchTensorBufSize = batchsize_ * tensors[k].size;
        HIAI_ENGINE_LOG(
            "batchTensorBufSize: %d, batchsize_: %d, tensorsize:%d", batchTensorBufSize, batchsize_, tensors.size());

        // 存储batchsize个输入tensor的buffer
        inData[k].reset((uint8_t*)HIAI_DVPP_DMalloc(batchTensorBufSize), [](uint8_t* p) { HIAI_DVPP_DFree(p); });
        uint8_t* pData = inData[k].get();

        // 遍历每一个sample, 直接取出第K个输入tensor, 拼接到一起
        for (int i = 0; i < imgData.size(); ++i) {
            vector<InputTensor> tensors = imgData[i]->inputs;
            InputTensor kthTensor = tensors[k];  // 直接取出第K个输入tensor

            err = memcpy_s(pData, batchTensorBufSize, kthTensor.data.get(), kthTensor.size);
            if (err != EOK) {
                return HIAI_AI_MODEL_MANAGER_PROCESS_FAIL;
            }
            pData += kthTensor.size;
        }

        // padding
        if (imgData.size() < batchsize_) {
            uint16_t padNum = batchsize_ - imgData.size();
            err = memset_s(pData, batchTensorBufSize, static_cast<char>(0), imgData[0]->inputs[k].size * padNum);
            if (err != EOK) {
                return HIAI_AI_MODEL_MANAGER_PROCESS_FAIL;
            }
        }

        // Transfer buffer to Framework directly, only one inputsize
        hiai::AITensorDescription inputTensorDesc = hiai::AINeuralNetworkBuffer::GetDescription();
        shared_ptr<hiai::IAITensor> inputTensor =
            hiai::AITensorFactory::GetInstance()->CreateTensor(inputTensorDesc, inData[k].get(), batchTensorBufSize);

        stringstream ss;
        ss << k;
        string name;
        ss >> name;
        string spath = "post_" + name;
        spath += ".bin";
        Util::WriteBinFile(spath.c_str(), inData[k].get(), batchTensorBufSize);

        inDataVec.push_back(inputTensor);
    }

    // process
    hiai::AIContext ai_context;
    // Process work
    HIAI_ENGINE_LOG("inDataVec size: %d, outData size: %d", inDataVec.size(), outData.data.size());
    HIAI_ENGINE_LOG("batch infer begin!");
    ret = ai_model_manager_->Process(ai_context, inDataVec, outData.data, 0);
    if (hiai::SUCCESS != ret) {
        imgData.clear();
        HIAI_ENGINE_LOG(this, HIAI_AI_MODEL_MANAGER_PROCESS_FAIL, "Fail to process ai model manager");
        return HIAI_AI_MODEL_MANAGER_PROCESS_FAIL;
    }
    HIAI_ENGINE_LOG("batch infer end!");

    imgData.clear();  // 清空batch

    return HIAI_OK;
}

/**
 * ingroup InferEngine
 * brief InferEngine Process函数
 * param [in]：arg0
 */
HIAI_IMPL_ENGINE_PROCESS("RawDataMutilInferEngine", RawDataMutilInferEngine, INFER_ENGINE_INPUT_SIZE)
{
    HIAI_ENGINE_LOG("RawDataMutilInferEngine Process Start");
    HIAI_StatusT ret = HIAI_OK;
    errno_t err = EOK;
    std::shared_ptr<MutilInputData> input_arg = std::static_pointer_cast<MutilInputData>(arg0);
    if (nullptr == input_arg) {
        HIAI_ENGINE_LOG(this, HIAI_INVALID_INPUT_MSG, "fail to process invalid message");
        return HIAI_INVALID_INPUT_MSG;
    }

    // 组batch
    batchData_.push_back(input_arg);
    uint16_t realSize = batchData_.size();
    HIAI_ENGINE_LOG("batchsize:%d, bs_file_:%d", batchData_.size(), bs_file_);
    if (batchData_.size() < bs_file_) {
        if (!(input_arg->isLastFrm)) {
            return HIAI_OK;
        }
    }
    static unsigned int cnt = 0;
    static double total = 0.0;
    struct timeval start, end;
    gettimeofday(&start, NULL);
    vector<FeatMapsData> allOutDatas;
    for (auto cfg : config_) {
        string modelName = cfg.first;  // 模型名
        ModelMgr mm = cfg.second;      // 模型相关信息

        HIAI_ENGINE_LOG("RawDataMutilInferEngine modelName:%s, modelPath:%s, modelWid:%d, modelHei:%d, scale:%f",
            modelName.c_str(),
            mm.modelPath.c_str(),
            mm.modelWid,
            mm.modelHei,
            mm.scale);

        HIAI_ENGINE_LOG("frameId:%d, isLastFrm:%d", batchData_[0]->frameId, batchData_[0]->isLastFrm);

        // infer
        FeatMapsData outData;
        HIAI_StatusT ret = BatchInfer(batchData_, modelName, outData);
        if (ret != HIAI_OK) {
            std::shared_ptr<EngineReturnDataT> retData = std::make_shared<EngineReturnDataT>();
            retData->processedFrameId = input_arg->frameId;
            retData->realSampleNum = realSize;
            HIAI_ENGINE_LOG(HIAI_IDE_ERROR, "retData->processedFrameId: %d", retData->processedFrameId);
            HIAI_ENGINE_LOG(HIAI_IDE_ERROR, "retData->realSampleNum: %d", retData->realSampleNum);
            hiai::Engine::SendData(0, "EngineReturnDataT", std::static_pointer_cast<void>(retData));

            HIAI_ENGINE_LOG(HIAI_IDE_ERROR, "[ERROR], Infer failed");
            return ret;
        }
        allOutDatas.push_back(outData);
    }

    gettimeofday(&end, NULL);
    double diff = (end.tv_sec - start.tv_sec) * 1000000 + (end.tv_usec - start.tv_usec);
    double avg = 0.0;
    cnt++;
    if (1 == cnt) {
        total = 0.0;
    } else {
        total += diff;
        avg = total / (cnt - 1);
    }
    HIAI_ENGINE_LOG(HIAI_IDE_ERROR,
        "[Inference Cost] diff time: %f us, avg time: %f us, total time: %f us, count: %d",
        diff,
        avg,
        total,
        cnt);

    // send data  !!!当前一个Engine只考虑单模型情况
    FeatMapsData sendData;
    if (allOutDatas.size() > 0) {
        sendData = allOutDatas[0];
    }
    std::shared_ptr<EngineReturnDataT> retData = std::make_shared<EngineReturnDataT>();
    retData->size = sendData.data.size();  // 模型输出tensor数目
    retData->batchsize = batchsize_;
    retData->realSampleNum = realSize;
    HIAI_ENGINE_LOG("InferEngine ouput_data_vec size: %d", sendData.data.size());

    // 遍历所有featuremap输出, 每一个out是一个batch的featuremap的拼接
    for (uint32_t index = 0; index < sendData.data.size(); index++) {
        HIAI_ENGINE_LOG("Infer output index: %d", index);
        // 解析输出代码, output_data包含一个batch的featuremap
        std::shared_ptr<hiai::AINeuralNetworkBuffer> output_data =
            std::static_pointer_cast<hiai::AINeuralNetworkBuffer>(sendData.data[index]);

        OutputT out;
        out.size = output_data->GetSize();
        out.name = sendData.dim[index].name;
        HIAI_ENGINE_LOG("Tensor Name: %s, size:%d", out.name.c_str(), out.size);
        out.data.reset((uint8_t*)new uint8_t[out.size], [](uint8_t* p) { delete[] p; });
        if (output_data->GetBuffer()) {
            err = memcpy_s(out.data.get(), output_data->GetSize(), output_data->GetBuffer(), output_data->GetSize());
            if (err != EOK) {
                return HIAI_AI_MODEL_MANAGER_PROCESS_FAIL;
            }
        }
        retData->output_data_vec.push_back(out);
    }
    // infer time
    retData->inferDiff = diff;
    retData->inferAvg = avg;
    retData->inferTotal = total;
    retData->processedFrameId = input_arg->frameId;

    HIAI_ENGINE_LOG("retData ouput_data_vec size: %d", retData->size);

    hiai::Engine::SendData(0, "EngineReturnDataT", std::static_pointer_cast<void>(retData));

    HIAI_ENGINE_LOG("RawDataMutilInferEngine Process End");

    return HIAI_OK;
}
