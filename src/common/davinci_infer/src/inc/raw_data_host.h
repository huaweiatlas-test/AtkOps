/*
 * License: Copyright (c) Huawei Technologies Co., Ltd. 2012-2019. All rights reserved.
 * Description: raw data读取的Engine(host侧)，然后直接传给device侧的InferEngine
 * Date: 2019-09-02 11:06:18
 * @LastEditTime: 2019-09-25 12:14:48
 */
#ifndef RAW_DATA_HOST_H
#define RAW_DATA_HOST_H

#include <hiaiengine/api.h>
#include <hiaiengine/multitype_queue.h>
#include "inc/common.h"

/*
* RawDataEngine
*/
class RawDataEngine : public hiai::Engine {
    /**
    * ingroup RawDataEngine
    * brief RawDataEngine Process 函数
    * param [in]: RAWDATA_ENGINE_INPUT_SIZE, RawData Engine in端口
    * param [in]: RAWDATA_ENGINE_OUTPUT_SIZE, RawData Engine out端口
    * param [out]: HIAI_StatusT
    */
    HIAI_DEFINE_PROCESS(RAWDATA_ENGINE_INPUT_SIZE, RAWDATA_ENGINE_OUTPUT_SIZE)
};




#endif //RAW_DATA_HOST_H


 
