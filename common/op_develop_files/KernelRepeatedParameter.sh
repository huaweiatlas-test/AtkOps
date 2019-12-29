#! /bin/bash

# kernel repeated !!!
id_re_bin=0
krid=0 # kernel repeated id
krid_for=0 # specified id in for cycle
for ID_RE_BIN in $repeated_parameter
do
	if [ "$version" == "C30" ];then # C30
		# add type BOOL, INT, FLOAT
		krid_for=0 # builder repeated id
		for ID_RE_BIN_type in $repeated_type_parameter
		do 
			if [ $id_re_bin == $krid_for ];then
				if [ "$ID_RE_BIN_type" == "float" ];then
					sed -i "$((plugin_kernel_repeated_offset_C30+poi+prid+boid+brid+koid)) s/^/$(echo "\
	vector<"$ID_RE_BIN_type"> "$ID_RE_BIN""";")\n/"                                                                               $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_kernel_repeated_offset_C30+$poi+$prid+$boid+$brid+$koid+1)) s/^/$(echo "\
	ge::AttrValue "$ID_RE_BIN"AttrValue;")\n/"                                                                                    $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_kernel_repeated_offset_C30+$poi+$prid+$boid+$brid+$koid+2)) s/^/$(echo "\
	if ((ge::GRAPH_SUCCESS != op.GetAttr(\""$ID_RE_BIN"\", "$ID_RE_BIN"AttrValue))")\n/"                                          $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_kernel_repeated_offset_C30+$poi+$prid+$boid+$brid+$koid+3)) s/^/$(echo "\
		|| (ge::GRAPH_SUCCESS != "$ID_RE_BIN"AttrValue.GetValue<ge::AttrValue::LIST_FLOAT>("$ID_RE_BIN")))")\n/"                    $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_kernel_repeated_offset_C30+$poi+$prid+$boid+$brid+$koid+4)) s/^/$(echo "\
	{")\n/"                                                                                                                       $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_kernel_repeated_offset_C30+$poi+$prid+$boid+$brid+$koid+5)) s/^/$(echo "\
		printf(\"Can not GetOpAttr "$ID_RE_BIN"!\\\n\");")\n/"                                                                      $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_kernel_repeated_offset_C30+$poi+$prid+$boid+$brid+$koid+6)) s/^/$(echo "\
	}")\n/"                                                                                                                       $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_kernel_repeated_offset_C30+$poi+$prid+$boid+$brid+$koid+7)) s/^/$(echo "\
	PyObject *py_"$ID_RE_BIN" = PyTuple_New("$ID_RE_BIN".size());")\n/"                                                           $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_kernel_repeated_offset_C30+$poi+$prid+$boid+$brid+$koid+8)) s/^/$(echo "\
	for(int i = 0; i< "$ID_RE_BIN".size(); i++)")\n/"                                                                             $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_kernel_repeated_offset_C30+$poi+$prid+$boid+$brid+$koid+9)) s/^/$(echo "\
		PyTuple_SetItem(py_"$ID_RE_BIN", i, Py_BuildValue(\"f\", "$ID_RE_BIN"[i]));")\n/"                                           $dir_op_name/plugin/$op_name"_parser_C30.cpp"
				elif [ "ID_RE_BIN_type" == "bool" ];then
					sed -i "$((plugin_kernel_repeated_offset_C30+poi+prid+boid+brid+koid)) s/^/$(echo "\
	vector<"$ID_RE_BIN_type"> "$ID_RE_BIN""";")\n/"                                                                               $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_kernel_repeated_offset_C30+$poi+$prid+$boid+$brid+$koid+1)) s/^/$(echo "\
	ge::AttrValue "$ID_RE_BIN"AttrValue;")\n/"                                                                                    $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_kernel_repeated_offset_C30+$poi+$prid+$boid+$brid+$koid+2)) s/^/$(echo "\
	if ((ge::GRAPH_SUCCESS != op.GetAttr(\""$ID_RE_BIN"\", "$ID_RE_BIN"AttrValue))")\n/"                                          $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_kernel_repeated_offset_C30+$poi+$prid+$boid+$brid+$koid+3)) s/^/$(echo "\
		|| (ge::GRAPH_SUCCESS != "$ID_RE_BIN"AttrValue.GetValue<ge::AttrValue::LIST_BOOL>("$ID_RE_BIN")))")\n/"                     $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_kernel_repeated_offset_C30+$poi+$prid+$boid+$brid+$koid+4)) s/^/$(echo "\
	{")\n/"                                                                                                                       $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_kernel_repeated_offset_C30+$poi+$prid+$boid+$brid+$koid+5)) s/^/$(echo "\
		printf(\"Can not GetOpAttr "$ID_RE_BIN"!\\\n\");")\n/"                                                                      $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_kernel_repeated_offset_C30+$poi+$prid+$boid+$brid+$koid+6)) s/^/$(echo "\
	}")\n/"                                                                                                                       $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_kernel_repeated_offset_C30+$poi+$prid+$boid+$brid+$koid+7)) s/^/$(echo "\
	PyObject *py_"$ID_RE_BIN" = PyTuple_New("$ID_RE_BIN".size());")\n/"                                                           $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_kernel_repeated_offset_C30+$poi+$prid+$boid+$brid+$koid+8)) s/^/$(echo "\
	for(int i = 0; i< "$ID_RE_BIN".size(); i++)")\n/"                                                                             $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_kernel_repeated_offset_C30+$poi+$prid+$boid+$brid+$koid+9)) s/^/$(echo "\
		PyTuple_SetItem(py_"$ID_RE_BIN", i, Py_BuildValue(\"b\", "$ID_RE_BIN"[i]));")\n/"                                           $dir_op_name/plugin/$op_name"_parser_C30.cpp"
				elif [ "ID_RE_BIN_type" == "string" ];then
					sed -i "$((plugin_kernel_repeated_offset_C30+poi+prid+boid+brid+koid)) s/^/$(echo "\
	vector<"$ID_RE_BIN_type"> "$ID_RE_BIN""";")\n/"                                                                               $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_kernel_repeated_offset_C30+$poi+$prid+$boid+$brid+$koid+1)) s/^/$(echo "\
	ge::AttrValue "$ID_RE_BIN"AttrValue;")\n/"                                                                                    $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_kernel_repeated_offset_C30+$poi+$prid+$boid+$brid+$koid+2)) s/^/$(echo "\
	if ((ge::GRAPH_SUCCESS != op.GetAttr(\""$ID_RE_BIN"\", "$ID_RE_BIN"AttrValue))")\n/"                                          $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_kernel_repeated_offset_C30+$poi+$prid+$boid+$brid+$koid+3)) s/^/$(echo "\
		|| (ge::GRAPH_SUCCESS != "$ID_RE_BIN"AttrValue.GetValue<ge::AttrValue::LIST_STR>("$ID_RE_BIN")))")\n/"                      $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_kernel_repeated_offset_C30+$poi+$prid+$boid+$brid+$koid+4)) s/^/$(echo "\
	{")\n/"                                                                                                                       $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_kernel_repeated_offset_C30+$poi+$prid+$boid+$brid+$koid+5)) s/^/$(echo "\
		printf(\"Can not GetOpAttr "$ID_RE_BIN"!\\\n\");")\n/"                                                                      $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_kernel_repeated_offset_C30+$poi+$prid+$boid+$brid+$koid+6)) s/^/$(echo "\
	}")\n/"                                                                                                                       $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_kernel_repeated_offset_C30+$poi+$prid+$boid+$brid+$koid+7)) s/^/$(echo "\
	PyObject *py_"$ID_RE_BIN" = PyTuple_New("$ID_RE_BIN".size());")\n/"                                                           $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_kernel_repeated_offset_C30+$poi+$prid+$boid+$brid+$koid+8)) s/^/$(echo "\
	for(int i = 0; i< "$ID_RE_BIN".size(); i++)")\n/"                                                                             $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_kernel_repeated_offset_C30+$poi+$prid+$boid+$brid+$koid+9)) s/^/$(echo "\
		PyTuple_SetItem(py_"$ID_RE_BIN", i, Py_BuildValue(\"s\", "$ID_RE_BIN"[i]));")\n/"                                           $dir_op_name/plugin/$op_name"_parser_C30.cpp"
				elif [[ "$ID_RE_BIN_type" == "int32" ]]||[[ "$ID_RE_BIN_type" == "uint32" ]]||\
        [[ "$ID_RE_BIN_type" == "int64" ]]||[[ "$ID_RE_BIN_type" == "uint64" ]]||[[ "$ID_RE_BIN_type" == "int" ]];then
					sed -i "$((plugin_kernel_repeated_offset_C30+poi+prid+boid+brid+koid)) s/^/$(echo "\
	vector<"$ID_RE_BIN_type"> "$ID_RE_BIN""";")\n/"                                                                               $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_kernel_repeated_offset_C30+$poi+$prid+$boid+$brid+$koid+1)) s/^/$(echo "\
	ge::AttrValue "$ID_RE_BIN"AttrValue;")\n/"                                                                                    $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_kernel_repeated_offset_C30+$poi+$prid+$boid+$brid+$koid+2)) s/^/$(echo "\
	if ((ge::GRAPH_SUCCESS != op.GetAttr(\""$ID_RE_BIN"\", "$ID_RE_BIN"AttrValue))")\n/"                                          $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_kernel_repeated_offset_C30+$poi+$prid+$boid+$brid+$koid+3)) s/^/$(echo "\
		|| (ge::GRAPH_SUCCESS != "$ID_RE_BIN"AttrValue.GetValue<ge::AttrValue::LIST_INT>("$ID_RE_BIN")))")\n/"                      $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_kernel_repeated_offset_C30+$poi+$prid+$boid+$brid+$koid+4)) s/^/$(echo "\
	{")\n/"                                                                                                                       $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_kernel_repeated_offset_C30+$poi+$prid+$boid+$brid+$koid+5)) s/^/$(echo "\
		printf(\"Can not GetOpAttr "$ID_RE_BIN"!\\\n\");")\n/"                                                                      $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_kernel_repeated_offset_C30+$poi+$prid+$boid+$brid+$koid+6)) s/^/$(echo "\
	}")\n/"                                                                                                                       $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_kernel_repeated_offset_C30+$poi+$prid+$boid+$brid+$koid+7)) s/^/$(echo "\
	PyObject *py_"$ID_RE_BIN" = PyTuple_New("$ID_RE_BIN".size());")\n/"                                                           $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_kernel_repeated_offset_C30+$poi+$prid+$boid+$brid+$koid+8)) s/^/$(echo "\
	for(int i = 0; i< "$ID_RE_BIN".size(); i++)")\n/"                                                                             $dir_op_name/plugin/$op_name"_parser_C30.cpp"
					sed -i "$(($plugin_kernel_repeated_offset_C30+$poi+$prid+$boid+$brid+$koid+9)) s/^/$(echo "\
		PyTuple_SetItem(py_"$ID_RE_BIN", i, Py_BuildValue(\"i\", "$ID_RE_BIN"[i]));")\n/"                                           $dir_op_name/plugin/$op_name"_parser_C30.cpp"
				fi
			fi
		krid_for=$(($krid_for+15))
		done
	fi
	krid=$(($krid+10))
done
 
