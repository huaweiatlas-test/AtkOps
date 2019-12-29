#! /bin/bash

# builder repeated !!!
id_re=0
brid=0 # builder repeated id
brid_for=0 # for cycle specified id
for ID_RE in $repeated_parameter
do  # C30
	if [ "$version" == "C30" ];then
		# add type BOOL, INT, FLOAT
		brid_for=0 # builder repeated id
		for ID_RE_type in $repeated_type_parameter
		do 
			if [ $id_re == $brid_for ];then
				if [ "$ID_RE_type" == "float" ];then
					sed -i "$((plugin_builder_repeated_offset_C30+poi+prid+boid)) s/^/$(echo "\
    vector<"$ID_RE_type"> "$ID_RE";")\n/"                                                                                         $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_builder_repeated_offset_C30+$poi+$prid+$boid+1)) s/^/$(echo "\
    ge::AttrValue "$ID_RE"AttrValue;")\n/"                                                                                        $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_builder_repeated_offset_C30+$poi+$prid+$boid+2)) s/^/$(echo "\
    if ((ge::GRAPH_SUCCESS != op.GetAttr(\""$ID_RE"\", "$ID_RE"AttrValue))")\n/"                                                  $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_builder_repeated_offset_C30+$poi+$prid+$boid+3)) s/^/$(echo "\
	    || (ge::GRAPH_SUCCESS != "$ID_RE"AttrValue.GetValue<ge::AttrValue::LIST_FLOAT>("$ID_RE")))")\n/"                            $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_builder_repeated_offset_C30+$poi+$prid+$boid+4)) s/^/$(echo "\
    {")\n/"                                                                                                                       $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_builder_repeated_offset_C30+$poi+$prid+$boid+5)) s/^/$(echo "\
	    printf(\"Can not GetOpAttr "$ID_RE"!\\\n\");")\n/"                                                                          $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_builder_repeated_offset_C30+$poi+$prid+$boid+6)) s/^/$(echo "\
    }")\n/"                                                                                                                       $dir_op_name/plugin/$op_name"_parser_C30.cpp"
				elif [ "ID_RE_type" == "bool" ];then
					sed -i "$((plugin_builder_repeated_offset_C30+poi+prid+boid)) s/^/$(echo "\
    vector<"$ID_RE_type"> "$ID_RE";")\n/"                                                                                         $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_builder_repeated_offset_C30+$poi+$prid+$boid+1)) s/^/$(echo "\
    ge::AttrValue "$ID_RE"AttrValue;")\n/"                                                                                        $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_builder_repeated_offset_C30+$poi+$prid+$boid+2)) s/^/$(echo "\
    if ((ge::GRAPH_SUCCESS != op.GetAttr(\""$ID_RE"\", "$ID_RE"AttrValue))")\n/"                                                  $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_builder_repeated_offset_C30+$poi+$prid+$boid+3)) s/^/$(echo "\
	    || (ge::GRAPH_SUCCESS != "$ID_RE"AttrValue.GetValue<ge::AttrValue::LIST_BOOL>("$ID_RE")))")\n/"                             $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_builder_repeated_offset_C30+$poi+$prid+$boid+4)) s/^/$(echo "\
    {")\n/"                                                                                                                       $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_builder_repeated_offset_C30+$poi+$prid+$boid+5)) s/^/$(echo "\
	    printf(\"Can not GetOpAttr "$ID_RE"!\\\n\");")\n/"                                                                          $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_builder_repeated_offset_C30+$poi+$prid+$boid+6)) s/^/$(echo "\
    }")\n/"                                                                                                                       $dir_op_name/plugin/$op_name"_parser_C30.cpp"
				elif [ "ID_RE_type" == "string" ];then
					sed -i "$((plugin_builder_repeated_offset_C30+poi+prid+boid)) s/^/$(echo "\
    vector<"$ID_RE_type"> "$ID_RE";")\n/"                                                                                         $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_builder_repeated_offset_C30+$poi+$prid+$boid+1)) s/^/$(echo "\
    ge::AttrValue "$ID_RE"AttrValue;")\n/"                                                                                        $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_builder_repeated_offset_C30+$poi+$prid+$boid+2)) s/^/$(echo "\
    if ((ge::GRAPH_SUCCESS != op.GetAttr(\""$ID_RE"\", "$ID_RE"AttrValue))")\n/"                                                  $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_builder_repeated_offset_C30+$poi+$prid+$boid+3)) s/^/$(echo "\
	    || (ge::GRAPH_SUCCESS != "$ID_RE"AttrValue.GetValue<ge::AttrValue::LIST_STR>("$ID_RE")))")\n/"                              $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_builder_repeated_offset_C30+$poi+$prid+$boid+4)) s/^/$(echo "\
    {")\n/"                                                                                                                       $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_builder_repeated_offset_C30+$poi+$prid+$boid+5)) s/^/$(echo "\
	    printf(\"Can not GetOpAttr "$ID_RE"!\\\n\");")\n/"                                                                          $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_builder_repeated_offset_C30+$poi+$prid+$boid+6)) s/^/$(echo "\
    }")\n/"                                                                                                                       $dir_op_name/plugin/$op_name"_parser_C30.cpp"
				elif [[ "$ID_RE_type" == "int32" ]]||[[ "$ID_RE_type" == "uint32" ]]||\
        [[ "$ID_RE_type" == "int64" ]]||[[ "$ID_RE_type" == "uint64" ]]||[[ "$ID_RE_type" == "int" ]];then 
					sed -i "$((plugin_builder_repeated_offset_C30+poi+prid+boid)) s/^/$(echo "\
    vector<"$ID_RE_type"> "$ID_RE";")\n/"                                                                                         $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_builder_repeated_offset_C30+$poi+$prid+$boid+1)) s/^/$(echo "\
    ge::AttrValue "$ID_RE"AttrValue;")\n/"                                                                                        $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_builder_repeated_offset_C30+$poi+$prid+$boid+2)) s/^/$(echo "\
    if ((ge::GRAPH_SUCCESS != op.GetAttr(\""$ID_RE"\", "$ID_RE"AttrValue))")\n/"                                                  $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_builder_repeated_offset_C30+$poi+$prid+$boid+3)) s/^/$(echo "\
	    || (ge::GRAPH_SUCCESS != "$ID_RE"AttrValue.GetValue<ge::AttrValue::LIST_INT>("$ID_RE")))")\n/"                              $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_builder_repeated_offset_C30+$poi+$prid+$boid+4)) s/^/$(echo "\
    {")\n/"                                                                                                                       $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_builder_repeated_offset_C30+$poi+$prid+$boid+5)) s/^/$(echo "\
	    printf(\"Can not GetOpAttr "$ID_RE"!\\\n\");")\n/"                                                                          $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_builder_repeated_offset_C30+$poi+$prid+$boid+6)) s/^/$(echo "\
    }")\n/"                                                                                                                       $dir_op_name/plugin/$op_name"_parser_C30.cpp"
				fi
			fi
		brid_for=$(($brid_for+10))
		done
	fi
	brid=$(($brid+7))
done
