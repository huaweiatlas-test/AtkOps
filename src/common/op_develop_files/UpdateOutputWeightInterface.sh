#! /bin/bash

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

weight_shape_offset=49   # set the offset for "$op_name"OutputShape.py

# operator file doesn't exist, new a file
	if [[ ! -f "$current_path/$op_name/operator/"$op_name"OutputShape.py" ]];then
		# operator
		cp $current_path/common/[om_op_name]OutputWeightShape                              $current_path/$dir_op_name/operator   # copy operator file
		mv $dir_op_name/operator/[om_op_name]OutputWeightShape                             $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
   
    sed -i "s/\[om_op_name\]/$op_name/g"                                               $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
    # add weight info
    if [ "$weight_num" -gt 0 ];then
        for((weightId=0;weightId<"$weight_num";weightId++));
        do 
            sed -i "$(($weight_shape_offset+8*$weightId)) s/^/$(echo "\
def Weight"$(($weightId+1))"Shape"$op_name"(")\n/"                                     $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
            sed -i "$(($weight_shape_offset+8*$weightId+1)) s/^/$(echo "\
     \"\"\" ")\n/"                                                                     $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
            sed -i "$(($weight_shape_offset+8*$weightId+2)) s/^/$(echo "\
     TODO\: ")\n/"                                                                     $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
            sed -i "$(($weight_shape_offset+8*$weightId+3)) s/^/$(echo "\
     Please add code here to obtain the weight_"$(($weightId+1))" shape\. ")\n/"       $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
            sed -i "$(($weight_shape_offset+8*$weightId+4)) s/^/$(echo "\
     \"\"\" ")\n/"                                                                     $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
            sed -i "$(($weight_shape_offset+8*$weightId+5)) s/^/$(echo "\
     weight_"$(($weightId+1))"_shape = () ")\n/"                                       $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
            sed -i "$(($weight_shape_offset+8*$weightId+7)) s/^/$(echo "\
     "return weight_"$(($weightId+1))"_shape" ")\n/"                                   $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
            
     done
    fi
    
   
		if [ "$input_num" == "2" ];then
			sed -i "/def / s/$/shape_1, shape_2, /"                                          $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
			in_op_id=0 # input optional parameter id
			for optional_param_operator in $optional_parameter
			do
				in_op_type_id=0 # input optional type parameter id
			    for optional_param_type_operator in $optional_type_parameter
				do	
					if [ "$in_op_id" == "$in_op_type_id" ];then
						var_line_num_ori=$(grep -rn "optional $optional_param_type_operator $optional_param_operator " $current_path/common/file.txt | awk '{print $1}')
						var_line_num=${var_line_num_ori%:*}
						var_full=`sed -n "$var_line_num"p $current_path/common/file.txt` # get the sentence of $ID_B from caffe.proto
						sed -n "$var_line_num"p $current_path/common/file.txt > $current_path/common/"$optional_param_operator".txt # get the sentence file of $ID_B from caffe.proto
						if [ `grep -c "default" $current_path/common/"$optional_param_operator".txt` -eq '0' ];then
                if [[ "$optional_param_type_operator" == "bool" ]]||[[ "$optional_param_type_operator" == "float" ]]||\
                [[ "$optional_param_type_operator" == "string" ]]||[[ "$optional_param_type_operator" == "int32" ]]||\
                [[ "$optional_param_type_operator" == "uint32" ]]||[[ "$optional_param_type_operator" == "int64" ]]||\
                [[ "$optional_param_type_operator" == "uint64" ]]||[[ "$optional_param_type_operator" == "int" ]];then 
				sed -i "/def / s/$/$optional_param_operator, /"                                 $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
                fi
						else
							var_cut_default=${var_full#*"default"}  # cut "default"
							var_cut_equal=${var_cut_default#*"="}   # cut "="
							var_cut_bracket_origin=${var_cut_equal%]*}     # cut "]"
							var_cut_left_blank=${var_cut_bracket_origin#*" "}     # cut left blank
							var_cut_right_blank=${var_cut_left_blank%*}     # cut right blank
							var_cut_bracket=$var_cut_right_blank # rename the final default parameter type as var_cut_bracket 
              # the content above is to cut for the default parameter
			        enum_input=0
							for enum_input_type_id in $enum_parameter
							do
							    if [ "$optional_param_type_operator" == "$enum_input_type_id" ];then
								enum_input=1  # check whether it is a enum parameter or not
							    fi
							done
				sed -i "/def / s/$/$optional_param_operator, /"                                                            $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py				           
				        fi
						rm -rf $current_path/common/"$optional_param_operator".txt
					fi
					in_op_type_id=$(($in_op_type_id+1))
				done
				sed -i "/Parameter Sequence in plugin file/ s/$/ $optional_param_operator/"                                $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
		    in_op_id=$(($in_op_id+1))
			done
			for repeat_param_operator in $repeated_parameter
			do
				sed -i "/def / s/$/$repeat_param_operator, /"                                                              $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
				sed -i "/Parameter Sequence in plugin file/ s/$/ $repeat_param_operator/"                                  $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
			done
			sed -i "/def / s/$/kernel_name = \""$op_name"\"):/"                  $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
		elif [[ "$input_num" == "1" ]]||[[ "$input_num" == "auto" ]]||[[ "$input_num" == "autoAll" ]];then
            if [ "$input_num" == "1" ];then
			    sed -i "/def / s/$/shape, /"                                                                             $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
            elif [ "$input_num" == "auto" ];then
			    sed -i "/def / s/$/shape, tensorNumber, /"                                                               $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
			else
			    sed -i "/def / s/$/shape, /"                                                                             $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
            fi
            in_op_id=0 # input optional parameter id
			for optional_param_operator in $optional_parameter
			do
 	            in_op_type_id=0 # input optional type parameter id
			    for optional_param_type_operator in $optional_type_parameter
				do	
					if [ "$in_op_id" == "$in_op_type_id" ];then
						var_line_num_ori=$(grep -rn "optional $optional_param_type_operator $optional_param_operator " $current_path/common/file.txt | awk '{print $1}')
						var_line_num=${var_line_num_ori%:*}
						var_full=`sed -n "$var_line_num"p $current_path/common/file.txt` # get the sentence of $ID_B from caffe.proto
						sed -n "$var_line_num"p $current_path/common/file.txt > $current_path/common/"$optional_param_operator".txt # get the sentence file of $ID_B from caffe.proto
						if [ `grep -c "default" $current_path/common/"$optional_param_operator".txt` -eq '0' ];then
                if [[ "$optional_param_type_operator" == "bool" ]]||[[ "$optional_param_type_operator" == "float" ]]||\
                [[ "$optional_param_type_operator" == "string" ]]||[[ "$optional_param_type_operator" == "int32" ]]||\
                [[ "$optional_param_type_operator" == "uint32" ]]||[[ "$optional_param_type_operator" == "int64" ]]||\
                [[ "$optional_param_type_operator" == "uint64" ]]||[[ "$optional_param_type_operator" == "int" ]];then 
				sed -i "/def / s/$/$optional_param_operator, /"                                                             $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
                fi
						else
							var_cut_default=${var_full#*"default"}  # cut "default"
							var_cut_equal=${var_cut_default#*"="}   # cut "="
							var_cut_bracket_origin=${var_cut_equal%]*}     # cut "]"
							var_cut_left_blank=${var_cut_bracket_origin#*" "}     # cut left blank
							var_cut_right_blank=${var_cut_left_blank%*}     # cut right blank
							var_cut_bracket=$var_cut_right_blank # rename the final default parameter type as var_cut_bracket 
						    
							enum_input=0
							for enum_input_type_id in $enum_parameter
							do
							    if [ "$optional_param_type_operator" == "$enum_input_type_id" ];then
								enum_input=1  # check whether it is a enum parameter or not
							    fi
							done
				
				    sed -i "/def / s/$/$optional_param_operator, /"                                                         $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
				        fi
						rm -rf $current_path/common/"$optional_param_operator".txt
					fi
					in_op_type_id=$(($in_op_type_id+1))
				done
				sed -i "/Parameter Sequence in plugin file/ s/$/ $optional_param_operator/"                                  $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
		    in_op_id=$(($in_op_id+1))
			done
			for repeat_param_operator in $repeated_parameter
			do
				sed -i "/def / s/$/$repeat_param_operator, /"                                                                $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
				sed -i "/Parameter Sequence in plugin file/ s/$/ $repeat_param_operator/"                                    $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
			done
			sed -i "/def / s/$/kernel_name = \""$op_name"\"):/"                                                            $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
		else  # more inputs
			for((i=1;i<="$input_num";i++));
			do
			sed -i "/def / s/$/shape_"$i", /"                                                                              $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
			done 
			
		    in_op_id=0 # input optional parameter id
			for optional_param_operator in $optional_parameter
			do
 	            in_op_type_id=0 # input optional type parameter id
			    for optional_param_type_operator in $optional_type_parameter
				do	
					if [ "$in_op_id" == "$in_op_type_id" ];then
						var_line_num_ori=$(grep -rn "optional $optional_param_type_operator $optional_param_operator " $current_path/common/file.txt | awk '{print $1}')
						var_line_num=${var_line_num_ori%:*}
						var_full=`sed -n "$var_line_num"p $current_path/common/file.txt` # get the sentence of $ID_B from caffe.proto
						sed -n "$var_line_num"p $current_path/common/file.txt > $current_path/common/"$optional_param_operator".txt # get the sentence file of $ID_B from caffe.proto
						if [ `grep -c "default" $current_path/common/"$optional_param_operator".txt` -eq '0' ];then
                if [[ "$optional_param_type_operator" == "bool" ]]||[[ "$optional_param_type_operator" == "float" ]]||\
                [[ "$optional_param_type_operator" == "string" ]]||[[ "$optional_param_type_operator" == "int32" ]]||\
                [[ "$optional_param_type_operator" == "uint32" ]]||[[ "$optional_param_type_operator" == "int64" ]]||\
                [[ "$optional_param_type_operator" == "uint64" ]]||[[ "$optional_param_type_operator" == "int" ]];then 
				sed -i "/def / s/$/$optional_param_operator, /"                                                            $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
                fi
						else
							var_cut_default=${var_full#*"default"}  # cut "default"
							var_cut_equal=${var_cut_default#*"="}   # cut "="
							var_cut_bracket_origin=${var_cut_equal%]*}     # cut "]"
							var_cut_left_blank=${var_cut_bracket_origin#*" "}     # cut left blank
							var_cut_right_blank=${var_cut_left_blank%*}     # cut right blank
							var_cut_bracket=$var_cut_right_blank # rename the final default parameter type as var_cut_bracket 
				
							enum_input=0
							for enum_input_type_id in $enum_parameter
							do
							    if [ "$optional_param_type_operator" == "$enum_input_type_id" ];then
								enum_input=1  # check whether it is a enum parameter or not
							    fi
							done

				sed -i "/def / s/$/$optional_param_operator, /"                                                            $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
				        fi
						rm -rf $current_path/common/"$optional_param_operator".txt
					fi
					in_op_type_id=$(($in_op_type_id+1))
				done
				sed -i "/Parameter Sequence in plugin file/ s/$/ $optional_param_operator/"                                $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
		    in_op_id=$(($in_op_id+1))
			done
			for repeat_param_operator in $repeated_parameter
			do
				sed -i "/def / s/$/$repeat_param_operator, /"                                                              $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
				sed -i "/Parameter Sequence in plugin file/ s/$/ $repeat_param_operator/"                                  $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
			done
			sed -i "/def / s/$/substitute/"                                                                              $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
      sed -i "s/, substitute/):/g"                                                                                 $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
		fi

	else
		echo "[Info] operator file exists, pass"
	fi


