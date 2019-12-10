/*
 * License: Copyright (c) Huawei Technologies Co., Ltd. 2012-2019. All rights reserved.
 * Description: raw data， mutil input tensor 
 * Date: 2019-09-26 16:33:04
 * @LastEditTime: 2019-09-26 16:37:21
 */
#ifndef RAW_DATA_MUTIL_HOST_H
#define RAW_DATA_MUTIL_HOST_H

#include <hiaiengine/api.h>
#include <hiaiengine/multitype_queue.h>
#include "inc/common.h"

/*
* RawDataEngine
*/
class RawDataMutilEngine : public hiai::Engine {
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


 
