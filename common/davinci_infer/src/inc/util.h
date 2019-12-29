/*
 * License: Copyright (c) Huawei Technologies Co., Ltd. 2012-2019. All rights reserved.
 * Description: 工具类定义头文件
 * Date: 2019-02-28
 * LastEditTime: 2019-09-23 16:19:01
 */
#ifndef INC_UTIL_H_
#define INC_UTIL_H_

#include <iostream>
#include <memory>
#include <vector>
#include "inc/sample_data.h"

using std::vector;

#define USER_DEBUG 1

class Util {
public:
    static char* ReadBinFile(std::shared_ptr<std::string> file_name_ptr, uint32_t offset, uint32_t* file_size);
    static bool CheckFileExist(const std::string& file_name);
    static void WriteBinFile(const char* filename, const void* data, int len);
    static void WriteTxtFile(const char* filename, const float* data, int len);
    static vector<std::shared_ptr<std::string>> GetFilenameList(std::shared_ptr<std::string> txtFilename);
    static void WriteReturnDataT(const char* filename, std::shared_ptr<EngineReturnDataT> msg);
    static uint32_t Odd(uint32_t x);
    static uint32_t Even(uint32_t x);
    static string Num2Str(const uint32_t& num);
    static uint32_t Str2Num(const string& str);
    static float Str2Float(const string& str);
};

#endif //INC_UTIL_H_
