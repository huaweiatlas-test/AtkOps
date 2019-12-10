#! /bin/bash

# call the operator start!
	# Build TE Custom Op
  layer_param_kc_num=0 # xxxParameter parameter number of "kernel call"
	if [ "$version" == "C30" ];then
		   if [ "$input_num" == "2" ];then
					if [ "$IO_5D" == "True" ];then
				sed -i "$((py_build_offset_C30+poi+prid+boid+brid+koid+krid+iid+ol)) s/^/$(echo "\
  te::BuildTeCustomOp(te_bin_info.ddk_version, op.GetName(), RealFilePath, FuncName,")\n/"                                        $dir_op_name/plugin/$op_name"_parser_C30.cpp"
		sed -i "$(($py_build_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$iid+$ol+1)) s/^/$(echo "\
		\"(i,i,i,i,i),(i,i,i,i,i),")\n/" $op_name/plugin/$op_name"_parser_C30.cpp"
					else
				sed -i "$((py_build_offset_C30+poi+prid+boid+brid+koid+krid+iid+ol)) s/^/$(echo "\
  te::BuildTeCustomOp(te_bin_info.ddk_version, op.GetName(), RealFilePath, FuncName,")\n/"                                        $dir_op_name/plugin/$op_name"_parser_C30.cpp"
		sed -i "$(($py_build_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$iid+$ol+1)) s/^/$(echo "\
		\"(i,i,i,i),(i,i,i,i),")\n/" $op_name/plugin/$op_name"_parser_C30.cpp"
				fi
			elif [ "$input_num" == "1" ];then
					if [ "$IO_5D" == "True" ];then
				sed -i "$((py_build_offset_C30+poi+prid+boid+brid+koid+krid+iid+ol)) s/^/$(echo "\
  te::BuildTeCustomOp(te_bin_info.ddk_version, op.GetName(), RealFilePath, FuncName,")\n/"                                        $dir_op_name/plugin/$op_name"_parser_C30.cpp"
		sed -i "$(($py_build_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$iid+$ol+1)) s/^/$(echo "\
		\"(i,i,i,i,i),")\n/"                                                                                                          $op_name/plugin/$op_name"_parser_C30.cpp"
					else
				sed -i "$((py_build_offset_C30+poi+prid+boid+brid+koid+krid+iid+ol)) s/^/$(echo "\
  te::BuildTeCustomOp(te_bin_info.ddk_version, op.GetName(), RealFilePath, FuncName,")\n/"                                        $dir_op_name/plugin/$op_name"_parser_C30.cpp"
		sed -i "$(($py_build_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$iid+$ol+1)) s/^/$(echo "\
		\"(i,i,i,i),")\n/"                                                                                                            $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					fi
			elif [ "$input_num" == "auto" ];then
				sed -i "$((py_build_offset_C30+poi+prid+boid+brid+koid+krid+iid+ol)) s/^/$(echo "\
  te::BuildTeCustomOp(te_bin_info.ddk_version, op.GetName(), RealFilePath, FuncName,")\n/"                                        $dir_op_name/plugin/$op_name"_parser_C30.cpp"
		sed -i "$(($py_build_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$iid+$ol+1)) s/^/$(echo "\
		\"O, s, i, ")\n/"                                                                                                             $dir_op_name/plugin/$op_name"_parser_C30.cpp"
			elif [ "$input_num" == "autoAll" ];then
				sed -i "$((py_build_offset_C30+poi+prid+boid+brid+koid+krid+iid+ol)) s/^/$(echo "\
  te::BuildTeCustomOp(te_bin_info.ddk_version, op.GetName(), RealFilePath, FuncName,")\n/"                                        $dir_op_name/plugin/$op_name"_parser_C30.cpp"
		sed -i "$(($py_build_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$iid+$ol+1)) s/^/$(echo "\
		\"O, s, ")\n/"                                                                                                                $dir_op_name/plugin/$op_name"_parser_C30.cpp"
			\
	        else
				py_build_multi_input_offset=$((py_build_offset_C30+poi+prid+boid+brid+koid+krid+iid+ol))
                if [ "$IO_5D" == "True" ];then
					sed -i "$((py_build_multi_input_offset)) s/^/$(echo "\
  te::BuildTeCustomOp(te_bin_info.ddk_version, op.GetName(), RealFilePath, FuncName,")\n/"                                    $dir_op_name/plugin/$op_name"_parser_C30.cpp"
			sed -i "$(($py_build_multi_input_offset+1)) s/^/$(echo "\
	\"(i,i,i,i,i), ")\n/"                                                                                                     $op_name/plugin/$op_name"_parser_C30.cpp"
					for((i=1;i<"$input_num";i++));
					do 
						sed -i "/(i,i,i,i,i/ s/$/(i,i,i,i,i), /"                                                                          $op_name/plugin/$op_name"_parser_C30.cpp"
					done
			    else
					sed -i "$((py_build_multi_input_offset)) s/^/$(echo "\
  te::BuildTeCustomOp(te_bin_info.ddk_version, op.GetName(), RealFilePath, FuncName,")\n/"                                    $dir_op_name/plugin/$op_name"_parser_C30.cpp"
			sed -i "$(($py_build_multi_input_offset+1)) s/^/$(echo "\
			\"(i,i,i,i), ")\n/"                                                                                                     $op_name/plugin/$op_name"_parser_C30.cpp"
					for((i=1;i<"$input_num";i++));
					do 
						sed -i "/(i,i,i,i/ s/$/(i,i,i,i), /"                                                                              $op_name/plugin/$op_name"_parser_C30.cpp"
					done
				fi
			fi
      
    if [ "$weight_num" -gt 0 ];then
        # add weight shape 
        for((weightNPK=0;weightNPK<"$weight_num";weightNPK++));
        do  
            weight_params_kernel=`cat $cur_path/config.json | jq '.weight_num_param'`;
            weightNumKernel=`echo $weight_params_kernel | jq -r ".[0].weight_"$(($weightNPK+1))""`
        
            sed -i "/(i,i,/ s/$/(/"                                                                                             $op_name/plugin/$op_name"_parser_C30.cpp"
            if [ "$weightNumKernel" -gt 0 ];then
                for((weiShapeIDK=0;weiShapeIDK<"$weightNumKernel";weiShapeIDK++));
                do 
                    if [ "$weiShapeIDK" == "$(($weightNumKernel-1))" ];then
                        sed -i "/(i,i,/ s/$/i), /"                                                                              $op_name/plugin/$op_name"_parser_C30.cpp"
                    else
                        sed -i "/(i,i,/ s/$/i,/"                                                                                $op_name/plugin/$op_name"_parser_C30.cpp"
                    fi
                done
             fi
          done
    fi
    
			# add dtype
		    sed -i "/(i,i/ s/$/s, /"                                                                                                $op_name/plugin/$op_name"_parser_C30.cpp"
		# optional parameters
		optional_type_parameter=$(awk '$1 == "optional" {print $2}' $current_path/common/file.txt)

		for optional_type_bin_c30 in $optional_type_parameter
		do 
			koi_bin_enum=0
			if [ $optional_type_bin_c30 == "bool" ];then
			    if [ "$input_num" == "auto" ];then                               
				    sed -i "/O, s, i/ s/$/O, /"                                                                                           $op_name/plugin/$op_name"_parser_C30.cpp"
			    elif [ "$input_num" == "autoAll" ];then
				    sed -i "/O, s/ s/$/O, /"                                                                                              $op_name/plugin/$op_name"_parser_C30.cpp"
				else
					sed -i "/(i,i/ s/$/O, /"                                                                                                $op_name/plugin/$op_name"_parser_C30.cpp"
				fi
		    elif [ $optional_type_bin_c30 == "float" ];then
			    if [ "$input_num" == "auto" ];then
				    sed -i "/O, s, i/ s/$/f, /"                                                                                           $op_name/plugin/$op_name"_parser_C30.cpp"
			    elif [ "$input_num" == "autoAll" ];then
				    sed -i "/O, s/ s/$/f, /"                                                                                              $op_name/plugin/$op_name"_parser_C30.cpp"
				else
				    sed -i "/(i,i/ s/$/f, /"                                                                                              $op_name/plugin/$op_name"_parser_C30.cpp"
				fi
			elif [ $optional_type_bin_c30 == "string"  ];then
			    if [ "$input_num" == "auto" ];then
				    sed -i "/O, s, i/ s/$/s, /"                                                                                           $op_name/plugin/$op_name"_parser_C30.cpp"
			    elif [ "$input_num" == "autoAll" ];then
				    sed -i "/O, s/ s/$/s, /"                                                                                              $op_name/plugin/$op_name"_parser_C30.cpp"
				else
				    sed -i "/(i,i/ s/$/s, /"                                                                                              $op_name/plugin/$op_name"_parser_C30.cpp"
				fi
			else # it comes to the int part (including int32, uint32, int64, etc) and other parameters.

				for ID_enum in $enum_parameter
				do
					if [ "$optional_type_bin_c30" == "$ID_enum" ];then
						koi_bin_enum=1
					fi
				done
				
				if [ "$koi_bin_enum" == 1 ];then
			        if [ "$input_num" == "auto" ];then
				        sed -i "/O, s, i/ s/$/s, /"                                                                                       $op_name/plugin/$op_name"_parser_C30.cpp"
			        elif [ "$input_num" == "autoAll" ];then
				        sed -i "/O, s/ s/$/s, /"                                                                                          $op_name/plugin/$op_name"_parser_C30.cpp"
				    else
				        sed -i "/(i,i/ s/$/s, /"                                                                                          $op_name/plugin/$op_name"_parser_C30.cpp"
					fi
				elif [[ "$optional_type_bin_c30" == "int32" ]]||[[ "$optional_type_bin_c30" == "uint32" ]]||\
        [[ "$optional_type_bin_c30" == "int64" ]]||[[ "$optional_type_bin_c30" == "uint64" ]]||[[ "$optional_type_bin_c30" == "int" ]];then
			        if [ "$input_num" == "auto" ];then
				        sed -i "/O, s, i/ s/$/i, /"                                                                                       $op_name/plugin/$op_name"_parser_C30.cpp"
			        elif [ "$input_num" == "autoAll" ];then
				        sed -i "/O, s/ s/$/i, /"                                                                                          $op_name/plugin/$op_name"_parser_C30.cpp"
				      else
				        sed -i "/(i,i/ s/$/i, /"                                                                                          $op_name/plugin/$op_name"_parser_C30.cpp"
					fi    
				fi
			fi
		done
		# repeated parameters
		repeat_param_list_bin_c30=1
		for repeat_type_bin in $repeated_parameter
		do
			if [ "$input_num" == "auto" ];then
				sed -i "/O, s, i/ s/$/O, /"                                                                                               $op_name/plugin/$op_name"_parser_C30.cpp"
			elif [ "$input_num" == "autoAll" ];then
				sed -i "/O, s/ s/$/O, /"                                                                                                  $op_name/plugin/$op_name"_parser_C30.cpp"
			else
			    sed -i "/(i,i/ s/$/O, /"                                                                                                $op_name/plugin/$op_name"_parser_C30.cpp"
			fi
			repeat_param_list_bin_c30=$((repeat_param_list_bin_c30+1))
		done
		if [ "$input_num" == "auto" ];then
			sed -i "/O, s, i/ s/$/s, O\", /"                                                                                            $op_name/plugin/$op_name"_parser_C30.cpp"
		elif [ "$input_num" == "autoAll" ];then
			sed -i "/O, s/ s/$/s, O\", /"                                                                                               $op_name/plugin/$op_name"_parser_C30.cpp"
		else
		    sed -i "/(i,i/ s/$/s, O\", /"                                                                                             $op_name/plugin/$op_name"_parser_C30.cpp"
		fi

		# input
		idd_offset=0 # to control the parameter offsets when input nums change 	
		if [ "$input_num" == "2" ];then
				if [ "$IO_5D" == "True" ];then
			sed -i "$(($py_build_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$iid+$ol+2))  s/^/$(echo "\
		input1_desc.GetShape().GetDim(0), input1_desc.GetShape().GetDim(1)\/16, input1_desc.GetShape().GetDim(2), input1_desc.GetShape().GetDim(3),16,")\n/"                                                                                                                                                                                      $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($py_build_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$iid+$ol+3)) s/^/$(echo "\
		input2_desc.GetShape().GetDim(0), input2_desc.GetShape().GetDim(1)\/16, input2_desc.GetShape().GetDim(2), input2_desc.GetShape().GetDim(3),16,")\n/"                                                                                                                                                                                      $dir_op_name/plugin/$op_name"_parser_C30.cpp"
				else
			sed -i "$(($py_build_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$iid+$ol+2))  s/^/$(echo "\
		input1_desc.GetShape().GetDim(0), input1_desc.GetShape().GetDim(1), input1_desc.GetShape().GetDim(2), input1_desc.GetShape().GetDim(3),")\n/"                                                                                                                                                                                             $dir_op_name/plugin/$op_name"_parser_C30.cpp"
			sed -i "$(($py_build_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$iid+$ol+3)) s/^/$(echo "\
		input2_desc.GetShape().GetDim(0), input2_desc.GetShape().GetDim(1), input2_desc.GetShape().GetDim(2), input2_desc.GetShape().GetDim(3),")\n/"                                                                                                                                                                                             $dir_op_name/plugin/$op_name"_parser_C30.cpp"
			    fi
				idd_offset=1
		elif [ "$input_num" == "1" ];then
				if [ "$IO_5D" == "True" ];then
			sed -i "$(($py_build_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$iid+$ol+2))  s/^/$(echo "\
		input1_desc.GetShape().GetDim(0), input1_desc.GetShape().GetDim(1)\/16, input1_desc.GetShape().GetDim(2), input1_desc.GetShape().GetDim(3),16,")\n/"                                                                                                                                                                                                                     $dir_op_name/plugin/$op_name"_parser_C30.cpp"
				else
			sed -i "$(($py_build_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$iid+$ol+2))  s/^/$(echo "\
		input1_desc.GetShape().GetDim(0), input1_desc.GetShape().GetDim(1), input1_desc.GetShape().GetDim(2), input1_desc.GetShape().GetDim(3),")\n/"                                                                                                                                                                                                                            $dir_op_name/plugin/$op_name"_parser_C30.cpp"
		  	    fi
		elif [ "$input_num" == "auto" ];then
			sed -i "$(($py_build_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$iid+$ol+2))  s/^/$(echo "\
		pyShape,")\n/"                                                                                                                   $dir_op_name/plugin/$op_name"_parser_C30.cpp"
			sed -i "$(($py_build_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$iid+$ol+3))  s/^/$(echo "\
		tensorNumber,")\n/"                                                                                                              $dir_op_name/plugin/$op_name"_parser_C30.cpp"
		    idd_offset=1
		elif [ "$input_num" == "autoAll" ];then
			sed -i "$(($py_build_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$iid+$ol+2))  s/^/$(echo "\
		pyShapes,")\n/"                                                                                                                $dir_op_name/plugin/$op_name"_parser_C30.cpp"
		else
			    if [ "$IO_5D" == "True" ];then
					for((i=1;i<="$input_num";i++));
					do
			sed -i "$(($py_build_multi_input_offset+$i+1))  s/^/$(echo "\
		input"$i"_desc.GetShape().GetDim("$((0))"), input"$i"_desc.GetShape().GetDim("$((1))")\/16, input"$i"_desc.GetShape().GetDim("$((2))"), input"$i"_desc.GetShape().GetDim("$((3))"),16,")\n/"                                                                                                                                                                             $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					done
					idd_offset=$(($input_num-1))
				else	 
					for((i=1;i<="$input_num";i++));
					do
			sed -i "$(($py_build_multi_input_offset+$i+1))  s/^/$(echo "\
		input"$i"_desc.GetShape().GetDim("$((0))"), input"$i"_desc.GetShape().GetDim("$((1))"), input"$i"_desc.GetShape().GetDim("$((2))"), input"$i"_desc.GetShape().GetDim("$((3))"),")\n/"                                                                                                                                                                                    $dir_op_name/plugin/$op_name"_parser_C30.cpp"
          done
			        idd_offset=$(($input_num-1))
		            
                fi 
		fi

    # add weight shape
    if [ "$weight_num" -gt 0 ];then
        for((weightNPKI=0;weightNPKI<"$weight_num";weightNPKI++));
        do  
            weight_params_kernel_input=`cat $cur_path/config.json | jq '.weight_num_param'`;
            weightNumKernelInput=`echo $weight_params_kernel_input | jq -r ".[0].weight_"$(($weightNPKI+1))""`
        
            if [ "$weightNumKernelInput" -gt 0 ];then
                for((weiShapeIDKI=0;weiShapeIDKI<"$weightNumKernelInput";weiShapeIDKI++));
                do  
                    if [[ "$weiShapeIDKI" == 0 ]] && [[ "$weightNumKernelInput" == 1 ]];then
                        sed -i "$(($py_build_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$iid+$ol+$idd_offset+weightNPKI+3)) s/^/$(echo "  \
      resW"$(($weightNPKI+1))"_0, ")\n/"                                                                                             $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
                    elif [[ "$weiShapeIDKI" == 0 ]] && [[ "$weightNumKernelInput" -gt 1 ]];then
                        sed -i "$(($py_build_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$iid+$ol+$idd_offset+weightNPKI+3)) s/^/$(echo "  \
      resW"$(($weightNPKI+1))"_0, ")\n/"                                                                                             $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
                    elif [ "$weiShapeIDKI" -le "$((weightNumKernelInput-1))" ];then
                        sed -i "/      resW"$(($weightNPKI+1))"_0/s/$/resW"$(($weightNPKI+1))"_"$weiShapeIDKI", /"                   $current_path/$dir_op_name/plugin/$op_name"_parser_C30.cpp"
                    fi  
                done
            fi
        done
        # add weight shape 
    fi
    ol=$((ol+weight_num))
    
		# add dtype!
		sed -i "$(($py_build_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$iid+$ol+$idd_offset+3)) s/^/$(echo "\
		dtype.c_str(),")\n/"                                                                                                             $dir_op_name/plugin/$op_name"_parser_C30.cpp"
		# optional parameters
		optional_parameter_c30_id=0
		optional_type_param_bin_c30_id=0
		optional_parameter_c30=$(awk '$1 == "optional" {print $3}' $current_path/common/file.txt)
		for optional_param_bin_c30 in $optional_parameter_c30
		do
			optional_type_param_bin_c30_id=0
			for optional_type_param_bin_c30 in $optional_type_parameter
			do
				koi_bin_str_enum=0
				if [ "$optional_parameter_c30_id" == "$optional_type_param_bin_c30_id"  ];then
					if [ "$optional_type_param_bin_c30" == "bool" ];then
		sed -i "$(($py_build_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$optional_parameter_c30_id-$layer_param_kc_num+$iid+$idd_offset+$ol+4)) s/^/$(echo "\
        "$optional_param_bin_c30"?Py_True:Py_False,")\n/"                                                                            $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					else
						if [ "$optional_type_param_bin_c30" == "string" ];then
		sed -i "$(($py_build_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$optional_parameter_c30_id-$layer_param_kc_num+$iid+$idd_offset+$ol+4)) s/^/$(echo "\
        "$optional_param_bin_c30".c_str(),")\n/"                                                                                         $dir_op_name/plugin/$op_name"_parser_C30.cpp"
            elif [ "$optional_type_param_bin_c30" == "float" ];then
		sed -i "$(($py_build_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$optional_parameter_c30_id-$layer_param_kc_num+$iid+$idd_offset+$ol+4)) s/^/$(echo "\
        $optional_param_bin_c30,")\n/"                                                                                         $dir_op_name/plugin/$op_name"_parser_C30.cpp"
						else

							for ID_enum in $enum_parameter
							do
								if [ "$optional_type_param_bin_c30" == "$ID_enum" ];then
									koi_bin_str_enum=1
								fi
							done
							if [ "$koi_bin_str_enum" == 1 ];then
		sed -i "$(($py_build_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$optional_parameter_c30_id-$layer_param_kc_num+$iid+$idd_offset+$ol+4)) s/^/$(echo "\
		"$optional_param_bin_c30".c_str(),")\n/"                                                                                         $dir_op_name/plugin/$op_name"_parser_C30.cpp"
							elif [[ "$ID_R_BIN" == "int32" ]]||[[ "$ID_R_BIN" == "uint32" ]]||[[ "$ID_R_BIN" == "int64" ]]||[[ "$ID_R_BIN" == "uint64" ]]||[[ "$ID_R_BIN" == "int" ]];then
		sed -i "$(($py_build_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$optional_parameter_c30_id-$layer_param_kc_num+$iid+$idd_offset+$ol+4)) s/^/$(echo "\
		$optional_param_bin_c30,")\n/"                                                                                                   $dir_op_name/plugin/$op_name"_parser_C30.cpp"
              else
                  layer_param_kc_num=$(($layer_param_kc_num+1))
							fi
						fi
					fi
				fi
				optional_type_param_bin_c30_id=$(($optional_type_param_bin_c30_id+1))
			done
			optional_parameter_c30_id=$(($optional_parameter_c30_id+1))
		done
    optional_parameter_c30_id=$(($optional_parameter_c30_id-$layer_param_kc_num*1))
		# add repeated parameters! 
		repeat_param_list_bin_c30_id=0
		for repeat_param_bin_c30 in $repeated_parameter
		do
			sed -i "$(($py_build_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$optional_parameter_c30_id+$repeat_param_list_bin_c30_id+$iid+$idd_offset+$ol+4)) s/^/$(echo "\
		"py_"$repeat_param_bin_c30,")\n/"                                                                                                $dir_op_name/plugin/$op_name"_parser_C30.cpp"
			repeat_param_list_bin_c30_id=$((repeat_param_list_bin_c30_id+1))
		done
		# add  kernel name and build item
		sed -i "$(($py_build_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$optional_parameter_c30_id+$repeat_param_list_bin_c30_id+$iid+$idd_offset+$ol+4)) s/^/$(echo "\
		KernelName.c_str(),")\n/"                                                                                                        $dir_op_name/plugin/$op_name"_parser_C30.cpp"
		
		
			sed -i "$(($py_build_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$optional_parameter_c30_id+$repeat_param_list_bin_c30_id+$iid+$idd_offset+$ol+5)) s/^/$(echo "\
        Py_True);")\n/"                                                                                                              $dir_op_name/plugin/$op_name"_parser_C30.cpp"
		

		# add Py_Finalize()
		if [[ "$input_num" == "auto" ]]||[[ "$input_num" == "autoAll"  ]];then
	 	    sed -i "$(($py_build_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$optional_parameter_c30_id+$repeat_param_list_bin_c30_id+$iid+$idd_offset+$ol+12)) s/^/$(echo "\
	Py_Finalize(); ")\n/"                                                                                                              $dir_op_name/plugin/$op_name"_parser_C30.cpp"
	    fi
	fi
	# call the operator end!


