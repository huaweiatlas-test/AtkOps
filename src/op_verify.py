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
from __future__ import print_function
import os
import sys
import json
import subprocess
import numpy as np
from google.protobuf import text_format


def load_json(json_file):
    """
        load json file
    """
    data = {}
    with open(json_file, 'r') as open_file:
        data = json.load(open_file)
    return data


def dump_data(input_data, name, fmt, data_type):
    if fmt == "binary" or fmt == "bin":
        with open(name, "wb") as f_output:
            if data_type == "float16":
                for elem in np.nditer(input_data, op_flags=["readonly"]):
                    f_output.write(np.float16(elem).tobytes())
            elif data_type == "float32":
                for elem in np.nditer(input_data, op_flags=["readonly"]):
                    f_output.write(np.float32(elem).tobytes())

    else:
        with open(name, "w") as f_output:
            index = 0
            for elem in np.nditer(input_data):
                f_output.write("%12.5f\t" % elem)
                index += 1
                if index % 16 == 0:
                    f_output.write("\n")


def get_bottom_and_top_names(caffe, prototxt, custom_layer_name):
    from caffe.proto import caffe_pb2
    net = caffe_pb2.NetParameter()
    with open(prototxt) as open_file:
        text_format.Parse(open_file.read(), net)

    bottom_names = None
    top_names = None
    for layer in net.layer:
        if layer.name == custom_layer_name:
            bottom_names = layer.bottom
            top_names = layer.top

    if bottom_names is None:
        print("Can't find the layer's bottom. Please Check the prototxt \
              and custom_layer_name in config.json")
    if top_names is None:
        print("Can't find the layer's top. Please Check the prototxt \
              and custom_layer_name in config.json")
    return bottom_names, top_names


def get_shape_and_name(caffe, prototxt_path, caffe_operator_type):
    from caffe.proto import caffe_pb2
    net = caffe_pb2.NetParameter()
    with open(prototxt_path) as open_file:
        text_format.Parse(open_file.read(), net)
    input_names = []
    input_shapes = []

    if not net.input:
        for i in range(len(net.input)):
            if not net.input_shape:
                input_shapes.append(net.input_shape[i].dim)

            if not net.input_dim:
                input_shapes.append(net.input_dim)
            input_names.append(str(net.input[i]))

    for i in range(len(net.layer)):
        if net.layer[i].type == 'Input':
            input_shapes.append(net.layer[i].input_param.shape[0].dim)
            input_names.append(str(net.layer[i].top[0]))

    custom_layer_name = ""
    for operator in net.layer:
        if operator.type == caffe_operator_type:
            custom_layer_name = str(operator.name)
            break
    return input_names, input_shapes, custom_layer_name


def verify_path_exist(path_dir):
    if not os.path.isdir(path_dir):
        print("{} is not a path!".format(path_dir))
        print("Please check again.")
        return -1
    return 0


def extract_caffe_op(caffe, prototxt, caffemodel, bottom_names,
                     top_name, net_input_names, net_input_shapes,
                     custom_layer_name):
    net = caffe.Net(prototxt, caffemodel, caffe.TEST)
    for i in range(len(net_input_names)):
        net.blobs[net_input_names[i]].data[...] = \
            np.random.rand(*net_input_shapes[i]) - 0.5
    bottoms = []
    net.forward()
    for bottom_name in bottom_names:
        print("bottoms " + str(bottom_name) + " shape: " +
              str(net.blobs[bottom_name].data.shape))
        bottom = net.blobs[bottom_name].data.flatten()
        bottoms.append(bottom)
    weights = []
    if custom_layer_name in net.params.keys():
        for i in range(len(net.params[custom_layer_name])):
            print("weight_%d shape: " % i +
                  str(net.params[custom_layer_name][i].data.shape))
            weight = net.params[custom_layer_name][i].data.flatten()
            weights.append(weight)
    return bottoms, net.blobs[top_name].data.flatten(), weights


def verify_file_exist(path_file):
    if not os.path.isfile(path_file):
        print("{} does not exist!".format(path_file))
        print("Please check again.")
        return -1
    return 0


def check_te_json_key_name(te_json):
    json_key = ["framework", "operator_path", "DDK_PATH",
                "single_operator_run_cfg"]
    if te_json["framework"] == "caffe":
        json_key.append("pycaffe_path")
        json_key.append("caffe_operator_type")
    run_keys = ["dtype", "precision_deviation", "statistical_discrepancy"]
    for key in json_key:
        if key not in te_json.keys():
            print(te_json.keys())
            line_num = sys._getframe().f_lineno
            print("[ERROR {line_num}] there is no {key} in \
                   config.json".format(line_num=line_num, key=key))
            return False

        if key == "single_operator_run_cfg":
            single = te_json["single_operator_run_cfg"]
            for run_key in run_keys:
                if run_key not in single.keys():
                    line_num = sys._getframe().f_lineno
                    print("[ERROR {line_num}] there is no {key} in \
                          config.json".format(line_num=line_num,
                                              key=run_key))
                    return False
    return True


class SingleOpRun(object):
    def __init__(self):
        self.config = {}
        self.run_config = {}
        self.run_time = 0

    def load_run_config(self, te_json):
        self.run_config = te_json["single_operator_run_cfg"]
        if float(self.run_config["precision_deviation"]) >= 1 or \
                float(self.run_config["precision_deviation"]) <= 0:
            print("precision_deviation {} does not in the domain of \
                  (0, 1) !".format(float(
                self.run_config["precision_deviation"])))
            print("Please check again.")
            return False
        self.run_config["precision_deviation"] = \
            float(self.run_config["precision_deviation"])
        if float(self.run_config["statistical_discrepancy"]) >= 1 or \
            float(self.run_config[
                "statistical_discrepancy"]) <= 0:
            print("statistical_discrepancy {} does not in the domain of \
                  (0, 1) !".format(float(
                self.run_config["statistical_discrepancy"])))
            print("Please check again.")
            return False
        self.run_config["statistical_discrepancy"] = \
            float(self.run_config["statistical_discrepancy"])
        return True

    def load_te_json(self):

        if verify_file_exist('./config.json') != 0:
            return False
        te_json = load_json("./config.json")

        flag = check_te_json_key_name(te_json)

        if flag:
            self.config["this_script_path"] = sys.path[0]
            if verify_path_exist(te_json["DDK_PATH"]) != 0:
                return False
            self.config["DDK_PATH"] = te_json["DDK_PATH"]
            if verify_file_exist(self.config["DDK_PATH"]
                                 + "/ddk_info") != 0:
                return False
            self.config["ddk_version"] = load_json(self.config["DDK_PATH"] +
                                                   "/ddk_info")["VERSION"]

            if verify_file_exist(te_json["operator_path"]) != 0:
                return False
            operator_path, operator_name = os.path.split(
                te_json["operator_path"])
            self.config["project_path"] = str(operator_path)
            self.config["operator_name"] = str(operator_name)

            self.config["framework"] = te_json["framework"]
            fmk = te_json["framework"]
            if fmk != "caffe" and fmk != "tensorflow":
                print("[ERROR] {fmk} is not supported, \
                      please check the framework name".format(fmk=fmk))
                return False

            if fmk == "caffe":
                if verify_path_exist(te_json["pycaffe_path"]) != 0:
                    return False
                self.config["pycaffe_path"] = te_json["pycaffe_path"]

                self.config["caffe_operator_type"] = \
                    te_json["caffe_operator_type"]

            flag = self.load_run_config(te_json)
        return flag

    def build_operator(self, operator_path=None, flag=True):
        if not flag:
            return False
        try:
            if operator_path is None:
                subprocess.call("[ -d kernel_meta ] && rm -rf kernel_meta/",
                                shell=True)
            else:
                self.config["operator_name"] = operator_path
            if not os.path.exists(self.config["project_path"]):
                line_num = sys._getframe().f_lineno
                print("[ERROR {line_num}] There is something wrong when \
                       do operator build.".format(line_num=line_num))
                return False
            os.chdir(self.config["project_path"])
            from topi.cce import te_set_version
            te_set_version(self.config["ddk_version"])
            print(self.config["operator_name"])
            status = subprocess.call("python " +
                                     self.config["operator_name"],
                                     shell=True)

            return True if not status else False
        except Exception as ex:
            line_num = sys._getframe().f_lineno
            print("[ERROR {line_num}] There is something wrong when build \
                  operator:{exception}.".format(line_num=line_num,
                                                exception=str(ex)))
            return False

    def config_command_line(self, input_data):
        def _gen_input_data_and_txt(self, input_data):
            try:
                input_num = len(input_data)
                self.run_config["-i"] = ""
                for i in range(input_num):
                    dump_data(input_data[i].flatten(),
                              "input_data%s.bin" % (i + 1),
                              "bin", self.run_config["dtype"])
                    with open("input%s.txt" % (i + 1), "w") as open_file:
                        open_file.write("dataPath=" + os.getcwd() +
                                        "/input_data%s.bin" % (i + 1))
                    self.run_config["-i"] = self.run_config["-i"] + \
                        os.path.join(
                        self.config["project_path"],
                        "single_op_run/",
                        "input/",
                        "input%s.txt," % (i + 1))
                self.run_config["-i"] = self.run_config["-i"][:-1]
            except Exception as ex:
                line_num = sys._getframe().f_lineno
                print("[ERROR {line_num}] There is wrong when generate input \
                      data:{exception}.".format(line_num=line_num,
                                                exception=str(ex)))
                return False
            return True

        def _gen_output_txt(self):
            try:
                with open("output.txt", "w") as open_file:
                    if self.run_config["dtype"] == "float16":
                        data_type_size = 2
                    else:
                        data_type_size = 4
                    out_size = str(int(self.run_config["out_len"]) *
                                   data_type_size)
                    open_file.write("size=" + out_size + "\n")
                    open_file.write("dataPath=" + os.path.join(
                        self.config["project_path"],
                        "single_op_run/",
                        "output/") +
                        "output.bin\n")
                    open_file.write("dtype=" + (
                        "0\n" if self.run_config["dtype"] ==
                        "float32" else "1\n"))
                self.run_config["-o"] = os.path.join(
                    self.config["project_path"],
                    "single_op_run/",
                    "input/",
                    "output.txt")
                self.run_config["outdata_path"] = \
                    os.path.join(self.config["project_path"],
                                 "single_op_run/",
                                 "output/") + "output.bin"
            except Exception as ex:
                line_num = sys._getframe().f_lineno
                print("[ERROR {line_num}] There is wrong when do output \
                      data{exception}.".format(line_num=line_num,
                                               exception=str(ex)))
                return False
            return True

        def _set_run_config(self):
            try:
                path = os.path.join(self.config["project_path"], "kernel_meta")
                file_names = os.listdir(path)
                os.chdir(path)
                for file_name in file_names:
                    if file_name[-4:] == "json":
                        data = load_json(file_name)
                        self.run_config["-b"] = os.path.join(
                            os.getcwd(),
                            data["binFileName"] +
                            data["binFileSuffix"])
                        self.run_config["-k"] = data["kernelName"]
                        if data["magic"] == "RT_DEV_BINARY_MAGIC_ELF":
                            self.run_config["-t"] = "0"
                        elif data["magic"] == "RT_DEV_BINARY_MAGIC_ELF_AICPU":
                            self.run_config["-t"] = "1"
                        else:
                            raise RuntimeError("operator's type should be \
                                               RT_DEV_BINARY_MAGIC_ELF or \
                                               RT_DEV_BINARY_MAGIC_ELF_AICPU!")
            except Exception as ex:
                line_num = sys._getframe().f_lineno
                print("[ERROR {line_num}] There is wrong when do set \
                     run config:{exception}.".format(
                    line_num=line_num, exception=str(ex)))
                return False
            return True

        os.chdir(self.config["project_path"])
        subprocess.call("[ -d single_op_run ] || mkdir single_op_run",
                        shell=True)
        os.chdir(os.path.join(self.config["project_path"], "single_op_run/"))
        subprocess.call("[ -d input ] || mkdir input", shell=True)
        project_path = os.path.join(self.config["project_path"],
                                    "single_op_run/", "input/")
        if not os.path.exists(project_path):
            line_num = sys._getframe().f_lineno
            print("[ERROR {line_num}] {path} is not \
                  exist.".format(line_num=line_num, path=project_path))
            return False

        os.chdir(os.path.join(self.config["project_path"], "single_op_run/",
                              "input/"))

        if (_gen_input_data_and_txt(self, input_data) and
                _gen_output_txt(self) and
                _set_run_config(self)):
            return True
        else:
            return False

    def run_davinci(self, inputs_data, out_len=None, dtype=None):
        def _make_directories():
            try:
                os.chdir(self.config["project_path"])
                subprocess.call("[ -d single_op_run ] || \
                                 mkdir single_op_run", shell=True)
                os.chdir(os.path.join(self.config["project_path"],
                                      "single_op_run/"))
                subprocess.call("[ -d output ] || mkdir output", shell=True)
                return True
            except Exception as ex:
                line_num = sys._getframe().f_lineno
                print("[ERROR {line_num}] There is something wrong when make \
                      directorices: \{exception}.".format(line_num=line_num,
                                                          exception=str(ex)))
                return False

        def _copy_main_and_custom_engine_so():
            try:
                os.chdir(self.config["this_script_path"])
                subprocess.call(
                    "cp ./common/op_verify_files/out/main " +
                    os.path.join(self.config["project_path"],
                                 "single_op_run/"), shell=True)
                subprocess.call(
                    "cp ./common/op_verify_files/out/libcustom_engine.so " +
                    os.path.join(self.config["project_path"],
                                 "single_op_run/"), shell=True)
                subprocess.call("cp ./common/op_verify_files/out/graph.config "
                                + os.path.join(self.config["project_path"],
                                               "single_op_run/"), shell=True)
                return True
            except Exception as ex:
                line_num = sys._getframe().f_lineno
                print("[ERROR {line_num}] There is something wrong when copy \
                      main and custom_so :{exception}."
                      .format(line_num=line_num, exception=str(ex)))
                return False

        def _run_main():
            try:
                os.chdir(os.path.join(self.config["project_path"],
                                      "single_op_run/"))
                # add executable permission
                subprocess.call("chmod +x main", shell=True)
                run_str = "./main "
                run_str = run_str + "-i " + self.run_config["-i"] + " "
                run_str = run_str + "-o " + self.run_config["-o"] + " "
                run_str = run_str + "-b " + self.run_config["-b"] + " "
                run_str = run_str + "-k " + self.run_config["-k"] + " "
                run_str = run_str + "-t " + self.run_config["-t"]
                subprocess.call(run_str, shell=True)
            except Exception as ex:
                line_num = sys._getframe().f_lineno
                print("[ERROR {line_num}] There is something wrong when \
                      do run main:{exception}."
                      .format(line_num=line_num, exception=str(ex)))
                return False
            return True

        if dtype is not None:
            self.run_config["dtype"] = dtype
        if not (self.run_config["dtype"] in ["float32", "float16"]):
            print("[ERROR {line_num}] Output's data type should be \
                   float32 or float16!")
            return None

        if out_len is not None:
            self.run_config["out_len"] = str(out_len)

        if self.config_command_line(inputs_data):
            _make_directories()
            _copy_main_and_custom_engine_so()
            _run_main()
        else:
            return None

        out_data = self.write_output_txt()
        self.delete_intermediate_file()
        return out_data

    def write_output_txt(self):
        try:
            with open(self.run_config["outdata_path"], 'rb') as open_file:
                d_str = open_file.read()
        except BaseException:
            print("Error: Can't generate D's output, please check \
                   the operator file and config.json!")
            return None

        if self.run_config["dtype"] == "float16":
            out_data = np.frombuffer(d_str, np.float16)
        elif self.run_config["dtype"] == "float32":
            out_data = np.frombuffer(d_str, np.float32)
        else:
            print("output's data type should be float32 or float16!")
            return None
        return out_data

    def delete_intermediate_file(self):
        try:
            os.chdir(os.path.join(self.config["project_path"],
                                  "single_op_run/"))
            subprocess.call("rm -rf graph.config libcustom_engine.so main",
                            shell=True)
            subprocess.call("rm -rf ./input/ ./input/*output.txt", shell=True)
            subprocess.call("rm -rf ./input/ ./input/*output.txt", shell=True)
            subprocess.call("rm -rf ./output", shell=True)
        except Exception as ex:
            line_num = sys._getframe().f_lineno
            print("[ERROR {line_num}]Remove temp file failed please check \
                  it by yourself:{exception}.".format(line_num=line_num,
                                                      exception=str(ex)))

    def run_caffe(self, flag=True):

        if not flag:
            return None, None, None

        caffe_path = self.config["pycaffe_path"]
        sys.path.insert(1, caffe_path)
        import caffe
        caffe.set_mode_cpu()
        prototxt_path = str(os.path.join(
            self.config["this_script_path"],
            "./common/op_verify_files/caffe_files/" +
            self.config["caffe_operator_type"] + ".prototxt"))
        caffemodel_path = str(os.path.join(
            self.config["this_script_path"],
            "./common/op_verify_files/caffe_files/" +
            self.config["caffe_operator_type"] + ".caffemodel"))
        net_input_names, net_input_shapes, custom_layer_name = \
            get_shape_and_name(caffe, prototxt_path,
                               self.config["caffe_operator_type"])
        bottom_names, top_names = get_bottom_and_top_names(caffe,
                                                           prototxt_path,
                                                           custom_layer_name)
        if bottom_names is not None and top_names is not None:
            return extract_caffe_op(caffe,
                                    prototxt_path,
                                    caffemodel_path,
                                    bottom_names,
                                    top_names[0],
                                    net_input_names,
                                    net_input_shapes,
                                    custom_layer_name)
        else:
            return None, None, None

    def write_result(self, expect_out, davinci_out):
        os.chdir(os.path.join(self.config["project_path"]))
        subprocess.call("[ -d single_op_run ] || mkdir single_op_run",
                        shell=True)
        os.chdir("./single_op_run")
        np.savetxt("expect_out.txt", expect_out)
        np.savetxt("davinci_out.txt", davinci_out)


def print_result(res, name):
    res = res.flatten()
    print('')
    repeat_num = 40
    print("=" * repeat_num + " Result name: %s. Length: %d " %
          (name, len(res)) + "=" * repeat_num)
    count = 0
    for i in range(len(res)):
        # need a ',' to prevent print '\n'
        if res[i] < 0:
            print("{:14.5e}".format(res[i]), end='')
        else:
            print("{:14.6e}".format(res[i]), end='')
        count += 1
        if count % 8 == 0:
            print('')
            count = 0
    print('')


def compare_result(
        expect_out,
        davinci_out,
        precision_deviation,
        statistical_discrepancy):
    flag = False
    if len(expect_out) != len(davinci_out):
        print("expect_out_len(%d) != davinci_out_len(%d), compare false!" % (
              len(expect_out), len(davinci_out)))
        return False
    total_num = len(expect_out)
    error_num = 0
    avg_error_rate = 0
    max_error_rate = 0

    for i in range(total_num):
        error_rate = abs((expect_out[i] - davinci_out[i]) /
                         (expect_out[i] + 0.000001))
        if error_rate > precision_deviation:
            error_num += 1
        avg_error_rate += error_rate
        if error_rate > max_error_rate:
            max_error_rate = error_rate
    avg_error_rate /= total_num
    if error_num <= statistical_discrepancy * total_num:
        flag = True
    print('')
    repeat_num = 12
    print("=" * repeat_num + " compare %s. average_error_rate: %10.3f%%, \
          max_error_rate: %10.3f%% " %
          (str(flag), avg_error_rate * 100,
           max_error_rate * 100) + "=" * repeat_num)
    return flag


def build_executable():
    # to do: exception check
    current_path = os.getcwd()
    os.chdir(os.path.join(current_path, "common", "op_verify_files", "out"))
    if not (os.path.exists("main") and os.path.exists("libcustom_engine.so")):
        print("=" * 40 + " Building the single op run tool. \
               Please wait. " + "=" * 40)
        os.chdir(
            os.path.join(
                current_path,
                "common",
                "op_verify_files",
                ".build"))
        subprocess.call("make clean", shell=True)
        subprocess.call("find . -iwholename '*cmake*' -not \
                        -name CMakeLists.txt -delete", shell=True)
        subprocess.call("find . -name 'Makefile' | xargs rm", shell=True)
        subprocess.call("cmake .", shell=True)
        subprocess.call("make", shell=True)
        print("=" * 40 + " Building of single op run tool is finished. " +
              "=" * 40)
    os.chdir(current_path)


def main():
    print('You should run "source env.conf" first before run this script.')

    build_executable()  # build C++ source files

    single_op = SingleOpRun()  # construction function

    flag = single_op.load_te_json()
    flag = single_op.build_operator(flag=flag)
    if flag:
        if single_op.config["framework"] == "caffe":
            caffe_bottoms, expect_out, weights = single_op.run_caffe(flag=flag)
            davinci_out = None
            if expect_out is not None:
                # run single operator on Ascend 310
                davinci_out = single_op.run_davinci(caffe_bottoms + weights,
                                                    out_len=len(expect_out))
        # print the results
        elif single_op.config["framework"] == "tensorflow":
            from get_tf_model_and_data import TFGenModelData
            os.chdir(single_op.config["this_script_path"])
            inputs, expect_out = TFGenModelData(gen_pb_model=False)
            expect_out = expect_out[0].flatten()
            inputs = [input.flatten() for input in inputs]
            davinci_out = None

            if expect_out is not None:
                davinci_out = single_op.run_davinci(inputs,
                                                    out_len=len(expect_out))
        else:
            pass

        if davinci_out is not None:
            print_result(davinci_out, "davinci_out")
            print_result(expect_out, "expect_out")
            compare_result(expect_out,
                           davinci_out,
                           single_op.run_config["precision_deviation"],
                           single_op.run_config["statistical_discrepancy"])
            single_op.write_result(expect_out, davinci_out)


if __name__ == "__main__":
    main()
