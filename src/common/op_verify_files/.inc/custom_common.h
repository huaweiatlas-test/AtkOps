/*
 * Copyright © Huawei Technologies Co., Ltd. 2012-2019. All rights reserved.
 * Description: Definition of custom_commmon
 */
#ifndef CUSTOM_COMMON_H_
#define CUSTOM_COMMON_H_
#include "hiaiengine/engine.h"
#include "hiaiengine/data_type.h"
#include "hiaiengine/multitype_queue.h"
#include "hiaiengine/status.h"
#include <iostream>
#include <string>
#include <dirent.h>
#include <memory>
#include <unistd.h>
#include <vector>
#include <stdint.h>

#include "cereal/cereal.hpp"
#include "cereal/types/unordered_map.hpp"
#include "cereal/types/memory.hpp"
#include "cereal/archives/binary.hpp"
#include "cereal/types/vector.hpp"
#include "cereal/types/map.hpp"

#define NAME_LEN 13
using namespace std;

struct CustomFileBlob
{
    uint32_t size;
    std::shared_ptr<char> data;
};


struct CustomInfo
{
    string name = "";
    int32_t type = 0;
    vector<uint32_t> outputSizeList;
    CustomFileBlob binFile;
    vector<CustomFileBlob> inputList;
    CustomFileBlob configFile;
    
     // compare related feilds
    vector<int32_t> dataTypeList;
    float precisionDeviation     = 0.1;
    float statisticalDiscrepancy = 0.1;
    vector<CustomFileBlob> expectFileList;
};

struct CustomOutput
{
    uint32_t size;
    vector<CustomFileBlob> outputList;
    vector<int32_t> compareResultList;
    double time;
};

/**
define MODULE_NAME
**/
const static char MODULE_NAME[NAME_LEN] = "C++ Operator";

/**
define error code for HIAI_ENGINE_LOG
**/
#define USE_DEFINE_ERROR 0x6001
enum{
    HIAI_IDE_ERROR_CODE,
    HIAI_IDE_INFO_CODE,
    HIAI_IDE_WARNING_CODE
};
HIAI_DEF_ERROR_CODE(USE_DEFINE_ERROR, HIAI_ERROR, HIAI_IDE_ERROR, \
    "Custom Operator runnning failed");
HIAI_DEF_ERROR_CODE(USE_DEFINE_ERROR, HIAI_INFO, HIAI_IDE_INFO, \
    "Custom Operator runnning ok");
HIAI_DEF_ERROR_CODE(USE_DEFINE_ERROR, HIAI_WARNING, HIAI_IDE_WARNING, \
    "Custom Operator runnning warning");
char* ReadFile(const char *fileName, uint32_t *fileSize);

int32_t  WriteFile(const char* file_name, const char* buffer, uint32_t size);

#endif



