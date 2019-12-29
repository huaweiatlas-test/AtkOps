/*
 * Copyright ? Huawei Technologies Co., Ltd. 2012-2019. All rights reserved.
 * Description: Definition of custom_engine
 */
#ifndef CUSTOM_ENGINE_H_
#define CUSTOM_ENGINE_H_
#include "hiaiengine/api.h"
#include "hiaiengine/log.h"
#include "hiaiengine/multitype_queue.h"
#include <iostream>
#include <string>
#include <dirent.h>
#include <memory>
#include <unistd.h>
#include <vector>
#include <stdint.h>
#include "custom/custom_op.h"
#include "custom_common.h"

#include "cereal/cereal.hpp"
#include "cereal/types/unordered_map.hpp"
#include "cereal/types/memory.hpp"
#include "cereal/archives/binary.hpp"
#include "cereal/types/vector.hpp"
#include "cereal/types/map.hpp"

#define CUSTOM_ENGINE_INPUT_SIZE  1
#define CUSTOM_ENGINE_OUTPUT_SIZE  1

#define SOURCE_ENGINE_INPUT_SIZE 1
#define SOURCE_ENGINE_OUTPUT_SIZE 1

#define DEST_ENGINE_INPUT_SIZE 1
#define DEST_ENGINE_OUTPUT_SIZE 1
using hiai::Engine;

// Framework Engine
class CUSTOMEngine : public Engine {
public:
    /**
    * @ingroup hiaiengine
    * @brief HIAI_DEFINE_PROCESS : ??????Engine Process????????????
    * @[in]: ?????????????????????????????????????????????
    */
    HIAI_DEFINE_PROCESS(CUSTOM_ENGINE_INPUT_SIZE, CUSTOM_ENGINE_OUTPUT_SIZE)
};
class SrcEngine : public Engine {
    /**
    * @ingroup hiaiengine
    * @brief HIAI_DEFINE_PROCESS : 重载Engine Process处理逻辑
    * @[in]: 定义一个输入端口，一个输出端口
    */
    HIAI_DEFINE_PROCESS(SOURCE_ENGINE_INPUT_SIZE, SOURCE_ENGINE_OUTPUT_SIZE)
};

// Dest Engine
class DestEngine : public Engine {
    /**
    * @ingroup hiaiengine
    * @brief HIAI_DEFINE_PROCESS : 重载Engine Process处理逻辑
    * @[in]: 定义一个输入端口，一个输出端口
    */
    HIAI_DEFINE_PROCESS(DEST_ENGINE_INPUT_SIZE, DEST_ENGINE_OUTPUT_SIZE)
};
#endif //IMPL_ENGINE_H_



