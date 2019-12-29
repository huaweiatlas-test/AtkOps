/*
 * License: Copyright (c) Huawei Technologies Co., Ltd. 2012-2019. All rights reserved.
 * Description: 裸数据多输入的推理engine
 * Date: 2019-09-29 10:37:42
 * LastEditTime: 2019-09-29 11:25:41
 */

#ifndef RAW_DATA_MUTIL_INFER_H
#define RAW_DATA_MUTIL_INFER_H

#include <string>
#include <vector>
#include <map>
#include <memory>

#include <hiaiengine/ai_tensor.h>
#include <hiaiengine/ai_model_manager.h>

#include "inc/common.h"
#include "inc/sample_data.h"

using hiai::AIConfig;
using hiai::AIModelDescription;
using hiai::AIModelManager;
using hiai::IAITensor;
using std::shared_ptr;
using std::vector;

// Raw data (mutil input) Infer Engine
class RawDataMutilInferEngine : public hiai::Engine {
public:
    ~RawDataMutilInferEngine();

    HIAI_StatusT Init(const hiai::AIConfig& config, const std::vector<hiai::AIModelDescription>& model_desc);

    HIAI_DEFINE_PROCESS(INFER_ENGINE_INPUT_SIZE, INFER_ENGINE_OUTPUT_SIZE);

private:
    // batchsize
    HIAI_StatusT BatchInfer(
        vector<shared_ptr<MutilInputData>>& imgData, const string& modelName, FeatMapsData& output_data_vec);

private:
    std::map<std::string, ModelMgr> config_;                  // config配置map
    std::shared_ptr<hiai::AIModelManager> ai_model_manager_;  // 模型管家实例

    std::shared_ptr<hiai::AINeuralNetworkBuffer> neural_buffer_img_;  // 输入Buffer

    std::vector<std::shared_ptr<hiai::IAITensor>> outDataVec_;
    std::vector<uint8_t *> outData_;

    uint16_t bs_file_ = 1;    // .config文件配置的batchsize, 需要与batchsize_校验一致性
    uint16_t batchsize_ = 1;  // om模型的batchsize

    vector<shared_ptr<MutilInputData>> batchData_;
};

#endif  // RAW_DATA_MUTIL_INFER_H
