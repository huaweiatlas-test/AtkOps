#! /bin/bash

# parser repeated !!!
repeated_type_parameter=$(awk '$1 == "repeated" {print $2}' $current_path/common/file.txt)
j=0
for IDR in $repeated_parameter
do  # C30
	if [ "$version" == "C30" ];then
		# add type BOOL, INT, FLOAT
		prid=0 # parse repeated id
		for IDR_type in $repeated_type_parameter
		do 
			if [ $j == $prid ];then
				if [ "$IDR_type" == "float" ];then
					sed -i "$((plugin_parser_repeated_offset_C30+poi)) s/^/$(echo "\
    vector<float> $IDR;")\n/"                                                                                                     $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_parser_repeated_offset_C30+$poi+1)) s/^/$(echo "\
    for(int i = 0; i < param."$IDR"_size(); ++i)")\n/"                                                                            $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_parser_repeated_offset_C30+$poi+2)) s/^/$(echo "\
    {")\n/"                                                                                                                       $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_parser_repeated_offset_C30+$poi+3)) s/^/$(echo "\
        "$IDR".push_back(param."$IDR"(i));")\n/"                                                                                  $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_parser_repeated_offset_C30+$poi+4)) s/^/$(echo "\
    }")\n/"                                                                                                                       $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_parser_repeated_offset_C30+$poi+5)) s/^/$(echo "\
    op_dest.SetAttr(\""$IDR"\", ge::AttrValue::CreateFrom<ge::AttrValue::LIST_FLOAT>("$IDR")); ")\n/"                             $dir_op_name/plugin/$op_name"_parser_C30.cpp"
				elif [ "$IDR_type" == "bool" ];then
					sed -i "$((plugin_parser_repeated_offset_C30+poi)) s/^/$(echo "\
    vector<bool> $IDR;")\n/"                                                                                                      $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_parser_repeated_offset_C30+$poi+1)) s/^/$(echo "\
    for(int i = 0; i < param."$IDR"_size(); ++i)")\n/"                                                                            $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_parser_repeated_offset_C30+$poi+2)) s/^/$(echo "\
    {")\n/"                                                                                                                       $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_parser_repeated_offset_C30+$poi+3)) s/^/$(echo "\
        "$IDR".push_back(param."$IDR"(i));")\n/"                                                                                  $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_parser_repeated_offset_C30+$poi+4)) s/^/$(echo "\
    }")\n/"                                                                                                                       $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_parser_repeated_offset_C30+$poi+5)) s/^/$(echo "\
    op_dest.SetAttr(\""$IDR"\", ge::AttrValue::CreateFrom<ge::AttrValue::LIST_BOOL>("$IDR")); ")\n/"                              $dir_op_name/plugin/$op_name"_parser_C30.cpp"
				elif [ "$IDR_type" == "string" ];then
					sed -i "$((plugin_parser_repeated_offset_C30+poi)) s/^/$(echo "\
        vector<string> $IDR;")\n/"                                                                                                $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_parser_repeated_offset_C30+$poi+1)) s/^/$(echo "\
    for(int i = 0; i < param."$IDR"_size(); ++i)")\n/"                                                                            $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_parser_repeated_offset_C30+$poi+2)) s/^/$(echo "\
    {")\n/"                                                                                                                       $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_parser_repeated_offset_C30+$poi+3)) s/^/$(echo "\
        "$IDR".push_back(param."$IDR"(i));")\n/"                                                                                  $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_parser_repeated_offset_C30+$poi+4)) s/^/$(echo "\
    }")\n/"                                                                                                                       $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_parser_repeated_offset_C30+$poi+5)) s/^/$(echo "\
    op_dest.SetAttr(\""$IDR"\", ge::AttrValue::CreateFrom<ge::AttrValue::LIST_STR>("$IDR")); ")\n/"                               $dir_op_name/plugin/$op_name"_parser_C30.cpp"
				else
                    if [[ "$IDR_type" == "int32" ]]||[[ "$IDR_type" == "uint32" ]]||\
                [[ "$IDR_type" == "int64" ]]||[[ "$IDR_type" == "uint64" ]]||[[ "$IDR_type" == "int" ]];then
					sed -i "$((plugin_parser_repeated_offset_C30+poi)) s/^/$(echo "\
		vector<int> $IDR;")\n/"                                                                                                       $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_parser_repeated_offset_C30+$poi+1)) s/^/$(echo "\
		for(int i = 0; i < param."$IDR"_size(); ++i)")\n/"                                                                            $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_parser_repeated_offset_C30+$poi+2)) s/^/$(echo "\
		{")\n/"                                                                                                                       $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_parser_repeated_offset_C30+$poi+3)) s/^/$(echo "\
		  	"$IDR".push_back(param."$IDR"(i));")\n/"                                                                                  $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_parser_repeated_offset_C30+$poi+4)) s/^/$(echo "\
		}")\n/"                                                                                                                       $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_parser_repeated_offset_C30+$poi+5)) s/^/$(echo "\
		op_dest.SetAttr(\""$IDR"\", ge::AttrValue::CreateFrom<ge::AttrValue::LIST_INT>("$IDR")); ")\n/"                               $dir_op_name/plugin/$op_name"_parser_C30.cpp"
				    fi
                fi
			fi
			prid=$(($prid+6))
		done
	fi
done
