"""
Copyright (C) 2016. Huawei Technologies Co., Ltd. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the Apache License Version 2.0.You may not use this file
except in compliance with the License.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
Apache License for more details at
http://www.apache.org/licenses/LICENSE-2.0
"""
import os
import json


class JsonExtract:
    """
        used to extract operator's parameter
    """

    def __init__(self, pb_path):
        self.pb_path = pb_path

    def get_pb_graph(self, ):
        import tensorflow as tf
        with open(self.pb_path, 'rb') as file_read:
            proto = tf.GraphDef()
            proto.ParseFromString(file_read.read())
        return proto

    def _json_extract(self, param_list, node, key):
        type_map = {'b': 'bool', 'i': 'int', 's': 'string', 'f': 'float'}
        shape_value = str(node.attr[key].shape)
        list_value = str(node.attr[key].list)
        tensor_value = str(node.attr[key].tensor)
        if list_value == '' and shape_value == '' and tensor_value == '':
            param_dict = {}
            param_dict['param'] = str(key)
            str_value = str(node.attr[key])
            type_value = str_value.strip().split(':')[
                0].strip()

            if type_value in type_map.keys():
                param_dict['type'] = type_map[type_value]
            else:
                param_dict['type'] = type_value

            param_dict['default'] = \
                str_value.strip().split(':')[
                    1].strip().lstrip(
                    "\"").rstrip(
                    "\"")
            param_list.append(param_dict)

    def json_extract(self, op_list, name):

        tensor_graph = self.get_pb_graph()
        all_op_list = []
        dealed = {}
        for node in tensor_graph.node:
            if node.op in op_list and node.op not in dealed.keys():
                op_dict = {}
                op_dict['tf_op_origin_name'] = str(node.op)
                param_list = []
                dealed[node.op] = True
                for key in node.attr.keys():
                    if key != 'T' and key != 'dtype':
                        self._json_extract(param_list, node, key)
                op_dict['tensorflow_param'] = param_list
                all_op_list.append(op_dict)
        json_path = os.path.join("./tensorflow_files", name)
        with open(json_path, 'w') as file_write:
            json_str = json.dumps(all_op_list, indent=2)
            file_write.write(json_str)
