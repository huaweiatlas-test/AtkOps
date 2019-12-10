/*
 * License: Copyright (c) Huawei Technologies Co., Ltd. 2012-2019. All rights reserved.
 * Description: raw data , mutil input tensor实现代码
 * Date: 2019-09-23 14:16:01
 * LastEditTime: 2019-09-30 17:56:39
 */

#include "inc/raw_data_mutil_input_host.h"

#include "hiaiengine/ai_memory.h"

#include "inc/common.h"
#include "inc/util.h"
#include "inc/error_code.h"
#include "inc/sample_data.h"


HIAI_IMPL_ENGINE_PROCESS("RawDataMutilEngine", RawDataMutilEngine, 1)
{
    HIAI_ENGINE_LOG(this, HIAI_OK, "RawDataMutilEngine Process");
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
        std::ifstream fs;
        fs.open(*fileList[index], std::ios::binary);
        if (!fs)
        {
            std::cout << "open binary file failed: " << *fileList[index] << std::endl;
            return HIAI_INVALID_INPUT_MSG;
        }
        float inputNum;
        float inputSize;
        float* inputData;

        // 读取文件头部信息中的input_num字段
        fs.read((char*)&(inputNum), sizeof(inputNum));
        cout << "=================" << endl;
        printf("inputnum=%f\n", inputNum);

        // 读取文件头部的每一个tensor的字节数
        vector<float> bytesOfTensors((uint32_t)inputNum);
        for (int i = 0; i < (uint32_t)inputNum; ++i) {
            fs.read((char*)&bytesOfTensors[i], sizeof(bytesOfTensors[i]));
        }

        std::shared_ptr<MutilInputData> raw_data_ptr = std::make_shared<MutilInputData>();
        raw_data_ptr->frameId = index;
        raw_data_ptr->isLastFrm = index == sendCnt - 1 ? true : false;
        
        // 分段读取每一个输入tensor
        for (int i = 0; i < (uint32_t)inputNum; ++i) {
            char * buffer = nullptr;
            HIAI_StatusT getRet = hiai::HIAIMemory::HIAI_DMalloc((uint32_t)bytesOfTensors[i], (void*&)buffer, 10000);
            if (HIAI_OK != getRet || nullptr == buffer)
            {
                std::cout << "ReadBinFile HIAI_DMalloc failed: " << *fileList[index] << std::endl;
                return HIAI_INVALID_INPUT_MSG;
            }
            fs.read(buffer, (uint32_t)bytesOfTensors[i]);
            InputTensor tensor;
            tensor.size = (uint32_t)bytesOfTensors[i];
            tensor.data.reset((unsigned char*)buffer, [](unsigned char *p){});
            raw_data_ptr->inputs.push_back(tensor);
        }
        
        hiai::Engine::SendData(0, "MutilInputData", std::static_pointer_cast<void>(raw_data_ptr));    
    }
    HIAI_ENGINE_LOG(this, HIAI_OK, "RawDataMutilEngine Process Success");  

    return HIAI_OK;
}