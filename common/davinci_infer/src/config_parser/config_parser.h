/*
 * License: Copyright (c) Huawei Technologies Co., Ltd. 2012-2019. All rights reserved.
 * Description: .ini config file parser
 * Date: 2019-02-28 16:10:27
 * LastEditTime: 2019-09-24 16:09:44
 */
 
#ifndef _CONFIG_PARSER_H_
#define _CONFIG_PARSER_H_

#include <string>
#include <map>

using namespace std;

#define COMMENT_CHAR '#'
bool ReadConfig(const string& filename, map<string, string>& m);
void PrintConfig(const map<string, string>& m);

#endif