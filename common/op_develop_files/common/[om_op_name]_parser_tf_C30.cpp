/* Copyright (C) 2019. Huawei Technologies Co., Ltd. All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the Apache License Version 2.0.You may not use this file except in compliance with the License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * Apache License for more details at
 * http://www.apache.org/licenses/LICENSE-2.0
 */

#include <Python.h>
#include "custom/custom_op.h"
#include "framework/omg/register.h"
#include "framework/omg/omg_types.h"
#include "operator.h"
#include "attr_value.h"
#include <memory>
#include <string>
#include <vector>

using namespace ge;
namespace domi
{

// #### Obtains the processing function of the output tensor description. 
Status TF[om_op_name]InferShapeAndType(const ge::Operator& op, vector<ge::TensorDesc>& v_output_desc)
{
    auto tensorDesc      = op.GetInputDesc(0);
    auto shape = tensorDesc.GetShape();

	// ### Please add code here to obatain the output shape.
	
	

     
	
    tensorDesc.SetShape(shape);
    v_output_desc.push_back(tensorDesc);

    return SUCCESS;

}


// build Te Binary file
Status TF[om_op_name]BuildTeBin(const ge::Operator& op, TEBinInfo& te_bin_info)
{
    std::string FilePath   = "";
    std::string FileRealPath = "";
    std::string FuncName   = "";
    std::string KernelName = "";
	
    // ### Parses the parameters. 
    
	// ### Parse input tensor description 

    FilePath   = "../operator/[om_op_name]";
    FuncName   = "[om_op_name]";
    KernelName = "[om_op_name]" + std::to_string(input_desc.GetShape().GetDim(0)) + std::to_string(input_desc.GetShape().GetDim(1));

    // ### Py module path
	char *CurPath = getcwd(NULL, 0);
	if (CurPath == NULL) {
		printf("Get the current directory path failed!\n");
		return FAILED;
	}
	std::string CurPath_s(CurPath);
	char *RealPath = realpath((CurPath_s + "/" + FilePath + ".py").c_str(), NULL);
	if (RealPath == NULL) {
		printf("Get the real path of Py module failed!\n");
		return FAILED;
	}
	std::string FileRealPath_ = std::string(RealPath);
	FileRealPath = FileRealPath_.substr(0, FileRealPath_.rfind("."));

	std::map<ge::DataType, std::string> OperationMap = {
		{ [om_ge]::DT_UNDEFINED,  "undefined" },
		{ [om_ge]::DT_FLOAT,        "float32" },
		{ [om_ge]::DT_FLOAT16,      "float16" },
		{ [om_ge]::DT_INT8,            "int8" },
		{ [om_ge]::DT_INT16,          "int16" },
		{ [om_ge]::DT_INT32,          "int32" },
		{ [om_ge]::DT_INT64,          "int64" },
		{ [om_ge]::DT_UINT8,          "uint8" },
		{ [om_ge]::DT_UINT16,        "uint16" },
		{ [om_ge]::DT_UINT32,        "uint32" },
		{ [om_ge]::DT_UINT64,        "uint64" },
		{ [om_ge]::DT_BOOL,            "bool" },
		{ [om_ge]::DT_DOUBLE,        "double" },
		{ [om_ge]::DT_DUAL,            "dual" },
		{ [om_ge]::DT_DUAL_SUB_INT8,    "dual_sub_int8" },
		{ [om_ge]::DT_DUAL_SUB_UINT8,  "dual_sub_uint8" }
	};
	std::string dtype = OperationMap[op.GetInputDesc(0).GetDataType()];
	
    // i => int; s => string; f => dobule; O => bool, and bool value is Py_True or Py_False
    te::BuildTeCustomOp(te_bin_info.ddk_version, op.GetName(), FileRealPath, FuncName,
		dtype.c_str(),
		KernelName.c_str(),
        Py_True);

    // set te op json to te_bin_info 
    te_bin_info.bin_file_path  = "./kernel_meta/" + KernelName + ".o";
    te_bin_info.json_file_path = "./kernel_meta/" + KernelName + ".json";
 
    return SUCCESS;
}

REGISTER_CUSTOM_OP("[om_op_name]") //test_ is the type name of the operator in the OM model. It can be specified randomly and cannot be the same as an existing type name. It is case sensitive. 
    .FrameworkType(TENSORFLOW)  // Enumerated type. The options are as follows: CAFFE, TENSORFLOW
    .OriginOpType("[tf_op_origin_name]")  // // batch_matmul indicates the type name of the operator in the caffe framework.
    .ParseParamsFn(AutoMappingFn)  // AutoMappingFn indicates automatic mapping the parameters of op.
    .InferShapeAndTypeFn(TF[om_op_name]InferShapeAndType)       // Set output description and datatype function
    .TEBinBuildFn(TF[om_op_name]BuildTeBin) // Build Te op binary function
    .ImplyType(ImplyType::TVM) // Implementation type. Enumerated type, The options are as follows: TVM, AI_CPU.
    .Formats({DOMI_TENSOR_ND},{DOMI_TENSOR_ND});   //  #### Format of the input and output

}  // namespace domi
