/*
 * License: Copyright (c) Huawei Technologies Co., Ltd. 2012-2019. All rights reserved.
 * Description: 传输数据结构的定义，序列化、反序列化
 * Date: 2019-08-22 15:30:17
 * LastEditTime: 2019-09-24 15:56:28
 */

#include "inc/sample_data.h"
#include "hiaiengine/data_type.h"

// EngineTransNewT 注册序列化和反序列化函数
/**
 * ingroup hiaiengine
 * brief GetTransSearPtr,        序列化Trans数据
 * param [in] : data_ptr         结构体指针
 * param [out]：struct_str       结构体buffer
 * param [out]：data_ptr         结构体数据指针buffer
 * param [out]：struct_size      结构体大小
 * param [out]：data_size        结构体数据大小
 */
void GetTransSearPtr(void *inputPtr, std::string &ctrlStr, uint8_t *&dataPtr, uint32_t &dataLen)
{
    EngineTransNewT* engineTrans = (EngineTransNewT*)inputPtr;
    ctrlStr = std::string((char*)inputPtr, sizeof(EngineTransNewT));
    dataPtr = (uint8_t*)engineTrans->trans_buff.get();
    dataLen = engineTrans->buffer_size;
}

/**
 * ingroup hiaiengine
 * brief GetTransSearPtr,             反序列化Trans数据
 * param [in] : ctrl_ptr              结构体指针
 * param [in] : data_ptr              结构体数据指针
 * param [out]：std::shared_ptr<void> 传给Engine的指针结构体指针
 */
std::shared_ptr<void> GetTransDearPtr(
    const char* ctrlPtr, const uint32_t& ctrlLen, const uint8_t* dataPtr, const uint32_t& dataLen)
{
    EngineTransNewT* engineTrans = (EngineTransNewT*)ctrlPtr;
    std::shared_ptr<EngineTransNewT> engineTranPtr(new EngineTransNewT);
    engineTranPtr->buffer_size = engineTrans->buffer_size;
    engineTranPtr->frameId = engineTrans->frameId;
    engineTranPtr->isLastFrm = engineTrans->isLastFrm;
    engineTranPtr->trans_buff.reset(const_cast<uint8_t *>(dataPtr), hiai::Graph::ReleaseDataBuffer);
    return std::static_pointer_cast<void>(engineTranPtr);
}

// 注册EngineTransNewT
HIAI_REGISTER_SERIALIZE_FUNC("EngineTransNewT", EngineTransNewT, GetTransSearPtr, GetTransDearPtr);
