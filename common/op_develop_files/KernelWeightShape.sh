layer_param_kweight_num=0 # xxxParameter parameter number of "Builder Output Shape"
if [ "$version" == "C30" ];then
    weight_shape_offset=py_build_offset_C30+poi+prid+boid+brid+koid+krid+iid+ol
    weight_shape_offset=$(($weight_shape_offset-2)) # set the propor place
    # ol means output line num offset about "C++ call python" output shape
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
    
    sed -i "$(($weight_shape_offset-1))   s/^/$(echo "\
    \/\/ ********************* C++ Call Python Weight ********************  ")\n/"              $op_name/plugin/$op_name"_parser_C30.cpp"
    sed -i "$(($weight_shape_offset))   s/^/$(echo "\
    Py_Initialize();  ")\n/"                                                                    $op_name/plugin/$op_name"_parser_C30.cpp"
    sed -i "$(($weight_shape_offset+1))   s/^/$(echo "\
    string chdir_cmd = string(\"sys.path.append('.\/..\/operator')\");  ")\n/"                  $op_name/plugin/$op_name"_parser_C30.cpp"
    sed -i "$(($weight_shape_offset+2))   s/^/$(echo "\
    const char* cstr_cmd = chdir_cmd.c_str();  ")\n/"                                           $op_name/plugin/$op_name"_parser_C30.cpp"
    sed -i "$(($weight_shape_offset+3))   s/^/$(echo "\
    PyRun_SimpleString(\"import sys\");   ")\n/"                                                $op_name/plugin/$op_name"_parser_C30.cpp"
    sed -i "$(($weight_shape_offset+4))   s/^/$(echo "\
    PyRun_SimpleString(cstr_cmd);  ")\n/"                                                       $op_name/plugin/$op_name"_parser_C30.cpp"
    sed -i "$(($weight_shape_offset+5))   s/^/$(echo "\
    PyObject* moduleName = PyString_FromString(\""$op_name"OutputWeightShape\");  ")\n/"        $op_name/plugin/$op_name"_parser_C30.cpp"   
    sed -i "$(($weight_shape_offset+6))   s/^/$(echo "\
    PyObject* pModule = PyImport_Import(moduleName);  ")\n/"                                    $op_name/plugin/$op_name"_parser_C30.cpp"   
    sed -i "$(($weight_shape_offset+7))   s/^/$(echo "\
    if (!pModule)  ")\n/"                                                                       $op_name/plugin/$op_name"_parser_C30.cpp"
    sed -i "$(($weight_shape_offset+8))   s/^/$(echo "\
    {  ")\n/"                                                                                   $op_name/plugin/$op_name"_parser_C30.cpp"
    sed -i "$(($weight_shape_offset+9))   s/^/$(echo "\
        printf( \"[ERROR] Python get module failed.\");  ")\n/"                                 $op_name/plugin/$op_name"_parser_C30.cpp"
    sed -i "$(($weight_shape_offset+10))   s/^/$(echo "\
        return 0;  ")\n/"                                                                       $op_name/plugin/$op_name"_parser_C30.cpp"
    sed -i "$(($weight_shape_offset+11))   s/^/$(echo "\
    }  ")\n/"                                                                                   $op_name/plugin/$op_name"_parser_C30.cpp"
    sed -i "$(($weight_shape_offset+12))   s/^/$(echo "\
    printf(\"[INFO] Python get module succeed.\");  ")\n/"                                      $op_name/plugin/$op_name"_parser_C30.cpp"   
    ol=$(($ol+13))
    
    # set the weight function
    for((weightN=0;weightN<"$weight_num";weightN++));
    do
        sed -i "$(($weight_shape_offset+$weightN*7+13))   s/^/$(echo "\
    PyObject* pv"$(($weightN+1))" = PyObject_GetAttrString(pModule, \"Weight"$(($weightN+1))"Shape"$op_name"\");   ")\n/"   $op_name/plugin/$op_name"_parser_C30.cpp" 
        sed -i "$(($weight_shape_offset+$weightN*7+14))   s/^/$(echo "\
    if (!pv"$(($weightN+1))" || !PyCallable_Check(pv"$(($weightN+1))"))  ")\n/"                                             $op_name/plugin/$op_name"_parser_C30.cpp" 
        sed -i "$(($weight_shape_offset+$weightN*7+15))   s/^/$(echo "\
    {  ")\n/"                                                                                     $op_name/plugin/$op_name"_parser_C30.cpp" 
        sed -i "$(($weight_shape_offset+$weightN*7+16))   s/^/$(echo "\
        printf(\"\[ERROR\] Can\'t find function Weight"$(($weightN+1))"Shape"$op_name"\");  ")\n/"                          $op_name/plugin/$op_name"_parser_C30.cpp" 
        sed -i "$(($weight_shape_offset+$weightN*7+17))   s/^/$(echo "\
        return 0;  ")\n/"                                                                        $op_name/plugin/$op_name"_parser_C30.cpp" 
        sed -i "$(($weight_shape_offset+$weightN*7+18))   s/^/$(echo "\
    }  ")\n/"                                                                                    $op_name/plugin/$op_name"_parser_C30.cpp" 
        sed -i "$(($weight_shape_offset+$weightN*7+19))   s/^/$(echo "\
    printf(\"\[INFO\] Get function Weight"$(($weightN+1))"Shape"$op_name" succeed.\");  ")\n/"   $op_name/plugin/$op_name"_parser_C30.cpp"    
    done
    
    ol=$(($ol+$weight_num*7))
    
    sed -i "$(($weight_shape_offset+$weight_num*7+13))   s/^/$(echo "\
    PyObject* args = PyTuple_New("$output_shape_param_num");  ")\n/"                             $op_name/plugin/$op_name"_parser_C30.cpp" 
    ol=$(($ol+1))
    
    # add input
    for((pyId=0;pyId<"$input_num";pyId++));
    do
        sed -i "$(($weight_shape_offset+$weight_num*7+pyId*10+14)) s/^/$(echo "  \
    PyObject* warg"$pyId" = PyTuple_New(4); ")\n/"                                                                     $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"     
        sed -i "$(($weight_shape_offset+$weight_num*7+pyId*10+15)) s/^/$(echo "  \
    PyObject* warg"$pyId"1 = PyInt_FromLong(input"$(($pyId+1))"_desc.GetShape().GetDim("$pyId")); ")\n/"               $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
        sed -i "$(($weight_shape_offset+$weight_num*7+pyId*10+16)) s/^/$(echo "  \
    PyObject* warg"$pyId"2 = PyInt_FromLong(input"$(($pyId+1))"_desc.GetShape().GetDim("$(($pyId+1))")); ")\n/"        $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
        sed -i "$(($weight_shape_offset+$weight_num*7+pyId*10+17)) s/^/$(echo "  \
    PyObject* warg"$pyId"3 = PyInt_FromLong(input"$(($pyId+1))"_desc.GetShape().GetDim("$(($pyId+2))")); ")\n/"        $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
        sed -i "$(($weight_shape_offset+$weight_num*7+pyId*10+18)) s/^/$(echo "  \
    PyObject* warg"$pyId"4 = PyInt_FromLong(input"$(($pyId+1))"_desc.GetShape().GetDim("$(($pyId+3))")); ")\n/"        $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
      
        sed -i "$(($weight_shape_offset+$weight_num*7+pyId*10+19)) s/^/$(echo "  \
    PyTuple_SetItem(warg"$pyId", 0, warg"$pyId"1);  ")\n/"                                                             $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
        sed -i "$(($weight_shape_offset+$weight_num*7+pyId*10+20)) s/^/$(echo "  \
    PyTuple_SetItem(warg"$pyId", 1, warg"$pyId"2);  ")\n/"                                                             $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
        sed -i "$(($weight_shape_offset+$weight_num*7+pyId*10+21)) s/^/$(echo "  \
    PyTuple_SetItem(warg"$pyId", 2, warg"$pyId"3);  ")\n/"                                                             $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
        sed -i "$(($weight_shape_offset+$weight_num*7+pyId*10+22)) s/^/$(echo "  \
    PyTuple_SetItem(warg"$pyId", 3, warg"$pyId"4);  ")\n/"                                                             $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
      
        sed -i "$(($weight_shape_offset+$weight_num*7+pyId*10+23)) s/^/$(echo "  \
    PyTuple_SetItem(args, "$pyId", warg"$pyId"); ")\n/"                                                                $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
    done
    ol=$(($ol+$input_num*10))

    
    if [ "$optional_para_num" -gt 0 ];then 
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
			                sed -i "$(($weight_shape_offset+$weight_num*7+input_num*10+op_py_offset*2+14)) s/^/$(echo "  \
    PyObject* arg"$((input_num+op_py_offset))" = Py_BuildValue(\"i\", "$ID_B_PY"); ")\n/"                            $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
                      sed -i "$(($weight_shape_offset+$weight_num*7+input_num*10+op_py_offset*2+15)) s/^/$(echo "  \
    PyTuple_SetItem(args, "$((input_num+op_py_offset))", arg"$((input_num+op_py_offset))"); ")\n/"                   $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
			                op_py_offset=$(($op_py_offset+1))
                  elif [ "$ID_R_PY" == "float" ];then
			                sed -i "$(($weight_shape_offset+$weight_num*7+input_num*10+op_py_offset*2+14)) s/^/$(echo "  \
    PyObject* arg"$((input_num+op_py_offset))" = Py_BuildValue(\"f\", "$ID_B_PY"); ")\n/"                            $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
                      sed -i "$(($weight_shape_offset+$weight_num*7+input_num*10+op_py_offset*2+15)) s/^/$(echo "  \
    PyTuple_SetItem(args, "$((input_num+op_py_offset))", arg"$((input_num+op_py_offset))"); ")\n/"                   $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
			                op_py_offset=$(($op_py_offset+1))
			            elif [ "$ID_R_PY" == "string" ];then
			                sed -i "$(($weight_shape_offset+$weight_num*7+input_num*10+op_py_offset*2+14)) s/^/$(echo "  \
    PyObject* arg"$((input_num+op_py_offset))" = Py_BuildValue(\"s\", "$ID_B_PY".c_str()); ")\n/"                    $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
                      sed -i "$(($weight_shape_offset+$weight_num*7+input_num*10+op_py_offset*2+15)) s/^/$(echo "  \
    PyTuple_SetItem(args, "$((input_num+op_py_offset))", arg"$((input_num+op_py_offset))"); ")\n/"                   $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
			                op_py_offset=$(($op_py_offset+1))
			            elif [[ "$ID_R_PY" == "int32" ]]||[[ "$ID_R_PY" == "uint32" ]]||[[ "$ID_R_PY" == "int64" ]]||[[ "$ID_R_PY" == "uint64" ]]||[[ "$ID_R_PY" == "int" ]];then
			                sed -i "$(($weight_shape_offset+$weight_num*7+input_num*10+op_py_offset*2+14)) s/^/$(echo "  \
    PyObject* arg"$((input_num+op_py_offset))" = Py_BuildValue(\"i\", "$ID_B_PY"); ")\n/"                            $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
                      sed -i "$(($weight_shape_offset+$weight_num*7+input_num*10+op_py_offset*2+15)) s/^/$(echo "  \
    PyTuple_SetItem(args, "$((input_num+op_py_offset))", arg"$((input_num+op_py_offset))"); ")\n/"                   $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
			                op_py_offset=$(($op_py_offset+1))
                  else
                      layer_param_kweight_num=$((layer_param_kweight_num+1))                                                     
			            fi
              fi
              id_r_py=$(($id_r_py+1))    
          done
          id_b_py=$(($id_b_py+1))
      done
      ol=$(($ol+2*$optional_para_num))
    fi
    
    
    # add repeated parameters
    if [ "$repeated_para_num" -gt 0 ];then
        op_num=$(($optional_para_num*2))
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
                        sed -i "$(($weight_shape_offset+$weight_num*7+input_num*10+6*op_re_offset+op_num+14)) s/^/$(echo "  \
    PyObject \*py_weight_"$ID_RE_PY" = PyTuple_New("$ID_RE_PY".size()); ")\n/"                                          $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
                        sed -i "$(($weight_shape_offset+$weight_num*7+input_num*10+6*op_re_offset+op_num+15)) s/^/$(echo "  \
      for(int i = 0; i< "$ID_RE_PY".size(); i++) ")\n/"                                                                 $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
                        sed -i "$(($weight_shape_offset+$weight_num*7+input_num*10+6*op_re_offset+op_num+16)) s/^/$(echo "  \
    { ")\n/"                                                                                                            $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
                        sed -i "$(($weight_shape_offset+$weight_num*7+input_num*10+6*op_re_offset+op_num+17)) s/^/$(echo "  \
      PyTuple_SetItem(py_weight_"$ID_RE_PY", i, Py_BuildValue(\"f\", "$ID_RE_PY"[i])); ")\n/"                           $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
                        sed -i "$(($weight_shape_offset+$weight_num*7+input_num*10+6*op_re_offset+op_num+18)) s/^/$(echo "  \
    } ")\n/"                                                                                                            $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
                        sed -i "$(($weight_shape_offset+$weight_num*7+input_num*10+6*op_re_offset+op_num+19)) s/^/$(echo "  \
    PyTuple_SetItem(args, "$(($input_num+optional_para_num+op_re_offset))", py_weight_"$ID_RE_PY"); ")\n/"              $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
                        op_re_offset=$(($op_re_offset+1))
                    elif [ "$ID_RE_PY_TYPE" == "string" ];then
                        sed -i "$(($weight_shape_offset+$weight_num*7+input_num*10+6*op_re_offset+op_num+14)) s/^/$(echo "  \
    PyObject \*py_weight_"$ID_RE_PY" = PyTuple_New("$ID_RE_PY".size()); ")\n/"                                          $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
                        sed -i "$(($weight_shape_offset+$weight_num*7+input_num*10+6*op_re_offset+op_num+15)) s/^/$(echo "  \
      for(int i = 0; i< "$ID_RE_PY".size(); i++) ")\n/"                                                                 $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
                        sed -i "$(($weight_shape_offset+$weight_num*7+input_num*10+6*op_re_offset+op_num+16)) s/^/$(echo "  \
    { ")\n/"                                                                                                            $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
                        sed -i "$(($weight_shape_offset+$weight_num*7+input_num*10+6*op_re_offset+op_num+17)) s/^/$(echo "  \
      PyTuple_SetItem(py_weight_"$ID_RE_PY", i, Py_BuildValue(\"s\", "$ID_RE_PY"[i])); ")\n/"                           $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
                        sed -i "$(($weight_shape_offset+$weight_num*7+input_num*10+6*op_re_offset+op_num+18)) s/^/$(echo "  \
    } ")\n/"                                                                                                            $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
                        sed -i "$(($weight_shape_offset+$weight_num*7+input_num*10+6*op_re_offset+op_num+19)) s/^/$(echo "  \
    PyTuple_SetItem(args, "$(($input_num+optional_para_num+op_re_offset))", py_weight_"$ID_RE_PY"); ")\n/"              $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
                        op_re_offset=$(($op_re_offset+1))
                    elif [ "$ID_RE_PY_TYPE" == "bool" ];then
                        sed -i "$(($weight_shape_offset+$weight_num*7+input_num*10+6*op_re_offset+op_num+14)) s/^/$(echo "  \
    PyObject \*py_weight_"$ID_RE_PY" = PyTuple_New("$ID_RE_PY".size()); ")\n/"                                          $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
                        sed -i "$(($weight_shape_offset+$weight_num*7+input_num*10+6*op_re_offset+op_num+15)) s/^/$(echo "  \
      for(int i = 0; i< "$ID_RE_PY".size(); i++) ")\n/"                                                                 $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
                        sed -i "$(($weight_shape_offset+$weight_num*7+input_num*10+6*op_re_offset+op_num+16)) s/^/$(echo "  \
    { ")\n/"                                                                                                            $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
                        sed -i "$(($weight_shape_offset+$weight_num*7+input_num*10+6*op_re_offset+op_num+17)) s/^/$(echo "  \
      PyTuple_SetItem(py_weight_"$ID_RE_PY", i, Py_BuildValue(\"b\", "$ID_RE_PY"[i])); ")\n/"                           $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
                        sed -i "$(($weight_shape_offset+$weight_num*7+input_num*10+6*op_re_offset+op_num+18)) s/^/$(echo "  \
    } ")\n/"                                                                                                            $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
                        sed -i "$(($weight_shape_offset+$weight_num*7+input_num*10+6*op_re_offset+op_num+19)) s/^/$(echo "  \
    PyTuple_SetItem(args, "$(($input_num+optional_para_num+op_re_offset))", py_weight_"$ID_RE_PY"); ")\n/"              $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
                        op_re_offset=$(($op_re_offset+1))
                    elif [[ "$ID_RE_PY_TYPE" == "int32" ]]||[[ "$ID_RE_PY_TYPE" == "uint32" ]]||[[ "$ID_RE_PY_TYPEe" == "int64" ]]\
                    ||[[ "$ID_RE_PY_TYPE" == "uint64" ]]||[[ "$ID_RE_PY_TYPE" == "int" ]];then
                        sed -i "$(($weight_shape_offset+$weight_num*7+input_num*10+6*op_re_offset+op_num+14)) s/^/$(echo "  \
    PyObject \*py_weight_"$ID_RE_PY" = PyTuple_New("$ID_RE_PY".size()); ")\n/"                                          $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
                        sed -i "$(($weight_shape_offset+$weight_num*7+input_num*10+6*op_re_offset+op_num+15)) s/^/$(echo "  \
      for(int i = 0; i< "$ID_RE_PY".size(); i++) ")\n/"                                                                 $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
                        sed -i "$(($weight_shape_offset+$weight_num*7+input_num*10+6*op_re_offset+op_num+16)) s/^/$(echo "  \
    { ")\n/"                                                                                                            $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
                        sed -i "$(($weight_shape_offset+$weight_num*7+input_num*10+6*op_re_offset+op_num+17)) s/^/$(echo "  \
      PyTuple_SetItem(py_weight_"$ID_RE_PY", i, Py_BuildValue(\"i\", "$ID_RE_PY"[i])); ")\n/"                           $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
                        sed -i "$(($weight_shape_offset+$weight_num*7+input_num*10+6*op_re_offset+op_num+18)) s/^/$(echo "  \
    } ")\n/"                                                                                                            $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
                        sed -i "$(($weight_shape_offset+$weight_num*7+input_num*10+6*op_re_offset+op_num+19)) s/^/$(echo "  \
    PyTuple_SetItem(args, "$(($input_num+optional_para_num+op_re_offset))", py_weight_"$ID_RE_PY"); ")\n/"              $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
                        op_re_offset=$(($op_re_offset+1))
                    fi                    
                fi
                py_dtype_reid=$(($py_dtype_reid+1))
            done
            py_param_reid=$(($py_param_reid+1))
        done
        ol=$(($ol+6*$repeated_para_num))
        ol=$(($ol-$layer_param_kweight_num*2))
    else
        op_num=$(($optional_para_num*2))
    fi
    
    # add weight output shape
    for((weightNP=0;weightNP<"$weight_num";weightNP++));
    do  
        weight_params=`cat $cur_path/config.json | jq '.weight_num_param'`;
        weightNum=`echo $weight_params | jq -r ".[0].weight_"$(($weightNP+1))""`
       
        
        sed -i "$(($weight_shape_offset+$weight_num*7+input_num*10+6*repeated_para_num+op_num+6*weightNP+14)) s/^/$(echo "  \
    PyObject* wRet"$(($weightNP+1))" = PyObject_CallObject(pv"$(($weightNP+1))", args); ")\n/"                   $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
        
        if [ "$weightNum" -gt 0 ];then
            for((resId=0;resId<"$weightNum";resId++));
            do
                if [[ "$resId" == 0 ]] && [[ "$weightNum" == 1 ]];then
                    sed -i "$(($weight_shape_offset+$weight_num*7+input_num*10+6*repeated_para_num+op_num+6*weightNP+15)) s/^/$(echo "  \
  long resW"$(($weightNP+1))"_0; ")\n/"                                                                          $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
                elif [[ "$resId" == 0 ]] && [[ "$weightNum" -gt 1 ]];then
                    sed -i "$(($weight_shape_offset+$weight_num*7+input_num*10+6*repeated_para_num+op_num+6*weightNP+15)) s/^/$(echo "  \
  long resW"$(($weightNP+1))"_0, ")\n/"                                                                          $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
                elif [ "$resId" -lt "$((weightNum-1))" ];then
                     sed -i "/long resW"$(($weightNP+1))"_0/s/$/resW"$(($weightNP+1))"_"$resId", /"              $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
                elif [ "$resId" -eq "$((weightNum-1))" ];then
                    sed -i "/long resW"$(($weightNP+1))"_0/s/$/resW"$(($weightNP+1))"_"$resId"; /"               $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
                fi
            done
        fi
        
        
        sed -i "$(($weight_shape_offset+$weight_num*7+input_num*10+6*repeated_para_num+op_num+6*weightNP+16)) s/^/$(echo "  \
  if (wRet"$(($weightNP+1))") ")\n/"                                                                             $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
        sed -i "$(($weight_shape_offset+$weight_num*7+input_num*10+6*repeated_para_num+op_num+6*weightNP+17)) s/^/$(echo "  \
  { ")\n/"                                                                                                       $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
        sed -i "$(($weight_shape_offset+$weight_num*7+input_num*10+6*repeated_para_num+op_num+6*weightNP+18)) s/^/$(echo "  \
      PyArg_ParseTuple(wRet"$(($weightNP+1))", \"")\n/"                                                          $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
      
        for((resId=0;resId<"$weightNum";resId++));
        do
            sed -i "/PyArg_ParseTuple(wRet"$(($weightNP+1))"/s/$/l/"                                             $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
        done
        sed -i "/PyArg_ParseTuple(wRet"$(($weightNP+1))"/s/$/\", /"                                              $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
      
        for((resId=0;resId<"$weightNum";resId++));
        do
            if [ "$resId" -lt "$((weightNum-1))" ];then
                sed -i "/PyArg_ParseTuple(wRet"$(($weightNP+1))"/s/$/\&resW"$(($weightNP+1))"_"$resId", /"         $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
            elif [ "$resId" -eq "$((weightNum-1))" ];then
                sed -i "/PyArg_ParseTuple(wRet"$(($weightNP+1))"/s/$/\&resW"$(($weightNP+1))"_"$resId"); /"        $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
            fi
        done
        
        sed -i "$(($weight_shape_offset+$weight_num*7+input_num*10+6*repeated_para_num+op_num+6*weightNP+19)) s/^/$(echo "  \
  } ")\n/"                                                                                                       $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
    done
    ol=$(($ol+6*$weight_num))
   
    sed -i "$(($weight_shape_offset+$weight_num*7+input_num*10+6*repeated_para_num+op_num+6*weight_num+14))   s/^/$(echo "\
    \/\/ ********************* C++ Call Python Weight End********************  ")\n/"                            $op_name/plugin/$op_name"_parser_C30.cpp" 
    ol=$(($ol+1))
fi
