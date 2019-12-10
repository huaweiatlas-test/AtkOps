/*
 * License: Copyright (c) Huawei Technologies Co., Ltd. 2012-2019. All rights reserved.
 * Description: ini config file parser
 * Date: 2019-09-20 10:50:42
 * LastEditTime: 2019-09-24 15:56:32
 */

#include "config_parser.h"

#include <fstream>
#include <iostream>

using namespace std;

bool IsSpace(char c)
{
    if (c == ' ' || c == '\t') {
        return true;
    }
    return false;
}

bool IsCommentChar(char c)
{
    if (c == COMMENT_CHAR) {
        return true;
    } else {
        return false;
    }
}

void Trim(string& str)
{
    if (str.empty()) {
        return;
    }
    int i;
    int startPos;
    int endPos;
    for (i = 0; i < str.size(); ++i) {
        if (!IsSpace(str[i])) {
            break;
        }
    }
    // 全部是空白字符串
    if (i == str.size()) {
        str = "";
        return;
    }
    startPos = i;
    for (i = str.size() - 1; i >= 0; --i) {
        if (!IsSpace(str[i])) {
            break;
        }
    }
    endPos = i;
    str = str.substr(startPos, endPos - startPos + 1);
}

bool AnalyseLine(const string& line, string& key, string& value)
{
    if (line.empty()) {
        return false;
    }
    int startPos = 0;
    int endPos = line.size() - 1; 
    int pos;
    if ((pos = line.find(COMMENT_CHAR)) != -1) {
		// 行的第一个字符就是注释字符
        if (0 == pos) {
            return false;
        }
        endPos = pos - 1;
    }
    string newLine = line.substr(startPos, startPos + 1 - endPos);  // 预处理，删除注释部分

    if ((pos = newLine.find('=')) == -1) {
        // 没有=号
        return false;
    }

    key = newLine.substr(0, pos);
    value = newLine.substr(pos + 1, endPos + 1 - (pos + 1));

    Trim(key);
    if (key.empty()) {
        return false;
    }
    Trim(value);
    return true;
}

// 读取数据
bool ReadConfig(const string& filename, map<string, string>& m)
{
    m.clear();
    ifstream infile(filename.c_str());
    if (!infile) {
        cout << "ini config file open error" << endl;
        return false;
    }
    string line, key, value;
    while (getline(infile, line)) {
        if (AnalyseLine(line, key, value)) {
            m[key] = value;
        }
    }
    infile.close();

    return true;
}

// 打印读取出来的数据
void PrintConfig(const map<string, string>& m)
{
    map<string, string>::const_iterator mite = m.begin();
    for (; mite != m.end(); ++mite) {
        cout << mite->first << "=" << mite->second << endl;
    }
}