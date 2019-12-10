/*
 * License: Copyright (c) Huawei Technologies Co., Ltd. 2012-2019. All rights reserved.
 * Description: dvpp 接口封转
 * Date: 2019-09-11 16:13:24
 * LastEditTime: 2019-09-24 15:56:31
 */

#include "inc/dvpp_warpper.h"
#include "inc/util.h"
#include "dvpp/idvppapi.h"
#include "dvpp/Vpc.h"
#include "inc/error_code.h"

DvppWarpper::DvppWarpper()
{
    int32_t ret = CreateDvppApi(pidvppapi_);
    if (ret != 0) {
        HIAI_ENGINE_LOG("creating CreateDvppApi handle failed");
    }
}

DvppWarpper::~DvppWarpper()
{
    if (pidvppapi_ != nullptr) {
        DestroyDvppApi(pidvppapi_);
        pidvppapi_ = nullptr;
    }
}

/**
 * decode jpeg
 */
HIAI_StatusT DvppWarpper::DecodeJpeg(shared_ptr<EngineTransNewT> rawData, uint32_t& jpegdinWid, uint32_t& jpegdinHei,
    uint32_t& jpegdoutWid, uint32_t& jpegdoutHei, shared_ptr<EngineTransNewT>& output)
{
    HIAI_ENGINE_LOG("[DEBUG] JpegdEngine Start Process");

    std::shared_ptr<struct jpegd_raw_data_info> jpegdInData = std::make_shared<struct jpegd_raw_data_info>();
    std::shared_ptr<struct jpegd_yuv_data_info> jpegdOutData = std::make_shared<struct jpegd_yuv_data_info>();

    jpegdInData->jpeg_data_size = rawData->buffer_size;
    jpegdInData->jpeg_data = reinterpret_cast<unsigned char*>(rawData->trans_buff.get());

    dvppapi_ctl_msg dvppApiCtlMsg;
    dvppApiCtlMsg.in = (void*)jpegdInData.get();
    dvppApiCtlMsg.in_size = sizeof(jpegd_raw_data_info);
    dvppApiCtlMsg.out = (void*)jpegdOutData.get();
    dvppApiCtlMsg.out_size = sizeof(jpegd_yuv_data_info);

    if (pidvppapi_ == nullptr) {
        HIAI_ENGINE_LOG("jpegd can not open dvppapi");
        return HIAI_JPEGD_CTL_ERROR;
    }

    if (0 != DvppCtl(pidvppapi_, DVPP_CTL_JPEGD_PROC, &dvppApiCtlMsg)) {
        HIAI_ENGINE_LOG("Jpegd dvppctl error ");
        DestroyDvppApi(pidvppapi_);
        pidvppapi_ = nullptr;
        return HIAI_JPEGD_CTL_ERROR;
    }

    HIAI_ENGINE_LOG("JPEGD OUTPUT FORMAT: %d", jpegdOutData->out_format);

    // 构造DVPP OUt数据并进行发送
    jpegdinWid = jpegdOutData->img_width;
    jpegdinHei = jpegdOutData->img_height;
    jpegdoutWid = jpegdOutData->img_width_aligned;
    jpegdoutHei = jpegdOutData->img_height_aligned;

    HIAI_ENGINE_LOG("Jpegdout_width: %d, Jpegdout_height: %d, Jpegdin_width:%d, Jpegdin_height:%d",
        jpegdoutWid,
        jpegdoutHei,
        jpegdinWid,
        jpegdinHei);

    output = std::make_shared<EngineTransNewT>();
    output->trans_buff.reset(
        (uint8_t*)jpegdOutData->yuv_data, [jpegdOutData](uint8_t* p) mutable { jpegdOutData->cbFree(); });
    output->buffer_size = jpegdOutData->yuv_data_size;
    output->frameId = rawData->frameId;
    output->isLastFrm = rawData->isLastFrm;

    HIAI_ENGINE_LOG("[DEBUG] JpegdEngine End Process");

    return HIAI_OK;
}

/**
 * crop and resize
 */
HIAI_StatusT DvppWarpper::Vpc(shared_ptr<EngineTransNewT> imgData, uint32_t modelWid, uint32_t modelHei,
    uint32_t jpegdinWid, uint32_t jpegdinHei, uint32_t jpegdoutWid, uint32_t jpegdoutHei,
    shared_ptr<EngineTransNewT>& output)
{
    uint32_t inWidthStride = jpegdoutWid;
    uint32_t inHeightStride = jpegdoutHei;
    uint32_t outWidthStride = ALIGN_UP(modelWid, 128);               // 128对齐, 避免硬编码!
    uint32_t outHeightStride = ALIGN_UP(modelHei, 16);               // 16对齐, 避免硬编码!
    uint32_t inBufferSize = inWidthStride * inHeightStride * 3 / 2;  // the size of yuv data is 1.5 times of
                                                                     // width*height
    uint32_t outBufferSize =
        outWidthStride * outHeightStride * 3 / 2;  // the size of yuv data is 1.5 times of width*height

    HIAI_ENGINE_LOG("inBufferSize:%d, outBufferSize:%d", inBufferSize, outBufferSize);
    // vpc 输出buf
    uint8_t* outBuffer = (uint8_t*)HIAI_DVPP_DMalloc(outBufferSize);
    // 构造输入图片配置
    std::shared_ptr<VpcUserImageConfigure> imageConfigure(new VpcUserImageConfigure);
    imageConfigure->bareDataAddr = reinterpret_cast<uint8_t*>(imgData->trans_buff.get());
    imageConfigure->bareDataBufferSize = imgData->buffer_size;
    imageConfigure->widthStride = inWidthStride;
    imageConfigure->heightStride = inHeightStride;
    imageConfigure->inputFormat = INPUT_YUV420_SEMI_PLANNER_VU;
    imageConfigure->outputFormat = OUTPUT_YUV420SP_UV;
    imageConfigure->isCompressData = false;
    imageConfigure->yuvSumEnable = false;
    imageConfigure->cmdListBufferAddr = nullptr;
    imageConfigure->cmdListBufferSize = 0;
    std::shared_ptr<VpcUserRoiConfigure> roiConfigure(new VpcUserRoiConfigure);
    roiConfigure->next = nullptr;
    VpcUserRoiInputConfigure* inputConfigure = &roiConfigure->inputConfigure;
    // 设置抠图区域，抠图区域左上角坐标[0,0],右下角坐标[jpegdinWid - 1, jpegdinHei - 1]
    inputConfigure->cropArea.leftOffset = 0;
    inputConfigure->cropArea.rightOffset = Util::Odd(jpegdinWid - 1);
    inputConfigure->cropArea.upOffset = 0;
    inputConfigure->cropArea.downOffset = Util::Odd(jpegdinHei - 1);
    VpcUserRoiOutputConfigure* outputConfigure = &roiConfigure->outputConfigure;
    outputConfigure->addr = outBuffer;
    outputConfigure->bufferSize = outBufferSize;
    outputConfigure->widthStride = outWidthStride;
    outputConfigure->heightStride = outHeightStride;
    // 设置贴图区域，贴图区域左上角坐标[0,0],右下角坐标[modelWid - 1, modelHei - 1]
    outputConfigure->outputArea.leftOffset = 0;
    outputConfigure->outputArea.rightOffset = Util::Odd(modelWid - 1);
    outputConfigure->outputArea.upOffset = 0;
    outputConfigure->outputArea.downOffset = Util::Odd(modelHei - 1);
    imageConfigure->roiConfigure = roiConfigure.get();
    dvppapi_ctl_msg dvppApiCtlMsg;
    dvppApiCtlMsg.in_size = sizeof(VpcUserImageConfigure);
    dvppApiCtlMsg.in = static_cast<void*>(imageConfigure.get());
    if (pidvppapi_ == nullptr) {
        HIAI_ENGINE_LOG("vpc can not open dvppapi");
        return HIAI_CREATE_DVPP_ERROR;
    }
    int32_t ret = DvppCtl(pidvppapi_, DVPP_CTL_VPC_PROC, &dvppApiCtlMsg);
    if (ret != 0) {
        pidvppapi_ = nullptr;
        ret = DestroyDvppApi(pidvppapi_);
        HIAI_ENGINE_LOG("call vpc dvppctl process failed!");
        return HIAI_CREATE_DVPP_ERROR;
    }
    HIAI_ENGINE_LOG("call vpc dvppctl process success! \n");

    // 返回数据，将buffer填入返回数据结构体
    output = std::make_shared<EngineTransNewT>();
    output->trans_buff.reset(outBuffer, [](uint8_t* p) { HIAI_DVPP_DFree(p); });
    output->buffer_size = outBufferSize;
    output->frameId = imgData->frameId;
    output->isLastFrm = imgData->isLastFrm;

    return HIAI_OK;
}

/**
 * crop and resize
 * imgData: 输入图像数据
 * inWidthStride: 输入图像width对齐到128的值
 * inHeightStride: 输入图像height对齐到16的值
 * cropX, cropY, cropWid, cropHei为crop的矩形区域
 * resizeWid, resizeHei为resize的大小
 * output: vpc的输出数据
 */
HIAI_StatusT DvppWarpper::Vpc(shared_ptr<EngineTransNewT> imgData, const uint32_t& inWidthStride,
    const uint32_t& inHeightStride, const uint32_t& cropX, const uint32_t& cropY, const uint32_t& cropWid,
    const uint32_t& cropHei, const uint32_t& resizeWid, const uint32_t& resizeHei, shared_ptr<EngineTransNewT>& output)
{
    uint32_t outWidthStride = ALIGN_UP(resizeWid, 128);  // 256;  // 128对齐, 避免硬编码!
    uint32_t outHeightStride = ALIGN_UP(resizeHei, 16);  // 224;  // 16对齐, 避免硬编码!
    uint32_t outBufferSize =
        outWidthStride * outHeightStride * 3 / 2;  // the size of yuv data is 1.5 times of width*height

    HIAI_ENGINE_LOG(
        "outWidthStride:%d, outHeightStride:%d, outBufferSize:%d", outWidthStride, outHeightStride, outBufferSize);
    // vpc 输出buf
    uint8_t* outBuffer = (uint8_t*)HIAI_DVPP_DMalloc(outBufferSize);
    // 构造输入图片配置
    std::shared_ptr<VpcUserImageConfigure> imageConfigure(new VpcUserImageConfigure);
    imageConfigure->bareDataAddr = reinterpret_cast<uint8_t*>(imgData->trans_buff.get());
    imageConfigure->bareDataBufferSize = imgData->buffer_size;
    imageConfigure->isCompressData = false;
    imageConfigure->widthStride = inWidthStride;
    imageConfigure->heightStride = inHeightStride;
    imageConfigure->inputFormat = INPUT_YUV420_SEMI_PLANNER_VU;
    imageConfigure->outputFormat = OUTPUT_YUV420SP_UV;
    imageConfigure->yuvSumEnable = false;
    imageConfigure->cmdListBufferAddr = nullptr;
    imageConfigure->cmdListBufferSize = 0;
    std::shared_ptr<VpcUserRoiConfigure> roiConfigure(new VpcUserRoiConfigure);
    roiConfigure->next = nullptr;
    VpcUserRoiInputConfigure* inputConfigure = &roiConfigure->inputConfigure;
    // 设置抠图区域，抠图区域左上角坐标[0,0],右下角坐标[cropWid - 1, cropHei - 1]
    HIAI_ENGINE_LOG("VPC crop: x:%d, y:%d, wid:%d, hei:%d", cropX, cropY, cropWid, cropHei);
    HIAI_ENGINE_LOG("VPC crop: left:%d, up:%d, right:%d, down:%d",
        Util::Even(cropX),
        Util::Even(cropY),
        Util::Odd(cropWid - 1),
        Util::Odd(cropHei - 1));
    inputConfigure->cropArea.leftOffset = Util::Even(cropX);
    inputConfigure->cropArea.rightOffset = Util::Odd(cropX + cropWid - 1);
    inputConfigure->cropArea.upOffset = Util::Even(cropY);
    inputConfigure->cropArea.downOffset = Util::Odd(cropY + cropHei - 1);
    VpcUserRoiOutputConfigure* outputConfigure = &roiConfigure->outputConfigure;
    outputConfigure->addr = outBuffer;
    outputConfigure->bufferSize = outBufferSize;
    outputConfigure->widthStride = outWidthStride;
    outputConfigure->heightStride = outHeightStride;
    // 设置贴图区域，贴图区域左上角坐标[0,0],右下角坐标[resizeWid - 1, resizeHei - 1]
    HIAI_ENGINE_LOG("VPC resize: wid:%d, hei:%d", resizeWid - 1, resizeHei - 1);
    outputConfigure->outputArea.leftOffset = 0;
    outputConfigure->outputArea.rightOffset = Util::Odd(resizeWid - 1);
    outputConfigure->outputArea.upOffset = 0;
    outputConfigure->outputArea.downOffset = Util::Odd(resizeHei - 1);
    imageConfigure->roiConfigure = roiConfigure.get();

    dvppapi_ctl_msg dvppApiCtlMsg;
    dvppApiCtlMsg.in = static_cast<void*>(imageConfigure.get());
    dvppApiCtlMsg.in_size = sizeof(VpcUserImageConfigure);

    if (pidvppapi_ == nullptr) {
        HIAI_ENGINE_LOG("vpc can not open dvppapi");
        return HIAI_CREATE_DVPP_ERROR;
    }

    int32_t ret = DvppCtl(pidvppapi_, DVPP_CTL_VPC_PROC, &dvppApiCtlMsg);
    if (ret != 0) {
        ret = DestroyDvppApi(pidvppapi_);
        pidvppapi_ = nullptr;
        HIAI_ENGINE_LOG("call vpc dvppctl process faild!");
        return HIAI_CREATE_DVPP_ERROR;
    }
    HIAI_ENGINE_LOG("call vpc dvppctl process success!\n");

    // 返回数据，将buffer填入返回数据结构体
    output = std::make_shared<EngineTransNewT>();
    output->trans_buff.reset(outBuffer, [](uint8_t* p) { HIAI_DVPP_DFree(p); });
    output->buffer_size = outBufferSize;
    output->frameId = imgData->frameId;
    output->isLastFrm = imgData->isLastFrm;

    return HIAI_OK;
}