/*
 * License: Copyright (c) Huawei Technologies Co., Ltd. 2012-2019. All rights reserved.
 * Description: common接口
 * Date: 2019-02-28
 * LastEditTime: 2019-09-24 15:57:29
 */
#ifndef INC_COMMON_H_
#define INC_COMMON_H_
#include <hiaiengine/data_type_reg.h>
#include <hiaiengine/ai_types.h>
#include <iostream>
#include <string>

using namespace hiai;

#define DMALLOC_TIMEOUT 1000
// 定义全局值
// 定义文件路径
static std::string TEST_SRC_FILE_PATH = "";
static std::string engine_config_path = "";
static std::string test_img_list_path = "";

// 定义Graph、Engine ID
static uint32_t graph_id = 100;
static uint32_t src_engine_id = 1000;
static const uint32_t SRC_PORT_ID = 0;
static uint32_t des_engine_id = 1001;
static const uint32_t DEST_PORT_ID_0 = 0;
static const uint32_t DEST_PORT_ID_1 = 1;

// 定义全局变量
static std::mutex g_local_test_mutex;
static std::condition_variable g_local_test_cv_;
static bool is_test_result_ready = false;
static const uint32_t MAX_SLEEP_TIMER = 24 * 60 * 60;  // 24h
static const uint32_t MIN_ARG_VALUE = 2;
// 定义图片参数
static uint32_t g_SendCount = 0;

static uint32_t g_ModelWidth = 0;
static uint32_t g_ModelHeight = 0;

// 定义message_type字符创
static const std::string message_type_engine_trans = "EngineTransT";
static const std::string message_type = "EngineTransNewT";

// 定义Engine端口数量
// Source Engine
#define SOURCE_ENGINE_INPUT_SIZE 1
#define SOURCE_ENGINE_OUTPUT_SIZE 1

// Dest Engine
#define DEST_ENGINE_INPUT_SIZE 1
#define DEST_ENGINE_OUTPUT_SIZE 1

// Infer Engine
#define INFER_ENGINE_INPUT_SIZE 1
#define INFER_ENGINE_OUTPUT_SIZE 1

// RawData Engine
#define RAWDATA_ENGINE_INPUT_SIZE 1
#define RAWDATA_ENGINE_OUTPUT_SIZE 1

#define IMAGE_INFO_DATA_NUM (3)

// 定义传输结构体
typedef struct EngineTrans {
    std::string trans_buff;
    uint32_t buffer_size;
    HIAI_SERIALIZE(trans_buff, buffer_size);
} EngineTransT;

// 模型信息结构体
typedef struct tag_ModelManager {
    std::string modelName;
    std::string modelPath;
    uint32_t modelWid;
    uint32_t modelHei;
    float scale;
    uint16_t batchsize;
} ModelMgr;

// 特征层的数据及维度等信息
typedef struct tag_LayerTensor {
    shared_ptr<IAITensor> data;
    TensorDimension dim;
} LayerTensor;

// 单个模型的所有输出(all featuremap all batch)
typedef struct tag_FeatureMapsData {
    vector<shared_ptr<IAITensor>> data;  // 多个输出tensor, 比如多个featuremap输出
    vector<TensorDimension> dim;         // 与data一一对应的tensor的维度等信息
    uint32_t cnt = 0;

} FeatMapsData;

#endif  // INC_COMMON_H_
