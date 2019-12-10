/*
 * License: Copyright (c) Huawei Technologies Co., Ltd. 2012-2019. All rights reserved.
 * Description: raw data engine实现代码
 * Date: 2019-09-23 14:16:01
 * LastEditTime: 2019-09-25 14:32:38
 */

#include "inc/raw_data_host.h"

#include "inc/common.h"
#include "inc/util.h"
#include "inc/error_code.h"
#include "inc/sample_data.h"

HIAI_IMPL_ENGINE_PROCESS("RawDataEngine", RawDataEngine, 1)
{
    HIAI_ENGINE_LOG(this, HIAI_OK, "RawDataEngine Process");
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
        char* bufData = Util::ReadBinFile(fileList[index], 0, &bufSize);

        std::shared_ptr<EngineTransNewT> raw_data_ptr = std::make_shared<EngineTransNewT>();
        raw_data_ptr->frameId = index;
        raw_data_ptr->isLastFrm = index == sendCnt - 1 ? true : false; 
        raw_data_ptr->buffer_size = bufSize;
        raw_data_ptr->trans_buff.reset((unsigned char*)bufData, [](unsigned char* p){});
        
        hiai::Engine::SendData(0, "EngineTransNewT", std::static_pointer_cast<void>(raw_data_ptr));        
    }
    HIAI_ENGINE_LOG(this, HIAI_OK, "RawDataEngine Process Success");

    return HIAI_OK;
}