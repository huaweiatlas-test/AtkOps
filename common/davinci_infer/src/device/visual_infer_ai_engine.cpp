/*
 * License: Copyright (c) Huawei Technologies Co., Ltd. 2012-2019. All rights reserved.
 * Description: device engine实现代码
 * Date: 2019-02-28
 * LastEditTime: 2019-09-29 10:32:47
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

#include "dvpp/idvppapi.h"
#include "dvpp/Vpc.h"

#include "inc/visual_infer_ai_engine.h"
#include "inc/error_code.h"
#include "inc/sample_data.h"
#include "inc/sample_status.h"
#include "inc/util.h"
#include "inc/common.h"

#include "inc/dvpp_warpper.h"

using namespace std;

static const uint32_t CREATE_DVPP_SUCCESS = 0;
static const uint32_t CREATE_DVPP_FAIL = -1;

using hiai::AIConfig;
using hiai::AIModelDescription;

// 全局变量
static uint32_t g_JpegdinWidth = 0;
static uint32_t g_JpegdinHeight = 0;
static uint32_t g_JpegdoutWidth = 0;
static uint32_t g_JpegdoutHeight = 0;

HIAI_REGISTER_DATA_TYPE("OutputT", OutputT);
HIAI_REGISTER_DATA_TYPE("EngineReturnDataT", EngineReturnDataT);

HIAI_REGISTER_DATA_TYPE("InputTensor", InputTensor);
HIAI_REGISTER_DATA_TYPE("MutilInputData", MutilInputData);

HIAI_IMPL_ENGINE_PROCESS("JpegdEngine", JpegdEngine, 1)
{
    std::shared_ptr<EngineTransNewT> result = std::static_pointer_cast<EngineTransNewT>(arg0);

    HIAI_ENGINE_LOG("Jpegd frameId:%d, isLastFrm:%d", result->frameId, result->isLastFrm);

    DvppWarpper dvppWarpper;
    shared_ptr<EngineTransNewT> output;
    HIAI_StatusT ret =
        dvppWarpper.DecodeJpeg(result, g_JpegdinWidth, g_JpegdinHeight, g_JpegdoutWidth, g_JpegdoutHeight, output);
    if (HIAI_OK != ret) {
        HIAI_ENGINE_LOG(HIAI_IDE_ERROR, "[ERROR], JpegdEngine dvpp failed");
        return ret;
    }
    // 发送数据
    if (HIAI_OK != SendData(0, message_type, output)) {
        HIAI_ENGINE_LOG(HIAI_IDE_ERROR, "SendData wrong");
    }

    HIAI_ENGINE_LOG("[DEBUG] JpegdEngine End Process");

    return HIAI_OK;
}

HIAI_StatusT VpcEngine::Init(const hiai::AIConfig& config, const std::vector<hiai::AIModelDescription>& model_desc)
{
    HIAI_ENGINE_LOG("VpcEngine Init");

    // 获取配置参数
    config_.clear();
    for (auto item : config.items()) {
        HIAI_ENGINE_LOG("VpcEngine Init item value: %s", item.value());
        stringstream ss;
        ss << item.value();
        ss >> config_[item.name()];

        HIAI_ENGINE_LOG("VpcEngine Init item value(uint32_t): %d", config_[item.name()]);
    }

    HIAI_ENGINE_LOG("VpcEngine init success");

    return HIAI_OK;
}

/**
 * ingroup hiaiengine
 * brief   VpcEngine        VpcEngine Process，进行Crop/Resize
 * return  HIAI_StatusT     HIAI_OK 为正确，其他为错误
 */
HIAI_IMPL_ENGINE_PROCESS("VpcEngine", VpcEngine, 1)
{
    if (nullptr == arg0) {
        return HIAI_OK;
    }
    HIAI_ENGINE_LOG("[DEBUG] VpcEngine Start Process");
    std::shared_ptr<EngineTransNewT> result = std::static_pointer_cast<EngineTransNewT>(arg0);

    g_ModelWidth = config_["model_width"];
    g_ModelHeight = config_["model_height"];

    HIAI_ENGINE_LOG("[VPC Engine] model_width:%d, model_height:%d", g_ModelWidth, g_ModelHeight);

    DvppWarpper dvppWarpper;
    shared_ptr<EngineTransNewT> output;
    HIAI_StatusT ret = dvppWarpper.Vpc(result,
        g_ModelWidth,
        g_ModelHeight,
        g_JpegdinWidth,
        g_JpegdinHeight,
        g_JpegdoutWidth,
        g_JpegdoutHeight,
        output);
    if (HIAI_OK != ret) {
        HIAI_ENGINE_LOG(HIAI_IDE_ERROR, "[ERROR], VpcEngine dvpp failed");
        return ret;
    }
    // 发送数据数据给到
    if (HIAI_OK != SendData(0, message_type, output)) {
        HIAI_ENGINE_LOG(HIAI_IDE_ERROR, "SendData wrong");
    }
    HIAI_ENGINE_LOG("[DEBUG] VpcEngine End Process");

    return HIAI_OK;
}

GeneralInferEngine::~GeneralInferEngine()
{
    // Release the pre-allocated memory of outData.
    for (auto buffer : outData_) {
        if (buffer != nullptr) {
            hiai::HIAIMemory::HIAI_DFree(buffer);
            buffer = nullptr;
        }
    }
}

HIAI_StatusT GeneralInferEngine::Init(
    const hiai::AIConfig& config, const std::vector<hiai::AIModelDescription>& model_desc)
{
    HIAI_ENGINE_LOG(this, HIAI_OK, "GeneralInferEngine Init");

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
        HIAI_ENGINE_LOG("[config parser] modelName:%s, modelPath:%s", mm.modelName.c_str(), mm.modelPath.c_str());
        for (auto subItem : item.sub_items()) {
            if ("model_width" == subItem.name()) {
                mm.modelWid = Util::Str2Num(subItem.value());
            }
            if ("model_height" == subItem.name()) {
                mm.modelHei = Util::Str2Num(subItem.value());
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
        HIAI_ENGINE_LOG("config parser modelName:%s", item.name().c_str());
        modelDesc.set_name(item.name());
        modelDesc.set_path(item.value());
        modelDescVec.push_back(modelDesc);
    }

    // 初始化多个模型
    hiai::AIStatus ret = ai_model_manager_->Init(config, modelDescVec);
    if (ret != hiai::SUCCESS) {
        HIAI_ENGINE_LOG(this, HIAI_AI_MODEL_MANAGER_INIT_FAIL, "hiai ai model manager init fail");
        return HIAI_AI_MODEL_MANAGER_INIT_FAIL;
    }
    if (neural_buffer_img_ == nullptr) {
        neural_buffer_img_ = std::shared_ptr<hiai::AINeuralNetworkBuffer>(new hiai::AINeuralNetworkBuffer());
    }

    HIAI_ENGINE_LOG(this, HIAI_OK, "GeneralInferEngine init success");

    return HIAI_OK;
}

void GeneralInferEngine::GetPnetInfo()
{
    for (auto cfg : config_) {
        if (cfg.second.scale > 0) {
            pnetCfg_[cfg.first] = cfg.second;
        }
    }
}

HIAI_StatusT GeneralInferEngine::Infer(
    shared_ptr<EngineTransNewT> imgData, const string& modelName, vector<shared_ptr<IAITensor>>& output_data_vec)
{
    // 设置图片buffer
    neural_buffer_img_->SetBuffer((void*)(imgData->trans_buff.get()), (uint32_t)(imgData->buffer_size), false);

    // 将数据转化为智能指针
    std::shared_ptr<hiai::IAITensor> input_data_img = std::static_pointer_cast<hiai::IAITensor>(neural_buffer_img_);

    // AIModelManager填充输入数据
    std::vector<std::shared_ptr<hiai::IAITensor>> input_data_vec;
    input_data_vec.push_back(input_data_img);

    // 创建out_data_vec
    hiai::AIContext ai_context;
    HIAI_StatusT ret = ai_model_manager_->CreateOutputTensor(input_data_vec, output_data_vec);
    if (hiai::SUCCESS != ret) {
        HIAI_ENGINE_LOG(this, HIAI_AI_MODEL_CREATE_OUTPUT_FAIL, "Failed to create output tensor, ret=%d", ret);
        return HIAI_AI_MODEL_CREATE_OUTPUT_FAIL;
    }

    HIAI_ENGINE_LOG("InferEngine Process Func(OME) Begin");
    // 进行Process处理
    ai_context.AddPara("model_name", modelName);
    ret = ai_model_manager_->Process(ai_context, input_data_vec, output_data_vec, 0);
    HIAI_ENGINE_LOG("InferEngine Process Func(OME) End");
    if (hiai::SUCCESS != ret) {
        HIAI_ENGINE_LOG(this, HIAI_AI_MODEL_MANAGER_PROCESS_FAIL, "Fail to process ai model manager");
        return HIAI_AI_MODEL_MANAGER_PROCESS_FAIL;
    }

    return HIAI_OK;
}

HIAI_StatusT GeneralInferEngine::Infer2(
    shared_ptr<EngineTransNewT> imgData, const string& modelName, FeatMapsData& outData)
{
    HIAI_StatusT ret = HIAI_OK;
    bool preOutBuffer = false;
    std::vector<std::shared_ptr<hiai::IAITensor>> inDataVec;

    // Allocate the Out memory, allocate it in advance.
    if (preOutBuffer == false) {
        std::vector<hiai::TensorDimension> inputTensorDim;
        std::vector<hiai::TensorDimension> outputTensorDim;
        ret = ai_model_manager_->GetModelIOTensorDim(modelName, inputTensorDim, outputTensorDim);
        if (ret != hiai::SUCCESS) {
            HIAI_ENGINE_LOG(this, HIAI_AI_MODEL_MANAGER_INIT_FAIL, "hiai ai model manager init failed!");
            return HIAI_AI_MODEL_MANAGER_INIT_FAIL;
        }

        if (inputTensorDim[0].n != bs_file_) {
            HIAI_ENGINE_LOG(HIAI_IDE_ERROR,
                "batchsize is not the sampel! om batchsize:%d, config file :%d",
                inputTensorDim[0].n,
                bs_file_);
            return HIAI_AI_MODEL_MANAGER_PROCESS_FAIL;
        }
        batchsize_ = inputTensorDim[0].n;
        HIAI_ENGINE_LOG("batchsize: %d", batchsize_);
        HIAI_ENGINE_LOG(
            "inputTensorDim size: %d, outputTensorDim size: %d", inputTensorDim.size(), outputTensorDim.size());
        // allocate OutData in advance
        HIAI_StatusT hiai_ret = HIAI_OK;
        for (uint32_t index = 0; index < outputTensorDim.size(); index++) {
            TensorDimension td = outputTensorDim[index];
            outData.dim.push_back(td);
            hiai::AITensorDescription outputTensorDesc = hiai::AINeuralNetworkBuffer::GetDescription();
            uint8_t* buffer = nullptr;
            HIAI_ENGINE_LOG("outputTensor name: %s, index: %d, w:%d, h:%d, c:%d, size:%d",
                outputTensorDim[index].name.c_str(),
                index,
                outputTensorDim[index].w,
                outputTensorDim[index].h,
                outputTensorDim[index].c,
                outputTensorDim[index].size);
            hiai_ret = hiai::HIAIMemory::HIAI_DMalloc(outputTensorDim[index].size, (void *&)buffer, DMALLOC_TIMEOUT);
            if (hiai_ret != HIAI_OK || buffer == nullptr) {
                HIAI_ENGINE_LOG(HIAI_IDE_ERROR, "HIAI_DMalloc failed");
                continue;
            }
            outData_.push_back(buffer);
            shared_ptr<hiai::IAITensor> outputTensor = hiai::AITensorFactory::GetInstance()->CreateTensor(
                outputTensorDesc, buffer, outputTensorDim[index].size);
            outData.data.push_back(outputTensor);
            outData.cnt++;
        }

        preOutBuffer = true;
    }

    // Transfer buffer to Framework directly, only one inputsize
    hiai::AITensorDescription inputTensorDesc = hiai::AINeuralNetworkBuffer::GetDescription();
    shared_ptr<hiai::IAITensor> inputTensor = hiai::AITensorFactory::GetInstance()->CreateTensor(
        inputTensorDesc, imgData->trans_buff.get(), imgData->buffer_size);
    // AIModelManager. fill in the input data.
    inDataVec.push_back(inputTensor);

    hiai::AIContext ai_context;
    ai_context.AddPara("model_name", modelName);  // 多模型，一定要分别设置模型名字
    // Process work
    HIAI_ENGINE_LOG("inDataVec size: %d, outData size: %d", inDataVec.size(), outData.data.size());
    ret = ai_model_manager_->Process(ai_context, inDataVec, outData.data, 0);
    if (hiai::SUCCESS != ret) {
        HIAI_ENGINE_LOG(this, HIAI_AI_MODEL_MANAGER_PROCESS_FAIL, "Fail to process ai model manager");
        return HIAI_AI_MODEL_MANAGER_PROCESS_FAIL;
    }

    return HIAI_OK;
}

HIAI_StatusT GeneralInferEngine::BatchInfer(
    vector<shared_ptr<EngineTransNewT>>& imgData, const string& modelName, FeatMapsData& outData)
{
    if (imgData.empty()) {
        return HIAI_AI_MODEL_MANAGER_PROCESS_FAIL;
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
    if (inputTensorDim[0].n != bs_file_) {
        HIAI_ENGINE_LOG(HIAI_IDE_ERROR,
            "batchsize is not the sampel! om batchsize:%d, config file: %d",
            inputTensorDim[0].n,
            bs_file_);
        return HIAI_AI_MODEL_MANAGER_PROCESS_FAIL;
    }
    batchsize_ = inputTensorDim[0].n;

    HIAI_ENGINE_LOG("model batchsize:%d", batchsize_);

    HIAI_ENGINE_LOG("inputTensorDim size: %d, outputTensorDim size:%d", inputTensorDim.size(), outputTensorDim.size());

    // allocate OutData in advance
    HIAI_StatusT hiai_ret = HIAI_OK;
    for (uint32_t index = 0; index < outputTensorDim.size(); index++) {
        TensorDimension td = outputTensorDim[index];
        outData.dim.push_back(td);
        HIAI_ENGINE_LOG("outputTensor name:%s, index: %d, w:%d, h:%d, c:%d, n:%d, size:%d",
            outputTensorDim[index].name.c_str(),
            index,
            outputTensorDim[index].w,
            outputTensorDim[index].h,
            outputTensorDim[index].c,
            outputTensorDim[index].n,
            outputTensorDim[index].size);
        hiai::AITensorDescription outputTensorDesc = hiai::AINeuralNetworkBuffer::GetDescription();
        uint8_t* buffer = nullptr;
        hiai_ret = hiai::HIAIMemory::HIAI_DMalloc(outputTensorDim[index].size, (void *&)buffer, DMALLOC_TIMEOUT);
        if (hiai_ret != HIAI_OK || buffer == nullptr) {
            HIAI_ENGINE_LOG(HIAI_IDE_ERROR, "HIAI_DMalloc failed");
            continue;
        }
        outData_.push_back(buffer);
        shared_ptr<hiai::IAITensor> outputTensor =
            hiai::AITensorFactory::GetInstance()->CreateTensor(outputTensorDesc, buffer, outputTensorDim[index].size);
        outData.data.push_back(outputTensor);
        outData.cnt++;
    }

    // filling the batch data to the input
    uint32_t batchBufSize = batchsize_ * imgData[0]->buffer_size;  // 送给模型管家的batch的数据长度
    shared_ptr<uint8_t> inData;
    inData.reset((uint8_t*)HIAI_DVPP_DMalloc(batchBufSize), [](uint8_t* p) { HIAI_DVPP_DFree(p); });
    uint8_t* pData = inData.get();
    for (int i = 0; i < imgData.size(); ++i) {
        err = memcpy_s(pData, batchBufSize, imgData[i]->trans_buff.get(), imgData[i]->buffer_size);
        if (err != EOK) {
            return HIAI_AI_MODEL_MANAGER_PROCESS_FAIL;
        }
        pData += imgData[i]->buffer_size;
    }
    // padding
    if (imgData.size() < batchsize_) {
        uint16_t padNum = batchsize_ - imgData.size();
        err = memset_s(pData, batchBufSize, static_cast<char>(0), imgData[0]->buffer_size * padNum);
        if (err != EOK) {
            return HIAI_AI_MODEL_MANAGER_PROCESS_FAIL;
        }
    }

    // Transfer buffer to Framework directly, only one inputsize
    hiai::AITensorDescription inputTensorDesc = hiai::AINeuralNetworkBuffer::GetDescription();
    shared_ptr<hiai::IAITensor> inputTensor =
        hiai::AITensorFactory::GetInstance()->CreateTensor(inputTensorDesc, inData.get(), batchBufSize);
    // AIModelManager. fill in the input data.
    inDataVec.push_back(inputTensor);

    // process
    hiai::AIContext ai_context;
    ai_context.AddPara("model_name", modelName);  // 多模型，一定要分别设置模型名字
    // Process work
    HIAI_ENGINE_LOG("inDataVec size: %d, outData size: %d", inDataVec.size(), outData.data.size());
    ret = ai_model_manager_->Process(ai_context, inDataVec, outData.data, 0);
    if (hiai::SUCCESS != ret) {
        imgData.clear();
        HIAI_ENGINE_LOG(this, HIAI_AI_MODEL_MANAGER_PROCESS_FAIL, "Fail to process ai model manager");
        return HIAI_AI_MODEL_MANAGER_PROCESS_FAIL;
    }

    imgData.clear();  // 清空batch

    return HIAI_OK;
}

LayerTensor GeneralInferEngine::GetDataByName(const string& layerName, const FeatMapsData& fmData)
{
    for (int i = 0; i < fmData.cnt; ++i) {
        string::size_type pos = fmData.dim[i].name.find(layerName);
        HIAI_ENGINE_LOG("modelName:%s, layername:%s", fmData.dim[i].name.c_str(), layerName.c_str());
        if (string::npos != pos) {
            LayerTensor lt;
            lt.data = fmData.data[i];
            lt.dim = fmData.dim[i];
            HIAI_ENGINE_LOG("find it!");
            return lt;
        }
    }
}

/**
 * ingroup InferEngine
 * brief InferEngine Process函数
 * param [in]：arg0
 */
HIAI_IMPL_ENGINE_PROCESS("GeneralInferEngine", GeneralInferEngine, INFER_ENGINE_INPUT_SIZE)
{
    HIAI_ENGINE_LOG("GeneralInferEngine Process Start");
    HIAI_StatusT ret = HIAI_OK;
    errno_t err = EOK;
    std::shared_ptr<EngineTransNewT> input_arg = std::static_pointer_cast<EngineTransNewT>(arg0);
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

    static double total = 0.0;
    static unsigned int cnt = 0;
    struct timeval start, end;
    gettimeofday(&start, NULL);

    vector<FeatMapsData> allOutDatas;
    for (auto cfg : config_) {
        string modelName = cfg.first;  // 模型名
        ModelMgr mm = cfg.second;      // 模型相关信息

        HIAI_ENGINE_LOG("GeneralInferEngine modelName:%s, modelPath:%s, modelWid:%d, modelHei:%d, scale:%f",
            modelName.c_str(),
            mm.modelPath.c_str(),
            mm.modelWid,
            mm.modelHei,
            mm.scale);
        HIAI_ENGINE_LOG(
            "GeneralInferEngine g_JpegdinWidth:%d, g_JpegdinHeight:%d, g_JpegdoutWidth:%d, g_JpegdoutHeight:%d",
            g_JpegdinWidth,
            g_JpegdinHeight,
            g_JpegdoutWidth,
            g_JpegdoutHeight);

        HIAI_ENGINE_LOG("frameId: %d, isLastFrm: %d", batchData_[0]->frameId, batchData_[0]->isLastFrm);

        // infer
        FeatMapsData outData;
        HIAI_StatusT ret = BatchInfer(batchData_, modelName, outData);
        if (HIAI_OK != ret) {
            std::shared_ptr<EngineReturnDataT> retData = std::make_shared<EngineReturnDataT>();
            retData->processedFrameId = input_arg->frameId;
            retData->realSampleNum = realSize;
            HIAI_ENGINE_LOG(HIAI_IDE_ERROR, "retData->processedFrameId:%d", retData->processedFrameId);
            HIAI_ENGINE_LOG(HIAI_IDE_ERROR, "retData->realSampleNum:%d", retData->realSampleNum);
            hiai::Engine::SendData(0, "EngineReturnDataT", std::static_pointer_cast<void>(retData));

            HIAI_ENGINE_LOG(HIAI_IDE_ERROR, "[ERROR], Infer failed!");
            return ret;
        }
        allOutDatas.push_back(outData);
    }

    gettimeofday(&end, NULL);
    double avg = 0.0;
    double diff = (end.tv_sec - start.tv_sec) * 1000000 + (end.tv_usec - start.tv_usec);
    cnt++;
    if (1 == cnt) {
        total = 0.0;
    } else {
        total += diff;
        avg = total / (cnt - 1);
    }
    HIAI_ENGINE_LOG(HIAI_IDE_ERROR,
        "[Inference Cost] diff time: %f us, avg time: %f us, total time: %f us, count:%d",
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
    HIAI_ENGINE_LOG("InferEngine ouput_data_vec size:%d", sendData.data.size());

    // 遍历所有featuremap输出, 每一个out是一个batch的featuremap的拼接
    for (uint32_t index = 0; index < sendData.data.size(); index++) {
        HIAI_ENGINE_LOG("Infer output index:%d", index);
        // 解析输出代码, output_data包含一个batch的featuremap
        std::shared_ptr<hiai::AINeuralNetworkBuffer> output_data =
            std::static_pointer_cast<hiai::AINeuralNetworkBuffer>(sendData.data[index]);

        OutputT out;
        out.size = output_data->GetSize();
        out.name = sendData.dim[index].name;
        HIAI_ENGINE_LOG("Tensor Name: %s, size: %d", out.name.c_str(), out.size);
        out.data.reset((uint8_t*)new uint8_t[out.size], [](uint8_t* p) { delete[] p; });
        if (output_data->GetBuffer()) {
            err = memcpy_s(out.data.get(), output_data->GetSize(), output_data->GetBuffer(), output_data->GetSize());
            if (err != EOK) {
                HIAI_ENGINE_LOG("memcpy failed");
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

    HIAI_ENGINE_LOG("retData ouput_data_vec size:%d", retData->size);

    hiai::Engine::SendData(0, "EngineReturnDataT", std::static_pointer_cast<void>(retData));

    HIAI_ENGINE_LOG("GeneralInferEngine Process End");

    return HIAI_OK;
}

/**
 * ingroup InferEngine
 * brief InferEngine init函数
 * param [in]：arg0
 */
HIAI_StatusT InferEngine::Init(const hiai::AIConfig& config, const std::vector<hiai::AIModelDescription>& model_desc)
{
    HIAI_ENGINE_LOG(this, HIAI_OK, "InferEngine Init");
    hiai::AIStatus ret = hiai::SUCCESS;

    // 获取配置参数
    config_.clear();
    for (auto item : config.items()) {
        config_[item.name()] = item.value();
    }
    if (ai_model_manager_ == nullptr) {
        ai_model_manager_ = std::make_shared<hiai::AIModelManager>();
    }

    // 初始化模型
    const char* model_path = config_["model_path"].c_str();
    std::vector<hiai::AIModelDescription> model_desc_vec;
    hiai::AIModelDescription model_desc_;
    model_desc_.set_path(model_path);
    model_desc_.set_key("");
    model_desc_vec.push_back(model_desc_);
    ret = ai_model_manager_->Init(config, model_desc_vec);

    if (ret != hiai::SUCCESS) {
        HIAI_ENGINE_LOG(this, HIAI_AI_MODEL_MANAGER_INIT_FAIL, "hiai ai model manager init fail");
        return HIAI_AI_MODEL_MANAGER_INIT_FAIL;
    }

    if (neural_buffer_img == nullptr) {
        neural_buffer_img = std::shared_ptr<hiai::AINeuralNetworkBuffer>(new hiai::AINeuralNetworkBuffer());
    }
    HIAI_ENGINE_LOG(this, HIAI_OK, "InferEngine init success");
    return HIAI_OK;
}

/**
 * ingroup InferEngine
 * brief InferEngine Process函数
 * param [in]：arg0
 */
HIAI_IMPL_ENGINE_PROCESS("InferEngine", InferEngine, INFER_ENGINE_INPUT_SIZE)
{
    HIAI_ENGINE_LOG("InferEngine Process Start");
    errno_t err = EOK;
    std::shared_ptr<EngineTransNewT> input_arg = std::static_pointer_cast<EngineTransNewT>(arg0);
    if (nullptr == input_arg) {
        HIAI_ENGINE_LOG(this, HIAI_INVALID_INPUT_MSG, "fail to process invalid message");
        return HIAI_INVALID_INPUT_MSG;
    }

    // 设置图片buffer
    neural_buffer_img->SetBuffer((void*)(input_arg->trans_buff.get()), (uint32_t)(input_arg->buffer_size), false);

    // 将数据转化为智能指针
    std::shared_ptr<hiai::IAITensor> input_data_img = std::static_pointer_cast<hiai::IAITensor>(neural_buffer_img);

    // AIModelManager填充输入数据
    std::vector<std::shared_ptr<hiai::IAITensor>> input_data_vec;
    input_data_vec.push_back(input_data_img);

    // 创建out_data_vec
    hiai::AIContext ai_context;
    std::vector<std::shared_ptr<hiai::IAITensor>> output_data_vec;
    HIAI_StatusT ret = ai_model_manager_->CreateOutputTensor(input_data_vec, output_data_vec);
    if (hiai::SUCCESS != ret) {
        HIAI_ENGINE_LOG(this, HIAI_AI_MODEL_CREATE_OUTPUT_FAIL, "Failed to create output tensor");
        return HIAI_AI_MODEL_CREATE_OUTPUT_FAIL;
    }

    HIAI_ENGINE_LOG("InferEngine Process Func(OME) Begin");
    // 进行Process处理
    ret = ai_model_manager_->Process(ai_context, input_data_vec, output_data_vec, 0);
    HIAI_ENGINE_LOG("InferEngine Process Func(OME) End");
    if (hiai::SUCCESS != ret) {
        HIAI_ENGINE_LOG(this, HIAI_AI_MODEL_MANAGER_PROCESS_FAIL, "Fail to process ai model manager");
        return HIAI_AI_MODEL_MANAGER_PROCESS_FAIL;
    }

    std::shared_ptr<EngineReturnDataT> retData = std::make_shared<EngineReturnDataT>();
    retData->size = output_data_vec.size();
    HIAI_ENGINE_LOG("InferEngine ouput_data_vec size: %d", output_data_vec.size());
    for (uint32_t index = 0; index < output_data_vec.size(); index++) {
        // 解析输出代码
        std::shared_ptr<hiai::AINeuralNetworkBuffer> output_data =
            std::static_pointer_cast<hiai::AINeuralNetworkBuffer>(output_data_vec[index]);

        OutputT out;
        out.size = output_data->GetSize();
        out.name = output_data->GetName();
        out.data.reset((uint8_t*)new uint8_t[out.size], [](uint8_t* p) { delete[] p; });
        if (out.data.get() && output_data->GetBuffer()) {
            err = memcpy_s(out.data.get(), output_data->GetSize(), output_data->GetBuffer(), output_data->GetSize());
            if (err != EOK) {
                return HIAI_AI_MODEL_MANAGER_PROCESS_FAIL;
            }
        }
        retData->output_data_vec.push_back(out);
    }

    HIAI_ENGINE_LOG("retData ouput_data_vec size: %d", retData->size);
    hiai::Engine::SendData(0, "EngineReturnDataT", std::static_pointer_cast<void>(retData));

    HIAI_ENGINE_LOG("InferEngine Process End");
    return HIAI_OK;
}
