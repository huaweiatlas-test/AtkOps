/*
 * Copyright © Huawei Technologies Co., Ltd. 2012-2019. All rights reserved.
 * Description: Definition of ioengine
 */
#include "ioengine.h"
#include <hiaiengine/log.h>
#include <vector>
#include <unistd.h>
#include <thread>
#include <fstream>
#include <algorithm>
#include <iostream>
#include "custom_common.h"

using namespace hiai;
using namespace std;

// Source Engine
HIAI_IMPL_ENGINE_PROCESS("SrcEngine", SrcEngine, SOURCE_ENGINE_INPUT_SIZE)
{

    std::shared_ptr<CustomInfo> input_arg =
        std::static_pointer_cast<CustomInfo>(arg0);
    
    if (nullptr == input_arg.get())
    {
        HIAI_ENGINE_LOG(this, HIAI_INVALID_INPUT_MSG, "fail to process invalid message");
        return HIAI_INVALID_INPUT_MSG;
    }
    
    hiai::Engine::SendData(0, "CustomInfo", std::static_pointer_cast<void>(input_arg));
    std::cout<<"Source engine processed. "<<std::endl;
    return HIAI_OK;
}

// Dest  Engine
HIAI_IMPL_ENGINE_PROCESS("DestEngine", DestEngine, DEST_ENGINE_INPUT_SIZE)
{

    std::shared_ptr<CustomOutput> input_arg = std::static_pointer_cast<CustomOutput>(arg0);
    if (nullptr == input_arg.get())
    {
        HIAI_ENGINE_LOG(this, HIAI_INVALID_INPUT_MSG, "fail to process invalid message");
        return HIAI_INVALID_INPUT_MSG;
    }

    
    hiai::Engine::SendData(0, "CustomOutput", std::static_pointer_cast<void>(input_arg));
    std::cout<<"Dest engine processed. "<<std::endl;
    return HIAI_OK;
}


