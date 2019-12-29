#! /bin/bash

# add input Desc
	if [ "$version" == "C30" ];then
		iid=0
		if [ "$input_num" == "2" ];then
			sed -i "$((input_desc_offset_C30+poi+prid+boid+brid+koid+krid+ol)) s/^/$(echo "\
	ge::TensorDesc input1_desc = op.GetInputDesc(0);")\n/"                                                                                                   $op_name/plugin/$op_name"_parser_C30.cpp"
			sed -i "$(($input_desc_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$ol+1)) s/^/$(echo "\
	ge::TensorDesc input2_desc = op.GetInputDesc(1);")\n/"                                                                                                   $op_name/plugin/$op_name"_parser_C30.cpp"
			sed -i "$(($input_desc_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$ol+4)) s/^/$(echo "\
	if(input1_desc.GetShape().GetDimNum() != 4) ")\n/"                                                                                                       $op_name/plugin/$op_name"_parser_C30.cpp"
			sed -i "$(($input_desc_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$ol+5)) s/^/$(echo "\
	{ ")\n/"                                                                                                                                                 $op_name/plugin/$op_name"_parser_C30.cpp"
			sed -i "$(($input_desc_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$ol+6)) s/^/$(echo "\
		printf(\"The shape size is %d, which is not 4!\\\n \", (int32_t)input1_desc.GetShape().GetDimNum()); ")\n/"                                            $op_name/plugin/$op_name"_parser_C30.cpp"
			sed -i "$(($input_desc_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$ol+7)) s/^/$(echo "\
		return FAILED; ")\n/"                                                                                                                                  $op_name/plugin/$op_name"_parser_C30.cpp"
			sed -i "$(($input_desc_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$ol+8)) s/^/$(echo "\
	} ")\n/"                                                                                                                                                 $op_name/plugin/$op_name"_parser_C30.cpp"
        
			sed -i "$(($input_desc_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$ol+9)) s/^/$(echo "\
	if(input2_desc.GetShape().GetDimNum() != 4) ")\n/"                                                                                                       $op_name/plugin/$op_name"_parser_C30.cpp"
			sed -i "$(($input_desc_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$ol+10)) s/^/$(echo "\
	{ ")\n/"                                                                                                                                                 $op_name/plugin/$op_name"_parser_C30.cpp"
			sed -i "$(($input_desc_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$ol+11)) s/^/$(echo "\
		printf(\"The shape size is %d, which is not 4!\\\n \", (int32_t)input2_desc.GetShape().GetDimNum()); ")\n/"                                            $op_name/plugin/$op_name"_parser_C30.cpp"
			sed -i "$(($input_desc_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$ol+12)) s/^/$(echo "\
		return FAILED; ")\n/"                                                                                                                                  $op_name/plugin/$op_name"_parser_C30.cpp"
			sed -i "$(($input_desc_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$ol+13)) s/^/$(echo "\
	} ")\n/"                                                                                                                                                 $op_name/plugin/$op_name"_parser_C30.cpp"

			iid=12
		elif [ "$input_num" == "1" ];then
			sed -i "$((input_desc_offset_C30+poi+prid+boid+brid+koid+krid+ol)) s/^/$(echo "\
	ge::TensorDesc input1_desc = op.GetInputDesc(0);")\n/"                                                                                               $op_name/plugin/$op_name"_parser_C30.cpp"
			sed -i "$(($input_desc_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$ol+3)) s/^/$(echo "\
	if(input1_desc.GetShape().GetDimNum() != 4) ")\n/"                                                                                                   $op_name/plugin/$op_name"_parser_C30.cpp"
			sed -i "$(($input_desc_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$ol+4)) s/^/$(echo "\
	{ ")\n/"                                                                                                                                             $op_name/plugin/$op_name"_parser_C30.cpp"
			sed -i "$(($input_desc_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$ol+5)) s/^/$(echo "\
	    printf(\"The shape size is %d, which is not 4!\\\n \", (int32_t)input1_desc.GetShape().GetDimNum()); ")\n/"                                      $op_name/plugin/$op_name"_parser_C30.cpp"
			sed -i "$(($input_desc_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$ol+6)) s/^/$(echo "\
		return FAILED; ")\n/"                                                                                                                              $op_name/plugin/$op_name"_parser_C30.cpp"
			sed -i "$(($input_desc_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$ol+7)) s/^/$(echo "\
	} ")\n/"                                                                                                                                             $op_name/plugin/$op_name"_parser_C30.cpp"
			
			iid=6
		elif [ "$input_num" == "auto" ];then
			sed -i "$((input_desc_offset_C30+poi+prid+boid+brid+koid+krid+ol)) s/^/$(echo "\
	auto tensorDesc = op.GetInputDesc(0);")\n/"                  $op_name/plugin/$op_name"_parser_C30.cpp"
            sed -i "$(($input_desc_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$ol+3)) s/^/$(echo "\
	int64_t tensorNumber = 0; ")\n/"                                                                                                                     $op_name/plugin/$op_name"_parser_C30.cpp"
            sed -i "$(($input_desc_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$ol+4)) s/^/$(echo "\
	for (size_t i = 0; op.GetInputDesc(i).GetShape().GetShapeSize(); i++) ")\n/"                                                                         $op_name/plugin/$op_name"_parser_C30.cpp"
			sed -i "$(($input_desc_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$ol+5)) s/^/$(echo "\
	{ ")\n/"                                                                                                                                             $op_name/plugin/$op_name"_parser_C30.cpp"
			sed -i "$(($input_desc_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$ol+6)) s/^/$(echo "\
		tensorNumber++;	")\n/"                                                                                                                             $op_name/plugin/$op_name"_parser_C30.cpp"
			sed -i "$(($input_desc_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$ol+7)) s/^/$(echo "\
	} ")\n/"                                                                                                                                             $op_name/plugin/$op_name"_parser_C30.cpp"
			sed -i "$(($input_desc_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$ol+8)) s/^/$(echo "\
	Py_Initialize();  ")\n/"                                                                                                                             $op_name/plugin/$op_name"_parser_C30.cpp"
			sed -i "$(($input_desc_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$ol+9)) s/^/$(echo "\
	PyObject *pyShape = PyTuple_New(tensorDesc.GetShape().GetDimNum()); ")\n/"                                                                           $op_name/plugin/$op_name"_parser_C30.cpp"
			sed -i "$(($input_desc_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$ol+10)) s/^/$(echo "\
	for (size_t j = 0; j < tensorDesc.GetShape().GetDimNum(); j++)   ")\n/"                                                                              $op_name/plugin/$op_name"_parser_C30.cpp"
			sed -i "$(($input_desc_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$ol+11)) s/^/$(echo "\
	{ ")\n/"                                                                                                                                             $op_name/plugin/$op_name"_parser_C30.cpp"
			sed -i "$(($input_desc_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$ol+12)) s/^/$(echo "\
		PyTuple_SetItem(pyShape, j, Py_BuildValue(\"i\", tensorDesc.GetShape().GetDim(j))); ")\n/"                                                         $op_name/plugin/$op_name"_parser_C30.cpp"
			sed -i "$(($input_desc_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$ol+13)) s/^/$(echo "\
	} ")\n/"                                                                                                                                             $op_name/plugin/$op_name"_parser_C30.cpp"

			iid=11
        elif [ "$input_num" == "autoAll" ];then
			sed -i "$((input_desc_offset_C30+poi+prid+boid+brid+koid+krid+ol)) s/^/$(echo "\
	auto tensorDesc = op.GetInputDesc(0);")\n/"                                                                                                        $op_name/plugin/$op_name"_parser_C30.cpp"
            sed -i "$(($input_desc_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$ol+3)) s/^/$(echo "\
	int64_t tensorNumber = 0; ")\n/"                                                                                                                   $op_name/plugin/$op_name"_parser_C30.cpp"
            sed -i "$(($input_desc_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$ol+4)) s/^/$(echo "\
	for (size_t i = 0; op.GetInputDesc(i).GetShape().GetShapeSize(); i++) ")\n/"                                                                       $op_name/plugin/$op_name"_parser_C30.cpp"
			sed -i "$(($input_desc_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$ol+5)) s/^/$(echo "\
	{ ")\n/"                                                                                                                                           $op_name/plugin/$op_name"_parser_C30.cpp"
			sed -i "$(($input_desc_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$ol+6)) s/^/$(echo "\
		tensorNumber++;	")\n/"                                                                                                                           $op_name/plugin/$op_name"_parser_C30.cpp"
			sed -i "$(($input_desc_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$ol+7)) s/^/$(echo "\
	} ")\n/"                                                                                                                                           $op_name/plugin/$op_name"_parser_C30.cpp"
			sed -i "$(($input_desc_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$ol+8)) s/^/$(echo "\
	Py_Initialize();  ")\n/"                                                                                                                           $op_name/plugin/$op_name"_parser_C30.cpp"
		

			sed -i "$(($input_desc_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$ol+9)) s/^/$(echo "\
	PyObject *pyShapes = PyTuple_New(tensorNumber); ")\n/"                                                                                             $op_name/plugin/$op_name"_parser_C30.cpp"
		sed -i "$(($input_desc_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$ol+10)) s/^/$(echo "\
	for (size_t k = 0; k < tensorNumber; k++)   ")\n/"                                                                                                 $op_name/plugin/$op_name"_parser_C30.cpp"
			sed -i "$(($input_desc_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$ol+11)) s/^/$(echo "\
	{ ")\n/"                                                                                                                                           $op_name/plugin/$op_name"_parser_C30.cpp"


			sed -i "$(($input_desc_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$ol+12)) s/^/$(echo "\
		PyObject *pyShape = PyTuple_New(op.GetInputDesc(k).GetShape().GetDimNum()); ")\n/"                                                               $op_name/plugin/$op_name"_parser_C30.cpp"
			sed -i "$(($input_desc_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$ol+13)) s/^/$(echo "\
		for (size_t j = 0; j < op.GetInputDesc(k).GetShape().GetDimNum(); j++)   ")\n/"                                                                  $op_name/plugin/$op_name"_parser_C30.cpp"
			sed -i "$(($input_desc_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$ol+14)) s/^/$(echo "\
		{ ")\n/"                                                                                                                                         $op_name/plugin/$op_name"_parser_C30.cpp"
			sed -i "$(($input_desc_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$ol+15)) s/^/$(echo "\
			PyTuple_SetItem(pyShape, j, Py_BuildValue(\"i\", op.GetInputDesc(k).GetShape().GetDim(j))); ")\n/"                                             $op_name/plugin/$op_name"_parser_C30.cpp"
			sed -i "$(($input_desc_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$ol+16)) s/^/$(echo "\
		} ")\n/"                                                                                                                                         $op_name/plugin/$op_name"_parser_C30.cpp"
			sed -i "$(($input_desc_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$ol+17)) s/^/$(echo "\
		PyTuple_SetItem(pyShapes, k, pyShape); ")\n/"                                                                                                    $op_name/plugin/$op_name"_parser_C30.cpp"
			sed -i "$(($input_desc_offset_C30+$poi+$prid+$boid+$brid+$koid+$krid+$ol+18)) s/^/$(echo "\
	} ")\n/"                                                                                                                                           $op_name/plugin/$op_name"_parser_C30.cpp"

			iid=16
		else
			input_num_offset=$((input_desc_offset_C30+poi+prid+boid+brid+koid+krid+ol))
	for((i=1;i<="$input_num";i++));
			do
			    sed -i "$(($input_num_offset+$i-1)) s/^/$(echo "\
		ge::TensorDesc input"$i"_desc = op.GetInputDesc("$(($i-1))");")\n/"                     $op_name/plugin/$op_name"_parser_C30.cpp"
				iid=$(($iid+1))
			done 
	    	for((i=1;i<="$input_num";i++));
			do 
				sed -i "$(($input_num_offset+$iid+$i+1)) s/^/$(echo "\
	if(input"$((i))"_desc.GetShape().GetDimNum() != 4) ")\n/"                                                                                              $op_name/plugin/$op_name"_parser_C30.cpp"
				sed -i "$(($input_num_offset+$iid+$i+2)) s/^/$(echo "\
	{ ")\n/"                                                                                                                                               $op_name/plugin/$op_name"_parser_C30.cpp"
				sed -i "$(($input_num_offset+$iid+$i+3)) s/^/$(echo "\
		printf(\"The shape size is %d, which is not 4!\\\n \", (int32_t)input"$((i))"_desc.GetShape().GetDimNum()); ")\n/"                                   $op_name/plugin/$op_name"_parser_C30.cpp"
				sed -i "$(($input_num_offset+$iid+$i+4)) s/^/$(echo "\
		return FAILED; ")\n/"                                                                                                                                $op_name/plugin/$op_name"_parser_C30.cpp"
				sed -i "$(($input_num_offset+$iid+$i+5)) s/^/$(echo "\
	} ")\n/"                                                                                                                                               $op_name/plugin/$op_name"_parser_C30.cpp"
                iid=$(($iid+4)) # minus one because the for cylcle
			done
		    iid=$(($iid+$input_num-1)) # plus one because of the offset
		fi
	fi

