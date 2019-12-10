#!/bin/bash

cur_path=`pwd` # to set the path of config.json

if [ ! -f "$cur_path/config.json" ];then
    echo "[Error] Please check the file config.json!"
fi

DDK_PATH=$(cat $cur_path/config.json | grep -Po 'DDK_PATH[" :]+\K[^"]+') 
op_name=$(cat $cur_path/config.json | grep -Po 'operator_name[" :]+\K[^"]+')
framework=$(cat $cur_path/config.json | grep -Po 'framework[" :]+\K[^"]+')
dir_op_name=${op_name}

echo "[info] jq needs to be installed!"
version=`cat $DDK_PATH/ddk_info | jq '.VERSION'`
if  [[ "$version" == \"1.3.* ]];then
    version="C30"
elif [[ "$version" == \"1.31.* ]];then
    version="C30" # C31 equals to C30
else 
    echo "[Error] only DDK version of C30 or C31 is supported!" 
fi

project_path=$(cat $cur_path/config.json | grep -Po 'project_path[" :]+\K[^"]+') 
if [[ "$project_path" == "" ]];then
    echo "[Info] Please check the name \"project_path\" in config.json!"
fi
#  $project_path/
if [ "$framework" == "caffe" ]; then
    if [ -d "$project_path" ];then
        if [[ -f "$project_path/$dir_op_name/operator/"$op_name".py" ]] && [[ -f "$project_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py" ]];then
            echo "[info] "$op_name".py and "$op_name"OutputWeightShape.py have been modified and prepared!" 
            if [ $version=="C30" ];then
                export PATH=$DDK_PATH/uihost/toolchains/ccec-linux/bin:$PATH
		            export LD_LIBRARY_PATH=$DDK_PATH/uihost/lib:$LD_LIBRARY_PATH
		            export TVM_AICPU_LIBRARY_PATH=$DDK_PATH/uihost/lib:$DDK_PATH/uihost/toolchains/ccec-linux/aicpu_lib:$TVM_AICPU_LIBRARY_PATH
		            export TVM_AICPU_INCLUDE_PATH=$DDK_PATH/include/inc/tensor_engine:$TVM_AICPU_INCLUDE_PATH
	              export PYTHONPATH=$DDK_PATH/site-packages/:$PYTHONPATH
		            export TVM_AICPU_OS_SYSROOT=$DDK_PATH/uihost/toolchains/aarch64-linux-gcc6.3/sysroot:$TVM_AICPU_OS_SYSROOT
                cd  $project_path/$dir_op_name/plugin
                make clean;make  
                mv $project_path/$dir_op_name/plugin/libreduction_parser.so  $project_path/$dir_op_name/plugin/libcaffe_"$op_name"_layer.so 
                echo "plugin compilation has been finished!"
                cd $cur_path
            fi
        else
            cd $cur_path/common/op_develop_files
            bash OpPluginAutoGeneration.sh $cur_path
            cd $cur_path
        fi
    else
        if [[ -f "$dir_op_name/operator/"$op_name".py" ]] && [[ -f "$dir_op_name/operator/"$op_name"OutputWeightShape.py" ]];then
	        echo "[info] "$op_name".py and "$op_name"OutputWeightShape.py have been modified and prepared!"      
	        if [ $version=="C30" ];then
                export PATH=$DDK_PATH/uihost/toolchains/ccec-linux/bin:$PATH
		        export LD_LIBRARY_PATH=$DDK_PATH/uihost/lib:$LD_LIBRARY_PATH
		        export TVM_AICPU_LIBRARY_PATH=$DDK_PATH/uihost/lib:$DDK_PATH/uihost/toolchains/ccec-linux/aicpu_lib:$TVM_AICPU_LIBRARY_PATH
		        export TVM_AICPU_INCLUDE_PATH=$DDK_PATH/include/inc/tensor_engine:$TVM_AICPU_INCLUDE_PATH
	            export PYTHONPATH=$DDK_PATH/site-packages/:$PYTHONPATH
		        export TVM_AICPU_OS_SYSROOT=$DDK_PATH/uihost/toolchains/aarch64-linux-gcc6.3/sysroot:$TVM_AICPU_OS_SYSROOT
		        cd $cur_path/$dir_op_name/plugin
		        make clean;make           
		        mv $cur_path/$dir_op_name/plugin/libreduction_parser.so  $cur_path/$dir_op_name/plugin/libcaffe_"$op_name"_layer.so 
		        echo "plugin compilation has been finished!"
		        cd $cur_path
            fi
        else
	        cd $cur_path/common/op_develop_files
	        bash OpPluginAutoGeneration.sh $cur_path
	        cd $cur_path
        fi
    fi
elif [ "$framework" == "tensorflow" ]; then   # $project_path
    if [ -d "$project_path" ];then
        if [[ -f "$project_path/$dir_op_name/operator/"$op_name".py" ]] || [[ -f "$project_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py" ]];then
            echo "[info] "$op_name".py and "$op_name"OutputWeightShape.py have been modified and prepared!"
            if [ $version=="C30" ];then
                export PATH=$DDK_PATH/uihost/toolchains/ccec-linux/bin:$PATH
		            export LD_LIBRARY_PATH=$DDK_PATH/uihost/lib:$LD_LIBRARY_PATH
		            export TVM_AICPU_LIBRARY_PATH=$DDK_PATH/uihost/lib:$DDK_PATH/uihost/toolchains/ccec-linux/aicpu_lib:$TVM_AICPU_LIBRARY_PATH
		            export TVM_AICPU_INCLUDE_PATH=$DDK_PATH/include/inc/tensor_engine:$TVM_AICPU_INCLUDE_PATH
	              export PYTHONPATH=$DDK_PATH/site-packages/:$PYTHONPATH
		            export TVM_AICPU_OS_SYSROOT=$DDK_PATH/uihost/toolchains/aarch64-linux-gcc6.3/sysroot:$TVM_AICPU_OS_SYSROOT
                cd $project_path/$dir_op_name/plugin  
                make clean;make    
                mv $project_path/$dir_op_name/plugin/libcustomop_demo.so  $project_path/$dir_op_name/plugin/libtf_"$op_name".so
                echo "plugin compilation has been finished!"
                cd $cur_path
             fi
        else
                  cd $cur_path/common/op_develop_files
                  bash OpPluginAutoGeneration.sh $cur_path
                  cd $cur_path
        fi  
    else
        if [[ -f "$dir_op_name/operator/"$op_name".py" ]] || [[ -f "$dir_op_name/operator/"$op_name"OutputWeightShape.py" ]];then
	        echo "[info] "$op_name".py and "$op_name"OutputWeightShape.py have been modified and prepared!"      
	        if [ $version=="C30" ];then
                export PATH=$DDK_PATH/uihost/toolchains/ccec-linux/bin:$PATH
		        export LD_LIBRARY_PATH=$DDK_PATH/uihost/lib:$LD_LIBRARY_PATH
		        export TVM_AICPU_LIBRARY_PATH=$DDK_PATH/uihost/lib:$DDK_PATH/uihost/toolchains/ccec-linux/aicpu_lib:$TVM_AICPU_LIBRARY_PATH
		        export TVM_AICPU_INCLUDE_PATH=$DDK_PATH/include/inc/tensor_engine:$TVM_AICPU_INCLUDE_PATH
	            export PYTHONPATH=$DDK_PATH/site-packages/:$PYTHONPATH
		        export TVM_AICPU_OS_SYSROOT=$DDK_PATH/uihost/toolchains/aarch64-linux-gcc6.3/sysroot:$TVM_AICPU_OS_SYSROOT
		        cd $cur_path/$dir_op_name/plugin
		        make clean;make           
		        mv $cur_path/$dir_op_name/plugin/libcustomop_demo.so  $cur_path/$dir_op_name/plugin/libtf_"$op_name".so 
		        echo "plugin compilation has been finished!"
		        cd $cur_path
            fi
        else
            cd $cur_path/common/op_develop_files
            bash OpPluginAutoGeneration.sh $cur_path
            cd $cur_path
        fi
    fi
else
    echo "[Error] only tensorflow and caffe are supported!"
fi
