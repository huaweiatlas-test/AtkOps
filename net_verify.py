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

import os
import sys
import numpy as np
import json
import subprocess
import convert2davinci
from op_verify import compare_result
from op_verify import print_result
from op_verify import get_bottom_and_top_names
from op_verify import get_shape_and_name

import shutil
import functools


def load_json(json_file):
    data = {}
    with open(json_file, 'r') as j_f:
        data = json.load(j_f)
    return data


def write_config_ini():

    with open("./config.ini", 'w') as open_file:
        open_file.write("graph_id = 100\n")
        open_file.write("src_engine_id = 1000\n")
        open_file.write("des_engine_id = 1001\n")
        open_file.write(
            "test_img_list_path = " +
            os.path.join(
                os.getcwd(),
                "tmp/") +
            "input_desc.txt\n")
        open_file.write(
            "engine_config_path = " +
            os.path.join(
                os.getcwd(),
                "tmp/graph_rawdata_multil.prototxt\n"))
        open_file.write(
            "result_file_path = " +
            os.path.join(
                os.getcwd(),
                "tmp/outputs\n"))


def gen_omg_str(net_input_names, net_input_shapes):

    omg_str = ""
    for i in range(len(net_input_names)):
        omg_str += net_input_names[i]
        omg_str += ":"
        omg_str += ",".join([str(v) for v in net_input_shapes[i]])
        omg_str += ";"
    omg_str = omg_str[:-1]

    return omg_str


def run_caffe(
        caffe, prototxt, caffemodel, top_name,
        net_input_names, net_input_shapes, custom_layer_name):

    net = caffe.Net(str(prototxt), str(caffemodel), caffe.TEST)

    inputs = []
    for i in range(len(net_input_names)):
        input_i = np.random.rand(*net_input_shapes[i]) - 0.5
        inputs.append(input_i)
        net.blobs[net_input_names[i]].data[...] = input_i
    net.forward()
    return inputs, [np.array(net.blobs[top_name].data.flatten()), ]


def gen_inputs_bin(inputs, batch_size):

    for i in range(batch_size):

        inputs_bin_i = np.array([len(inputs)])
        for input in inputs:
            inputs_bin_i = np.concatenate(
                (inputs_bin_i, [input[i].size * 4, ]))

        for input in inputs:
            inputs_bin_i = np.concatenate((inputs_bin_i, input[i].flatten()))
        inputs_bin_i = inputs_bin_i.astype(np.float32)
        inputs_bin_i.tofile("./inputs_batch_%d.bin" % i)


def write_input_txt(batch_size):

    with open("./input_desc.txt", 'w') as open_file:
        for i in range(batch_size):
            open_file.write(
                os.path.join(
                    os.getcwd(),
                    "inputs_batch_%d.bin\n" %
                    i))


def run_davinci(inputs, te_json):

    batch_size = inputs[0].shape[0]

    current_path = os.getcwd()
    os.chdir("./common/davinci_infer/")

    if os.path.exists("tmp"):
        shutil.rmtree("tmp")
    os.makedirs("tmp")
    os.chdir(current_path)
    write_graph_prototxt(
        te_json["framework"],
        te_json["caffe_operator_type"] +
        ".om",
        batch_size)
    os.chdir("./common/davinci_infer/")
    write_config_ini()
    os.chdir("./tmp/")
    os.makedirs("outputs")
    gen_inputs_bin(inputs, batch_size)
    write_input_txt(batch_size)

    os.chdir(current_path)
    cmd = './common/davinci_infer/DavinciInfer 0 \
        ./common/davinci_infer/config.ini'

    ret = subprocess.call(cmd, shell=True)
    if ret == 0:
        print('run on Atlas SUCCESS')
    else:
        print('run on Atlas FAILED')
    return ret


def write_graph_prototxt(framework, om_name, batch_size):

    so_path = os.path.join(
        os.getcwd(),
        "common/davinci_infer/",
        "libai_engine.so")

    if framework == "caffe":
        om_path = os.path.join(
            os.getcwd(),
            "common/op_verify_files/caffe_files",
            om_name)

    else:
        om_path = os.path.join(
            os.getcwd(),
            "common/op_verify_files/tensorflow_files/")
        for filename in os.listdir(
                "./common/op_verify_files/tensorflow_files/"):
            if filename.endswith(".om"):
                om_path += filename
                break
    graph = """
    graphs {
        graph_id: 100
        priority: 1
        engines {
            id: 1000
            engine_name: "RawDataMutilEngine"
            side: HOST
            thread_num: 1
        }
        engines {
            id: 1001
            engine_name: "DestEngine"
            side: HOST
            thread_num: 1
        }
        engines {
            id: 1005
            engine_name: "RawDataMutilInferEngine"
            side: DEVICE
            so_name:"%s"
            thread_num: 1
            ai_config{
                items{
                    name: "model_path"
                    value:"%s"
                    sub_items{
                        name: "batchsize"
                        value:"%d"
                    }
                }
            }
        }
        connects {
            src_engine_id: 1000
            src_port_id: 0
            target_engine_id: 1005
            target_port_id: 0
        }
        connects {
            src_engine_id: 1005
            src_port_id: 0
            target_engine_id: 1001
            target_port_id: 0
        }
    }""" % (so_path, om_path, batch_size)
    graph_path = os.path.join(
        os.getcwd(),
        "common/davinci_infer/tmp/",
        "graph_rawdata_multil.prototxt")
    with open(graph_path, 'w') as open_file:
        open_file.write(graph)


def get_tf_input(pb_path):

    import tensorflow as tf
    omg_str = ""
    input_shapes = []
    with open(pb_path, 'rb') as pb_f:
        graph_def = tf.compat.v1.GraphDef()
        graph_def.ParseFromString(pb_f.read())
        feed_dict = {}
        for node in graph_def.node:
            if node.op == 'Placeholder':
                omg_str += node.name
                omg_str += ":"
                shape = getattr(node.attr['shape'].shape, 'dim')
                omg_str += ",".join([str(v.size) for v in shape])
                omg_str += ";"
                input_shapes.append([v.size for v in shape])
                feed_dict[node.name] = np.random.rand(
                    *[v.size for v in shape]) - 0.5
        omg_str = omg_str[:-1]
        return input_shapes, omg_str


def cmp(para_a, para_b):
    para_a = int(para_a.split("_")[0][6:])
    para_b = int(para_b.split("_")[0][6:])
    return para_a - para_b


def read_davinci_outputs(outputs_path):

    davinci_outputs = []
    outputs_bin = []
    for filename in os.listdir(outputs_path):
        if filename.endswith(".bin"):
            outputs_bin.append(filename)

    outputs_bin = sorted(outputs_bin, key=functools.cmp_to_key(cmp))
    for output_bin in outputs_bin:
        davinci_outputs.append(
            np.fromfile(
                outputs_path +
                output_bin,
                dtype=np.float32))
    return davinci_outputs


def concat_outputs(outputs):
    ret = np.array([])
    for output in outputs:
        ret = np.concatenate((ret, output))
    return ret


def write_result(path, expect_outputs, davinci_outputs):
    current_path = os.getcwd()
    os.chdir(path)
    if os.path.exists("net_verify"):
        shutil.rmtree("net_verify")
    os.makedirs("net_verify")
    os.chdir("./net_verify")
    os.makedirs("expect_outputs")
    os.makedirs("davinci_outputs")
    os.chdir("./davinci_outputs")
    for i, davinci_output in enumerate(davinci_outputs):
        np.savetxt("davinci_output%d.txt" % i, davinci_output)
    os.chdir("../expect_outputs")
    for i, expect_output in enumerate(expect_outputs):
        np.savetxt("expect_output%d.txt" % i, expect_output)
    os.chdir(current_path)


def check_te_json(te_json):
    fmk = te_json["framework"]
    if fmk != "caffe" and fmk != "tensorflow":
        print("[ERROR] {fmk} is not supported, \
                please check the framework name".format(fmk=fmk))
        return 1
    precision_deviation = float(
        te_json["single_operator_run_cfg"]["precision_deviation"])
    statistical_discrepancy = float(
        te_json["single_operator_run_cfg"]["statistical_discrepancy"])

    if precision_deviation <= 0 or precision_deviation >= 1:
        print("precision_deviation %f does not in the domain of \
            (0, 1) !" % precision_deviation)
        return 1

    if statistical_discrepancy <= 0 or statistical_discrepancy >= 1:
        print("statistical_discrepancy %f does not in the domain of \
            (0, 1) !" % statistical_discrepancy)
        return 1
    return 0


def main():
    current_path = os.getcwd()
    te_json = load_json("./config.json")
    ret = 0
    ret = check_te_json(te_json)
    if ret == 0:
        if te_json["framework"] == "caffe":
            pycaffe_path = te_json["pycaffe_path"]
            caffe_operator_type = te_json["caffe_operator_type"]
            sys.path.insert(1, pycaffe_path)
            import caffe
            prototxt_path = str(
                os.path.join(
                    current_path,
                    "common/op_verify_files/caffe_files/" +
                    caffe_operator_type +
                    ".prototxt"))

            caffemodel_path = str(
                os.path.join(
                    current_path,
                    "common/op_verify_files/caffe_files/" +
                    caffe_operator_type +
                    ".caffemodel"))
            net_input_names, net_input_shapes, custom_layer_name = \
                get_shape_and_name(caffe, prototxt_path,
                                   te_json["caffe_operator_type"])

            omg_str = gen_omg_str(net_input_names, net_input_shapes)

            _, top_names = get_bottom_and_top_names(caffe,
                                                    prototxt_path,
                                                    custom_layer_name)

            inputs, expect_outputs = run_caffe(caffe,
                                               prototxt_path,
                                               caffemodel_path,
                                               top_names[0],
                                               net_input_names,
                                               net_input_shapes,
                                               custom_layer_name)
        else:
            os.environ["CUDA_VISIBLE_DEVICES"] = ''
            from get_tf_model_and_data import TFGenModelData
            inputs, expect_outputs = TFGenModelData(gen_pb_model=True)
            expect_outputs = [expect_output.flatten()
                              for expect_output in expect_outputs]
            pb_path = os.path.join(
                current_path, "./common/op_verify_files/tensorflow_files/")
            for filename in os.listdir(
                    "./common/op_verify_files/tensorflow_files/"):
                if filename.endswith(".pb"):
                    pb_path += filename
                    break

            input_shapes, omg_str = get_tf_input(pb_path)

        ret = convert2davinci.convert_model(mode=1, input_info=omg_str)

    if ret == 0:
        os.chdir(current_path)
        ret = run_davinci(inputs, te_json)
    else:
        print('OMG Fail')

    # delete intermediate outputs
    if ret == 0:
        davinci_outputs = read_davinci_outputs(
            "./common/davinci_infer/tmp/outputs/")
        deviation = float(
            te_json["single_operator_run_cfg"]["precision_deviation"])
        discrepancy = float(
            te_json["single_operator_run_cfg"]["statistical_discrepancy"])

        expect_outputs_concat = concat_outputs(expect_outputs)
        davinci_outputs_concat = concat_outputs(davinci_outputs)

        print_result(expect_outputs_concat, "expect_outputs")
        print_result(davinci_outputs_concat, "davinci_outputs")
        compare_result(
            expect_outputs_concat,
            davinci_outputs_concat,
            deviation,
            discrepancy)
        write_result(
            os.path.join(
                te_json["plugin_path"],
                "../"),
            expect_outputs,
            davinci_outputs)
        # shutil.rmtree("./common/davinci_infer/tmp")


if __name__ == "__main__":
    main()
