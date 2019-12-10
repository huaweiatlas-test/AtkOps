/*
 * License: Copyright (c) Huawei Technologies Co., Ltd. 2012-2019. All rights reserved.
 * Description: host 数据接收接口实现
 * Date: 2019-02-28
 * LastEditTime: 2019-09-26 12:26:52
 */
#include <fstream>
#include <iostream>
#include <algorithm>
#include <functional>
#include <string>
#include "inc/data_recv.h"
#include "inc/error_code.h"
#include "inc/common.h"
#include "inc/sample_data.h"
#include "inc/util.h"

using namespace std;

extern uint32_t g_count;
extern std::string g_resultSavePath;
extern int g_state;

InferDataRecvInterface::~InferDataRecvInterface()
{

}

void SaveEscapedTime(const string& savePath, const shared_ptr<EngineReturnData>& retData)
{
    string escapedTime = savePath + "escaped_time.txt";
    ofstream of(escapedTime);
    of << "diff: " << retData->inferDiff << "us" << std::endl;
    of << "avg: " << retData->inferAvg << "us" << std::endl;
    of << "total: " << retData->inferTotal << "us" << std::endl;

    of.close();
}

/**
* brief RecvData RecvData回调，保存文件
*/
HIAI_StatusT InferDataRecvInterface::RecvData(const std::shared_ptr<void>& message)
{
    HIAI_ENGINE_LOG("Receive data begin");
    std::shared_ptr<EngineReturnDataT> msg = std::static_pointer_cast<EngineReturnDataT>(message);
    if (nullptr == msg) {
        HIAI_ENGINE_LOG("Fail to receive data");
        return HIAI_INVALID_INPUT_MSG;
    }
    errno_t err = EOK;
    uint32_t processedFrameId = msg->processedFrameId;

    std::cout << "processedFrameId: " << processedFrameId <<  std::endl;
    std::cout << "realSampleNum: " << msg->realSampleNum <<  std::endl;
    
    // 遍历batch
    for (int i = 0; i < msg->realSampleNum; ++i) {
        g_count++;
        std::cout << "RecvData g_count: " << g_count <<  std::endl;

        std::cout << "user parser model output data..." << std::endl;
        // user parser model output data
        string savePath = g_resultSavePath;
        string sampleId;
        sampleId = Util::Num2Str(g_count);
        savePath = savePath + "/sample" + sampleId + "_";

        std::cout << "receive data msg size(output_data_vec size): " << msg->size << std::endl;
        
        // 遍历featuremap
        for (int j = 0; j < msg->output_data_vec.size(); ++j) {
            OutputT out = msg->output_data_vec[j];

            std::cout << "recv Tensor Name: " << out.name.c_str() << " " << "size: " << out.size << std::endl;

            // 对于某一个featuremap, out.data中保存了整个batch的数据
            float *data = (float*)(out.data.get());
            uint32_t size = out.size / sizeof(float);    

            std::cout << "Tensor element size: " << size << std::endl;
            
            // 除以batchsize, 不能除以realSampleNum, 因为推理的时候是padding到一个batch的
            uint32_t singleSize = size / msg->batchsize;
            data += i * singleSize;

            std::cout << "recv singleSize: " << singleSize << " " << "realNum: " << msg->realSampleNum << std::endl;

            // 将tensor name中的"/"替换为"_"
            string tensorName = out.name;
            std::replace_if(tensorName.begin(), tensorName.end(), bind2nd(std::equal_to<char>(), '/'), '_');

            string fmSavePath = savePath + tensorName + ".bin";
            cout << "fmSavePath:" << fmSavePath << endl;

            HIAI_ENGINE_LOG("receive data(output_data) size: %d", singleSize);
            char path[PATH_MAX] = {0};
            if (realpath(fmSavePath.c_str(), path) == NULL) {
                HIAI_ENGINE_LOG("======================realpath error: %d   :%s", err, strerror(err));
            }
            FILE* fp = fopen(path, "ab");
            if (fp) {
                fwrite(data, singleSize * sizeof(float), 1, fp);
                fclose(fp);
            } else {
                HIAI_ENGINE_LOG("======================fopen error");
            }
        }

    }  

    // save time
    string savePath = g_resultSavePath;
    string sampleId;
    sampleId = Util::Num2Str(g_count);
    savePath = savePath + "/sample" + sampleId + "_";
    SaveEscapedTime(savePath, msg);
    
    std::cout << "user parser model output data finished!" << std::endl;

    if (msg->size > 0) {
        g_state = 0;
    } else {
        g_state = -1;
    }
    return HIAI_OK;
}
