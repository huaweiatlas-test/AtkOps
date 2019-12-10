#!/bin/bash

# plugin in
# parser optional !!!
poi=0 # parser_optional_id
poit_enum_id=0 # parser optional type id in the enum situation
poit=0 # parser_optional_id_type, i.e, the whole num of optional paramters
poi_enum=0 # whether the parameter tyep is enum or not
layer_param_po_num=0 # xxxParameter parameter number of parser optional
for ID in $optional_parameter
do  # C30
    if [ "$version" == "C30" ];then
		# add type BOOL, INT, FLOAT
		poit=0
		for ID_type in $optional_type_parameter
		do 
			if [ $poit == $poit_enum_id ];then
				if [ "$ID_type" == "bool" ];then
		sed -i "$plugin_parser_optional_offset_C30 s/^/$(echo "\
    if(param.has_"$ID"()) ")\n/"                                                                                                  $dir_op_name/plugin/$op_name"_parser_C30.cpp" 
		sed -i "$(($plugin_parser_optional_offset_C30+1)) s/^/$(echo "\
    {")\n/"                                                                                                                       $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_parser_optional_offset_C30+2)) s/^/$(echo "\
        op_dest.SetAttr(\""$ID"\", AttrValue::CreateFrom<AttrValue::BOOL>(param."$ID"()));  ")\n/"                                $dir_op_name/plugin/$op_name"_parser_C30.cpp"
		sed -i "$(($plugin_parser_optional_offset_C30+3)) s/^/$(echo "\
    }")\n/"                                                                                                                       $dir_op_name/plugin/$op_name"_parser_C30.cpp"
				elif [ "$ID_type" == "float" ];then
		sed -i "$plugin_parser_optional_offset_C30 s/^/$(echo "\
    if(param.has_"$ID"()) ")\n/"                                                                                                  $dir_op_name/plugin/$op_name"_parser_C30.cpp" 
		sed -i "$(($plugin_parser_optional_offset_C30+1)) s/^/$(echo "\
    {")\n/"                                                                                                                       $dir_op_name/plugin/$op_name"_parser_C30.cpp"
		sed -i "$(($plugin_parser_optional_offset_C30+2)) s/^/$(echo "\
        op_dest.SetAttr(\""$ID"\", AttrValue::CreateFrom<AttrValue::FLOAT>(param."$ID"()));  ")\n/"                               $dir_op_name/plugin/$op_name"_parser_C30.cpp"
		sed -i "$(($plugin_parser_optional_offset_C30+3)) s/^/$(echo "\
    }")\n/"                                                                                                                       $dir_op_name/plugin/$op_name"_parser_C30.cpp"
				elif [ "$ID_type" == "string" ];then
		sed -i "$plugin_parser_optional_offset_C30 s/^/$(echo "\
    if(param.has_"$ID"()) ")\n/"                                                                                                  $dir_op_name/plugin/$op_name"_parser_C30.cpp" 
		sed -i "$(($plugin_parser_optional_offset_C30+1)) s/^/$(echo "\
    {")\n/"                                                                                                                       $dir_op_name/plugin/$op_name"_parser_C30.cpp"
    sed -i "$(($plugin_parser_optional_offset_C30+2)) s/^/$(echo "\
        op_dest.SetAttr(\""$ID"\", AttrValue::CreateFrom<AttrValue::STR>(param."$ID"()));  ")\n/"                                 $dir_op_name/plugin/$op_name"_parser_C30.cpp"
		sed -i "$(($plugin_parser_optional_offset_C30+3)) s/^/$(echo "\
    }")\n/"                                                                                                                       $dir_op_name/plugin/$op_name"_parser_C30.cpp"
				else   # int, int32, uint32, int64, etc.
					poi_enum=0
					for ID_enum in $enum_parameter
					do
						if [ "$ID_type" == "$ID_enum" ];then
							poi_enum=1
                            # to extract the enum struct
							sed -n "/enum $ID_enum/,/}/p" $current_path/common/file.txt > $current_path/common/"$ID_enum".txt # extract information: enum 
							# to extract the member of this enum struct
                            enum_optional=$(awk '$2 == "=" {print $1}' $current_path/common/"$ID_enum".txt)
							enum_optional_num=0
                            # to count the member number of this enum struct
							for enum_optional_id in $enum_optional
							do
								enum_optional_num=$(($enum_optional_num+1))
							done
					sed -i "$(($plugin_parser_optional_offset_C30)) s/^/$(echo "\
    std::map<caffe::"$op_name"Parameter_"$ID_enum", std::string> "$ID"_map = {  ")\n/"                                            $dir_op_name/plugin/$op_name"_parser_C30.cpp"
							enum_optional_name_id=1 # the parameter num, the maximum number is enum_optional_num
							for enum_optional_name in $enum_optional	
							do
                                # come to the final enum member
								if [ "$enum_optional_name_id" == "$enum_optional_num" ];then
					sed -i "$((plugin_parser_optional_offset_C30+enum_optional_name_id)) s/^/$(echo "\
		{ caffe::"$op_name"Parameter_"$ID_enum"_"$enum_optional_name", \""$enum_optional_name"\" }  ")\n/"                            $dir_op_name/plugin/$op_name"_parser_C30.cpp"
								else
					sed -i "$((plugin_parser_optional_offset_C30+enum_optional_name_id)) s/^/$(echo "\
		{ caffe::"$op_name"Parameter_"$ID_enum"_"$enum_optional_name", \""$enum_optional_name"\" },  ")\n/"                           $dir_op_name/plugin/$op_name"_parser_C30.cpp"
								fi
							    enum_optional_name_id=$(($enum_optional_name_id+1))
							done
		sed -i "$(($plugin_parser_optional_offset_C30+$enum_optional_name_id)) s/^/$(echo "\
    };")\n/"                                                                                                                      $dir_op_name/plugin/$op_name"_parser_C30.cpp"
        # it comes to the parser parameter part
		sed -i "$(($plugin_parser_optional_offset_C30+$enum_optional_name_id+1))  s/^/$(echo "\
    if(param.has_"$ID"()) ")\n/"                                                                                                  $dir_op_name/plugin/$op_name"_parser_C30.cpp" 
		sed -i "$(($plugin_parser_optional_offset_C30+$enum_optional_name_id+2)) s/^/$(echo "\
    {")\n/"                                                                                                                       $dir_op_name/plugin/$op_name"_parser_C30.cpp"
		sed -i "$(($plugin_parser_optional_offset_C30+$enum_optional_name_id+3)) s/^/$(echo "\
		    op_dest.SetAttr(\""$ID"\", AttrValue::CreateFrom<AttrValue::STR>("$ID"_map[param."$ID"()]));  ")\n/"                      $dir_op_name/plugin/$op_name"_parser_C30.cpp"
		sed -i "$(($plugin_parser_optional_offset_C30+$enum_optional_name_id+4)) s/^/$(echo "  \
    }")\n/"                                                                                                                       $dir_op_name/plugin/$op_name"_parser_C30.cpp"
						poi=$(($poi+$enum_optional_name_id+1)) # add the enum parameter offsets
						fi
					done
                    # it comes to the int part (including int32, uint32, int64, etc) and other parameters.
					if [ "$poi_enum" == 0 ];then
                        # particulary to handle the int dtype
                        if [[ "$ID_type" == "int32" ]]||[[ "$ID_type" == "uint32" ]]||\
                    [[ "$ID_type" == "int64" ]]||[[ "$ID_type" == "uint64" ]]||[[ "$ID_type" == "int" ]];then 
		sed -i "$plugin_parser_optional_offset_C30 s/^/$(echo "\
    if(param.has_"$ID"()) ")\n/"                                                                                                  $dir_op_name/plugin/$op_name"_parser_C30.cpp" 
		sed -i "$(($plugin_parser_optional_offset_C30+1)) s/^/$(echo "\
    {")\n/"                                                                                                                       $dir_op_name/plugin/$op_name"_parser_C30.cpp"
		sed -i "$(($plugin_parser_optional_offset_C30+2)) s/^/$(echo "\
       op_dest.SetAttr(\""$ID"\", AttrValue::CreateFrom<AttrValue::INT>(param."$ID"()));  ")\n/"                                  $dir_op_name/plugin/$op_name"_parser_C30.cpp"
			sed -i "$(($plugin_parser_optional_offset_C30+3)) s/^/$(echo "\
    }")\n/"                                                                                                                       $dir_op_name/plugin/$op_name"_parser_C30.cpp"
                        else 
                            layer_param_po_num=$(($layer_param_po_num+1))
                        fi                                      
					fi
				fi
			fi
			poit=$(($poit+4))
		done
		poi=$(($poi+4))
		poit_enum_id=$(($poit_enum_id+4))
	fi
done
poi=$(($poi-1)) # set to control the precice place!
poi=$(($poi-$layer_param_po_num*4))

