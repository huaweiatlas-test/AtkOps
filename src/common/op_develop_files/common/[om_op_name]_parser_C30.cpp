/* Copyright (C) 2018. Huawei Technologies Co., Ltd. All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the Apache License Version 2.0.You may not use this file except in compliance with the 
License.
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
#include "proto/caffe/caffe.pb.h"
#include "operator.h"
#include "attr_value.h"
#include <memory>
#include <string>
#include <vector>
using namespace ge;

namespace domi
{
// Caffe ParseParams function
Status Caffe[om_op_name]ParseParams(const Message* op_origin, ge::Operator& op_dest)
{
    // trans op_origin to layer
    const caffe::LayerParameter* layer = dynamic_cast<const caffe::LayerParameter*>(op_origin);


    // #### Verify the validity of input operator parameters.
    if (nullptr == layer)
    {
        printf("Dynamic cast op_src to LayerParameter failed\n");
        return FAILED;
    }
    // #### Obtains operator parameters.
    const caffe::[om_op_name]Parameter& param = layer->[om_op_name_param]();
    
    return SUCCESS;
}

// #### Obtains the processing function of the output tensor description. 
Status Caffe[om_op_name]InferShapeAndType(const ge::Operator& op, vector<ge::TensorDesc>& v_output_desc)
{
    auto tensorDesc      = op.GetInputDesc(0);
    auto shape = tensorDesc.GetShape();
    
    // ********************* C++  Call  Python_Start ********************
	Py_Initialize();  
	string chdir_cmd = string("sys.path.append('./../operator')");
	const char* cstr_cmd = chdir_cmd.c_str();
	PyRun_SimpleString("import sys"); 
	PyRun_SimpleString(cstr_cmd);
	PyObject* moduleName = PyString_FromString("[om_op_name]OutputWeightShape");
	PyObject* pModule = PyImport_Import(moduleName);  
	if (!pModule)
	{
		  printf("[ERROR] Python get module failed.");
	    return 0;
	}
    printf("[INFO] Python get module succeed."); 
	PyObject* pv = PyObject_GetAttrString(pModule, "OutputShape[om_op_name]"); 
	if (!pv || !PyCallable_Check(pv)) 
	{
	    printf("[ERROR] Can't find function [om_op_name]OutputShape");
	    return 0;
	}
	printf("[INFO] Get function [om_op_name]OutputShape succeed.");
	
  
  
    long res_0, res_1, res_2, res_3;
	if (pRet)
    {
        PyArg_ParseTuple(pRet, "llll", &res_0, &res_1, &res_2, &res_3);
	}   
    shape.SetDim(0, res_0);
    shape.SetDim(1, res_1);
	shape.SetDim(2, res_2);
	shape.SetDim(3, res_3);
    // ********************* C++ Call Python_End ********************
    tensorDesc.SetShape(shape);
    v_output_desc.push_back(tensorDesc);

    return SUCCESS;

}


// build Te Binary file
Status Caffe[om_op_name]BuildTeBin(const ge::Operator& op, TEBinInfo& te_bin_info)
{
    std::string FilePath   = "";
	std::string RealFilePath    = "";
    std::string FuncName   = "";
    std::string KernelName = "";
    // ### Parse the parameters

    // ### Parse input tensor description 

    // ### Parse the input shape value 

    FilePath   = "../operator/[om_op_name]";
    FuncName   = "[om_op_name]";
    KernelName = "[om_op_name]_" + std::to_string(op.GetInputDesc(0).GetShape().GetDim(0)) + "_" +  std::to_string(op.GetInputDesc(0).GetShape().GetDim(1)) + "_" +
         std::to_string(op.GetInputDesc(0).GetShape().GetDim(2)) + "_" + std::to_string(op.GetInputDesc(0).GetShape().GetDim(3));

    // get real path of Py module
	char *cwd = getcwd(NULL, 0);
	if (cwd == NULL) {
		printf("Get current directory path failed!\n");
		return FAILED;
	}
	std::string cwd_s(cwd);
	char *real_path = realpath((cwd_s + "/" + FilePath + ".py").c_str(), NULL);
	if (real_path == NULL) {
		printf("Get real path of Py module failed!\n");
		return FAILED;
	}
	std::string RealFilePath_ = std::string(real_path);
	RealFilePath = RealFilePath_.substr(0, RealFilePath_.rfind("."));

	std::map<ge::DataType, std::string> operation_map = {
		{ ge::DT_UNDEFINED, "undefined" },
		{ ge::DT_FLOAT, "float32" },
		{ ge::DT_FLOAT16, "float16" },
		{ ge::DT_INT8, "int8" },
		{ ge::DT_INT16, "int16" },
		{ ge::DT_INT32, "int32" },
		{ ge::DT_INT64, "int64" },
		{ ge::DT_UINT8, "uint8" },
		{ ge::DT_UINT16, "uint16" },
		{ ge::DT_UINT32, "uint32" },
		{ ge::DT_UINT64, "uint64" },
        { ge::DT_BOOL, "bool" },
		{ ge::DT_DOUBLE, "double" },
		{ ge::DT_DUAL, "dual" },
		{ ge::DT_DUAL_SUB_INT8, "dual_sub_int8" },
		{ ge::DT_DUAL_SUB_UINT8, "dual_sub_uint8" }
	};

    std::string dtype = operation_map[op.GetInputDesc(0).GetDataType()];

    // i => int; s => string; f => dobule; O => bool, and bool value is Py_True or Py_False




    // set te op json to te_bin_info 
    te_bin_info.bin_file_path  = "./kernel_meta/" + KernelName + ".o";
    te_bin_info.json_file_path = "./kernel_meta/" + KernelName + ".json";

    return SUCCESS;
}

REGISTER_CUSTOM_OP("[om_op_name_param]") // [om_op_name_param] is the type name of the operator in the OM model. It can be specified randomly and cannot be the same as an existing type name. It is case sensitive. 
    .FrameworkType(CAFFE)  // Enumerated type. The options are as follows: CAFFE, TENSORFLOW
    .OriginOpType("[om_op_name]")  // [om_op_name] indicates the type name of the operator in the caffe framework.
    .ParseParamsFn(Caffe[om_op_name]ParseParams)  // Op parameters parse function
    .InferShapeAndTypeFn(Caffe[om_op_name]InferShapeAndType)       // Set output description and datatype function
    .TEBinBuildFn(Caffe[om_op_name]BuildTeBin)           // Build Te op binary function
    .ImplyType(ImplyType::TVM)

}  // namespace domi
