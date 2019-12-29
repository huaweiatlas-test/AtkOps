/*
 * Copyright © Huawei Technologies Co., Ltd. 2012-2019. All rights reserved.
 * Description: Definition of custom_engine
 */
#include "custom_engine.h"
#include "error_code.h"
#include <algorithm>
#include <fstream>
#include <hiaiengine/ai_types.h>
#include <hiaiengine/log.h>
#include <iostream>
#include <thread>
#include <unistd.h>
#include <vector>
#include <hiaiengine/graph.h>
#include <sys/time.h>
#include "../common/op_attr.h"

#define CUSTOM_SUCCESS 0
#define CUSTOM_FAILED -1
#define RT_DEV_BINARY_MAGIC_ELF 0
#define RT_DEV_BINARY_MAGIC_ELF_AICPU 1
#define RT_DEV_BINARY_MAGIC_ELF_AICPU_OPERATOR 2
#define TIMEM	1000000.0

#define BASE_NAME "/tmp/"

#define HIAI_RETURN_IF_ERROR(expr)  \
do  \
{   \
    const int _status = (expr); \
    if(_status != 0) \
    { \
        HIAI_ENGINE_LOG(HIAI_IDE_ERROR, "Custom operator engine run failed!"); \
        return HIAI_ERROR; \
    } \
}while (0)

class TempFile
{
public:
    TempFile(std::string fileNameStr) : fileName(fileNameStr) {}

    ~TempFile()
    {
        std::remove(fileName.c_str());
    }

    int32_t Write(const CustomFileBlob& fileBlob)
    {
        return WriteFile(fileName.c_str(), fileBlob.data.get(), fileBlob.size);
    }

    int32_t Read(CustomFileBlob& fileBlob)
    {
        std::ifstream file(fileName, std::ios::binary | std::ios::ate);
        if (!file.is_open()) {
            return CUSTOM_FAILED;
        }

        uint32_t length = file.tellg();
        file.seekg(0, std::ios::beg);

        fileBlob.size = length;

        shared_ptr< char > dataPtr(new char[ length ](), [](char* p) {
            delete[] p;
        });
        fileBlob.data = dataPtr;

        file.read(dataPtr.get(), length);
        file.close();
        return CUSTOM_SUCCESS;
    }

    std::string fileName;
};

int CustomOpRun(std::shared_ptr<CustomInfo> customInfo, vector<string> inFileNames, vector<string> outFileNames,
                vector<uint32_t> outBufSizes, vector<uint32_t> workspaceSizes, double &time)
{

    string binFileName = "";


    HIAI_ENGINE_LOG(HIAI_IDE_INFO, "Custom operator run start!");
    HIAI_ENGINE_LOG(HIAI_IDE_INFO, "Run params,name:%s, type:%d, input size=%d.", customInfo->name.c_str(),
                    customInfo->type, customInfo->inputList.size());
    custom::ErrorInfo result;
    if (customInfo->type == RT_DEV_BINARY_MAGIC_ELF_AICPU_OPERATOR) {
        OpAttr opAttr;
        setOpParam(&opAttr);
        // create config file
        string configFileName = string(BASE_NAME) + "configFile";
        TempFile configFile = TempFile(configFileName);
        HIAI_RETURN_IF_ERROR(configFile.Write(customInfo->configFile));
        // create bin file
        binFileName = string(BASE_NAME) + "binFile ";
        TempFile binFile = TempFile(binFileName);
        HIAI_RETURN_IF_ERROR(binFile .Write(customInfo->binFile));
        
        struct timeval t1, t2;
        gettimeofday(&t1, NULL);
        result = custom::custom_op_run(customInfo->name, customInfo->type, binFileName,
                                       inFileNames, outFileNames, outBufSizes, workspaceSizes, configFileName, &opAttr, sizeof(OpAttr));                          
        gettimeofday(&t2, NULL);
        time = t2.tv_sec - t1.tv_sec + (t2.tv_usec - t1.tv_usec) / TIMEM;
        
    } else {
        // create bin file
        binFileName = string(BASE_NAME) + "tvm_op_run_temp_file_bin_file.o";
        TempFile binFile = TempFile(binFileName);
        HIAI_RETURN_IF_ERROR(binFile .Write(customInfo->binFile));
        struct timeval t1, t2;
        gettimeofday(&t1, NULL);
        result = custom::custom_op_run(customInfo->name, customInfo->type, binFileName,
                                       inFileNames, outFileNames, outBufSizes);
        gettimeofday(&t2, NULL);
        time = t2.tv_sec - t1.tv_sec + (t2.tv_usec - t1.tv_usec) / TIMEM;
        
    }
    
    HIAI_ENGINE_LOG(HIAI_IDE_INFO, "Custom operator run end!");
    if (result.error_code != 0) {
        HIAI_ENGINE_LOG(HIAI_IDE_ERROR, "Engine run failed, error_code: %d, message: %s.", result.error_code,
                        result.error_msg.c_str());
        return HIAI_ERROR;
    } else {
        HIAI_ENGINE_LOG(HIAI_IDE_INFO, "Engine run success.");
    }
    return HIAI_OK;
}
HIAI_IMPL_ENGINE_PROCESS("CUSTOMEngine", CUSTOMEngine, CUSTOM_ENGINE_INPUT_SIZE)
{
    HIAI_StatusT ret = HIAI_OK;
    // Framework
    HIAI_ENGINE_LOG(HIAI_IDE_INFO, "Engine process begin!");
    if (arg0 == NULL) {
        HIAI_ENGINE_LOG(HIAI_IDE_ERROR, "Custom info is NULL!");
        return HIAI_ERROR;
    }
    std::shared_ptr<CustomInfo> customInfo = std::static_pointer_cast<CustomInfo>(arg0);
    if (nullptr == customInfo) {
        HIAI_ENGINE_LOG(HIAI_IDE_ERROR, "Fail to process invalid message.");
        return HIAI_INVALID_INPUT_MSG;
    }

    std::shared_ptr< CustomOutput > customOutput = std::make_shared< CustomOutput >();
    vector< string > inFileNames;
    vector< shared_ptr<TempFile> > inFiles;

    for (uint32_t j = 0; j < customInfo->inputList.size(); j++) {
        stringstream ss;
        ss << BASE_NAME << "input_"  << j;
        inFiles.push_back(make_shared<TempFile>(ss.str()));
        HIAI_RETURN_IF_ERROR(inFiles[ j ]->Write(customInfo->inputList[ j ]));
        inFileNames.push_back(inFiles[j]->fileName);
    }




    // create out file
    vector< uint32_t > outBufSizes;
    vector< uint32_t > workspaceSizes = std::vector<uint32_t>();
    vector< string > outFileNames;
    vector< shared_ptr<TempFile> > outFiles;

    for (uint32_t j = 0; j < customInfo->outputSizeList.size(); j++) {
        stringstream ss;
        ss << BASE_NAME << "output_"  << j;
        outFiles.push_back(make_shared<TempFile>(ss.str()));
        outFileNames.push_back(outFiles[j]->fileName);
        outBufSizes.push_back(customInfo->outputSizeList[j]);
    }

    // aicpu only
    double time = 0;
    if (CustomOpRun(customInfo, inFileNames, outFileNames, outBufSizes, workspaceSizes, time) == HIAI_ERROR) {
        return HIAI_ERROR;
    }
    customOutput -> time = time;
       
    for (auto &outFile : outFiles) {
        CustomFileBlob tb;
        outFile->Read(tb);
        customOutput->outputList.push_back(tb);
    }
    
    // do compare
    if (customInfo->expectFileList.size() != 0) {
        if (outFiles.size() != customInfo->expectFileList.size()) {
            HIAI_ENGINE_LOG(HIAI_IDE_ERROR, "Expect output file number: %d != actual output file number: %d.",
                            customInfo->expectFileList.size(), outFiles.size());
            return HIAI_ERROR;
        }
        for (uint32_t i = 0; i < outFileNames.size(); i++) {
            string   eFileName = string(BASE_NAME) + "expexct_file";
            TempFile eFile      = TempFile(eFileName);
            HIAI_RETURN_IF_ERROR(eFile.Write(customInfo->expectFileList[i]));

            bool              compareRet = false;
            custom::ErrorInfo errorInfo  = custom::custom_op_compare(
                                                eFileName, outFileNames[i], customInfo->dataTypeList[i], customInfo->precisionDeviation,
                                                customInfo->statisticalDiscrepancy, compareRet);

            if (errorInfo.error_code != 0) {
                customOutput->compareResultList.push_back(false);
                HIAI_ENGINE_LOG(HIAI_IDE_ERROR, "Compare failed, error_code: %d, message: %s.", errorInfo.error_code,
                                errorInfo.error_msg.c_str());
            } else {
                customOutput->compareResultList.push_back(compareRet);
                HIAI_ENGINE_LOG(HIAI_IDE_INFO, "Compare result: %s.", compareRet ? "true" : "false");
            }
        }
    }

    HIAI_ENGINE_LOG(HIAI_IDE_INFO, "Engine send data begin!");
    ret = SendData(0, "CustomOutput", std::static_pointer_cast<void>(customOutput));
    HIAI_ENGINE_LOG(HIAI_IDE_INFO, "Engine send data end!");

    HIAI_ENGINE_LOG(HIAI_IDE_INFO, "Engine process end!");
    return ret;
}


