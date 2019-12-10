/*
 * License: Copyright (c) Huawei Technologies Co., Ltd. 2012-2019. All rights reserved.
 * Description: device侧engine接口
 * Date: 2019-02-28
 * @LastEditTime: 2019-09-29 10:41:14
 */
#ifndef INC_CLASSIFY_NET_AI_ENGINE_H_
#define INC_CLASSIFY_NET_AI_ENGINE_H_

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

// Jpegd Engine
class JpegdEngine : public hiai::Engine {
    HIAI_DEFINE_PROCESS(1, 1);
};

// Vpc Engine
class VpcEngine : public hiai::Engine {
    HIAI_StatusT Init(const hiai::AIConfig& config, const std::vector<hiai::AIModelDescription>& model_desc);

    HIAI_DEFINE_PROCESS(1, 1);

private:
    std::map<std::string, uint32_t> config_;  // config配置map
};

#endif  // INC_CLASSIFY_NET_AI_ENGINE_H_

class InferEngine : public hiai::Engine {
public:
    /**
     * ingroup InferEngine
     * brief InferEngine 初始化函数
     * param [in]：config, 配置参数
     * param [in]: model_desc, 模型描述
     * param [out]: HIAI_StatusT
     */
    HIAI_StatusT Init(const hiai::AIConfig& config, const std::vector<hiai::AIModelDescription>& model_desc);

    /**
     * ingroup InferEngine
     * brief InferEngine 执行函数
     * param [in]：INFER_ENGINE_INPUT_SIZE， in端口数量
     * param [in]: INFER_ENGINE_OUTPUT_SIZE, out端口数量
     * param [out]: HIAI_StatusT
     */
    HIAI_DEFINE_PROCESS(INFER_ENGINE_INPUT_SIZE, INFER_ENGINE_OUTPUT_SIZE);

private:
    std::map<std::string, std::string> config_;               // config配置map
    std::shared_ptr<hiai::AIModelManager> ai_model_manager_;  // 模型管家实例

    std::shared_ptr<hiai::AINeuralNetworkBuffer> neural_buffer_img;  // 输入Buffer
};

// 通用的InferEngine, 单模型，batchsize
class BatchInferEngine : public hiai::Engine {
public:
    ~BatchInferEngine();
    /**
     * ingroup BatchInferEngine
     * brief BatchInferEngine 初始化函数
     * param [in]：config, 配置参数
     * param [in]: model_desc, 模型描述
     * param [out]: HIAI_StatusT
     */
    HIAI_StatusT Init(const hiai::AIConfig& config, const std::vector<hiai::AIModelDescription>& model_desc);

    /**
     * ingroup BatchInferEngine
     * brief BatchInferEngine 执行函数
     * param [in]：INFER_ENGINE_INPUT_SIZE， in端口数量
     * param [in]: INFER_ENGINE_OUTPUT_SIZE, out端口数量
     * param [out]: HIAI_StatusT
     */
    HIAI_DEFINE_PROCESS(INFER_ENGINE_INPUT_SIZE, INFER_ENGINE_OUTPUT_SIZE);

private:
    // batchsize
    HIAI_StatusT BatchInfer(
        vector<shared_ptr<EngineTransNewT>> imgData, const string& modelName, FeatMapsData& output_data_vec);

private:
    std::map<std::string, ModelMgr> config_;                  // config配置map
    std::shared_ptr<hiai::AIModelManager> ai_model_manager_;  // 模型管家实例

    std::shared_ptr<hiai::AINeuralNetworkBuffer> neural_buffer_img_;  // 输入Buffer

    std::vector<std::shared_ptr<hiai::IAITensor>> outDataVec_;
    std::vector<uint8_t *> outData_;

    uint16_t bs_file_;    // .config文件配置的batchsize, 需要与batchsize_校验一致性
    uint16_t batchsize_;  // om模型的batchsize

    vector<shared_ptr<EngineTransNewT>> batchData_;
};

// 通用的InferEngine
class GeneralInferEngine : public hiai::Engine {
public:
    ~GeneralInferEngine();
    /**
     * ingroup GeneralInferEngine
     * brief GeneralInferEngine 初始化函数
     * param [in]：config, 配置参数
     * param [in]: model_desc, 模型描述
     * param [out]: HIAI_StatusT
     */
    HIAI_StatusT Init(const hiai::AIConfig& config, const std::vector<hiai::AIModelDescription>& model_desc);

    /**
     * ingroup GeneralInferEngine
     * brief GeneralInferEngine 执行函数
     * param [in]：INFER_ENGINE_INPUT_SIZE， in端口数量
     * param [in]: INFER_ENGINE_OUTPUT_SIZE, out端口数量
     * param [out]: HIAI_StatusT
     */
    HIAI_DEFINE_PROCESS(INFER_ENGINE_INPUT_SIZE, INFER_ENGINE_OUTPUT_SIZE);

private:
    // single model infer
    HIAI_StatusT Infer(
        shared_ptr<EngineTransNewT> imgData, const string& modelName, vector<shared_ptr<IAITensor>>& output_data_vec);

    // mutil model infer
    HIAI_StatusT Infer2(shared_ptr<EngineTransNewT> imgData, const string& modelName, FeatMapsData& output_data_vec);

    // batchsize
    HIAI_StatusT BatchInfer(
        vector<shared_ptr<EngineTransNewT>>& imgData, const string& modelName, FeatMapsData& output_data_vec);

    void GetPnetInfo();

    LayerTensor GetDataByName(const string& layerName, const FeatMapsData& fmData);

private:
    std::map<std::string, ModelMgr> config_;                  // config配置map
    std::shared_ptr<hiai::AIModelManager> ai_model_manager_;  // 模型管家实例

    std::shared_ptr<hiai::AINeuralNetworkBuffer> neural_buffer_img_;  // 输入Buffer

    std::vector<std::shared_ptr<hiai::IAITensor>> outDataVec_;
    std::vector<uint8_t *> outData_;

    std::map<std::string, ModelMgr> pnetCfg_;  // pnetCfg_配置map

    uint16_t bs_file_ = 1;    // .config文件配置的batchsize, 需要与batchsize_校验一致性
    uint16_t batchsize_ = 1;  // om模型的batchsize

    vector<shared_ptr<EngineTransNewT>> batchData_;
};
