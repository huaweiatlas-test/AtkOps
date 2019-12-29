/*
 * License: Copyright (c) Huawei Technologies Co., Ltd. 2012-2019. All rights reserved.
 * Description: device层工具类接口
 * Date: 2019-02-28
 * LastEditTime: 2019-09-24 15:56:39
 */

#include <fstream>
#include <algorithm>
#include <iostream>
#include <string>
#include <sstream>
#include <math.h>
#include "inc/util.h"
#include "hiaiengine/api.h"
#include "hiaiengine/ai_memory.h"

using namespace std;
#define GET_LENGTH 10000
/**
 * ingroup Util
 * brief ReadBinFile 读取文件，返回buffer;
 * param [in]：file_name, 文件路径
 * param [in]: offset, 比文件大小多申请的字节数， 一般取0或者8, jpeg数据文件设为8， 裸数据文件设置为0
 * param [out]: file_size, 文件的实际字节数+多申请的字节数之和
 */
char* Util::ReadBinFile(std::shared_ptr<std::string> file_name, uint32_t offset, uint32_t* file_size)
{
    std::filebuf* pbuf;
    std::ifstream filestr;
    size_t size;
    filestr.open(file_name->c_str(), std::ios::binary);
    if (!filestr) {
        return NULL;
    }
    pbuf = filestr.rdbuf();
    size = pbuf->pubseekoff(0, std::ios::end, std::ios::in);
    pbuf->pubseekpos(0, std::ios::in);
    size += offset;
    char* buffer = nullptr;
    HIAI_StatusT getRet = hiai::HIAIMemory::HIAI_DMalloc(size, (void *&)buffer, GET_LENGTH);
    if (HIAI_OK != getRet || nullptr == buffer) {
        std::cout << "ReadBinFile HIAI_DMalloc failed!: " << *file_name << std::endl;
        return NULL;
    }

    pbuf->sgetn(buffer, size - offset);
    *file_size = size;
    filestr.close();
    return buffer;
}

/**
 * ingroup Util
 * device brief CheckFileExist 检查文件是否存在
 * param [in]：file_name, 文件路径
 * param [out]: std::string
 */
bool Util::CheckFileExist(const std::string& file_name)
{
    std::ifstream f(file_name.c_str());
    std::cout << "check file exist" << std::endl;
    return f.good();
}

void Util::WriteBinFile(const char* filename, const void* data, int len)
{
#ifdef USER_DEBUG
    char path[PATH_MAX] = {0};
    if (realpath(filename, path) == NULL) {
        return;
    }
    FILE* fpOut = fopen(path, "wb");
    if (fpOut) {
        HIAI_ENGINE_LOG("%s fwrite expected size: %d", filename, len);
        size_t wsize = fwrite(data, 1, len, fpOut);
        HIAI_ENGINE_LOG("%s fwrite real size: %d", filename, wsize);
        fflush(fpOut);
        fclose(fpOut);
    }
#endif  // USER_DEBUG
}

void Util::WriteTxtFile(const char* filename, const float* data, int len)
{
#ifdef USER_DEBUG
    ofstream of(filename);
    for (size_t j = 0; j < len; j++) {
        of << *data++ << "\n";
    }
    of.close();
#endif  // USER_DEBUG
}

void Util::WriteReturnDataT(const char* filename, std::shared_ptr<EngineReturnDataT> msg)
{
#ifdef USER_DEBUG
    for (uint32_t i = 0; i < msg->size; i++) {
        OutputT out = msg->output_data_vec[i];
        float* data = (float*)(out.data.get());
        HIAI_ENGINE_LOG("receive data(output_data) size: %d", out.size);
        ofstream of(filename, ios::out | ios::app);
        for (size_t j = 0; j < out.size / sizeof(float); j++) {
            of << *data++ << "\n";
        }
        of.close();
    }

#endif  // USER_DEBUG
}

/* function odd */
uint32_t Util::Odd(uint32_t x)
{
    HIAI_ENGINE_LOG("odd");
    uint32_t oddNum = x % 2 == 0 ? x - 1 : x;
    return oddNum;
}

/* function even */
uint32_t Util::Even(uint32_t x)
{
    HIAI_ENGINE_LOG("even");
    uint32_t evenNum = x % 2 == 0 ? x : x + 1;
    return evenNum;
}

/* function num2str */
string Util::Num2Str(const uint32_t& num)
{
    HIAI_ENGINE_LOG("num2str");
    stringstream ss;
    ss << num;
    string str;
    ss >> str;
    return str;
}

/* function str2num */
uint32_t Util::Str2Num(const string& str)
{
    HIAI_ENGINE_LOG("str2num");
    stringstream ss;
    ss << str;
    uint32_t num;
    ss >> num;
    return num;
}

/* function str2float */
float Util::Str2Float(const string& str)
{
    HIAI_ENGINE_LOG("str2float");
    stringstream ss;
    ss << str;
    float num;
    ss >> num;
    return num;
}
