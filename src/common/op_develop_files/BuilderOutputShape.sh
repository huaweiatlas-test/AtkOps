#! /bin/bash

layer_param_bout_num=0 # xxxParameter parameter number of "Builder Output Shape"
# output shape calculation in the following
	if [ "$version" == "C30" ];then
    ol=0  # ol means output line num offset about "C++ call python" output shape
    optional_para_num=0
    repeated_para_num=0
    enum_para_num=0
    for optional_para_id in $optional_parameter
    do
        optional_para_num=$(($optional_para_num+1))
    done
    optional_para_num=$(($optional_para_num-$layer_param_po_num*1))
    
    for repeated_para_id in $repeated_parameter
    do
        repeated_para_num=$((repeated_para_num+1))
    done
    
    for enum_para_id in $enum_parameter
    do
        enum_para_num=$((enum_para_num+1))
    done
    
    output_shape_param_num=$((input_num+optional_para_num+repeated_para_num)) # notice that, enum param is part of optional param
    
    for((pyInputId=0;pyInputId<"$input_num";pyInputId++));
    do
        sed -i "$(($python_output_shape_offset_C30+poi+prid+boid+brid+pyInputId)) s/^/$(echo "\
     ge::TensorDesc input"$(($pyInputId+1))"_desc = op.GetInputDesc("$pyInputId");")\n/"                              $op_name/plugin/$op_name"_parser_C30.cpp"
    done
    #update the offset about "python_output_shape_offset_C30"
    python_output_shape_offset_C30=$((python_output_shape_offset_C30+input_num))
    
    sed -i "$(($python_output_shape_offset_C30+poi+prid+boid+brid)) s/^/$(echo "  \
   PyObject* args = PyTuple_New("$output_shape_param_num"); ")\n/"                                                    $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
    python_output_shape_offset_C30=$((python_output_shape_offset_C30+1))
    
    # add input
    for((pyId=0;pyId<"$input_num";pyId++));
    do
        sed -i "$(($python_output_shape_offset_C30+poi+prid+boid+brid+pyId*10)) s/^/$(echo "  \
   PyObject* iarg"$pyId" = PyTuple_New(4); ")\n/"                                                                     $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"     
        sed -i "$(($python_output_shape_offset_C30+poi+prid+boid+brid+pyId*10+1)) s/^/$(echo "  \
   PyObject* iarg"$pyId"1 = PyInt_FromLong(input"$(($pyId+1))"_desc.GetShape().GetDim("0")); ")\n/"                   $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
        sed -i "$(($python_output_shape_offset_C30+poi+prid+boid+brid+pyId*10+2)) s/^/$(echo "  \
   PyObject* iarg"$pyId"2 = PyInt_FromLong(input"$(($pyId+1))"_desc.GetShape().GetDim("1")); ")\n/"                   $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
        sed -i "$(($python_output_shape_offset_C30+poi+prid+boid+brid+pyId*10+3)) s/^/$(echo "  \
   PyObject* iarg"$pyId"3 = PyInt_FromLong(input"$(($pyId+1))"_desc.GetShape().GetDim("2")); ")\n/"                   $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
        sed -i "$(($python_output_shape_offset_C30+poi+prid+boid+brid+pyId*10+4)) s/^/$(echo "  \
   PyObject* iarg"$pyId"4 = PyInt_FromLong(input"$(($pyId+1))"_desc.GetShape().GetDim("3")); ")\n/"                   $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
      
        sed -i "$(($python_output_shape_offset_C30+poi+prid+boid+brid+pyId*10+5)) s/^/$(echo "  \
   PyTuple_SetItem(iarg"$pyId", 0, iarg"$pyId"1);  ")\n/"                                                             $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
        sed -i "$(($python_output_shape_offset_C30+poi+prid+boid+brid+pyId*10+6)) s/^/$(echo "  \
   PyTuple_SetItem(iarg"$pyId", 1, iarg"$pyId"2);  ")\n/"                                                             $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
        sed -i "$(($python_output_shape_offset_C30+poi+prid+boid+brid+pyId*10+7)) s/^/$(echo "  \
   PyTuple_SetItem(iarg"$pyId", 2, iarg"$pyId"3);  ")\n/"                                                             $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
        sed -i "$(($python_output_shape_offset_C30+poi+prid+boid+brid+pyId*10+8)) s/^/$(echo "  \
   PyTuple_SetItem(iarg"$pyId", 3, iarg"$pyId"4);  ")\n/"                                                             $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
      
      sed -i "$(($python_output_shape_offset_C30+poi+prid+boid+brid+pyId*10+9)) s/^/$(echo "  \
   PyTuple_SetItem(args, "$pyId", iarg"$pyId"); ")\n/"                                                                $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
    done

    if [ "$optional_para_num" > 0 ];then 
	    # add optional parameters
	    id_b_py=0
	    id_r_py=0
	    op_py_offset=0
	    for ID_B_PY in $optional_parameter
	    do
	        id_r_py=0
	        for ID_R_PY in $optional_type_parameter
		      do 
		          if [ $id_b_py == $id_r_py ];then
			            if [ "$ID_R_PY" == "bool" ];then
			                sed -i "$(($python_output_shape_offset_C30+poi+prid+boid+brid+input_num*10+op_py_offset*2)) s/^/$(echo "  \
   PyObject* arg"$((input_num+op_py_offset))" = Py_BuildValue(\"b\", "$ID_B_PY"); ")\n/"                                                            $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
                      sed -i "$(($python_output_shape_offset_C30+poi+prid+boid+brid+input_num*10+op_py_offset*2+1)) s/^/$(echo "  \
   PyTuple_SetItem(args, "$((input_num+op_py_offset))", arg"$((input_num+op_py_offset))"); ")\n/"                                                   $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
			                op_py_offset=$(($op_py_offset+1))
                  elif [ "$ID_R_PY" == "float" ];then
			                sed -i "$(($python_output_shape_offset_C30+poi+prid+boid+brid+input_num*10+op_py_offset*2)) s/^/$(echo "  \
   PyObject* arg"$((input_num+op_py_offset))" = Py_BuildValue(\"f\", "$ID_B_PY"); ")\n/"                                                            $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
                      sed -i "$(($python_output_shape_offset_C30+poi+prid+boid+brid+input_num*10+op_py_offset*2+1)) s/^/$(echo "  \
   PyTuple_SetItem(args, "$((input_num+op_py_offset))", arg"$((input_num+op_py_offset))"); ")\n/"                                                   $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
			                op_py_offset=$(($op_py_offset+1))
			            elif [ "$ID_R_PY" == "string" ];then
			                sed -i "$(($python_output_shape_offset_C30+poi+prid+boid+brid+input_num*10+op_py_offset*2)) s/^/$(echo "  \
   PyObject* arg"$((input_num+op_py_offset))" = Py_BuildValue(\"s\", "$ID_B_PY".c_str()); ")\n/"                                                    $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
                      sed -i "$(($python_output_shape_offset_C30+poi+prid+boid+brid+input_num*10+op_py_offset*2+1)) s/^/$(echo "  \
   PyTuple_SetItem(args, "$((input_num+op_py_offset))", arg"$((input_num+op_py_offset))"); ")\n/"                                                   $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
			                op_py_offset=$(($op_py_offset+1))
			            elif [[ "$ID_R_PY" == "int32" ]]||[[ "$ID_R_PY" == "uint32" ]]||[[ "$ID_R_PY" == "int64" ]]||[[ "$ID_R_PY" == "uint64" ]]||[[ "$ID_R_PY" == "int" ]];then
			                sed -i "$(($python_output_shape_offset_C30+poi+prid+boid+brid+input_num*10+op_py_offset*2)) s/^/$(echo "  \
   PyObject* arg"$((input_num+op_py_offset))" = Py_BuildValue(\"i\", "$ID_B_PY"); ")\n/"                                                            $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
                      sed -i "$(($python_output_shape_offset_C30+poi+prid+boid+brid+input_num*10+op_py_offset*2+1)) s/^/$(echo "  \
   PyTuple_SetItem(args, "$((input_num+op_py_offset))", arg"$((input_num+op_py_offset))"); ")\n/"                                                   $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
			                op_py_offset=$(($op_py_offset+1))
                  else 
                      layer_param_bout_num=$(($layer_param_bout_num+1))
			            fi
              fi
              id_r_py=$(($id_r_py+1))    
          done
          id_b_py=$(($id_b_py+1))
      done
    fi
    
    # add repeated parameters
    if [ "$repeated_para_num" > 0 ];then
        op_num=$(($optional_para_num*2)) # optional parameters offsets
        op_num=$(($op_num-$layer_param_bout_num*2))
        py_param_reid=0 # repeated id for python params
        py_dtype_reid=0
        op_re_offset=0
        for ID_RE_PY in $repeated_parameter
        do
            py_dtype_reid=0
            for ID_RE_PY_TYPE in $repeated_type_parameter
            do
                if [ $py_param_reid == $py_dtype_reid ];then
                    if [ "$ID_RE_PY_TYPE" == "float" ];then
                        sed -i "$(($python_output_shape_offset_C30+poi+prid+boid+brid+input_num*10+6*op_re_offset+op_num)) s/^/$(echo "  \
   PyObject \*py_"$ID_RE_PY" = PyTuple_New("$ID_RE_PY".size()); ")\n/" $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
                        sed -i "$(($python_output_shape_offset_C30+poi+prid+boid+brid+input_num*10+6*op_re_offset+op_num+1)) s/^/$(echo "  \
   for(int i = 0; i< "$ID_RE_PY".size(); i++) ")\n/"                                                    $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
                        sed -i "$(($python_output_shape_offset_C30+poi+prid+boid+brid+input_num*10+op_num+6*op_re_offset+2)) s/^/$(echo "  \
   { ")\n/"                                                            $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
                        sed -i "$(($python_output_shape_offset_C30+poi+prid+boid+brid+input_num*10+op_num+6*op_re_offset+3)) s/^/$(echo "  \
       PyTuple_SetItem(py_"$ID_RE_PY", i, Py_BuildValue(\"f\", "$ID_RE_PY"[i])); ")\n/"                $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
                        sed -i "$(($python_output_shape_offset_C30+poi+prid+boid+brid+input_num*10+op_num+6*op_re_offset+4)) s/^/$(echo "  \
   } ")\n/"                                                            $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
                        sed -i "$(($python_output_shape_offset_C30+poi+prid+boid+brid+input_num*10+op_num+6*op_re_offset+5)) s/^/$(echo "  \
   PyTuple_SetItem(args, "$(($input_num+optional_para_num+op_re_offset))", py_"$ID_RE_PY"); ")\n/"     $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
                        op_re_offset=$(($op_re_offset+1))
                    elif [ "$ID_RE_PY_TYPE" == "string" ];then
                        sed -i "$(($python_output_shape_offset_C30+poi+prid+boid+brid+input_num*10+op_num+6*op_re_offset)) s/^/$(echo "  \
   PyObject \*py_"$ID_RE_PY" = PyTuple_New("$ID_RE_PY".size()); ")\n/"  $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
                        sed -i "$(($python_output_shape_offset_C30+poi+prid+boid+brid+input_num*10+op_num+6*op_re_offset+1)) s/^/$(echo "  \
   for(int i = 0; i< "$ID_RE_PY".size(); i++) ")\n/"                    $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
                        sed -i "$(($python_output_shape_offset_C30+poi+prid+boid+brid+input_num*10+op_num+6*op_re_offset+2)) s/^/$(echo "  \
   { ")\n/"                                                            $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
                        sed -i "$(($python_output_shape_offset_C30+poi+prid+boid+brid+input_num*10+op_num+6*op_re_offset+3)) s/^/$(echo "  \
       PyTuple_SetItem(py_"$ID_RE_PY", i, Py_BuildValue(\"s\", "$ID_RE_PY"[i])); ")\n/"                $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
                        sed -i "$(($python_output_shape_offset_C30+poi+prid+boid+brid+input_num*10+op_num+6*op_re_offset+4)) s/^/$(echo "  \
   } ")\n/"                                                            $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
                        sed -i "$(($python_output_shape_offset_C30+poi+prid+boid+brid+input_num*10+op_num+6*op_re_offset+5)) s/^/$(echo "  \
   PyTuple_SetItem(args, "$(($input_num+optional_para_num+op_re_offset))", py_"$ID_RE_PY"); ")\n/"     $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
                        op_re_offset=$(($op_re_offset+1))
                    elif [[ "$ID_RE_PY_TYPE" == "int32" ]]||[[ "$ID_RE_PY_TYPE" == "uint32" ]]||[[ "$ID_RE_PY_TYPEe" == "int64" ]]\
                    ||[[ "$ID_RE_PY_TYPE" == "uint64" ]]||[[ "$ID_RE_PY_TYPE" == "int" ]]||[[ "$ID_RE_PY_TYPE" == "bool" ]];then
                        sed -i "$(($python_output_shape_offset_C30+poi+prid+boid+brid+input_num*10+op_num+6*op_re_offset)) s/^/$(echo "  \
   PyObject \*py_"$ID_RE_PY" = PyTuple_New("$ID_RE_PY".size()); ")\n/" $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
                        sed -i "$(($python_output_shape_offset_C30+poi+prid+boid+brid+input_num*10+op_num+6*op_re_offset+1)) s/^/$(echo "  \
   for(int i = 0; i< "$ID_RE_PY".size(); i++) ")\n/"                   $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
                        sed -i "$(($python_output_shape_offset_C30+poi+prid+boid+brid+input_num*10+op_num+6*op_re_offset+2)) s/^/$(echo "  \
   { ")\n/"                                                            $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
                        sed -i "$(($python_output_shape_offset_C30+poi+prid+boid+brid+input_num*10+op_num+6*op_re_offset+3)) s/^/$(echo "  \
       PyTuple_SetItem(py_"$ID_RE_PY", i, Py_BuildValue(\"i\", "$ID_RE_PY"[i])); ")\n/"                $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
                        sed -i "$(($python_output_shape_offset_C30+poi+prid+boid+brid+input_num*10+op_num+6*op_re_offset+4)) s/^/$(echo "  \
   } ")\n/"                                                            $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
                        sed -i "$(($python_output_shape_offset_C30+poi+prid+boid+brid+input_num*10+op_num+6*op_re_offset+5)) s/^/$(echo "  \
   PyTuple_SetItem(args, "$(($input_num+optional_para_num+op_re_offset))", py_"$ID_RE_PY"); ")\n/"     $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
                        op_re_offset=$(($op_re_offset+1))
                    fi                    
                fi
                py_dtype_reid=$(($py_dtype_reid+1))
            done
            py_param_reid=$(($py_param_reid+1))
        done
    else
        poi=$(($poi-$layer_param_bout_num*2))  # xxxParameter for optional parameters.
    fi
	    
    sed -i "$(($python_output_shape_offset_C30+poi+prid+boid+brid+input_num*10+2*optional_para_num+6*repeated_para_num)) s/^/$(echo "  \
   PyObject* pRet = PyObject_CallObject(pv, args); ")\n/"                                               $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
   
   ol=$(($ol+11*$input_num+2*$optional_para_num+6*$repeated_para_num+2))
	fi


  
