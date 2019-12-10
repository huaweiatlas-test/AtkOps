/*
 * License: Copyright (c) Huawei Technologies Co., Ltd. 2012-2019. All rights reserved.
 * Description: host侧工具类代码
 * Date: 2019-02-28
 * LastEditTime: 2019-09-24 17:35:23
 */
#include <fstream>
#include <algorithm>
#include <iostream>
#include <sstream>
#include <string>
#include "hiaiengine/api.h"
#include "hiaiengine/ai_memory.h"
#include "inc/util.h"

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
        std::cout << "open jpeg file failed: " << *file_name << std::endl;
        return NULL;
    }

    pbuf = filestr.rdbuf();
    size = pbuf->pubseekoff(0, std::ios::end, std::ios::in);
    pbuf->pubseekpos(0, std::ios::in);
    size += offset;
    char* buffer = nullptr;
    HIAI_StatusT getRet = hiai::HIAIMemory::HIAI_DMalloc(size, (void *&)buffer, GET_LENGTH);
    if (HIAI_OK != getRet || nullptr == buffer) {
        // 有漏洞，buffer如果为HIAI_DMalloc开辟，sendData高速通道（DMA）发送的话，系统自己释放资源，不需要显示释放！但如果这里用new的话，必须手动释放内存
        std::cout << "ReadBinFile HIAI_DMalloc failed: " << *file_name << std::endl;
        return NULL;
    }

    pbuf->sgetn(buffer, size - offset);
    *file_size = size;

    filestr.close();
    return buffer;
}

/**
 * ingroup Util
 * brief CheckFileExist 检查文件是否存在
 * param [in]：file_name, 文件路径
 * param [out]: std::string
 */
bool Util::CheckFileExist(const std::string& file_name)
{
    std::ifstream f(file_name.c_str());
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
        size_t wsize = fwrite(data, 1, len, fpOut);
        HIAI_ENGINE_LOG("%s fwrite real size: %d", filename, wsize);
        fflush(fpOut);
        fclose(fpOut);
    }
#endif  // USER_DEBUG
}

void Util::WriteReturnDataT(const char* filename, std::shared_ptr<EngineReturnDataT> msg)
{
#ifdef USER_DEBUG
    for (uint32_t i = 0; i < msg->size; i++) {
        OutputT out = msg->output_data_vec[i];
        float* data = (float*)(out.data.get());
        HIAI_ENGINE_LOG("receive data(output_data) size: %d", out.size);
        ofstream of(filename);
        for (size_t j = 0; j < out.size / sizeof(float); j++) {
            of << *data++ << "\n";
        }
        of.close();
    }

#endif  // USER_DEBUG
}

vector<std::shared_ptr<std::string>> Util::GetFilenameList(std::shared_ptr<std::string> txtFilename)
{
    vector<std::shared_ptr<std::string>> res;
    std::ifstream in(*txtFilename, ios::in);
    std::shared_ptr<std::string> line = std::make_shared<std::string>();
    while (getline(in, *line)) {
        if (line->empty()) {
            continue;
        }
        res.push_back(line);
        line = std::make_shared<std::string>();
    }
    return res;
}

string Util::Num2Str(const uint32_t& num)
{
    stringstream ss;
    ss << num;
    string str;
    ss >> str;

    return str;
}

uint32_t Util::Str2Num(const string& str)
{
    stringstream ss;
    ss << str;
    uint32_t num;
    ss >> num;

    return num;
}

float Util::Str2Float(const string& str)
{
    stringstream ss;
    ss << str;
    float num;
    ss >> num;

    return num;
}
