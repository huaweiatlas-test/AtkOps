#! /bin/bash

  echo "[info] Start tensorflow operator project generation!"
  rm -rf $dir_op_name/plugin/$op_name"_parser_C30.cpp"
  cp $current_path/common/[om_op_name]_parser_tf_C30.cpp  $dir_op_name/plugin
  mv $dir_op_name/plugin/[om_op_name]_parser_tf_C30.cpp  $dir_op_name/plugin/"$op_name"_tf_parser.cpp
  cp $current_path/common/[om_op_name] $dir_op_name/operator
  mv $dir_op_name/operator/[om_op_name]  $dir_op_name/operator/"$op_name".py

  tf_op_origin_name=$(cat $cur_path/config.json | grep -Po 'tf_op_origin_name[" :]+\K[^"]+') # get the tensorflow name of the operator 
  tf_op_origin_name_check=`cat $cur_path/config.json | jq '.tf_op_origin_name'`
  if [[ "$tf_op_origin_name_check" == null ]];then
      echo "[Error] Please check the name \"tf_op_origin_name\" in config.json!"
      exit
  fi
  
  if [[ "$tf_op_origin_name" == "" ]];then
    echo "[Error] Please check the parameter \"tf_op_origin_name\" in config.json!"
    exit
fi
  
	for files in $(find $current_path/$dir_op_name -type f)
	do
		sed -i "s/\[om_op_name\]/$op_name/g" $files
		sed -i "s/\[tf_op_origin_name\]/$tf_op_origin_name/g" $files
    sed -i "s/\[om_ge\]/ge/g" $files
	done

    tf_parser_param_id=0
    # parser the tf parameters, the second offset
    param_list=`cat $cur_path/config.json | jq '.tensorflow_param'`;
    param_length=`cat $cur_path/config.json | jq '.tensorflow_param|length'`;
   
    if [[ "$param_list" == null ]];then
        echo "[Error] Please check the name \"tensorflow_param\" in config.json!"
    fi
    
    param_length=$(($param_length-1)) # the length needs to minus one
    for index in `seq 0 $param_length`
    do
         param_1=`echo $param_list | jq -r ".[$index].param"`
         type_1=`echo $param_list | jq -r ".[$index].type"`
         if [[ "$param_1" == null ]];then
             echo "[Error] Please check the name \"tensorflow_param: param\" in config.json!"
         fi
         if [[ "$type_1" == null ]];then
             echo "[Error] Please check the name \"tensorflow_param: type\" in config.json!"
         fi
    
		if [ "$type_1" == "bool" ];then
		sed -i "$(($tf_parser_param+$tf_builder_input_id+6*index))   s/^/$(echo "\
	"$type_1" "$param_1" = false;  ")\n/"                                                                                    $dir_op_name/plugin/"$op_name"_tf_parser.cpp
		sed -i "$(($tf_parser_param+$tf_builder_input_id+6*$index+1))   s/^/$(echo "\
	ge::AttrValue "$param_1"AttrValue;  ")\n/"                                                                               $dir_op_name/plugin/"$op_name"_tf_parser.cpp
	sed -i "$(($tf_parser_param+$tf_builder_input_id+6*$index+2))   s/^/$(echo "\
	if ((ge::GRAPH_SUCCESS != op.GetAttr(\""$param_1"\", "$param_1"AttrValue)) || (ge::GRAPH_SUCCESS != "$param_1"AttrValue.GetValue<AttrValue::BOOL>("$param_1")))  ")\n/"                                                                                                                                                                                          $dir_op_name/plugin/"$op_name"_tf_parser.cpp
	elif [ "$type_1" == "float" ];then 
		sed -i "$(($tf_parser_param+$tf_builder_input_id+6*index))   s/^/$(echo "\
	"$type_1" "$param_1" = 0.0;  ")\n/"                                                                                      $dir_op_name/plugin/"$op_name"_tf_parser.cpp
		sed -i "$(($tf_parser_param+$tf_builder_input_id+6*index+1))   s/^/$(echo "\
	ge::AttrValue "$param_1"AttrValue;  ")\n/"                                                                               $dir_op_name/plugin/"$op_name"_tf_parser.cpp
	sed -i "$(($tf_parser_param+$tf_builder_input_id+6*index+2))   s/^/$(echo "\
	if ((ge::GRAPH_SUCCESS != op.GetAttr(\""$param_1"\", "$param_1"AttrValue)) || (ge::GRAPH_SUCCESS != "$param_1"AttrValue.GetValue<AttrValue::FLOAT>("$param_1")))  ")\n/"                                                                                                                                                                                         $dir_op_name/plugin/"$op_name"_tf_parser.cpp
	elif [ "$type_1" == "string" ];then
		sed -i "$(($tf_parser_param+$tf_builder_input_id+6*index))   s/^/$(echo "\
	"$type_1" "$param_1" = \" \";  ")\n/"                                                                                    $dir_op_name/plugin/"$op_name"_tf_parser.cpp
		sed -i "$(($tf_parser_param+$tf_builder_input_id+6*index+1))   s/^/$(echo "\
	ge::AttrValue "$param_1"AttrValue;  ")\n/"                                                                               $dir_op_name/plugin/"$op_name"_tf_parser.cpp
	sed -i "$(($tf_parser_param+$tf_builder_input_id+6*index+2))   s/^/$(echo "\
	if ((ge::GRAPH_SUCCESS != op.GetAttr(\""$param_1"\", "$param_1"AttrValue)) || (ge::GRAPH_SUCCESS != "$param_1"AttrValue.GetValue<AttrValue::STR>("$param_1")))  ")\n/"                                                                                                                                                                                           $dir_op_name/plugin/"$op_name"_tf_parser.cpp
	else 
		sed -i "$(($tf_parser_param+$tf_builder_input_id+6*index))   s/^/$(echo "\
	"$type_1" "$param_1" = 0;  ")\n/"                                                                                        $dir_op_name/plugin/"$op_name"_tf_parser.cpp
		sed -i "$(($tf_parser_param+$tf_builder_input_id+6*index+1))   s/^/$(echo "\
	ge::AttrValue "$param_1"AttrValue;  ")\n/"                                                                               $dir_op_name/plugin/"$op_name"_tf_parser.cpp
	sed -i "$(($tf_parser_param+$tf_builder_input_id+6*index+2))   s/^/$(echo "\
	if ((ge::GRAPH_SUCCESS != op.GetAttr(\""$param_1"\", "$param_1"AttrValue)) || (ge::GRAPH_SUCCESS != "$param_1"AttrValue.GetValue<AttrValue::INT>("$param_1")))  ")\n/"                                                                                                                                                                                           $dir_op_name/plugin/"$op_name"_tf_parser.cpp
	fi 
		sed -i "$(($tf_parser_param+$tf_builder_input_id+6*index+3))   s/^/$(echo "\
	{  ")\n/"                                                                                                                $dir_op_name/plugin/"$op_name"_tf_parser.cpp
		sed -i "$(($tf_parser_param+$tf_builder_input_id+6*index+4))   s/^/$(echo "\
	    printf(\"Can not Get "$param_1"!\\\n\");  ")\n/"                                                                     $dir_op_name/plugin/"$op_name"_tf_parser.cpp
		sed -i "$(($tf_parser_param+$tf_builder_input_id+6*index+5))   s/^/$(echo "\
	}  ")\n/"                                                                                                                $dir_op_name/plugin/"$op_name"_tf_parser.cpp
	tf_parser_param_id=$(($tf_parser_param_id+6))       
  done
  echo "[info] tensorflow operator builder parameters have been finished!"

  # sampe input and output shape or not
  if [ "$same_input_output_shape" == "False" ];then 
      echo "[info] the input shape and the output shape are different!" 
      tf_output_shape_id=$(($tf_parser_param_id+$tf_parser_param+2)) # ($tf_parser_param+2) means the offset to output shape
      . ./TensorflowOutputShape.sh
  else
      echo "[info] the input shape and the output shape are the same!" 
  fi
  
  # kernel parameters
  tf_kernel_param=$((tf_kernel_param+tf_parser_param_id)) # update the tf_kernel_param, it include two parts, tf_kernel_param and tf_parser_param_id
  # placed in the kernel bin part
  for index in `seq 0 $param_length`
    do
         param_1=`echo $param_list | jq -r ".[$index].param"`
         type_1=`echo $param_list | jq -r ".[$index].type"`
    
		if [ "$type_1" == "bool" ];then
		sed -i "$(($tf_kernel_param+$tf_builder_input_id+6*index))   s/^/$(echo "\
	"$type_1" "$param_1" = false;  ")\n/"                                                                                    $dir_op_name/plugin/"$op_name"_tf_parser.cpp
		sed -i "$(($tf_kernel_param+$tf_builder_input_id+6*index+1))   s/^/$(echo "\
	ge::AttrValue "$param_1"AttrValue;  ")\n/"                                                                               $dir_op_name/plugin/"$op_name"_tf_parser.cpp
	sed -i "$(($tf_kernel_param+$tf_builder_input_id+6*index+2))   s/^/$(echo "\
	if ((ge::GRAPH_SUCCESS != op.GetAttr(\""$param_1"\", "$param_1"AttrValue)) || (ge::GRAPH_SUCCESS != "$param_1"AttrValue.GetValue<AttrValue::BOOL>("$param_1")))  ")\n/"                                                                                                                                                                                          $dir_op_name/plugin/"$op_name"_tf_parser.cpp
	elif [ "$type_1" == "float" ];then 
		sed -i "$(($tf_kernel_param+$tf_builder_input_id+6*index))   s/^/$(echo "\
	"$type_1" "$param_1" = 0.0;  ")\n/"                                                                                      $dir_op_name/plugin/"$op_name"_tf_parser.cpp
		sed -i "$(($tf_kernel_param+$tf_builder_input_id+6*index+1))   s/^/$(echo "\
	ge::AttrValue "$param_1"AttrValue;  ")\n/"                                                                               $dir_op_name/plugin/"$op_name"_tf_parser.cpp
	sed -i "$(($tf_kernel_param+$tf_builder_input_id+6*index+2))   s/^/$(echo "\
	if ((ge::GRAPH_SUCCESS != op.GetAttr(\""$param_1"\", "$param_1"AttrValue)) || (ge::GRAPH_SUCCESS != "$param_1"AttrValue.GetValue<AttrValue::FLOAT>("$param_1")))  ")\n/"                                                                                                                                                                                         $dir_op_name/plugin/"$op_name"_tf_parser.cpp
	elif [ "$type_1" == "string" ];then
		sed -i "$(($tf_kernel_param+$tf_builder_input_id+6*index))   s/^/$(echo "\
	"$type_1" "$param_1" = \" \";  ")\n/"                                                                                    $dir_op_name/plugin/"$op_name"_tf_parser.cpp
		sed -i "$(($tf_kernel_param+$tf_builder_input_id+6*index+1))   s/^/$(echo "\
	ge::AttrValue "$param_1"AttrValue;  ")\n/"                                                                               $dir_op_name/plugin/"$op_name"_tf_parser.cpp
	sed -i "$(($tf_kernel_param+$tf_builder_input_id+6*index+2))   s/^/$(echo "\
	if ((ge::GRAPH_SUCCESS != op.GetAttr(\""$param_1"\", "$param_1"AttrValue)) || (ge::GRAPH_SUCCESS != "$param_1"AttrValue.GetValue<AttrValue::STR>("$param_1")))  ")\n/"                                                                                                                                                                                           $dir_op_name/plugin/"$op_name"_tf_parser.cpp
	else 
		sed -i "$(($tf_kernel_param+$tf_builder_input_id+6*index))   s/^/$(echo "\
	"$type_1" "$param_1" = 0;  ")\n/"                                                                                        $dir_op_name/plugin/"$op_name"_tf_parser.cpp
		sed -i "$(($tf_kernel_param+$tf_builder_input_id+6*index+1))   s/^/$(echo "\
	ge::AttrValue "$param_1"AttrValue;  ")\n/"                                                                               $dir_op_name/plugin/"$op_name"_tf_parser.cpp
	sed -i "$(($tf_kernel_param+$tf_builder_input_id+6*index+2))   s/^/$(echo "\
	if ((ge::GRAPH_SUCCESS != op.GetAttr(\""$param_1"\", "$param_1"AttrValue)) || (ge::GRAPH_SUCCESS != "$param_1"AttrValue.GetValue<AttrValue::INT>("$param_1")))  ")\n/"                                                                                                                                                                                           $dir_op_name/plugin/"$op_name"_tf_parser.cpp
	fi 
		sed -i "$(($tf_kernel_param+$tf_builder_input_id+6*index+3))   s/^/$(echo "\
	{  ")\n/"                                                                                                                $dir_op_name/plugin/"$op_name"_tf_parser.cpp
		sed -i "$(($tf_kernel_param+$tf_builder_input_id+6*index+4))   s/^/$(echo "\
	    printf(\"Can not Get "$type_1"!\\\n\");  ")\n/"                                                                      $dir_op_name/plugin/"$op_name"_tf_parser.cpp
		sed -i "$(($tf_kernel_param+$tf_builder_input_id+6*index+5))   s/^/$(echo "\
	}  ")\n/"                                                                                                                $dir_op_name/plugin/"$op_name"_tf_parser.cpp
	tf_parser_param_id=$(($tf_parser_param_id+6))       
  done
  echo "[info] tensorflow operator kernel parameters generation have been finished!"

    # kernel input
  if [ "$input_num" == "2" ];then
		sed -i "$((tf_kernel_input+tf_builder_input_id+tf_parser_param_id))   s/^/$(echo "\
	TensorDesc input_desc     = op.GetInputDesc(0); ")\n/"                                                                   $dir_op_name/plugin/"$op_name"_tf_parser.cpp
		sed -i "$(($tf_kernel_input+$tf_builder_input_id+$tf_parser_param_id+1))   s/^/$(echo "\
	TensorDesc input_desc_2     = op.GetInputDesc(1); ")\n/"                                                                 $dir_op_name/plugin/"$op_name"_tf_parser.cpp
	    tf_builder_input_id=$((tf_builder_input_id+2))
	elif [ "$input_num" == "1" ];then
		sed -i "$((tf_kernel_input+tf_builder_input_id+tf_parser_param_id))   s/^/$(echo "\
	TensorDesc input_desc     = op.GetInputDesc(0); ")\n/"                                                                   $dir_op_name/plugin/"$op_name"_tf_parser.cpp
	    tf_builder_input_id=$((tf_builder_input_id+1))
         
  elif [ "$input_num" == "auto" ];then
			sed -i "$((tf_kernel_input+tf_builder_input_id+tf_parser_param_id)) s/^/$(echo "\
	auto input_desc = op.GetInputDesc(0);")\n/"                                                                               $dir_op_name/plugin/"$op_name"_tf_parser.cpp
      sed -i "$(($tf_kernel_input+$tf_builder_input_id+$tf_parser_param_id+1)) s/^/$(echo "\
	int64_t tensorNumber = 0; ")\n/"                                                                                          $dir_op_name/plugin/"$op_name"_tf_parser.cpp
      sed -i "$(($tf_kernel_input+$tf_builder_input_id+$tf_parser_param_id+2)) s/^/$(echo "\
	for (size_t i = 0; op.GetInputDesc(i).GetShape().GetShapeSize(); i++) ")\n/"                                              $dir_op_name/plugin/"$op_name"_tf_parser.cpp
      sed -i "$(($tf_kernel_input+$tf_builder_input_id+$tf_parser_param_id+3)) s/^/$(echo "\
	{ ")\n/"                                                                                                                  $dir_op_name/plugin/"$op_name"_tf_parser.cpp
	    sed -i "$(($tf_kernel_input+$tf_builder_input_id+$tf_parser_param_id+4)) s/^/$(echo "\
		tensorNumber++;	")\n/"                                                                                                  $dir_op_name/plugin/"$op_name"_tf_parser.cpp
		 	sed -i "$(($tf_kernel_input+$tf_builder_input_id+$tf_parser_param_id+5)) s/^/$(echo "\
	} ")\n/"                                                                                                                  $dir_op_name/plugin/"$op_name"_tf_parser.cpp
	    sed -i "$(($tf_kernel_input+$tf_builder_input_id+$tf_parser_param_id+6)) s/^/$(echo "\
	Py_Initialize();  ")\n/"                                                                                                  $dir_op_name/plugin/"$op_name"_tf_parser.cpp
	    sed -i "$(($tf_kernel_input+$tf_builder_input_id+$tf_parser_param_id+7)) s/^/$(echo "\
	PyObject *pyShape = PyTuple_New(input_desc.GetShape().GetDimNum()); ")\n/"                                                $dir_op_name/plugin/"$op_name"_tf_parser.cpp
	    sed -i "$(($tf_kernel_input+$tf_builder_input_id+$tf_parser_param_id+8)) s/^/$(echo "\
	for (size_t j = 0; j < input_desc.GetShape().GetDimNum(); j++)   ")\n/"                                                   $dir_op_name/plugin/"$op_name"_tf_parser.cpp
	    sed -i "$(($tf_kernel_input+$tf_builder_input_id+$tf_parser_param_id+9)) s/^/$(echo "\
	{ ")\n/"                                                                                                                  $dir_op_name/plugin/"$op_name"_tf_parser.cpp
	   	sed -i "$(($tf_kernel_input+$tf_builder_input_id+$tf_parser_param_id+10)) s/^/$(echo "\
		PyTuple_SetItem(pyShape, j, Py_BuildValue(\"i\", input_desc.GetShape().GetDim(j))); ")\n/"                              $dir_op_name/plugin/"$op_name"_tf_parser.cpp
	    sed -i "$(($tf_kernel_input+$tf_builder_input_id+$tf_parser_param_id+11)) s/^/$(echo "\
	} ")\n/"                                                                                                                  $dir_op_name/plugin/"$op_name"_tf_parser.cpp
 
      tf_builder_input_id=$((tf_builder_input_id+12))			 
      
  elif [ "$input_num" == "autoAll" ];then
			sed -i "$((tf_kernel_input+tf_builder_input_id+tf_parser_param_id)) s/^/$(echo "\
	auto input_desc = op.GetInputDesc(0);")\n/"                                                                                $dir_op_name/plugin/"$op_name"_tf_parser.cpp
            sed -i "$(($tf_kernel_input+$tf_builder_input_id+$tf_parser_param_id+1)) s/^/$(echo "\
	int64_t tensorNumber = 0; ")\n/"                                                                                           $dir_op_name/plugin/"$op_name"_tf_parser.cpp
            sed -i "$(($tf_kernel_input+$tf_builder_input_id+$tf_parser_param_id+2)) s/^/$(echo "\
	for (size_t i = 0; op.GetInputDesc(i).GetShape().GetShapeSize(); i++) ")\n/"                                               $dir_op_name/plugin/"$op_name"_tf_parser.cpp
			sed -i "$(($tf_kernel_input+$tf_builder_input_id+$tf_parser_param_id+3)) s/^/$(echo "\
	{ ")\n/"                                                                                                                   $dir_op_name/plugin/"$op_name"_tf_parser.cpp
			sed -i "$(($tf_kernel_input+$tf_builder_input_id+$tf_parser_param_id+4)) s/^/$(echo "\
		tensorNumber++;	")\n/"                                                                                                   $dir_op_name/plugin/"$op_name"_tf_parser.cpp
			sed -i "$(($tf_kernel_input+$tf_builder_input_id+$tf_parser_param_id+5)) s/^/$(echo "\
	} ")\n/"                                                                                                                   $dir_op_name/plugin/"$op_name"_tf_parser.cpp
			sed -i "$(($tf_kernel_input+$tf_builder_input_id+$tf_parser_param_id+6)) s/^/$(echo "\
	Py_Initialize();  ")\n/"                                                                                                   $dir_op_name/plugin/"$op_name"_tf_parser.cpp
		

			sed -i "$(($tf_kernel_input+$tf_builder_input_id+$tf_parser_param_id+7)) s/^/$(echo "\
	PyObject *pyShapes = PyTuple_New(tensorNumber); ")\n/"                                                                     $dir_op_name/plugin/"$op_name"_tf_parser.cpp
	  	sed -i "$(($tf_kernel_input+$tf_builder_input_id+$tf_parser_param_id+8)) s/^/$(echo "\
	for (size_t k = 0; k < tensorNumber; k++)   ")\n/"                                                                         $dir_op_name/plugin/"$op_name"_tf_parser.cpp
			sed -i "$(($tf_kernel_input+$tf_builder_input_id+$tf_parser_param_id+9)) s/^/$(echo "\
	{ ")\n/"                                                                                                                   $dir_op_name/plugin/"$op_name"_tf_parser.cpp


			sed -i "$(($tf_kernel_input+$tf_builder_input_id+$tf_parser_param_id+10)) s/^/$(echo "\
		PyObject *pyShape = PyTuple_New(op.GetInputDesc(k).GetShape().GetDimNum()); ")\n/"                                       $dir_op_name/plugin/"$op_name"_tf_parser.cpp
			sed -i "$(($tf_kernel_input+$tf_builder_input_id+$tf_parser_param_id+11)) s/^/$(echo "\
		for (size_t j = 0; j < op.GetInputDesc(k).GetShape().GetDimNum(); j++)   ")\n/"                                          $dir_op_name/plugin/"$op_name"_tf_parser.cpp
			sed -i "$(($tf_kernel_input+$tf_builder_input_id+$tf_parser_param_id+12)) s/^/$(echo "\
		{ ")\n/"                                                                                                                 $dir_op_name/plugin/"$op_name"_tf_parser.cpp
			sed -i "$(($tf_kernel_input+$tf_builder_input_id+$tf_parser_param_id+13)) s/^/$(echo "\
			PyTuple_SetItem(pyShape, j, Py_BuildValue(\"i\", op.GetInputDesc(k).GetShape().GetDim(j))); ")\n/"                     $dir_op_name/plugin/"$op_name"_tf_parser.cpp
			sed -i "$(($tf_kernel_input+$tf_builder_input_id+$tf_parser_param_id+14)) s/^/$(echo "\
		} ")\n/"                                                                                                                 $dir_op_name/plugin/"$op_name"_tf_parser.cpp
			sed -i "$(($tf_kernel_input+$tf_builder_input_id+$tf_parser_param_id+15)) s/^/$(echo "\
		PyTuple_SetItem(pyShapes, k, pyShape); ")\n/"                                                                            $dir_op_name/plugin/"$op_name"_tf_parser.cpp
			sed -i "$(($tf_kernel_input+$tf_builder_input_id+$tf_parser_param_id+16)) s/^/$(echo "\
	} ")\n/"                                                                                                                   $dir_op_name/plugin/"$op_name"_tf_parser.cpp

			tf_builder_input_id=$((tf_builder_input_id+17))       
      
      
  else
		input_num_offset=$((tf_kernel_input+tf_builder_input_id+tf_parser_param_id))
    for((i=1;i<="$input_num";i++));
		do
        if [ "$i" == 1 ];then
            sed -i "$(($input_num_offset+$i-1)) s/^/$(echo "\
    ge::TensorDesc input_desc = op.GetInputDesc("$(($i-1))");")\n/"                                                          $dir_op_name/plugin/"$op_name"_tf_parser.cpp
        else 
			      sed -i "$(($input_num_offset+$i-1)) s/^/$(echo "\
    ge::TensorDesc input"$i"_desc = op.GetInputDesc("$(($i-1))");")\n/"                                                      $dir_op_name/plugin/"$op_name"_tf_parser.cpp
        fi
		    tf_builder_input_id=$((tf_builder_input_id+1))
		done        
	fi
  echo "[info] tensorflow operator input numbers generation have been finished!"
 
    # notice that the tf_builder_input_id include two parts, two offsets about intputs  
	
    # kernel bin
    tf_kernel_bin_offset=0 # whether 2 or 3, according to the input_num
    if [ "$input_num" == "2" ];then
		    if [ "$IO_5D" == "True" ];then # 5D IO
		        sed -i "$((tf_kernel_bin_id+tf_builder_input_id+tf_parser_param_id)) s/^/$(echo " \
		\"(i,i,i,i,i),(i,i,i,i,i),")\n/"                                                                                     $dir_op_name/plugin/"$op_name"_tf_parser.cpp
			      # add dtype
		        sed -i "/(i,i/ s/$/s, /"                                                                                     $dir_op_name/plugin/"$op_name"_tf_parser.cpp
            # add the parameter type in kernel bin
			for index in `seq 0 $param_length` # the updated length
			do
				param_1=`echo $param_list | jq -r ".[$index].param"`
				type_1=`echo $param_list | jq -r ".[$index].type"`
				if [ "$type_1" == "bool" ];then
		            sed -i "/(i,i/ s/$/O, /"                                                                                 $dir_op_name/plugin/"$op_name"_tf_parser.cpp
				elif [ "$type_1" == "string" ];then
		            sed -i "/(i,i/ s/$/s, /"                                                                                 $dir_op_name/plugin/"$op_name"_tf_parser.cpp
				elif [ "$type_1" == "float" ];then
		            sed -i "/(i,i/ s/$/f, /"                                                                                 $dir_op_name/plugin/"$op_name"_tf_parser.cpp
				else
		            sed -i "/(i,i/ s/$/i, /"                                                                                 $dir_op_name/plugin/"$op_name"_tf_parser.cpp
                fi
    done
	      	# add kernel_name and need_build
		sed -i "/(i,i/ s/$/s,O\", /"                                                                                         $dir_op_name/plugin/"$op_name"_tf_parser.cpp
	
		sed -i "$(($tf_kernel_bin_id+$tf_builder_input_id+$tf_parser_param_id+1)) s/^/$(echo "\
		input_desc.GetShape().GetDim(0), input_desc.GetShape().GetDim(1)\/16, input_desc.GetShape().GetDim(2), input_desc.GetShape().GetDim(3), 16,")\n/"  $dir_op_name/plugin/"$op_name"_tf_parser.cpp
	sed -i "$(($tf_kernel_bin_id+$tf_builder_input_id+$tf_parser_param_id+2)) s/^/$(echo "\
		input_desc_2.GetShape().GetDim(0), input_desc_2.GetShape().GetDim(1), input_desc_2.GetShape().GetDim(2), input_desc_2.GetShape().GetDim(3), 16,")\n/"
      	                                                                                                                 $dir_op_name/plugin/"$op_name"_tf_parser.cpp
		else 
			sed -i "$((tf_kernel_bin_id+tf_builder_input_id+tf_parser_param_id)) s/^/$(echo " \
		\"(i,i,i,i),(i,i,i,i),")\n/"                                                                                         $dir_op_name/plugin/"$op_name"_tf_parser.cpp
			# add dtype
		sed -i "/(i,i/ s/$/s, /"                                                                                             $dir_op_name/plugin/"$op_name"_tf_parser.cpp
   # add the parameter type in kernel bin
			for index in `seq 0 $param_length` # the updated length
			do
				param_1=`echo $param_list | jq -r ".[$index].param"`
				type_1=`echo $param_list | jq -r ".[$index].type"`
				if [ "$type_1" == "bool" ];then
		            sed -i "/(i,i/ s/$/O, /"                                                                                  $dir_op_name/plugin/"$op_name"_tf_parser.cpp
				elif [ "$type_1" == "string" ];then
		            sed -i "/(i,i/ s/$/s, /"                                                                                  $dir_op_name/plugin/"$op_name"_tf_parser.cpp
				elif [ "$type_1" == "float" ];then
		            sed -i "/(i,i/ s/$/f, /"                                                                                  $dir_op_name/plugin/"$op_name"_tf_parser.cpp
				else
		            sed -i "/(i,i/ s/$/i, /"                                                                                  $dir_op_name/plugin/"$op_name"_tf_parser.cpp
                fi
            done
	      	# add kernel_name and need_build
		sed -i "/(i,i/ s/$/s,O\", /"                                                                                          $dir_op_name/plugin/"$op_name"_tf_parser.cpp
	sed -i "$(($tf_kernel_bin_id+$tf_builder_input_id+$tf_parser_param_id+1)) s/^/$(echo "\
		input_desc.GetShape().GetDim(0), input_desc.GetShape().GetDim(1), input_desc.GetShape().GetDim(2), input_desc.GetShape().GetDim(3),")\n/"  $dir_op_name/plugin/"$op_name"_tf_parser.cpp
	sed -i "$(($tf_kernel_bin_id+$tf_builder_input_id+$tf_parser_param_id+2)) s/^/$(echo "\
		input_desc_2.GetShape().GetDim(0), input_desc_2.GetShape().GetDim(1), input_desc_2.GetShape().GetDim(2), input_desc_2.GetShape().GetDim(3),")\n/" $dir_op_name/plugin/"$op_name"_tf_parser.cpp
        tf_kernel_bin_offset=3 # two inputs
		fi
	else  # input num 1 or other
		if [ "$IO_5D" == "True" ];then
        if [ "$input_num" == "1" ];then   
            sed -i "$((tf_kernel_bin_id+tf_builder_input_id+tf_parser_param_id)) s/^/$(echo " \
		    \"(i,i,i,i,i),")\n/"                                                                                                  $dir_op_name/plugin/"$op_name"_tf_parser.cpp
        elif [ "$input_num" == "auto" ];then
            sed -i "$((tf_kernel_bin_id+tf_builder_input_id+tf_parser_param_id)) s/^/$(echo "\
		    \"O, s, i, ")\n/"                                                                                                     $dir_op_name/plugin/"$op_name"_tf_parser.cpp
        elif [ "$input_num" == "autoAll" ];then
				    sed -i "$((tf_kernel_bin_id+tf_builder_input_id+tf_parser_param_id)) s/^/$(echo "\
  	    \"O, s, ")\n/"                                                                                                        $dir_op_name/plugin/"$op_name"_tf_parser.cpp
        else
            sed -i "$((tf_kernel_bin_id+tf_builder_input_id+tf_parser_param_id)) s/^/$(echo "\
		    \"(i,i,i,i,i), ")\n/"                                                                                                 $dir_op_name/plugin/"$op_name"_tf_parser.cpp
					for((i=1;i<"$input_num";i++));
					do 
						sed -i "/(i,i,i,i,i/ s/$/(i,i,i,i,i), /"                                                                          $dir_op_name/plugin/"$op_name"_tf_parser.cpp
					done
   
			  fi
      # add dtype  5D
    if [ "$input_num" == "auto" ];then
          sed -i "/O, s/ s/$/s, /"                                                                                            $dir_op_name/plugin/"$op_name"_tf_parser.cpp
      elif [ "$input_num" == "autoAll" ];then
          sed -i "/O, s/ s/$/s, /"                                                                                            $dir_op_name/plugin/"$op_name"_tf_parser.cpp
      else 
		      sed -i "/(i,i/ s/$/s, /"                                                                                            $dir_op_name/plugin/"$op_name"_tf_parser.cpp
      fi
      	
      # add the parameter type in kernel bin   5D
			for index in `seq 0 $param_length` # the updated length
			do
				param_1=`echo $param_list | jq -r ".[$index].param"`
				type_1=`echo $param_list | jq -r ".[$index].type"`
   	    if [ "$type_1" == "bool" ];then
            if [ "$input_num" == "auto" ];then
                sed -i "/O, s/ s/$/O, /"                                                                                  $dir_op_name/plugin/"$op_name"_tf_parser.cpp
            elif [ "$input_num" == "autoAll" ];then
                sed -i "/O, s/ s/$/O, /"                                                                                  $dir_op_name/plugin/"$op_name"_tf_parser.cpp
            else
		            sed -i "/(i,i/ s/$/O, /"                                                                                  $dir_op_name/plugin/"$op_name"_tf_parser.cpp
            fi
				elif [ "$type_1" == "string" ];then
            if [ "$input_num" == "auto" ];then
                sed -i "/O, s/ s/$/s, /"                                                                                  $dir_op_name/plugin/"$op_name"_tf_parser.cpp
            elif [ "$input_num" == "autoAll" ];then
                sed -i "/O, s/ s/$/s, /"                                                                                  $dir_op_name/plugin/"$op_name"_tf_parser.cpp
            else
		            sed -i "/(i,i/ s/$/s, /"                                                                                  $dir_op_name/plugin/"$op_name"_tf_parser.cpp
            fi            
				elif [ "$type_1" == "float" ];then
            if [ "$input_num" == "auto" ];then
                sed -i "/O, s/ s/$/f, /"                                                                                  $dir_op_name/plugin/"$op_name"_tf_parser.cpp
            elif [ "$input_num" == "autoAll" ];then
                sed -i "/O, s/ s/$/f, /"                                                                                  $dir_op_name/plugin/"$op_name"_tf_parser.cpp
            else
		            sed -i "/(i,i/ s/$/f, /"                                                                                  $dir_op_name/plugin/"$op_name"_tf_parser.cpp
            fi 
		            
				else
            if [ "$input_num" == "auto" ];then
                sed -i "/O, s/ s/$/i, /"                                                                                  $dir_op_name/plugin/"$op_name"_tf_parser.cpp
            elif [ "$input_num" == "autoAll" ];then
                sed -i "/O, s/ s/$/i, /"                                                                                  $dir_op_name/plugin/"$op_name"_tf_parser.cpp
            else
		            sed -i "/(i,i/ s/$/i, /"                                                                                  $dir_op_name/plugin/"$op_name"_tf_parser.cpp
            fi           
        fi
      done

      # add kernel_name and need_build 5D
      if [ "$input_num" == "auto" ];then
          sed -i "/O, s/ s/$/s,O\", /"                                                                                          $dir_op_name/plugin/"$op_name"_tf_parser.cpp
      elif [ "$input_num" == "autoAll" ];then
          sed -i "/O, s/ s/$/s,O\", /"                                                                                          $dir_op_name/plugin/"$op_name"_tf_parser.cpp
      else
		      sed -i "/(i,i/ s/$/s,O\", /"                                                                                          $dir_op_name/plugin/"$op_name"_tf_parser.cpp
      fi 
      
  if [ "$input_num" == "1" ];then
  	    sed -i "$(($tf_kernel_bin_id+$tf_builder_input_id+$tf_parser_param_id+1))  s/^/$(echo "\
		input_desc.GetShape().GetDim(0), input_desc.GetShape().GetDim(1)\/16, input_desc.GetShape().GetDim(2), input_desc.GetShape().GetDim(3), 16,")\n/"  $dir_op_name/plugin/"$op_name"_tf_parser.cpp
        tf_kernel_bin_offset=2 # one input
		elif [ "$input_num" == "auto" ];then
			sed -i "$(($tf_kernel_bin_id+$tf_builder_input_id+$tf_parser_param_id+1))  s/^/$(echo "\
		pyShape,")\n/"                                                                                                                    $dir_op_name/plugin/"$op_name"_tf_parser.cpp
			sed -i "$(($tf_kernel_bin_id+$tf_builder_input_id+$tf_parser_param_id+2))  s/^/$(echo "\
		tensorNumber,")\n/"                                                                                                               $dir_op_name/plugin/"$op_name"_tf_parser.cpp
		    tf_kernel_bin_offset=3 
		elif [ "$input_num" == "autoAll" ];then
			sed -i "$(($tf_kernel_bin_id+$tf_builder_input_id+$tf_parser_param_id+1))  s/^/$(echo "\
			pyShapes,")\n/"                                                                                                                 $dir_op_name/plugin/"$op_name"_tf_parser.cpp
		else 
		  for((i=1;i<="$input_num";i++));
		  do
         if [ "$i" == 1 ];then
			       sed -i "$(($tf_kernel_bin_id+$tf_builder_input_id+$tf_parser_param_id+1))  s/^/$(echo "\
		input_desc.GetShape().GetDim(0), input_desc.GetShape().GetDim(1)\/16, input_desc.GetShape().GetDim(2), input_desc.GetShape().GetDim(3), 16,")\n/"  $dir_op_name/plugin/"$op_name"_tf_parser.cpp
         else                                                      
             sed -i "$(($tf_kernel_bin_id+$tf_builder_input_id+$tf_parser_param_id+i))  s/^/$(echo "\
		input"$i"_desc.GetShape().GetDim("$((0))"), input"$i"_desc.GetShape().GetDim("$((1))")\/16, input"$i"_desc.GetShape().GetDim("$((2))"), input"$i"_desc.GetShape().GetDim("$((3))"), 16,")\n/" $dir_op_name/plugin/"$op_name"_tf_parser.cpp
          fi
      done 
         tf_kernel_bin_offset=$(($input_num+1))
      fi 
 
  
  sed -i "$(($tf_kernel_bin_id+$tf_builder_input_id+$tf_parser_param_id+1)) s/^/$(echo "\
		input_desc.GetShape().GetDim(0), input_desc.GetShape().GetDim(1)\/16, input_desc.GetShape().GetDim(2), input_desc.GetShape().GetDim(3), 16,")\n/"  $dir_op_name/plugin/"$op_name"_tf_parser.cpp
		
		else # not IO_5D   4D
        if [ "$input_num" == "1" ];then   
            sed -i "$((tf_kernel_bin_id+tf_builder_input_id+tf_parser_param_id)) s/^/$(echo " \
		\"(i,i,i,i),")\n/"                                                                                                  $dir_op_name/plugin/"$op_name"_tf_parser.cpp
        elif [ "$input_num" == "auto" ];then
            sed -i "$((tf_kernel_bin_id+tf_builder_input_id+tf_parser_param_id)) s/^/$(echo "\
		\"O, s, i, ")\n/"                                                                                                   $dir_op_name/plugin/"$op_name"_tf_parser.cpp
        elif [ "$input_num" == "autoAll" ];then
				    sed -i "$((tf_kernel_bin_id+tf_builder_input_id+tf_parser_param_id)) s/^/$(echo "\
  	\"O, s, ")\n/"                                                                                                      $dir_op_name/plugin/"$op_name"_tf_parser.cpp
        else
            sed -i "$((tf_kernel_bin_id+tf_builder_input_id+tf_parser_param_id)) s/^/$(echo "\
		\"(i,i,i,i), ")\n/"                                                                                                 $dir_op_name/plugin/"$op_name"_tf_parser.cpp
					for((i=1;i<"$input_num";i++));
					do 
						sed -i "/(i,i,i,i/ s/$/(i,i,i,i), /"                                                                        $dir_op_name/plugin/"$op_name"_tf_parser.cpp
					done
   
			  fi   

			# add dtype 4D
      if [ "$input_num" == "auto" ];then
          sed -i "/O, s/ s/$/s, /"                                                                                          $dir_op_name/plugin/"$op_name"_tf_parser.cpp
      elif [ "$input_num" == "autoAll" ];then
          sed -i "/O, s/ s/$/s, /"                                                                                          $dir_op_name/plugin/"$op_name"_tf_parser.cpp
      else
		      sed -i "/(i,i/ s/$/s, /"                                                                                          $dir_op_name/plugin/"$op_name"_tf_parser.cpp
      fi
            
		    
      # add the parameter type in kernel bin  4D
			for index in `seq 0 $param_length` # the updated length
			do
				param_1=`echo $param_list | jq -r ".[$index].param"`
				type_1=`echo $param_list | jq -r ".[$index].type"`
				if [ "$type_1" == "bool" ];then
            if [ "$input_num" == "auto" ];then
                sed -i "/O, s/ s/$/O, /"                                                                                  $dir_op_name/plugin/"$op_name"_tf_parser.cpp
            elif [ "$input_num" == "autoAll" ];then
                sed -i "/O, s/ s/$/O, /"                                                                                  $dir_op_name/plugin/"$op_name"_tf_parser.cpp
            else
		            sed -i "/(i,i/ s/$/O, /"                                                                                  $dir_op_name/plugin/"$op_name"_tf_parser.cpp
            fi
				elif [ "$type_1" == "string" ];then
            if [ "$input_num" == "auto" ];then
                sed -i "/O, s/ s/$/s, /"                                                                                  $dir_op_name/plugin/"$op_name"_tf_parser.cpp
            elif [ "$input_num" == "autoAll" ];then
                sed -i "/O, s/ s/$/s, /"                                                                                  $dir_op_name/plugin/"$op_name"_tf_parser.cpp
            else
		            sed -i "/(i,i/ s/$/s, /"                                                                                  $dir_op_name/plugin/"$op_name"_tf_parser.cpp
            fi            
				elif [ "$type_1" == "float" ];then
            if [ "$input_num" == "auto" ];then
                sed -i "/O, s/ s/$/f, /"                                                                                  $dir_op_name/plugin/"$op_name"_tf_parser.cpp
            elif [ "$input_num" == "autoAll" ];then
                sed -i "/O, s/ s/$/f, /"                                                                                  $dir_op_name/plugin/"$op_name"_tf_parser.cpp
            else
		            sed -i "/(i,i/ s/$/f, /"                                                                                  $dir_op_name/plugin/"$op_name"_tf_parser.cpp
            fi 
		            
				else
            if [ "$input_num" == "auto" ];then
                sed -i "/O, s/ s/$/i, /"                                                                                  $dir_op_name/plugin/"$op_name"_tf_parser.cpp
            elif [ "$input_num" == "autoAll" ];then
                sed -i "/O, s/ s/$/i, /"                                                                                  $dir_op_name/plugin/"$op_name"_tf_parser.cpp
            else
		            sed -i "/(i,i/ s/$/i, /"                                                                                  $dir_op_name/plugin/"$op_name"_tf_parser.cpp
            fi  
		            
        fi
    done
	      	# add kernel_name and need_build
    if [ "$input_num" == "auto" ];then
        sed -i "/O, s/ s/$/s,O\", /"                                                                                          $dir_op_name/plugin/"$op_name"_tf_parser.cpp
    elif [ "$input_num" == "autoAll" ];then
        sed -i "/O, s/ s/$/s,O\", /"                                                                                          $dir_op_name/plugin/"$op_name"_tf_parser.cpp
    else
		    sed -i "/(i,i/ s/$/s,O\", /"                                                                                          $dir_op_name/plugin/"$op_name"_tf_parser.cpp
    fi  
            
    if [ "$input_num" == "1" ];then
  	    sed -i "$(($tf_kernel_bin_id+$tf_builder_input_id+$tf_parser_param_id+1))  s/^/$(echo "\
		input_desc.GetShape().GetDim(0), input_desc.GetShape().GetDim(1), input_desc.GetShape().GetDim(2), input_desc.GetShape().GetDim(3),")\n/"  $dir_op_name/plugin/"$op_name"_tf_parser.cpp
        tf_kernel_bin_offset=2 # one input
		elif [ "$input_num" == "auto" ];then
			sed -i "$(($tf_kernel_bin_id+$tf_builder_input_id+$tf_parser_param_id+1))  s/^/$(echo "\
		pyShape,")\n/"                                                                                                                    $dir_op_name/plugin/"$op_name"_tf_parser.cpp
			sed -i "$(($tf_kernel_bin_id+$tf_builder_input_id+$tf_parser_param_id+2))  s/^/$(echo "\
		tensorNumber,")\n/"                                                                                                               $dir_op_name/plugin/"$op_name"_tf_parser.cpp
		    tf_kernel_bin_offset=3 
		elif [ "$input_num" == "autoAll" ];then
			sed -i "$(($tf_kernel_bin_id+$tf_builder_input_id+$tf_parser_param_id+1))  s/^/$(echo "\
		pyShapes,")\n/"                                                                                                                   $dir_op_name/plugin/"$op_name"_tf_parser.cpp
		else 
		  for((i=1;i<="$input_num";i++));
		  do
         if [ "$i" == 1 ];then
			       sed -i "$(($tf_kernel_bin_id+$tf_builder_input_id+$tf_parser_param_id+1))  s/^/$(echo "\
		input_desc.GetShape().GetDim("$((0))"), input_desc.GetShape().GetDim("$((1))"), input_desc.GetShape().GetDim("$((2))"), input_desc.GetShape().GetDim("$((3))"),")\n/"  $dir_op_name/plugin/"$op_name"_tf_parser.cpp
         else                                                      
             sed -i "$(($tf_kernel_bin_id+$tf_builder_input_id+$tf_parser_param_id+i))  s/^/$(echo "\
		input"$i"_desc.GetShape().GetDim("$((0))"), input"$i"_desc.GetShape().GetDim("$((1))"), input"$i"_desc.GetShape().GetDim("$((2))"), input"$i"_desc.GetShape().GetDim("$((3))"),")\n/" $dir_op_name/plugin/"$op_name"_tf_parser.cpp
          fi
      done 
         tf_kernel_bin_offset=$(($input_num+1))
      fi 
		fi
	fi

    # kernel bin parameter
    tf_kernel_bin_id=$(($tf_kernel_bin_id+$tf_kernel_bin_offset+1)) # integrated tf_kernel_bin_id
   
    for index in `seq 0 $param_length` # the updated length
    do
        param_1=`echo $param_list | jq -r ".[$index].param"`
        type_1=`echo $param_list | jq -r ".[$index].type"`
    
		if [ "$type_1" == "bool" ];then
		sed -i "$((tf_kernel_bin_id+tf_builder_input_id+tf_parser_param_id+index))   s/^/$(echo "\
        "$param_1" ? Py_True: Py_False,  ")\n/"                                                                               $dir_op_name/plugin/"$op_name"_tf_parser.cpp
        elif [ "$type_1" == "string" ];then
		sed -i "$((tf_kernel_bin_id+tf_builder_input_id+tf_parser_param_id+index))   s/^/$(echo "\
        "$param_1",  ")\n/"                                                                                                   $dir_op_name/plugin/"$op_name"_tf_parser.cpp
        elif [ "$type_1" == "float" ];then
		sed -i "$((tf_kernel_bin_id+tf_builder_input_id+tf_parser_param_id+index))   s/^/$(echo "\
        "$param_1",  ")\n/"                                                                                                   $dir_op_name/plugin/"$op_name"_tf_parser.cpp
        else
		sed -i "$((tf_kernel_bin_id+tf_builder_input_id+tf_parser_param_id+index))   s/^/$(echo "\
        "$param_1",  ")\n/"                                                                                                   $dir_op_name/plugin/"$op_name"_tf_parser.cpp
        fi
    done
    
    # add input interface
    . ./UpdateTfOperatorInterface.sh
    
    
