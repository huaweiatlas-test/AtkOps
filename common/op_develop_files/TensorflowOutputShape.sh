#!/bin/bash

sed -i "$(($tf_output_shape_id))   s/^/$(echo "\
    Py_Initialize();  ")\n/"                                                                 $dir_op_name/plugin/"$op_name"_tf_parser.cpp
sed -i "$(($tf_output_shape_id+1))   s/^/$(echo "\
    string chdir_cmd = string(\"sys.path.append('.\/..\/operator')\");  ")\n/"               $dir_op_name/plugin/"$op_name"_tf_parser.cpp
sed -i "$(($tf_output_shape_id+2))   s/^/$(echo "\
    const char* cstr_cmd = chdir_cmd.c_str();  ")\n/"                                        $dir_op_name/plugin/"$op_name"_tf_parser.cpp
sed -i "$(($tf_output_shape_id+3))   s/^/$(echo "\
    PyRun_SimpleString(\"import sys\");   ")\n/"                                             $dir_op_name/plugin/"$op_name"_tf_parser.cpp
sed -i "$(($tf_output_shape_id+4))   s/^/$(echo "\
    PyRun_SimpleString(cstr_cmd);  ")\n/"                                                    $dir_op_name/plugin/"$op_name"_tf_parser.cpp
sed -i "$(($tf_output_shape_id+5))   s/^/$(echo "\
    PyObject* moduleName = PyString_FromString(\""$op_name"OutputWeightShape\");  ")\n/"     $dir_op_name/plugin/"$op_name"_tf_parser.cpp       
sed -i "$(($tf_output_shape_id+6))   s/^/$(echo "\
    PyObject* pModule = PyImport_Import(moduleName);  ")\n/"                                 $dir_op_name/plugin/"$op_name"_tf_parser.cpp    
sed -i "$(($tf_output_shape_id+7))   s/^/$(echo "\
    if (!pModule)  ")\n/"                                                                    $dir_op_name/plugin/"$op_name"_tf_parser.cpp
sed -i "$(($tf_output_shape_id+8))   s/^/$(echo "\
    {  ")\n/"                                                                                $dir_op_name/plugin/"$op_name"_tf_parser.cpp
sed -i "$(($tf_output_shape_id+9))   s/^/$(echo "\
        printf( \"[ERROR] Python get module failed.\");  ")\n/"                              $dir_op_name/plugin/"$op_name"_tf_parser.cpp
sed -i "$(($tf_output_shape_id+10))   s/^/$(echo "\
        return 0;  ")\n/"                                                                    $dir_op_name/plugin/"$op_name"_tf_parser.cpp
sed -i "$(($tf_output_shape_id+11))   s/^/$(echo "\
    }  ")\n/"                                                                                $dir_op_name/plugin/"$op_name"_tf_parser.cpp
sed -i "$(($tf_output_shape_id+12))   s/^/$(echo "\
    printf(\"[INFO] Python get module succeed.\");  ")\n/"                                   $dir_op_name/plugin/"$op_name"_tf_parser.cpp   
sed -i "$(($tf_output_shape_id+13))   s/^/$(echo "\
     PyObject* pv = PyObject_GetAttrString(pModule, \"OutputShape"$op_name"\");   ")\n/"     $dir_op_name/plugin/"$op_name"_tf_parser.cpp
sed -i "$(($tf_output_shape_id+14))   s/^/$(echo "\
    if (!pv || !PyCallable_Check(pv))  ")\n/"                                                $dir_op_name/plugin/"$op_name"_tf_parser.cpp
sed -i "$(($tf_output_shape_id+15))   s/^/$(echo "\
    {  ")\n/"                                                                                $dir_op_name/plugin/"$op_name"_tf_parser.cpp
sed -i "$(($tf_output_shape_id+16))   s/^/$(echo "\
        printf(\"\[ERROR\] Can\'t find function "$op_name"OutputShape\");  ")\n/"            $dir_op_name/plugin/"$op_name"_tf_parser.cpp
sed -i "$(($tf_output_shape_id+17))   s/^/$(echo "\
        return 0;  ")\n/"                                                                    $dir_op_name/plugin/"$op_name"_tf_parser.cpp
sed -i "$(($tf_output_shape_id+18))   s/^/$(echo "\
    }  ")\n/"                                                                                $dir_op_name/plugin/"$op_name"_tf_parser.cpp
sed -i "$(($tf_output_shape_id+19))   s/^/$(echo "\
    printf( \"\[INFO\] Get function "$op_name"OutputShape succeed.\");  ")\n/"               $dir_op_name/plugin/"$op_name"_tf_parser.cpp   
tf_parser_param_id=$(($tf_parser_param_id+20))

for((pyTfInputId=0;pyTfInputId<"$input_num";pyTfInputId++));
do
    sed -i "$(($tf_output_shape_id+pyTfInputId+20)) s/^/$(echo "\
    ge::TensorDesc input"$(($pyTfInputId+1))"_desc = op.GetInputDesc("$pyTfInputId");")\n/"  $dir_op_name/plugin/"$op_name"_tf_parser.cpp
done
tf_parser_param_id=$((tf_parser_param_id+input_num))

output_shape_param_num=$((input_num+param_length+1))
sed -i "$(($tf_output_shape_id+input_num+20)) s/^/$(echo "\
    PyObject* args = PyTuple_New("$output_shape_param_num");   ")\n/"                        $dir_op_name/plugin/"$op_name"_tf_parser.cpp
tf_parser_param_id=$((tf_parser_param_id+1))

# add input
for((pyId=0;pyId<"$input_num";pyId++));
do
    sed -i "$(($tf_output_shape_id+input_num+pyId*10+21)) s/^/$(echo "  \
  PyObject* iarg"$pyId" = PyTuple_New(4); ")\n/"                                                          $dir_op_name/plugin/"$op_name"_tf_parser.cpp     
    sed -i "$(($tf_output_shape_id+input_num+pyId*10+22)) s/^/$(echo "  \
  PyObject* iarg"$pyId"1 = PyInt_FromLong(input"$(($pyId+1))"_desc.GetShape().GetDim("0")); ")\n/"        $dir_op_name/plugin/"$op_name"_tf_parser.cpp
    sed -i "$(($tf_output_shape_id+input_num+pyId*10+23)) s/^/$(echo "  \
  PyObject* iarg"$pyId"2 = PyInt_FromLong(input"$(($pyId+1))"_desc.GetShape().GetDim("1")); ")\n/"        $dir_op_name/plugin/"$op_name"_tf_parser.cpp
    sed -i "$(($tf_output_shape_id+input_num+pyId*10+24)) s/^/$(echo "  \
  PyObject* iarg"$pyId"3 = PyInt_FromLong(input"$(($pyId+1))"_desc.GetShape().GetDim("2")); ")\n/"        $dir_op_name/plugin/"$op_name"_tf_parser.cpp
    sed -i "$(($tf_output_shape_id+input_num+pyId*10+25)) s/^/$(echo "  \
  PyObject* iarg"$pyId"4 = PyInt_FromLong(input"$(($pyId+1))"_desc.GetShape().GetDim("3")); ")\n/"        $dir_op_name/plugin/"$op_name"_tf_parser.cpp
      
    sed -i "$(($tf_output_shape_id+input_num+pyId*10+26)) s/^/$(echo "  \
  PyTuple_SetItem(iarg"$pyId", 0, iarg"$pyId"1);  ")\n/"                                                  $dir_op_name/plugin/"$op_name"_tf_parser.cpp
    sed -i "$(($tf_output_shape_id+input_num+pyId*10+27)) s/^/$(echo "  \
  PyTuple_SetItem(iarg"$pyId", 1, iarg"$pyId"2);  ")\n/"                                                  $dir_op_name/plugin/"$op_name"_tf_parser.cpp
    sed -i "$(($tf_output_shape_id+input_num+pyId*10+28)) s/^/$(echo "  \
  PyTuple_SetItem(iarg"$pyId", 2, iarg"$pyId"3);  ")\n/"                                                  $dir_op_name/plugin/"$op_name"_tf_parser.cpp
    sed -i "$(($tf_output_shape_id+input_num+pyId*10+29)) s/^/$(echo "  \
  PyTuple_SetItem(iarg"$pyId", 3, iarg"$pyId"4);  ")\n/"                                                  $dir_op_name/plugin/"$op_name"_tf_parser.cpp
      
    sed -i "$(($tf_output_shape_id+input_num+pyId*10+30)) s/^/$(echo "  \
  PyTuple_SetItem(args, "$pyId", iarg"$pyId"); ")\n/"                                                     $dir_op_name/plugin/"$op_name"_tf_parser.cpp
done
tf_parser_param_id=$(($tf_parser_param_id+$input_num*10))

# add parameters
for tfIndex in `seq 0 $param_length`
do
    tf_param=`echo $param_list | jq -r ".[$tfIndex].param"`
    tf_dtype=`echo $param_list | jq -r ".[$tfIndex].type"`
    
    if [ "$tf_dtype" == "bool" ];then
        sed -i "$(($tf_output_shape_id+input_num+input_num*10+tfIndex*2+21)) s/^/$(echo "  \
  PyObject* arg"$((input_num+tfIndex))" = Py_BuildValue(\"b\", "$tf_param"); ")\n/"       $dir_op_name/plugin/"$op_name"_tf_parser.cpp
        sed -i "$(($tf_output_shape_id+input_num+input_num*10+tfIndex*2+22)) s/^/$(echo "  \
  PyTuple_SetItem(args, "$((input_num+tfIndex))", arg"$((input_num+tfIndex))"); ")\n/"    $dir_op_name/plugin/"$op_name"_tf_parser.cpp
    elif [ "$tf_dtype" == "float" ];then
        sed -i "$(($tf_output_shape_id+input_num+input_num*10+tfIndex*2+21)) s/^/$(echo "  \
  PyObject* arg"$((input_num+tfIndex))" = Py_BuildValue(\"f\", "$tf_param"); ")\n/"       $dir_op_name/plugin/"$op_name"_tf_parser.cpp
        sed -i "$(($tf_output_shape_id+input_num+input_num*10+tfIndex*2+22)) s/^/$(echo "  \
  PyTuple_SetItem(args, "$((input_num+tfIndex))", arg"$((input_num+tfIndex))"); ")\n/"    $dir_op_name/plugin/"$op_name"_tf_parser.cpp
    elif [ "$tf_dtype" == "string" ];then
        sed -i "$(($tf_output_shape_id+input_num+input_num*10+tfIndex*2+21)) s/^/$(echo "  \
  PyObject* arg"$((input_num+tfIndex))" = Py_BuildValue(\"s\", "$tf_param"); ")\n/"       $dir_op_name/plugin/"$op_name"_tf_parser.cpp
        sed -i "$(($tf_output_shape_id+input_num+input_num*10+tfIndex*2+22)) s/^/$(echo "  \
  PyTuple_SetItem(args, "$((input_num+tfIndex))", arg"$((input_num+tfIndex))"); ")\n/"    $dir_op_name/plugin/"$op_name"_tf_parser.cpp
    elif [[ "$tf_dtype" == "int32" ]]||[[ "$tf_dtype" == "uint32" ]]||[[ "$tf_dtype" == "int64" ]]||[[ "$tf_dtype" == "uint64" ]]||[[ "$tf_dtype" == "int" ]];then
        sed -i "$(($tf_output_shape_id+input_num+input_num*10+tfIndex*2+21)) s/^/$(echo "  \
  PyObject* arg"$((input_num+tfIndex))" = Py_BuildValue(\"i\", "$tf_param"); ")\n/"       $dir_op_name/plugin/"$op_name"_tf_parser.cpp
        sed -i "$(($tf_output_shape_id+input_num+input_num*10+tfIndex*2+22)) s/^/$(echo "  \
  PyTuple_SetItem(args, "$((input_num+tfIndex))", arg"$((input_num+tfIndex))"); ")\n/"    $dir_op_name/plugin/"$op_name"_tf_parser.cpp
    fi
done

sed -i "$(($tf_output_shape_id+input_num+input_num*10+param_length*2+23)) s/^/$(echo "  \
  PyObject* pRet = PyObject_CallObject(pv, args); ")\n/"                                  $dir_op_name/plugin/"$op_name"_tf_parser.cpp
  
tf_parser_param_id=$(($tf_parser_param_id+$param_length*2+3))

sed -i "$(($tf_output_shape_id+input_num+input_num*10+param_length*2+24)) s/^/$(echo "  \
  long res_0, res_1, res_2, res_3; ")\n/"                                                 $dir_op_name/plugin/"$op_name"_tf_parser.cpp
sed -i "$(($tf_output_shape_id+input_num+input_num*10+param_length*2+25)) s/^/$(echo "  \
  if (pRet) ")\n/"                                                                        $dir_op_name/plugin/"$op_name"_tf_parser.cpp
sed -i "$(($tf_output_shape_id+input_num+input_num*10+param_length*2+26)) s/^/$(echo "  \
  { ")\n/"                                                                                $dir_op_name/plugin/"$op_name"_tf_parser.cpp
sed -i "$(($tf_output_shape_id+input_num+input_num*10+param_length*2+27)) s/^/$(echo "  \
      PyArg_ParseTuple(pRet, \"llll\", \&res_0, \&res_1, \&res_2, \&res_3); ")\n/"        $dir_op_name/plugin/"$op_name"_tf_parser.cpp
sed -i "$(($tf_output_shape_id+input_num+input_num*10+param_length*2+28)) s/^/$(echo "  \
  } ")\n/"                                                                                $dir_op_name/plugin/"$op_name"_tf_parser.cpp
sed -i "$(($tf_output_shape_id+input_num+input_num*10+param_length*2+29)) s/^/$(echo "  \
  shape.SetDim(0, res_0); ")\n/"                                                          $dir_op_name/plugin/"$op_name"_tf_parser.cpp
sed -i "$(($tf_output_shape_id+input_num+input_num*10+param_length*2+30)) s/^/$(echo "  \
  shape.SetDim(1, res_1); ")\n/"                                                          $dir_op_name/plugin/"$op_name"_tf_parser.cpp
sed -i "$(($tf_output_shape_id+input_num+input_num*10+param_length*2+31)) s/^/$(echo "  \
  shape.SetDim(2, res_2); ")\n/"                                                          $dir_op_name/plugin/"$op_name"_tf_parser.cpp
sed -i "$(($tf_output_shape_id+input_num+input_num*10+param_length*2+32)) s/^/$(echo "  \
  shape.SetDim(3, res_3); ")\n/"                                                          $dir_op_name/plugin/"$op_name"_tf_parser.cpp
 
tf_parser_param_id=$(($tf_parser_param_id+9))   



