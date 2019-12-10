/*
 * License: Copyright (c) Huawei Technologies Co., Ltd. 2012-2019. All rights reserved.
 * Description: 结构体定义，序列化反序列化
 * Date: 2019-02-28
 * @LastEditTime: 2019-09-27 15:30:51
 */
#ifndef INC_SAMPLE_DATA_H_
#define INC_SAMPLE_DATA_H_

#include "hiaiengine/data_type.h"
#include "hiaiengine/data_type_reg.h"
#include <vector>

using std::vector;

// 注册Engine将流转的结构体, 单tensor输入
typedef struct EngineTransNew {
    std::shared_ptr<uint8_t> trans_buff;
    uint32_t buffer_size;  // buffer大小
    uint32_t frameId;      // 帧号
    bool isLastFrm;        // 是否是最后一帧图像
} EngineTransNewT;

// 注册Engine将流转的结构体, input对应tensor
typedef struct tagInputTensor {
    int32_t size;                   // data的字节数
    std::shared_ptr<uint8_t> data;  // 字节流
} InputTensor;
template <class Archive>
void serialize(Archive& ar, InputTensor& data)
{
    ar(data.size);
    if (data.size > 0 && data.data.get() == nullptr) {
        data.data.reset(new uint8_t[data.size], [](uint8_t* p) { delete[] p; });
    }

    ar(cereal::binary_data(data.data.get(), data.size * sizeof(uint8_t)));
}

// 多个tesnsor输入的结构体
typedef struct tagMutilInputData {
    uint32_t frameId;
    bool isLastFrm;
    vector<InputTensor> inputs;  // 多个输入tensor的vector
} MutilInputData;
template <class Archive>
void serialize(Archive& ar, MutilInputData& mData)
{
    ar(mData.frameId);
    ar(mData.isLastFrm);
    ar(mData.inputs);
}

// 注册Engine将流转的结构体, outputT对应featuremap
typedef struct Output {
    int32_t size;  // data的字节数
    std::string name;
    std::shared_ptr<uint8_t> data;  // 字节流
} OutputT;
template <class Archive>
void serialize(Archive& ar, OutputT& data)
{
    ar(data.size);
    ar(data.name);
    if (data.size > 0 && data.data.get() == nullptr) {
        data.data.reset(new uint8_t[data.size], [](uint8_t* p) { delete[] p; });
    }

    ar(cereal::binary_data(data.data.get(), data.size * sizeof(uint8_t)));
}

typedef struct EngineReturnData {
    // 推理引擎耗时
    double inferDiff;   // 当前帧/batch推理耗时
    double inferAvg;    // 平均耗时
    double inferTotal;  // 总耗时

    uint16_t batchsize;
    uint16_t realSampleNum;     // 一个batchsize中真实的样本个数
    uint32_t size;              // tensor的数目，即output_data_vec的size, 表示模型有多少个featuremap输出
    uint32_t processedFrameId;  // 当前已经处理完的帧号
    vector<OutputT> output_data_vec;  // 多个featuremap的vector, 每一个vector的元素都是由batch个featuremap拼接而成一维数组

} EngineReturnDataT;
template <class Archive>
void serialize(Archive& ar, EngineReturnDataT& data)
{
    ar(data.inferDiff);
    ar(data.inferAvg);
    ar(data.inferTotal);
    ar(data.batchsize);
    ar(data.realSampleNum);
    ar(data.size, data.processedFrameId, data.output_data_vec);
}

#endif  // INC_SAMPLE_DATA_H_
