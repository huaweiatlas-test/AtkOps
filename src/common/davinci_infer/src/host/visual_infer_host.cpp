/*
 * License: Copyright (c) Huawei Technologies Co., Ltd. 2012-2019. All rights reserved.
 * Description: host engine实现代码
 * Date: 2019-02-28
 * LastEditTime: 2019-09-27 11:31:33
 */

#include <unistd.h>
#include <thread>
#include <hiaiengine/data_type.h>
#include <vector>
#include <fstream>
#include <algorithm>
#include <iostream>
#include <string>
#include "inc/visual_infer_host.h"
#include "inc/common.h"
#include "inc/util.h"
#include "inc/error_code.h"
#include "inc/sample_data.h"
#include <time.h>

#include "hiaiengine/c_graph.h"
#include "hiaiengine/ai_memory.h"
#include <dvpp/dvpp_config.h>

// 同侧只需要注册一次，不同侧要分别注册
HIAI_REGISTER_DATA_TYPE("OutputT", OutputT);
HIAI_REGISTER_DATA_TYPE("EngineReturnDataT", EngineReturnDataT);
HIAI_REGISTER_DATA_TYPE("InputTensor", InputTensor);
HIAI_REGISTER_DATA_TYPE("MutilInputData", MutilInputData);

DestEngine::~DestEngine()
{

}

void Delay(int time)
{
    clock_t now = clock();
    while (clock() - now < time) { }
}

void ReleaseDataBuffer(void* ptr)
{
    // do nothing
}

/**
* ingroup SourceEngine
* brief SourceEngine Process函数
* param [in]：arg0
*/
HIAI_IMPL_ENGINE_PROCESS("SourceEngine", SourceEngine, 1)
{
    HIAI_ENGINE_LOG(this, HIAI_OK, "SourceEngine Process");
    // 获取原始文件路径
    std::shared_ptr<std::string> input_arg = std::static_pointer_cast<std::string>(arg0);
    if (nullptr == input_arg)
    {
        HIAI_ENGINE_LOG(this, HIAI_INVALID_INPUT_MSG, "fail to process invalid message");
        return HIAI_INVALID_INPUT_MSG;
    }

    vector<std::shared_ptr<std::string>> fileList = Util::GetFilenameList(input_arg);
    uint32_t sendCnt = fileList.size();

    for (uint32_t index = 0; index < sendCnt; index++)
    {
        std::cout << "SendData index: " << index << " Total Count: " << sendCnt << std::endl;
        // 读取数据， 生成信息
        uint32_t bufSize = 0;
        char* bufData = Util::ReadBinFile(fileList[index], 8, &bufSize);

        std::shared_ptr<EngineTransNewT> raw_data_ptr = std::make_shared<EngineTransNewT>();
        raw_data_ptr->frameId = index;
        raw_data_ptr->isLastFrm = index == sendCnt - 1 ? true : false; 
        raw_data_ptr->buffer_size = bufSize;
        raw_data_ptr->trans_buff.reset((unsigned char*)bufData, ReleaseDataBuffer);
        
        hiai::Engine::SendData(0, "EngineTransNewT", std::static_pointer_cast<void>(raw_data_ptr));        
    }
    HIAI_ENGINE_LOG(this, HIAI_OK, "SourceEngine Process Success");

    return HIAI_OK;
}
/**
* ingroup DestEngine
* brief DestEngine Process函数
* param [in]：arg0
*/
HIAI_IMPL_ENGINE_PROCESS("DestEngine", DestEngine, DEST_ENGINE_INPUT_SIZE)
{
    HIAI_ENGINE_LOG(this, HIAI_OK, "DestEngine Process");
    std::shared_ptr<EngineReturnDataT> input_arg = std::static_pointer_cast<EngineReturnDataT>(arg0);
    if (nullptr == input_arg)
    {
        HIAI_ENGINE_LOG(this, HIAI_INVALID_INPUT_MSG, "fail to process invalid message");
        return HIAI_INVALID_INPUT_MSG;
    }

    HIAI_ENGINE_LOG("DestEngine data msg size(output_data_vec size): %d", input_arg->size);

    hiai::Engine::SendData(0, "EngineReturnDataT", std::static_pointer_cast<void>(input_arg));

    HIAI_ENGINE_LOG(this, HIAI_OK, "DestEngine Process Success");
    
    return HIAI_OK;
}
