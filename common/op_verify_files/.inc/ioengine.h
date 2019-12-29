/*
 * Copyright © Huawei Technologies Co., Ltd. 2012-2019. All rights reserved.
 * Description: ioengine definition
 */
#ifndef CUSTOM_INPUT_OUTPUT_ENGINE_H_
#define CUSTOM_INPUT_OUTPUT_ENGINE_H_
#include "hiaiengine/engine.h"
#include "hiaiengine/data_type.h"
#include "hiaiengine/multitype_queue.h"
#include <iostream>
#include <string>
#include <dirent.h>
#include <memory>
#include <unistd.h>
#include <vector>
#include <stdint.h>
#include "error_code.h"
#include "custom_common.h"

#include "cereal/cereal.hpp"
#include "cereal/types/unordered_map.hpp"
#include "cereal/types/memory.hpp"
#include "cereal/archives/binary.hpp"
#include "cereal/types/vector.hpp"
#include "cereal/types/map.hpp"


#define SOURCE_ENGINE_INPUT_SIZE 1
#define SOURCE_ENGINE_OUTPUT_SIZE 1

#define DEST_ENGINE_INPUT_SIZE 1
#define DEST_ENGINE_OUTPUT_SIZE 1

using hiai::Engine;
using namespace std;



// Source Engine
class SrcEngine : public Engine {
    /**
    * @ingroup hiaiengine
    * @brief HIAI_DEFINE_PROCESS : ??????Engine Process????????????
    * @[in]: ?????????????????????????????????????????????
    */
    HIAI_DEFINE_PROCESS(SOURCE_ENGINE_INPUT_SIZE, SOURCE_ENGINE_OUTPUT_SIZE)
};

// Dest Engine
class DestEngine : public Engine {
    /**
    * @ingroup hiaiengine
    * @brief HIAI_DEFINE_PROCESS : ??????Engine Process????????????
    * @[in]: ?????????????????????????????????????????????
    */
    HIAI_DEFINE_PROCESS(DEST_ENGINE_INPUT_SIZE, DEST_ENGINE_OUTPUT_SIZE)
};
#endif



