/*
 * License: Copyright (c) Huawei Technologies Co., Ltd. 2012-2019. All rights reserved.
 * Description: dvpp封装接口声明
 * Date: 2019-07-24
 * LastEditTime: 2019-09-24 15:58:12
 */
#ifndef __DVPP_WARPPER_H__
#define __DVPP_WARPPER_H__

#include <memory>

#include "hiaiengine/c_graph.h"
#include "hiaiengine/ai_memory.h"
#include "hiaiengine/api.h"
#include "hiaiengine/data_type.h"

#include "dvpp/idvppapi.h"
#include "dvpp/Vpc.h"

#include "inc/sample_data.h"

using std::shared_ptr;

#ifndef ALIGN_UP
#define ALIGN_UP(val, align) (((val) % (align) == 0) ? (val) : (((val) / (align) + 1) * (align)))
#endif

class DvppWarpper {
    public:
        // jpeg decode
        HIAI_StatusT DecodeJpeg(shared_ptr<EngineTransNewT> rawData, uint32_t& jpegdinWid, uint32_t& jpegdinHei, 
                uint32_t& jpegdoutWid, uint32_t& jpegdoutHei, shared_ptr<EngineTransNewT>& output);
        // crop and resize        
        HIAI_StatusT Vpc(shared_ptr<EngineTransNewT> imgData, uint32_t modelWid, uint32_t modelHei, 
                    uint32_t jpegdinWid, uint32_t jpegdinHei, uint32_t jpegdoutWid, uint32_t jpegdoutHei, 
                    shared_ptr<EngineTransNewT>& output);
        // generation vpc
        HIAI_StatusT Vpc(shared_ptr<EngineTransNewT> imgData, const uint32_t& inWidthStride, const uint32_t& inHeightStride, 
                    const uint32_t& cropX, const uint32_t& cropY, const uint32_t& cropWid, const uint32_t& cropHei, 
                    const uint32_t& resizeWid, const uint32_t& resizeHei, 
                    shared_ptr<EngineTransNewT>& output);

        DvppWarpper();
        ~DvppWarpper();

    private:
        IDVPPAPI *pidvppapi_ = nullptr;
};


#endif // !__DVPP_WARPPER_H__

