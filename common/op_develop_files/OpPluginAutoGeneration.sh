#!/bin/bash

# coding=utf-8
# ============================================================================
#
# Copyright (C) 2019, Huawei Technologies Co., Ltd. All Rights Reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#   1 Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
#
#   2 Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
#   3 Neither the names of the copyright holders nor the names of the
#    contributors may be used to endorse or promote products derived from this
#    software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# ============================================================================

# Get parameters form config.json file
cur_path=$1
op_name=$(cat $cur_path/config.json | grep -Po 'operator_name[" :]+\K[^"]+')
DDK_PATH_C30=$(cat $cur_path/config.json | grep -Po 'DDK_PATH[" :]+\K[^"]+') 
same_input_output_shape=$(cat $cur_path/config.json | grep -Po 'same_input_output_shape[" :]+\K[^"]+')
input_num=$(cat $cur_path/config.json | grep -Po 'input_num[" :]+\K[^"]+') # get the input num in the json file
weight_num=$(cat $cur_path/config.json | grep -Po 'weight_num[" :]+\K[^"]+') # get the weight num in the json file
framework=$(cat $cur_path/config.json | grep -Po 'framework[" :]+\K[^"]+') # choose tensorflow or caffe
tensorflow_param=$(cat $cur_path/config.json | grep -Po 'tensorflow_param[" :]+\K[^"]+') # get the tensorflow parameter of the operator 
filter_caffe_param=$(cat $cur_path/config.json | grep -Po 'filter_caffe_param[" :]+\K[^"]+') # filter the caffe parameters of the operator 

# check parameters
if [[ "$same_input_output_shape" != True ]] && [[ "$same_input_output_shape" != False ]];then
    echo "[Error] Please check the parameter same_input_output_shape, which can only be set to True or False!"
    exit
fi

if echo $input_num | grep -q '[^0-9]'
then
    if [[ "$input_num" != "auto" ]] && [[ "$input_num" != "autoAll" ]];then
        echo "[Error] "input_num" can only be set to a digital num, auto, or autoAll!"
        exit
    fi    
fi

if echo $weight_num | grep -q '[^0-9]'
then
    echo "[Error] "weight_num" can only be set to a digital num."
fi

op_name_check=`cat $cur_path/config.json | jq '.operator_name'`
if [[ "$op_name_check" == null ]];then
    echo "[Error] Please check the name \"operator_name\" in config.json!"
    exit
fi

framework_check=`cat $cur_path/config.json | jq '.framework'`
if [[ "$framework_check" == null ]];then
    echo "[Error] Please check the name \"framework\" in config.json!"
    exit
fi

DDK_PATH_check=`cat $cur_path/config.json | jq '.DDK_PATH'`
if [[ "$DDK_PATH_check" == null ]];then
    echo "[Error] Please check the name \"DDK_PATH\" in config.json!"
    exit
fi

same_input_output_shape_check=`cat $cur_path/config.json | jq '.same_input_output_shape'`
if [[ "$same_input_output_shape_check" == null ]];then
    echo "[Error] Please check the name \"same_input_output_shape\" in config.json!"
    exit
fi

input_num_check=`cat $cur_path/config.json | jq '.input_num'`
if [[ "$input_num_check" == null ]];then
    echo "[Error] Please check the name \"input_num\" in config.json!"
    exit
fi

# High Level Item
plugin_build=True
IO_5D=False       # input_output_5D_format, i.e., the format of input and output is set to 5D

version=`cat $DDK_PATH_C30/ddk_info | jq '.VERSION' `
if  [[ "$version" == \"1.3.* ]];then
    version="C30"
elif [[ "$version" == \"1.31.* ]];then
    version="C30"
fi

op_name_param=${op_name,,} # lower case
dir_op_name=${op_name}

caffe_proto_param_num=900

# C30
plugin_parser_optional_offset_C30=42
plugin_parser_repeated_offset_C30=43
plugin_builder_optional_offset_C30=52
plugin_builder_repeated_offset_C30=52

python_output_shape_offset_C30=75

plugin_kernel_optional_offset_C30=103   # add 7
plugin_kernel_repeated_offset_C30=103

input_desc_offset_C30=106   # output
py_build_offset_C30=152   # output

# tensorflow
tf_builder_input=31
tf_parser_param=32
tf_kernel_param=56
tf_kernel_input=58
tf_kernel_bin_id=100

current_path=`pwd` # current path
if [ "$op_name" = "" ];then
	echo "input operator name is empty, please input operator_name in config.json"
	exit 1
elif [ -d $dir_op_name ];then
	echo "op dir is already exist"
	if [ -d $dir_op_name/plugin ];then
		echo "op_dir/plugin_dir is already exist"
		if [ -d $current_path/$dir_op_name/operator ];then
			echo "op_dir/operator is already exist"
		else
			mkdir $dir_op_name/operator
		fi
	else
		mkdir $dir_op_name/plugin
	fi
else
	mkdir $dir_op_name
	mkdir $dir_op_name/plugin
	mkdir $dir_op_name/operator
fi

if [ "$framework" == "caffe" ];then
  # parameters check!
  custom_caffe_proto_file_check=`cat $cur_path/config.json | jq '.custom_caffe_proto_file'`
  if [[ "$custom_caffe_proto_file_check" == null ]];then
      echo "[Error] Please check the name \"custom_caffe_proto_file\" in config.json!"
      exit
  fi

	# Automatic generate caffe.proto
	custom_caffe_proto_file=$(cat $cur_path/config.json | grep -Po 'custom_caffe_proto_file[" :]+\K[^"]+')
	custom_caffe_proto_directory=${custom_caffe_proto_file%???????????} # delete the string: caffe.proto
	if [[ ! -d "$custom_caffe_proto_directory" ]]&&[[ $custom_caffe_proto_file =~ "caffe.proto" ]];then
       echo "Please check the config.json file to provide the caffe.proto path !"
       exit
	else  # use custom caffe.proto
        # check whether the operator is in caffe.proto or not     
        if [ "$version" == "C30" ];then
			     sed -n "/message LayerParameter/,/}/p" $DDK_PATH_C30/include/inc/custom/proto/caffe/caffe.proto > $current_path/common/LayerParameter.txt 
        fi
        OpExist=0 # it is used to check whether OP is exist in DDK or not
        operator_name_in_DDK_caffe_proto=$(awk '$1 == "optional" {print $2}' $current_path/common/LayerParameter.txt)
        for OpNameID in $operator_name_in_DDK_caffe_proto
        do
            if [ "$OpNameID" == "$op_name"Parameter ];then
                OpExist=1
                break
            fi
        done 
        
        if [ "$OpExist" == 0 ];then
            # op is not in caffe.proto of DDK
            if [ "$version" == "C30" ];then
		     	      cp $DDK_PATH_C30/include/inc/custom/proto/caffe/caffe.proto $current_path/common/caffe.proto  # caffe.proto in DDK
		        fi
                    
            . ./CaffeProtoPublic.sh 
            
            getCustomMessageInCustomCaffeProto $custom_caffe_proto_file $current_path $op_name
     
            generateNewCaffeProtoWithCustomOperator $DDK_PATH_C30 $current_path $caffe_proto_param_num $op_name $OpExist
        else 
            # op is in caffe.proto of DDK
            if [ "$version" == "C30" ];then
		     	      cp $DDK_PATH_C30/include/inc/custom/proto/caffe/caffe.proto $current_path/common/caffe.proto  # caffe.proto in DDK
		        fi
               
           
            # to get the op param name
            param_name_in_DDK_caffe_proto=$(awk '$1 == "optional" {print $3}' $current_path/common/LayerParameter.txt) 
            custom_param_name_in_DDK=""
            custom_operator_in_DDK_id=0
            custom_param_in_DDK_id=0
            for operator_name_in_DDK in $operator_name_in_DDK_caffe_proto
            do
                custom_operator_in_DDK_id=0
                for param_name_in_DDK in $param_name_in_DDK_caffe_proto
                do
                    if [ "$custom_operator_in_DDK_id" == "$custom_param_in_DDK_id" ];then
                        if [ "$operator_name_in_DDK" == "$op_name"Parameter"" ];then
                            custom_param_name_in_DDK=$param_name_in_DDK
                        fi
                    fi
                    custom_operator_in_DDK_id=$(($custom_operator_in_DDK_id + 1))
                done
                custom_param_in_DDK_id=$(($custom_param_in_DDK_id + 1))
            done
            
            sed -i "s/$op_name/"$op_name"_origin/g" $current_path/common/caffe.proto # substitute the op to op_origin.
            
            
            sed -i "s/"$custom_param_name_in_DDK"/origin_"$custom_param_name_in_DDK"/g" $current_path/common/caffe.proto # substitute the op to op_origin.
            . ./CaffeProtoPublic.sh 
            
            getCustomMessageInCustomCaffeProto $custom_caffe_proto_file $current_path $op_name
     
            generateNewCaffeProtoWithCustomOperator $DDK_PATH_C30 $current_path $caffe_proto_param_num $op_name $OpExist $version

        fi
	fi
	echo "[info] caffe.proto is prepared!"

	# generate parser file
	rm -rf $current_path/$dir_op_name/plugin/$op_name"_parser_C30".cpp
	rm -rf $dir_op_name/plugin/Makefile
	rm -rf $current_path/common/file.txt
	rm -rf $current_path/$dir_op_name/plugin/caffe.pb.*

	# just transfer plugin file
	if [ "$version" == "C30" ];then
		# copy the C30 parser template
		cp $current_path/common/[om_op_name]_parser_C30.cpp $dir_op_name/plugin # copy plugin file
		mv $current_path/$dir_op_name/plugin/[om_op_name]_parser_C30.cpp                   $current_path/$dir_op_name/plugin/$op_name"_parser_C30".cpp
	fi

	# extract the similar operatorParameter part from the original or user defined caffe.proto
	sed -n "/message $op_name"Parameter"/,/message/p" $current_path/common/caffe.proto > $current_path/common/file.txt # extract information: message $op_name"Parameter"/message
	sed -i '$d' $current_path/common/file.txt # delete the last line

  # filter the parameters
  param_list=`cat $cur_path/config.json | jq '.filter_caffe_param'`;
  if [[ "$param_list" == null ]];then
    echo "[Error] Please check the name \"filter_caffe_param\" in config.json!"
  fi
  
 	filter_length=`cat $cur_path/config.json | jq '.filter_caffe_param|length'`;
  current_path=`pwd` # current path of Auto_plugin
  filter_length=$(($filter_length-1)) # the length needs to minus one
  for index in `seq 0 $filter_length`
  do
		  filter_param=`echo $param_list | jq -r ".[$index]"`
		  sed -e '/'''$filter_param'''/d' $current_path/common/file.txt > $current_path/common/filter.txt
		  rm -rf $current_path/common/file.txt
		  mv $current_path/common/filter.txt   $current_path/common/file.txt
	done

	optional_parameter=$(awk '$1 == "optional" {print $3}' $current_path/common/file.txt) # get the optional parameter domain 
	optional_type_parameter=$(awk '$1 == "optional" {print $2}' $current_path/common/file.txt)
	repeated_parameter=$(awk '$1 == "repeated" {print $3}' $current_path/common/file.txt)
	enum_parameter=$(awk '$1 == "enum" {print $2}' $current_path/common/file.txt)   # enum parameter, like the type

	# run the file of UpdateOperatorInterface.sh in the single operator file.
  . ./UpdateOperatorInterface.sh
  echo "[info] operator interface has been finished!"

	# change the template name as a specific operator name
	pmname=${op_name}"Parameter" 
	for files in $(find $current_path/$dir_op_name -type f)
	do       
		sed -i "s/\[om_op_name\]/$op_name/g" $files
		sed -i "s/\[param_message_name\]/$pmname/g" $files
		if [[ ! -d "$custom_caffe_proto_directory" ]]&&[[ $custom_caffe_proto_file =~ "caffe.proto" ]];then
			sed -i "s/\[om_op_name_param\]/"$op_name_param"_param/g" $files
        else
			sed -i "s/\[om_op_name_param\]/$custom_operator_name_caffe_proto/g" $files
        fi
	done
     
  # run the file of ParserOptionalParameter.sh	
  . ./ParserOptionalParameter.sh
  echo "[info] optional parameters parser has been finished!"
   
  # run the file of ParserRepeatedParameter.sh
	. ./ParserRepeatedParameter.sh
  echo "[info] repeated parameters parser has been finished!"

	# run the file of BuilderOptionalParameter.sh
  . ./BuilderOptionalParameter.sh
  echo "[info] optional parameters builder has been finished!"
  
  # run the file of BuilderRepeatedParameter.sh
  . ./BuilderRepeatedParameter.sh
  echo "[info] repeated parameters builder has been finished!"
	
  # run the file of KernelOptionalParameter.sh
  . ./KernelOptionalParameter.sh
  echo "[info] optional parameters kernel has been finished!"
	
  # run the file of KernelRepeatedParameter.sh
  . ./KernelRepeatedParameter.sh
  echo "[info] repeated parameters kernel has been finished!"
	

	for files in $(find $current_path/$op_name/plugin -type f)
	do
		sed -i "s/uint32/int32/g" $files
		sed -i "s/int32/uint32_t/g" $files
		sed -i "s/ge::DT_INT32, \"uint32_t\"/ge::DT_INT32, \"int32\"/g" $files
		sed -i "s/ge::DT_UINT32, \"uint32_t\"/ge::DT_UINT32, \"uint32\"/g" $files
	done

	# run the file of BuilderOutputShape.sh 
  . ./BuilderOutputShape.sh
  echo "[info] output shape builder has been finished!"

  # run the file of KernelInputDesc.sh to set the input, one or more inputs.
  . ./KernelInputDesc.sh	
  echo "[info] input description kernel has been finished!"
 
  # run the file of KernelWeightShape.sh
  if [ "$weight_num" -gt 0 ];then    
    weight_num_check=`cat $cur_path/config.json | jq '.weight_num'`
    if [[ "$weight_num_check" == null ]];then
        echo "[Error] Please check the name \"weight_num\" in config.json!"
        exit
    fi
    weight_num_param_check=`cat $cur_path/config.json | jq '.weight_num_param'`
    if [[ "$weight_num_param_check" == null ]];then
        echo "[Error] Please check the name \"weight_num_param\" in config.json!"
        exit
    fi
    weight_params_check=`cat $cur_path/config.json | jq '.weight_num_param'`;
    for((weightN_check=0;weightN_check<"$weight_num";weightN_check++));
    do
        weightNum_check=`echo $weight_params_check | jq -r ".[0].weight_"$(($weightN_check+1))""`
        if [[ $weightNum_check == null ]];then
            echo "[Error] Please check the name weight_"$(($weightN_check+1))" in config.json!"
            exit
        fi
    done
    . ./KernelWeightShape.sh
  fi
 
       
 
  # run the file of KernelCallOperator.sh
  . ./KernelCallOperator.sh
  echo "[info] "plugin call operator" kernel has been finished!"

  # run the file of UpdateOutputWeightInterface.sh in the single operator file.
  . ./UpdateOutputWeightInterface.sh
  echo "[info] output and weight interface update has been finished!"


	if [ "$version" == "C30" ];then
		  # register module for weight or 5D IO
		  if [ "$IO_5D" == "True" ];then
          if [ "$weight_num" -gt 0 ];then
              sed -i "/.ImplyType(ImplyType/s/$/ \n    .Formats(\{DOMI_TENSOR_NC1HWC0\}, \{DOMI_TENSOR_NC1HWC0\}) /"                          $op_name/plugin/$op_name"_parser_C30.cpp"
              sed -i "/.Formats/s/$/ \n    .WeightFormats(\{/"                          $op_name/plugin/$op_name"_parser_C30.cpp"
              for((weightNum=0;weightNum<"$weight_num";weightNum++));
              do
                  if [ "$weightNum" == $(($weight_num-1)) ];then
                      sed -i "/.WeightFormats/s/$/DOMI_TENSOR_ND\});  /"                          $op_name/plugin/$op_name"_parser_C30.cpp"
                  else
                      sed -i "/.WeightFormats/s/$/DOMI_TENSOR_ND, /"                          $op_name/plugin/$op_name"_parser_C30.cpp"
                  fi
              done 
          else
		          sed -i "/.ImplyType(ImplyType/s/$/ \n    .Formats(\{DOMI_TENSOR_NC1HWC0\}, \{DOMI_TENSOR_NC1HWC0\}); /"                          $op_name/plugin/$op_name"_parser_C30.cpp"
          fi
		  else
          if [ "$weight_num" -gt 0 ];then
              sed -i "/.ImplyType(ImplyType/s/$/\n    .WeightFormats(\{/"                          $op_name/plugin/$op_name"_parser_C30.cpp"
              for((weightNum=0;weightNum<"$weight_num";weightNum++));
              do
                  if [ "$weightNum" == $(($weight_num-1)) ];then
                      sed -i "/.WeightFormats/s/$/DOMI_TENSOR_ND\});  /"                          $op_name/plugin/$op_name"_parser_C30.cpp"
                  else
                      sed -i "/.WeightFormats/s/$/DOMI_TENSOR_ND, /"                          $op_name/plugin/$op_name"_parser_C30.cpp"
                  fi
              done
          else
			        sed -i "/.ImplyType(ImplyType/ s/$/;  /"                                                                                        $op_name/plugin/$op_name"_parser_C30.cpp"
          fi
		  fi
	fi

  # input shape equals output shape (one input) or the first input shape equals output shape (multi inputs) or C++ for output shape
  if [ "$same_input_output_shape" == "True" ];then
      echo "[info] the input shape and the output shape are the same!"
      sed -n "/Copyright/,/Python_Start/p" $current_path/$dir_op_name/plugin/"$op_name"_parser_C30.cpp > $current_path/temp_start_file.txt
      start_line=$(awk 'END{print NR}' $current_path/temp_start_file.txt)
      sed -n "/Copyright/,/Python_End/p" $current_path/$dir_op_name/plugin/"$op_name"_parser_C30.cpp > $current_path/temp_end_file.txt
      end_line=$(awk 'END{print NR}' $current_path/temp_end_file.txt)
      rm -rf $current_path/temp_start_file.txt
      rm -rf $current_path/temp_end_file.txt
      sed -i $start_line','$end_line'd' $current_path/$dir_op_name/plugin/"$op_name"_parser_C30.cpp
      
      if [ "$weight_num" == "0" ];then
          if [ -f "$current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py" ];then
              rm -rf $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
          fi
      fi
  else
      echo "[info] the input shape and the output shape are different!"
  fi

	# delete the redundant files
	rm -rf $current_path/common/file.txt

  project_path=$(cat $cur_path/config.json | grep -Po 'project_path[" :]+\K[^"]+') 

	# caffe.pb.h is needed for the plugin
	rm -rf $current_path/caffe.proto
	cp $current_path/common/caffe.proto $current_path/ 
	if [ "$plugin_build" == "True" ];then
		if [ "$version" == "C30" ];then
			export PATH=$DDK_PATH_C30/uihost/toolchains/ccec-linux/bin:$PATH
			export LD_LIBRARY_PATH=$DDK_PATH_C30/uihost/lib:$LD_LIBRARY_PATH
			export TVM_AICPU_LIBRARY_PATH=$DDK_PATH_C30/uihost/lib:$DDK_PATH/uihost/toolchains/ccec-linux/aicpu_lib:$TVM_AICPU_LIBRARY_PATH
			export TVM_AICPU_INCLUDE_PATH=$DDK_PATH_C30/include/inc/tensor_engine:$TVM_AICPU_INCLUDE_PATH
			export PYTHONPATH=$DDK_PATH_C30/site-packages/:$PYTHONPATH
			export TVM_AICPU_OS_SYSROOT=$DDK_PATH_C30/uihost/toolchains/aarch64-linux-gcc6.3/sysroot:$TVM_AICPU_OS_SYSROOT
			
      if [ -d "$DDK_PATH_C30/bin/x86_64-linux-gcc5.4" ];then
            $DDK_PATH_C30/bin/x86_64-linux-gcc5.4/protoc caffe.proto --cpp_out=$current_path/
      elif [ -d "$DDK_PATH_C30/bin/x86_64-linux-gcc4.8.5" ];then
            $DDK_PATH_C30/bin/x86_64-linux-gcc4.8.5/protoc caffe.proto --cpp_out=$current_path/
      elif [ -d "$DDK_PATH_C30/bin/aarch64-linux-gcc7.3.1" ];then
            $DDK_PATH_C30/bin/aarch64-linux-gcc7.3.1/protoc caffe.proto --cpp_out=$current_path/
      elif [ -d "$DDK_PATH_C30/bin/aarch64-linux-gcc4.8.5" ];then
            $DDK_PATH_C30/bin/aarch64-linux-gcc4.8.5/protoc caffe.proto --cpp_out=$current_path/
      else 
            echo "[Error] Please check the existence of x86_64-linux-gcc5.4, x86_64-linux-gcc4.8.5, aarch64-linux-gcc4.8.5 or aarch64-linux-gcc7.3.1!"
      fi
      
			if [ -d "$project_path" ];then
          project_path_check=`cat $cur_path/config.json | jq '.project_path'`
          if [[ "$project_path_check" == null ]];then
              echo "[Error] Please check the name \"project_path\" in config.json!"
              exit
          fi
      
          rm -rf $project_path/$dir_op_name
          mv $current_path/$dir_op_name $project_path/$dir_op_name  # move the operator project to the src directory
          cp $current_path/caffe.* $project_path/$dir_op_name/plugin  # get caffe.pb.h for C30
          cp $current_path/common/Makefile $project_path/$dir_op_name/plugin # Makefile
          
          DDK_PATH_C302=$(echo $DDK_PATH_C30 |sed -e 's/\//\\\//g') # use path variable in sed command
          sed -i "$((12)) s/^/$(echo "\TOPDIR :=$DDK_PATH_C302")\n/" $project_path/$dir_op_name/plugin/Makefile   # first "plugin in" of Makefile
          
          current_path=`pwd` # current path of Auto_plugin
          cd $project_path/$dir_op_name/plugin
          if [ ! -d "$project_path/$dir_op_name/plugin/proto" ];then
				      mkdir proto
			    fi
			    cd proto
			    if [ ! -d "$project_path/$dir_op_name/plugin/proto/caffe" ];then
				      mkdir caffe
			    fi
          cp $project_path/$dir_op_name/plugin/caffe.* $project_path/$dir_op_name/plugin/proto/caffe
			    cd ..
          export DDK_PATH=$DDK_PATH_C30
			    make clean;make
			    mv $project_path/$dir_op_name/plugin/libreduction_parser.so  $project_path/$dir_op_name/plugin/libcaffe_"$op_name"_layer.so 
          echo "plugin compilation has been finished!"
			    cd $current_path
			    rm -rf caffe.pb.*
          rm -rf proto
			    rm -rf $project_path/$dir_op_name/plugin/caffe.*
      else
          rm -rf $current_path/../../$dir_op_name
          mv $current_path/$dir_op_name $current_path/../../$dir_op_name  # move the operator project to the src directory
          cp $current_path/caffe.* $current_path/../../$dir_op_name/plugin  # get caffe.pb.h for C30
			    cp $current_path/common/Makefile $current_path/../../$dir_op_name/plugin # Makefile

			    DDK_PATH_C302=$(echo $DDK_PATH_C30 |sed -e 's/\//\\\//g') # use path variable in sed command
		    	sed -i "$((12)) s/^/$(echo "\TOPDIR :=$DDK_PATH_C302")\n/" $current_path/../../$dir_op_name/plugin/Makefile   # first "plugin in" of Makefile
			
			    current_path=`pwd` # current path of Auto_plugin
			    cd $current_path/../../$dir_op_name/plugin
			    if [ ! -d "$current_path/../../$dir_op_name/plugin/proto" ];then
				      mkdir proto
			    fi
			    cd proto
			    if [ ! -d "$current_path/../../$dir_op_name/plugin/proto/caffe" ];then
				      mkdir caffe
			    fi
			    cp $current_path/../../$dir_op_name/plugin/caffe.* $current_path/../../$dir_op_name/plugin/proto/caffe
			    cd ..
			    export DDK_PATH=$DDK_PATH_C30
			    make clean;make
			    mv $current_path/../../$dir_op_name/plugin/libreduction_parser.so  $current_path/../../$dir_op_name/plugin/libcaffe_"$op_name"_layer.so 

			    echo "plugin compilation has been finished!"
			    cd $current_path
			    rm -rf caffe.pb.*
          rm -rf proto
			    rm -rf $current_path/../../$dir_op_name/plugin/caffe.*
      fi
		fi
	else
		echo "This plugin needs to be compiled manually"
	fi

elif [ "$framework" == "tensorflow" ];then
    # run the tensorflow automatica plugin generation
    . ./TensorflowAutoPlugin.sh
    
    project_path=$(cat $cur_path/config.json | grep -Po 'project_path[" :]+\K[^"]+') 
    if [[ "$project_path" == "" ]];then
        echo "[Info] Please check the name \"project_path\" in config.json!"
    fi
    
    if [[ "$same_input_output_shape" == "True" ]] && [[ "$weight_num" == "0" ]];then
        if [ -f "$current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py" ];then
          rm -rf $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
        fi
    fi
	  # build
	  if [ "$plugin_build" == "True" ];then
		    export PATH=$DDK_PATH_C30/uihost/toolchains/ccec-linux/bin:$PATH
		    export LD_LIBRARY_PATH=$DDK_PATH_C30/uihost/lib:$LD_LIBRARY_PATH
		    export TVM_AICPU_LIBRARY_PATH=$DDK_PATH_C30/uihost/lib:$DDK_PATH/uihost/toolchains/ccec-linux/aicpu_lib:$TVM_AICPU_LIBRARY_PATH
		    export TVM_AICPU_INCLUDE_PATH=$DDK_PATH_C30/include/inc/tensor_engine:$TVM_AICPU_INCLUDE_PATH
		    export PYTHONPATH=$DDK_PATH_C30/site-packages/:$PYTHONPATH
		    export TVM_AICPU_OS_SYSROOT=$DDK_PATH_C30/uihost/toolchains/aarch64-linux-gcc6.3/sysroot:$TVM_AICPU_OS_SYSROOT
        
        current_path=`pwd` # current path of Auto_plugin
        
        if [ -d "$project_path" ];then
            project_path_check=`cat $cur_path/config.json | jq '.project_path'`
            if [[ "$project_path_check" == null ]];then
                echo "[Error] Please check the name \"project_path\" in config.json!"
                exit
            fi
            rm -rf $project_path/$dir_op_name
            mv $current_path/$dir_op_name $project_path/$dir_op_name  # move the operator project to the src directory
            cp $current_path/common/makefile_tf $project_path/$dir_op_name/plugin
            mv $project_path/$dir_op_name/plugin/makefile_tf  $project_path/$dir_op_name/plugin/makefile
            
            DDK_PATH_tf=$(echo $DDK_PATH_C30 |sed -e 's/\//\\\//g') # use path variable in sed command
            sed -i "$((17)) s/^/$(echo "\ TOPDIR :=$DDK_PATH_tf")\n/" $project_path/$dir_op_name/plugin/makefile   # first "plugin in" of makefile
            
            cd $project_path/$dir_op_name/plugin
            make clean;make
            mv $project_path/$dir_op_name/plugin/libcustomop_demo.so  $project_path/$dir_op_name/plugin/libtf_"$op_name".so
        
        else
            rm -rf $current_path/../../$dir_op_name
            mv $current_path/$dir_op_name $current_path/../../$dir_op_name  # move the operator project to the src directory
	          cp $current_path/common/makefile_tf $current_path/../../$dir_op_name/plugin
	          mv $current_path/../../$dir_op_name/plugin/makefile_tf $current_path/../../$dir_op_name/plugin/makefile
			
            DDK_PATH_tf=$(echo $DDK_PATH_C30 |sed -e 's/\//\\\//g') # use path variable in sed command
		        sed -i "$((17)) s/^/$(echo "\ TOPDIR :=$DDK_PATH_tf")\n/" $current_path/../../$dir_op_name/plugin/makefile   # first "plugin in" of makefile
		
		        cd $current_path/../../$dir_op_name/plugin
		        make clean;make
		        mv $current_path/../../$dir_op_name/plugin/libcustomop_demo.so  $current_path/../../$dir_op_name/plugin/libtf_"$op_name".so 
        fi
		echo "plugin compilation has been finished!"
		cd $current_path
	fi
else
	echo "Currently, only caffe or tensorflow is supported!"

fi

if [ -d "$project_path" ];then
    echo "Notice that, the operator path is in the path of \""$project_path\/$dir_op_name\/operator"\"."
    echo "Notice that, the operator plugin path is in the path of \""$project_path\/$dir_op_name\/plugin"\"."
    echo "Notice that, please modify the operator file "$op_name".py in \""$project_path\/$dir_op_name\/operator\/"$op_name".py"\"."
else
    echo "Notice that, the operator path is in the path of \""$current_path\/..\/..\/$dir_op_name\/operator"\"."
    echo "Notice that, the operator plugin path is in the path of \""$current_path\/..\/..\/$dir_op_name\/plugin"\"."
    echo "Notice that, please modify the operator file "$op_name".py in \""$current_path\/..\/..\/$dir_op_name\/operator\/"$op_name".py"\"."
fi
