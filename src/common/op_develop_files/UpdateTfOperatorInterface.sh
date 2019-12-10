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

tf_weight_shape_offset=49
# operator file doesn't exist, new a file
if [ "$input_num" == "1" ];then
    sed -i "/def / s/$/shape, dtype, /"                                                            $current_path/$dir_op_name/operator/"$op_name".py
elif [ "$input_num" == "auto" ];then
    sed -i "/def / s/$/shape, dtype, tensorNumber, /"                                              $current_path/$dir_op_name/operator/"$op_name".py
elif [ "$input_num" == "autoAll" ];then
    sed -i "/def / s/$/shape, dtype, /"                                                            $current_path/$dir_op_name/operator/"$op_name".py
else
    for((i=1;i<="$input_num";i++));
    do
        sed -i "/def / s/$/shape_"$i", /"                                                          $current_path/$dir_op_name/operator/"$op_name".py
    done 
			  sed -i "/def / s/$/dtype, /"                                                               $current_path/$dir_op_name/operator/"$op_name".py
fi

for index in `seq 0 $param_length` # the updated length
do
    param_op=`echo $param_list | jq -r ".[$index].param"`
    sed -i "/def / s/$/$param_op, /"                                                               $current_path/$dir_op_name/operator/"$op_name".py
    sed -i "/Parameter Sequence in plugin file/ s/$/ $param_op/"                                   $current_path/$dir_op_name/operator/"$op_name".py
done

sed -i "/def / s/$/kernel_name = \""$op_name"\", need_build = False, need_print = False):/"        $current_path/$dir_op_name/operator/"$op_name".py

if [[ ! -f "$current_path/$op_name/operator/"$op_name"OutputShape.py" ]];then
		# output shape
		cp $current_path/common/\[om_op_name\]OutputWeightShape                                        $current_path/$dir_op_name/operator      # copy operator file
		mv $current_path/$dir_op_name/operator/\[om_op_name\]OutputWeightShape                         $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
    sed -i "s/\[om_op_name\]/$op_name/g"                                                           $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
  
    para_len=$(($param_length+1))
    if [ "$input_num" == "1" ];then
        if [ "$para_len" -gt 0 ];then
            sed -i "/def / s/$/shape, /"                                                           $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
        elif [ "$para_len" == 0 ];then 
            sed -i "/def / s/$/shape): /"                                                          $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
        fi
    elif [ "$input_num" == "auto" ];then
        if [ "$para_len" -gt 0 ];then
            sed -i "/def / s/$/shape, tensorNumber, /"                                             $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
        elif [ "$para_len" == 0 ];then
            sed -i "/def / s/$/shape, tensorNumber): /"                                            $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
        fi
    elif [ "$input_num" == "autoAll" ];then
        if [ "$para_len" -gt 0 ];then
            sed -i "/def / s/$/shape, /"                                                           $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
        elif [ "$para_len" == 0 ];then
            sed -i "/def / s/$/shape): /"                                                          $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
        fi
    else
        for((i=1;i<="$input_num";i++));
        do
            if [[ "$i" == "$input_num" ]] && [[ "$para_len" -gt 0 ]];then
                sed -i "/def / s/$/shape_"$i", /"                                                  $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
            elif [[ "$i" == "$input_num" ]] && [[ "$para_len" == 0 ]];then
                sed -i "/def / s/$/shape_"$i"): /"                                                 $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
            else
                sed -i "/def / s/$/shape_"$i", /"                                                  $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
            fi
        done 
    fi
 
    param_len=$(($param_length+1))
    
    for index in `seq 0 $param_length` # the updated length
    do           
        param_op=`echo $param_list | jq -r ".[$index].param"`
        if [ "$index" == "$param_length" ];then
            sed -i "/def / s/$/$param_op):/"                                                       $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
            sed -i "/Parameter / s/$/ $param_op. /"                                                $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
        else
            sed -i "/def / s/$/$param_op, /"                                                       $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
            sed -i "/Parameter / s/$/ $param_op,/"                                                 $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
        fi
    done
    
    # weight shape
    if [ "$weight_num" > 0 ];then
        for((weightId=0;weightId<"$weight_num";weightId++));
        do 
            sed -i "$(($tf_weight_shape_offset+9*weightId)) s/^/$(echo "\
def Weight"$((weightId+1))"Shape"$op_name"(")\n/"                                                  $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
            sed -i "$(($tf_weight_shape_offset+9*$weightId+1)) s/^/$(echo "\
     \"\"\" ")\n/"                                                                                 $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
            sed -i "$(($tf_weight_shape_offset+9*$weightId+2)) s/^/$(echo "\
     TODO\: ")\n/"                                                                                 $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
            sed -i "$(($tf_weight_shape_offset+9*$weightId+3)) s/^/$(echo "\
     Please add code here to obtain the weight_"$(($weightId+1))" shape\. ")\n/"                   $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
            sed -i "$(($tf_weight_shape_offset+9*$weightId+4)) s/^/$(echo "\
     \"\"\" ")\n/"                                                                                 $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
            sed -i "$(($tf_weight_shape_offset+9*$weightId+5)) s/^/$(echo "\
     weight_"$(($weightId+1))"_shape = () ")\n/"                                                   $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
            sed -i "$(($tf_weight_shape_offset+9*$weightId+7)) s/^/$(echo "\
     "return weight_"$(($weightId+1))"_shape" ")\n/"                                               $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
        done
        
        if [ "$input_num" == "1" ];then
            if [ "$param_len" -gt "0" ];then
                 sed -i "/def Weight/ s/$/shape, /"                                                $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
            elif [ "$param_len" == "0" ];then
                sed -i "/def Weight/ s/$/shape): /"                                                $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
            fi
        elif [ "$input_num" == "auto" ];then
            if [ "$param_len" -gt 0 ];then
                sed -i "/def Weight/ s/$/shape, tensorNumber, /"                                   $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
            elif [ "$param_len" == 0 ];then
                sed -i "/def Weight/ s/$/shape, tensorNumber): /"                                  $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
            fi
        elif [ "$input_num" == "autoAll" ];then
            if [ "$param_len" -gt 0 ];then
                sed -i "/def Weight/ s/$/shape, /"                                                 $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
            elif [ "$param_len" == 0 ];then
                sed -i "/def Weight/ s/$/shape): /"                                                $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
            fi
        else
            for((i=1;i<="$input_num";i++));
            do
                if [[ "$i" == "$input_num" ]] && [[ "$param_len" == 0 ]];then
                    sed -i "/def Weight/ s/$/shape_"$i"): /"                                       $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py                
                elif [[ "$i" == "$input_num" ]] && [[ "$param_len" -gt 0 ]];then
                    sed -i "/def Weight/ s/$/shape_"$i", /"                                        $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
                else
                    sed -i "/def Weight/ s/$/shape_"$i", /"                                        $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
                fi
            done 
         fi
         param_len=$(($param_length+1))
    
         for index in `seq 0 $param_length` # the updated length
         do           
             param_op=`echo $param_list | jq -r ".[$index].param"`
             if [ "$index" == "$param_length" ];then
                 sed -i "/def Weight/ s/$/$param_op):/"                                            $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
             else
                 sed -i "/def Weight/ s/$/$param_op, /"                                            $current_path/$dir_op_name/operator/"$op_name"OutputWeightShape.py
             fi
        done
    fi
fi
   
   
   