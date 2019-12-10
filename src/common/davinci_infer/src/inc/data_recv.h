/*
 * License: Copyright (c) Huawei Technologies Co., Ltd. 2012-2019. All rights reserved.
 * Description: 数据接收接口头文件
 * Date: 2019-02-28 16:15:04
 * LastEditTime: 2019-09-24 15:57:54
 */
#ifndef INC_DATA_RECV_H_
#define INC_DATA_RECV_H_

#include <hiaiengine/api.h>
#include <string>
class InferDataRecvInterface : public hiai::DataRecvInterface {
 public:
    /**
    * ingroup InferDataRecvInterface
    * brief 构造函数
    * param [in]desc:std::string
    */
    InferDataRecvInterface(const std::string& filename) :
        file_name_(filename) {}
    ~InferDataRecvInterface();
    /**
    * ingroup InferDataRecvInterface
    * brief RecvData RecvData回调，保存文件
    * param [in]
    */
    HIAI_StatusT RecvData(const std::shared_ptr<void>& message);

 private:
    std::string file_name_;     // 目标保存文件
};

#endif  // INC_DATA_RECV_H_
