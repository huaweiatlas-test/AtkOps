/*
 * License: Copyright (c) Huawei Technologies Co., Ltd. 2012-2019. All rights reserved.
 * Description: host engine 接口
 * Date: 2019-02-28
 * LastEditTime: 2019-09-23 16:20:12
 */
#ifndef INC_CLASSIFY_NET_HOST_H_
#define INC_CLASSIFY_NET_HOST_H_

#include <hiaiengine/api.h>
#include <hiaiengine/multitype_queue.h>
#include "inc/common.h"
/*
* Source Engine
*/
class SourceEngine : public hiai::Engine {
    /**
    * ingroup SourceEngine
    * brief SourceEngine Process 函数
    * param [in]: SOURCE_ENGINE_INPUT_SIZE, Source Engine in端口
    * param [in]: SOURCE_ENGINE_OUTPUT_SIZE, Source Engine out 端口
    * param [out]: HIAI_StatusT
    */
    HIAI_DEFINE_PROCESS(SOURCE_ENGINE_INPUT_SIZE, SOURCE_ENGINE_OUTPUT_SIZE)
};

/*
* Dest Engine
*/
class DestEngine : public hiai::Engine {
 public:
    DestEngine() :
        input_que_(DEST_ENGINE_INPUT_SIZE) {}

    ~DestEngine();
    /**
    * ingroup SourceEngine
    * brief SourceEngine Process 函数
    * param [in]: DEST_ENGINE_INPUT_SIZE, Source Engine in端口
    * param [in]: DEST_ENGINE_OUTPUT_SIZE, Source Engine out 端口
    * param [out]: HIAI_StatusT
    */
    HIAI_DEFINE_PROCESS(DEST_ENGINE_INPUT_SIZE, DEST_ENGINE_OUTPUT_SIZE)

 private:
    hiai::MultiTypeQueue input_que_;
};

#endif  // INC_CLASSIFY_NET_HOST_H_
