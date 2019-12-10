#! /bin/bash

# builder optional !!!
id_b=0
id_r=0
boid=0
boi_enum=0 
layer_param_br_num=0
for ID_B in $optional_parameter
do
	id_r=0
	for ID_R in $optional_type_parameter
	do 
	    if [ $id_b == $id_r ]
	    then  # C30
	       if [ "$version" == "C30" ];then
	           if [ "$ID_R" == "bool" ];then
		           var_line_num_ori=$(grep -rn "optional $ID_R $ID_B " $current_path/common/file.txt | awk '{print $1}')
		           var_line_num=${var_line_num_ori%:*}
		           var_full=`sed -n "$var_line_num"p $current_path/common/file.txt` # get the sentence of $ID_B from caffe.proto
		           sed -n "$var_line_num"p $current_path/common/file.txt > $current_path/common/"$ID_B".txt # get the sentence file of $ID_B from caffe.proto
		           if [ `grep -c "default" $current_path/common/"$ID_B".txt` -eq '0' ];then
				        var_cut_bracket=false
		           else
						var_cut_default=${var_full#*"default"}  # cut "default"
						var_cut_equal=${var_cut_default#*"="}   # cut "="
						var_cut_bracket_origin=${var_cut_equal%]*}     # cut "]"
						var_cut_left_blank=${var_cut_bracket_origin#*" "}     # cut left blank
						var_cut_right_blank=${var_cut_left_blank%*}     # cut right blank
						var_cut_bracket=$var_cut_right_blank # rename the final default parameter type as var_cut_bracket 
		           fi
				   rm -rf $current_path/common/"$ID_B".txt
				   sed -i "$((plugin_builder_optional_offset_C30+poi+prid)) s/^/$(echo "\
    $ID_R $ID_B = $var_cut_bracket;")\n/"                                                                                         $dir_op_name/plugin/$op_name"_parser_C30.cpp"
				   sed -i "$(($plugin_builder_optional_offset_C30+$poi+$prid+1)) s/^/$(echo "\
    ge::AttrValue "$ID_B"AttrValue;")\n/"                                                                                         $dir_op_name/plugin/$op_name"_parser_C30.cpp"
				   sed -i "$(($plugin_builder_optional_offset_C30+$poi+$prid+2)) s/^/$(echo "\
    if ((ge::GRAPH_SUCCESS != op.GetAttr(\""$ID_B"\", "$ID_B"AttrValue))")\n/"                                                    $dir_op_name/plugin/$op_name"_parser_C30.cpp"
				   sed -i "$(($plugin_builder_optional_offset_C30+$poi+$prid+3)) s/^/$(echo "\
	    || (ge::GRAPH_SUCCESS != "$ID_B"AttrValue.GetValue<ge::AttrValue::BOOL>("$ID_B")))")\n/"                                    $dir_op_name/plugin/$op_name"_parser_C30.cpp"
				   sed -i "$(($plugin_builder_optional_offset_C30+$poi+$prid+4)) s/^/$(echo "\
    {")\n/"                                                                                                                       $dir_op_name/plugin/$op_name"_parser_C30.cpp"
				   sed -i "$(($plugin_builder_optional_offset_C30+$poi+$prid+5)) s/^/$(echo "\
	    printf(\"Can not GetOpAttr "$ID_B"!\\\n\");")\n/"                                                                           $dir_op_name/plugin/$op_name"_parser_C30.cpp"
				   sed -i "$(($plugin_builder_optional_offset_C30+$poi+$prid+6)) s/^/$(echo "\
    }")\n/"                                                                                                                       $dir_op_name/plugin/$op_name"_parser_C30.cpp"
               elif [ "$ID_R" == "float" ];then
				   var_line_num_ori=$(grep -rn "optional $ID_R $ID_B " $current_path/common/file.txt | awk '{print $1}')
				   var_line_num=${var_line_num_ori%:*}
				   var_full=`sed -n "$var_line_num"p $current_path/common/file.txt` # get the sentence of $ID_B from caffe.proto
				   sed -n "$var_line_num"p $current_path/common/file.txt > $current_path/common/"$ID_B".txt # get the sentence file of $ID_B from caffe.proto
				   if [ `grep -c "default" $current_path/common/"$ID_B".txt` -eq '0' ];then
						var_cut_bracket=0.0
				   else
						var_cut_default=${var_full#*"default"}  # cut "default"
						var_cut_equal=${var_cut_default#*"="}   # cut "="
						var_cut_bracket_origin=${var_cut_equal%]*}     # cut "]"
						var_cut_left_blank=${var_cut_bracket_origin#*" "}     # cut left blank
						var_cut_right_blank=${var_cut_left_blank%*}     # cut right blank
						var_cut_bracket=$var_cut_right_blank # rename the final default parameter type as var_cut_bracket 
				   fi 
				   rm -rf $current_path/common/"$ID_B".txt
				   sed -i "$((plugin_builder_optional_offset_C30+poi+prid)) s/^/$(echo "\
    $ID_R $ID_B = $var_cut_bracket;")\n/"                                                                                         $dir_op_name/plugin/$op_name"_parser_C30.cpp"
				   sed -i "$(($plugin_builder_optional_offset_C30+$poi+$prid+1)) s/^/$(echo "\
    ge::AttrValue "$ID_B"AttrValue;")\n/"                                                                                         $dir_op_name/plugin/$op_name"_parser_C30.cpp"
				   sed -i "$(($plugin_builder_optional_offset_C30+$poi+$prid+2)) s/^/$(echo "\
    if ((ge::GRAPH_SUCCESS != op.GetAttr(\""$ID_B"\", "$ID_B"AttrValue))")\n/"                                                    $dir_op_name/plugin/$op_name"_parser_C30.cpp"
				   sed -i "$(($plugin_builder_optional_offset_C30+$poi+$prid+3)) s/^/$(echo "\
	    || (ge::GRAPH_SUCCESS != "$ID_B"AttrValue.GetValue<ge::AttrValue::FLOAT>("$ID_B")))")\n/"                                   $dir_op_name/plugin/$op_name"_parser_C30.cpp"
				   sed -i "$(($plugin_builder_optional_offset_C30+$poi+$prid+4)) s/^/$(echo "\
    {")\n/"                                                                                                                       $dir_op_name/plugin/$op_name"_parser_C30.cpp"
				   sed -i "$(($plugin_builder_optional_offset_C30+$poi+$prid+5)) s/^/$(echo "\
	    printf(\"Can not GetOpAttr "$ID_B"!\\\n\");")\n/"                                                                           $dir_op_name/plugin/$op_name"_parser_C30.cpp"
				   sed -i "$(($plugin_builder_optional_offset_C30+$poi+$prid+6)) s/^/$(echo "\
    }")\n/"                                                                                                                       $dir_op_name/plugin/$op_name"_parser_C30.cpp"
			   elif [ "$ID_R" == "string" ];then
				   var_line_num_ori=$(grep -rn "optional $ID_R $ID_B " $current_path/common/file.txt | awk '{print $1}')
				   var_line_num=${var_line_num_ori%:*}
				   var_full=`sed -n "$var_line_num"p $current_path/common/file.txt` # get the sentence of $ID_B from caffe.proto
				   sed -n "$var_line_num"p $current_path/common/file.txt > $current_path/common/"$ID_B".txt # get the sentence file of $ID_B from caffe.proto
				         if [ `grep -c "default" $current_path/common/"$ID_B".txt` -eq '0' ];then
						var_cut_bracket=\"""\"
				         else
						var_cut_default=${var_full#*"default"}  # cut "default"
						var_cut_equal=${var_cut_default#*"="}   # cut "="
						var_cut_bracket_origin=${var_cut_equal%]*}     # cut "]"
						var_cut_left_blank=${var_cut_bracket_origin#*" "}     # cut left blank
						var_cut_right_blank=${var_cut_left_blank%*}     # cut right blank
						var_cut_bracket=$var_cut_right_blank # rename the final default parameter type as var_cut_bracket 
				         fi
				   rm -rf $current_path/common/"$ID_B".txt
				   sed -i "$((plugin_builder_optional_offset_C30+poi+prid)) s/^/$(echo "\
    $ID_R $ID_B = $var_cut_bracket;")\n/"                                                                                         $dir_op_name/plugin/$op_name"_parser_C30.cpp"
				   sed -i "$(($plugin_builder_optional_offset_C30+$poi+$prid+1)) s/^/$(echo "\
    ge::AttrValue "$ID_B"AttrValue;")\n/"                                                                                         $dir_op_name/plugin/$op_name"_parser_C30.cpp"
				   sed -i "$(($plugin_builder_optional_offset_C30+$poi+$prid+2)) s/^/$(echo "\
    if ((ge::GRAPH_SUCCESS != op.GetAttr(\""$ID_B"\", "$ID_B"AttrValue))")\n/"                                                    $dir_op_name/plugin/$op_name"_parser_C30.cpp"
				   sed -i "$(($plugin_builder_optional_offset_C30+$poi+$prid+3)) s/^/$(echo "\
	    || (ge::GRAPH_SUCCESS != "$ID_B"AttrValue.GetValue<ge::AttrValue::STR>("$ID_B")))")\n/"                                     $dir_op_name/plugin/$op_name"_parser_C30.cpp"
				   sed -i "$(($plugin_builder_optional_offset_C30+$poi+$prid+4)) s/^/$(echo "\
    {")\n/"                                                                                                                       $dir_op_name/plugin/$op_name"_parser_C30.cpp"
				   sed -i "$(($plugin_builder_optional_offset_C30+$poi+$prid+5)) s/^/$(echo "\
	    printf(\"Can not GetOpAttr "$ID_B"!\\\n\");")\n/"                                                                           $dir_op_name/plugin/$op_name"_parser_C30.cpp"
				   sed -i "$(($plugin_builder_optional_offset_C30+$poi+$prid+6)) s/^/$(echo "\
    }")\n/"                                                                                                                       $dir_op_name/plugin/$op_name"_parser_C30.cpp"
			   else
				     boi_enum=0
				     for ID_enum in $enum_parameter
				     do
					       if [ "$ID_R" == "$ID_enum" ];then
						         boi_enum=1
				         fi
			         done

				   var_line_num_ori=$(grep -rn "optional $ID_R $ID_B " $current_path/common/file.txt | awk '{print $1}')
				   var_line_num=${var_line_num_ori%:*}
				   var_full=`sed -n "$var_line_num"p $current_path/common/file.txt` # get the sentence of $ID_B from caffe.proto
				   sed -n "$var_line_num"p $current_path/common/file.txt > $current_path/common/"$ID_B".txt # get the sentence file of $ID_B from caffe.proto
	               if [ `grep -c "default" $current_path/common/"$ID_B".txt` -eq '0' ];then
					       if [ "$boi_enum" == "1" ];then
						        var_cut_bracket=" "
					       else
						        var_cut_bracket=0
					       fi
	               else
							 var_cut_default=${var_full#*"default"}  # cut "default"
							 var_cut_equal=${var_cut_default#*"="}   # cut "="
							 var_cut_bracket_origin=${var_cut_equal%]*}     # cut "]"
							 var_cut_left_blank=${var_cut_bracket_origin#*" "}     # cut left blank
							 var_cut_right_blank=${var_cut_left_blank%*}     # cut right blank
							 var_cut_bracket=$var_cut_right_blank # rename the final default parameter type as var_cut_bracket 
				   fi
				   rm -rf $current_path/common/"$ID_B".txt

                   if [ "$boi_enum" == 1 ];then
				   sed -i "$((plugin_builder_optional_offset_C30+poi+prid)) s/^/$(echo "\
    string $ID_B = \""$var_cut_bracket"\";")\n/"                                                                                  $dir_op_name/plugin/$op_name"_parser_C30.cpp"
				   sed -i "$(($plugin_builder_optional_offset_C30+$poi+$prid+1)) s/^/$(echo "\
    ge::AttrValue "$ID_B"AttrValue;")\n/" $dir_op_name/plugin/$op_name"_parser_C30.cpp"
				   sed -i "$(($plugin_builder_optional_offset_C30+$poi+$prid+2)) s/^/$(echo "\
    if ((ge::GRAPH_SUCCESS != op.GetAttr(\""$ID_B"\", "$ID_B"AttrValue))")\n/"                                                    $dir_op_name/plugin/$op_name"_parser_C30.cpp"
           sed -i "$(($plugin_builder_optional_offset_C30+$poi+$prid+3)) s/^/$(echo "\
	    || (ge::GRAPH_SUCCESS != "$ID_B"AttrValue.GetValue<ge::AttrValue::STR>("$ID_B")))")\n/"                                     $dir_op_name/plugin/$op_name"_parser_C30.cpp"
           sed -i "$(($plugin_builder_optional_offset_C30+$poi+$prid+4)) s/^/$(echo "\
    {")\n/"                                                                                                                       $dir_op_name/plugin/$op_name"_parser_C30.cpp"
				   sed -i "$(($plugin_builder_optional_offset_C30+$poi+$prid+5)) s/^/$(echo "\
	    printf(\"Can not GetOpAttr "$ID_B"!\\\n\");")\n/"                                                                           $dir_op_name/plugin/$op_name"_parser_C30.cpp"
				   sed -i "$(($plugin_builder_optional_offset_C30+$poi+$prid+6)) s/^/$(echo "\
    }")\n/"                                                                                                                       $dir_op_name/plugin/$op_name"_parser_C30.cpp"
                   elif [[ "$ID_R" == "int32" ]]||[[ "$ID_R" == "uint32" ]]||[[ "$ID_R" == "int64" ]]||[[ "$ID_R" == "uint64" ]]||[[ "$ID_R" == "int" ]];then
				   sed -i "$((plugin_builder_optional_offset_C30+poi+prid)) s/^/$(echo "\
    $ID_R $ID_B = $var_cut_bracket;")\n/"                                                                                         $dir_op_name/plugin/$op_name"_parser_C30.cpp"
				   sed -i "$(($plugin_builder_optional_offset_C30+$poi+$prid+1)) s/^/$(echo "\
    ge::AttrValue "$ID_B"AttrValue;")\n/" $dir_op_name/plugin/$op_name"_parser_C30.cpp"
				   sed -i "$(($plugin_builder_optional_offset_C30+$poi+$prid+2)) s/^/$(echo "\
    if ((ge::GRAPH_SUCCESS != op.GetAttr(\""$ID_B"\", "$ID_B"AttrValue))")\n/"                                                    $dir_op_name/plugin/$op_name"_parser_C30.cpp"
           sed -i "$(($plugin_builder_optional_offset_C30+$poi+$prid+3)) s/^/$(echo "\
	    || (ge::GRAPH_SUCCESS != "$ID_B"AttrValue.GetValue<ge::AttrValue::INT>("$ID_B")))")\n/"                                     $dir_op_name/plugin/$op_name"_parser_C30.cpp"
           sed -i "$(($plugin_builder_optional_offset_C30+$poi+$prid+4)) s/^/$(echo "\
    {")\n/"                                                                                                                       $dir_op_name/plugin/$op_name"_parser_C30.cpp"
				   sed -i "$(($plugin_builder_optional_offset_C30+$poi+$prid+5)) s/^/$(echo "\
	    printf(\"Can not GetOpAttr "$ID_B"!\\\n\");")\n/"                                                                           $dir_op_name/plugin/$op_name"_parser_C30.cpp"
				   sed -i "$(($plugin_builder_optional_offset_C30+$poi+$prid+6)) s/^/$(echo "\
    }")\n/"                                                                                                                       $dir_op_name/plugin/$op_name"_parser_C30.cpp"
                   else
                       layer_param_br_num=$(($layer_param_br_num+1))
                   fi
              fi
           fi
	    fi
    	id_r=$(($id_r+5))
	done
	id_b=$(($id_b+5))
	boid=$(($boid+7))
done
boid=$(($boid-$layer_param_br_num*7))
