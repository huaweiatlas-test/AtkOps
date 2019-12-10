#!/bin/bash

# $1: $custom_caffe_proto_file, $2: $current_path, $3: $op_name
function getCustomMessageInCustomCaffeProto() 
{
    cp $1  $2/common/caffe_customer.proto
    # get the customer structure!
    echo "message" >> $2/common/caffe_customer.proto  # add "message"
    sed -n "/message "$3"Parameter/,/message/p" $2/common/caffe_customer.proto > $2/common/"$3"Parameter_caffe_proto.txt  
    sed -i '$d' $2/common/caffe_customer.proto  # delete "message"
    sed -i '$d' $2/common/"$3"Parameter_caffe_proto.txt   # delete the last line
}


function generateNewCaffeProtoWithCustomOperator() 
{
		# generator caffe.proto for this operator_name  
		
		operator_layer_nums=$(cat $2/common/LayerParameter.txt | grep "optional" |wc -l)
		this_operator_num=`expr $operator_layer_nums + $3`                          # calculate the number to plugin in     
		LayerParameter_file_line_num=$(awk 'END{print NR}' $2/common/LayerParameter.txt)

		if [ "$6" == "C30" ];then
            if [ "$5" == 0 ];then
			    cp $1/include/inc/custom/proto/caffe/caffe.proto $2/common/caffe.proto  # caffe.proto in DDK
            fi
        fi
		
		sed -n "/message LayerParameter/,/}/p" $2/common/caffe_customer.proto > $2/common/Customer_LayerParameter.txt  # get the custom LayerParameter
		all_parameter_name_caffe_proto=$(awk '$1 == "optional" {print $2}' $2/common/Customer_LayerParameter.txt) # content of the first "plugin in"
		all_operator_name_caffe_proto=$(awk '$1 == "optional" {print $3}' $2/common/Customer_LayerParameter.txt) # content of the first "plugin in"
		
		custom_operator_name_caffe_proto=""
		all_parameter_name_caffe_proto_id=0
		all_operator_name_caffe_proto_id=0
		for all_parameter in $all_parameter_name_caffe_proto
		do
			all_operator_name_caffe_proto_id=0
			for all_operator in $all_operator_name_caffe_proto
			do 
				if [ "$all_parameter_name_caffe_proto_id" == "$all_operator_name_caffe_proto_id" ];then
					if [ "$all_parameter"  == "$op_name"Parameter"" ];then
						custom_operator_name_caffe_proto=$all_operator
					fi
				fi
				all_operator_name_caffe_proto_id=$(($all_operator_name_caffe_proto_id+1))
			done
			all_parameter_name_caffe_proto_id=$(($all_parameter_name_caffe_proto_id+1))
		done

		type_line=$(grep -rn "message LayerParameter" $2/common/caffe.proto | awk '{print $1}') # get the line num of "message LayerParameter"
		sed -n "/syntax/,/message LayerParameter/p" $2/common/caffe.proto > $2/common/Top2LayerParameter.txt # from the top to the line of "message LayerParameter"
		Top2LayerParameter_file_line_num=$(awk 'END{print NR}' $2/common/Top2LayerParameter.txt) # the end line num of the file
		Line_num_1=`expr $Top2LayerParameter_file_line_num + $LayerParameter_file_line_num - 1` # the place to plugin in 
        # first "plugin in" of caffe.proto
		sed -i "$Line_num_1 s/^/$(echo "  optional $4"Parameter" ${custom_operator_name_caffe_proto} = $this_operator_num\;")\n/" $2/common/caffe.proto
		# plugin the above file to caffe.proto (the second plugin)
		cat $2/common/"$op_name"Parameter_caffe_proto.txt >> $2/common/caffe.proto
        rm -rf $2/common/caffe_customer.proto
        rm -rf $2/common/"$op_name"Parameter_caffe_proto.txt
		rm -rf $2/common/LayerParameter.txt
		rm -rf $2/common/Top2LayerParameter.txt
}
