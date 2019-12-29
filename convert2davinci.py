# coding=UTF-8
import json
import os
import re
import subprocess
import sys
from google.protobuf import text_format
from common.op_verify_files.extract_json import JsonExtract


supop_list = ["Input",
              "Convolution",
              "Correlation",
              "Correlation_V2",
              "Deconvolution",
              "Pooling",
              "InnerProduct",
              "Scale",
              "BatchNorm",
              "Eltwise",
              "ReLU",
              "Sigmoid",
              "AbsVal",
              "TanH",
              "PReLU",
              "Softmax",
              "Reshape",
              "ConvolutionDepthwise",
              "Dropout",
              "Concat",
              "ROIPooling",
              "FSRDetectionOutput",
              "Detectpostprocess",
              "LRN",
              "LSTM",
              "Upsample",
              "Proposal",
              "Flatten",
              "PriorBox",
              "Normalize",
              "Permute",
              "NetOutput",
              "SSDDetectionOutput",
              "ChannelAxpy",
              "PSROIPooling",
              "ChannelAxpy",
              "Power",
              "ROIAlign",
              "FreespaceExtract",
              "SpatialTransform",
              "ProposalSigmoid",
              "Slice",
              "Region",
              "Yolo",
              "YoloDetectionOutput",
              "Reorg",
              "Reverse",
              "Crop",
              "Interp",
              "ShuffleChannel",
              "ELU",
              "ArgMax",
              "Log"]


class Model:
    '''
    功能描述：构造转换模型，包含模型信息
    '''

    def __init__(self, model, weight, framework, om, plugin, ddk_version,
                 info=None):
        self.om_model = om
        self._plugin_path = plugin if plugin != '' else ''
        self._model = model
        self._weight = ''
        self._input = info
        self._ddk_version = ddk_version if ddk_version != '' else ''
        if framework == 'caffe':
            self._framework = str(0)
            self._weight = weight
        else:
            self._framework = str(3)
            if not info:
                try:
                    self._input = self.__get_tf_input(self._model)
                except Exception as e:
                    print('Could not get input shape: {e}'.format(e=str(e)))
        self.command = self.__gen_omg_command()

    def __get_valid_dim(self, dim_shape, value):
        if dim_shape == -1:
            dim_shape = value
        return str(dim_shape)

    def __get_tf_input(self, pb_path):
        import tensorflow as tf
        result = ''
        input_dim = ''
        with open(pb_path, 'rb') as pb_f:
            graph_def = tf.compat.v1.GraphDef()
            graph_def.ParseFromString(pb_f.read())
            for node in graph_def.node:
                if node.op == 'Placeholder':
                    name = getattr(node, 'name')
                    dims = getattr(node.attr['shape'].shape, 'dim')
                    if len(dims) > 4:
                        print("Input shape is more than 4.")
                        return ''
                    # CNN model for 4-input && input format is NHWC
                    if len(dims) == 4:
                        input_dim = self.__get_valid_dim(
                            getattr(dims[0], 'size'), 1) + ','
                        input_dim += self.__get_valid_dim(
                            getattr(dims[1], 'size'), 224) + ','
                        input_dim += self.__get_valid_dim(
                            getattr(dims[2], 'size'), 224) + ','
                        input_dim += self.__get_valid_dim(
                            getattr(dims[3], 'size'), 3)
                    elif len(dims) == 3:
                        input_dim = self.__get_valid_dim(
                            getattr(dims[0], 'size'), 1) + ','
                        input_dim += self.__get_valid_dim(
                            getattr(dims[1], 'size'), 224) + ','
                        input_dim += self.__get_valid_dim(
                            getattr(dims[2], 'size'), 224)
                    # NLP model
                    elif len(dims) == 2:
                        input_dim = self.__get_valid_dim(
                            getattr(dims[0], 'size'), 1) + ','
                        input_dim += self.__get_valid_dim(
                            getattr(dims[1], 'size'), 128)
                    elif len(dims) == 1:
                        input_dim = self.__get_valid_dim(
                            getattr(dims[0], 'size'), 1)
                    # just for test
                    elif getattr(node.attr['shape'].shape, 'unknown_rank'):
                        input_dim = '1,224,224,3'
                        print('Input shape is unknown_rank. \
                              Please convert model manually.')
                    # use ';' to split different inputs
                    if result != '':
                        result += ';'
                    if input_dim != '':
                        result += name + ':' + input_dim
        return result

    def __gen_omg_command(self):
        model = ' --model=' + self._model
        weight = ' --weight=' + self._weight if self._weight else ''
        output = ' --output=' + self.om_model
        framework = ' --framework=' + self._framework
        input_str = ' --input_shape="' + self._input + '"' if self._input \
            else ''
        plugin = ' --plugin_path=' + self._plugin_path \
            if self._plugin_path != '' else ''
        ddk_version = ' --ddk_version=' + self._ddk_version \
            if self._ddk_version != '' else ''
        check_file = ' --check_report=' + self.om_model + '.json'
        command = model + weight + output + framework + \
            input_str + plugin + ddk_version + check_file
        return command


def load_json(json_file):
    data = {}
    with open(json_file, 'r') as j_f:
        data = json.load(j_f)
    return data


def get_caffe_unsupinfo_new():
    te_json = load_json("./config.json")
    op_json = "./common/op_verify_files/caffe_files/caffe_op.json"
    caffe_path = te_json["pycaffe_path"]
    model_path = os.path.abspath(te_json['net_prototxt']).encode(
        'raw_unicode_escape')
    weight_path = os.path.abspath(te_json['net_caffemodel']).encode(
        'raw_unicode_escape')

    sys.path.insert(1, caffe_path)
    import caffe
    from caffe.proto import caffe_pb2
    caffe.set_mode_cpu()
    caffe_net = caffe.Net(model_path, weight_path, caffe.TEST)
    net = caffe_pb2.NetParameter()
    with open(model_path, 'r') as model_f:
        net = text_format.Merge(str(model_f.read()), net)
    op_dict = {}
    i = 0
    with open(op_json, 'w') as json_f:
        for op in net.layer:
            ret = ''
            name = ''
            if op.type not in supop_list:
                ret = op
                name = op.name.encode('raw_unicode_escape')
                layer_attr = str(ret)
                param_name = re.search(r'\S*_param', layer_attr)
                param_dict = {}
                opattr_dict = {}
                param_list = []
                weight_num = 0
                opattr_dict['op_name'] = op.type
                if param_name is not None:
                    param_attr = getattr(ret, str(param_name.group()))
                    print(param_attr)
                    param_key = re.findall(r'\S*:', str(param_attr))
                    param_value = re.findall(r': \S*', str(param_attr))
                    for j in range(len(param_key)):
                        key = param_key[j].split(":")[0]
                        if key != 'type':
                            param_dict[key] = param_value[j].split()[1]

                if name in caffe_net.params.keys():
                    weight_num = weight_num + len(caffe_net.params[name])
                    for k in range(len(caffe_net.params[name])):
                        opattr_dict['weight_' + str(k) + '_shape'] = str(
                            caffe_net.params[name][k].data.shape)
                    opattr_dict['weight_num'] = str(weight_num)
                param_list.append(param_dict)
                param_list.append(opattr_dict)
                op_dict['op_' + str(i)] = param_list
                i = i + 1
        json.dump(op_dict, json_f, indent=2)
        print('op info is write into common/op_verify_files/caffe_files/\
        caffe_op.json')


def get_caffe_unsupinfo(unsupport_op_list):
    te_json = load_json("./config.json")
    op_json = "./common/op_verify_files/caffe_files/caffe_op.json"
    caffe_path = te_json["pycaffe_path"]
    model_path = os.path.abspath(te_json['net_prototxt']).encode(
        'raw_unicode_escape')

    sys.path.insert(1, caffe_path)
    import caffe
    from caffe.proto import caffe_pb2
    caffe.set_mode_cpu()
    caffe_net = caffe.Net(model_path, caffe.TEST)
    net = caffe_pb2.NetParameter()
    with open(model_path, 'r') as model_f:
        net = text_format.Merge(str(model_f.read()), net)
    op_dict = {}
    with open(op_json, 'w') as json_f:
        for i in range(len(unsupport_op_list)):
            ret = ''
            name = ''
            for op in net.layer:
                if op.type == unsupport_op_list[i]:
                    ret = op
                    name = op.name.encode('raw_unicode_escape')
                    break
            layer_attr = str(ret)
            param_name = re.search(r'\S*_param', layer_attr)
            param_dict = {}
            opattr_dict = {}
            param_list = []
            weight_num = 0
            opattr_dict['op_name'] = unsupport_op_list[i].strip()
            if param_name is not None:
                param_attr = getattr(ret, str(param_name.group()))
                print(param_attr)
                param_key = re.findall(r'\S*:', str(param_attr))
                param_value = re.findall(r': \S*', str(param_attr))
                for j in range(len(param_key)):
                    key = param_key[j].split(":")[0]
                    if key != 'type':
                        param_dict[key] = param_value[j].split()[1]

            for op_type, blob in caffe_net.blobs.items():
                if op_type == name:
                    if name in caffe_net.params.keys():
                        weight_num = weight_num + len(caffe_net.params[name])
                        for k in range(len(caffe_net.params[name])):
                            opattr_dict['weight_' + str(k) + '_shape'] = str(
                                caffe_net.params[name][k].data.shape)
                        opattr_dict['weight_num'] = str(weight_num)
                        break
            param_list.append(param_dict)
            param_list.append(opattr_dict)
            op_dict['op_' + str(i)] = param_list
        json.dump(op_dict, json_f, indent=2)
        print('op info is write into common/op_verify_files/caffe_files/\
        caffe_op.json')


def get_ops_from_json(json_file, unsupport_op_list, all_op_list):
    with open(json_file, 'r') as check_result:
        result = json.load(check_result)
        all_result = result['op']
        for op_result in all_result:
            if op_result['type'] not in all_op_list:
                all_op_list.append(op_result['type'])
            if op_result['result'] == 'failed' and \
                    op_result['type'] not in unsupport_op_list:
                unsupport_op_list.append(op_result['type'])


def show_op_list(op_file, unsupport_op_list, all_op_list):
    with open(op_file, 'w') as file_p:
        file_p.writelines('unsupported ops list: \n')
        file_p.writelines(op + '\n' for op in unsupport_op_list)
        file_p.writelines('\n\ncomplete ops list: \n')
        file_p.writelines(op + '\n' for op in all_op_list)
    print('\nUnsupported ops list:')
    for op in unsupport_op_list:
        print(op)
    print('\nYou could check all ops in {}'.format(op_file))


def get_ops(om_model_path, save_path, model_file, framework):
    json_file = om_model_path + '.json'
    if not os.path.isfile(json_file):
        return
    om_model_name = om_model_path.split('/')[-1]
    op_file = os.path.join(save_path, om_model_name + '_ops.txt')
    unsupport_op_list = []
    all_op_list = []
    get_ops_from_json(json_file, unsupport_op_list, all_op_list)

    if framework == 'tensorflow':
        extract = JsonExtract(model_file)
        unsupport_result_path = os.path.join(save_path, 'unsupport_' +
                                             om_model_name + '.json')
        extract.json_extract(unsupport_op_list, unsupport_result_path)
        support_result_path = os.path.join(save_path, 'support_' +
                                           om_model_name + '.json')
        extract.json_extract(
            [item for item in all_op_list if item not in unsupport_op_list],
            support_result_path)
    elif framework == 'caffe':
        get_caffe_unsupinfo(unsupport_op_list)

    show_op_list(op_file, unsupport_op_list, all_op_list)


def remove_file(path):
    if os.path.isfile(path):
        subprocess.call('rm ' + path, shell=True)


def search_pb_file(root):
    items = os.listdir(root)
    for item in items:
        path = os.path.join(root, item)
        if os.path.isfile(path):
            _, ext = os.path.splitext(path)
            if ext == '.pb':
                return path
    return ''


def get_model_file(config, mode=0, framework='caffe', op_path=''):
    model = ''
    weight = ''
    if mode != 0:
        op_file = config['caffe_operator_type'].strip()
        verify_file = os.path.join(os.path.abspath(op_path),
                                   framework + '_files')
        if framework == 'caffe':
            model_path = os.path.join(verify_file, op_file)
            model = model_path + '.prototxt'
            weight = model_path + '.caffemodel'
        else:
            model = search_pb_file(verify_file)
            if model == '':
                print('Could not find the pb file of custom_op in {}.\
                        Please check.'.format(verify_file))
    else:
        if framework == 'caffe':
            model = os.path.abspath(config['net_prototxt'])
            weight = os.path.abspath(config['net_caffemodel'])
        else:
            model = os.path.abspath(config['net_pb'])
    return model, weight


def verify_file_path(path):
    if not path:
        return -1
    if not os.path.isfile(path):
        print("{} does not exist!".format(path))
        print("Please check again.")
        return -1
    return 0


def verify_framework_params(config):
    framework = config['framework'].strip().lower()
    if framework != 'caffe' and framework != 'tensorflow':
        print('Framework is invalid. Please check')
        exit()
    if framework == 'caffe':
        if 'net_prototxt' not in config.keys() or \
                'net_caffemodel' not in config.keys():
            print('please check caffe model file')
            exit()
    else:
        if 'net_pb' not in config.keys():
            print('there is no {}. please check.'.format('net_pb'))
            exit()


def verify_mode(mode):
    if mode != 0 and mode != 1:
        print("Mode must be 0 or 1. Error input {}".format(mode))
        exit()


def verify_custom_params(config, mode):
    framework = config['framework'].strip().lower()
    if mode == 1:
        if 'plugin_path' not in config.keys():
            print('there is no {}. please check.'.format('plugin_path'))
            exit()
        if framework == 'caffe' and 'caffe_operator_type' not in config.keys():
            print('there is no caffe_operator_type. please check.')
            exit()


def verify_config_key(config, mode):
    default_keys = ["framework", "DDK_PATH"]
    for key in default_keys:
        if key not in config.keys():
            print(config.keys())
            line_num = sys._getframe().f_lineno
            print("[ERROR {line_num}] there is no {key} in \
                    config.json".format(line_num=line_num, key=key))
            return -1

    verify_framework_params(config)
    verify_mode(mode)
    verify_custom_params(config, mode)
    return 0


def search_file(root, target_file):
    items = os.listdir(root)
    target_full_path = None
    for item in items:
        path = os.path.join(root, item)
        if item == target_file:
            target_full_path = path
            break
        elif os.path.isdir(path):
            target_full_path = search_file(path, target_file)
            if target_full_path:
                break
        else:
            pass
    return target_full_path


def search_omg(ddk_path):
    rPath = os.path.join(ddk_path, 'bin')
    path = search_file(rPath, 'omg')
    gcc_item = path.split('/')[-2]
    os.environ['LD_LIBRARY_PATH'] = os.path.join(ddk_path, 'lib', gcc_item)
    omg_path = os.path.join(ddk_path, 'bin', gcc_item, 'omg')
    return omg_path


def get_config_info(user_conf, mode):
    if verify_file_path(user_conf) != 0:
        exit()
    config = load_json(user_conf)
    if verify_config_key(config, mode) != 0:
        exit()
    return config


def get_plugin_info(config, mode):
    plugin_path = ''
    if mode != 0:
        plugin_path = config["plugin_path"]
        os.chdir(plugin_path)
    return plugin_path


def convert_model(user_conf='./config.json', mode=0,
                  custom_op_path='./common/op_verify_files/', input_info=None):
    config = get_config_info(user_conf, mode)
    DDKHOME = os.path.abspath(config['DDK_PATH'])
    OMG = search_omg(DDKHOME)
    if verify_file_path(OMG) != 0:
        return
    framework = config['framework'].strip().lower()
    model_file, weight_file = get_model_file(config, mode, framework=framework,
                                             op_path=custom_op_path)

    if verify_file_path(model_file) != 0 or \
            (weight_file != '' and verify_file_path(weight_file) != 0):
        return

    if framework == 'caffe':
        get_caffe_unsupinfo_new()

    version = load_json(os.path.join(DDKHOME, 'ddk_info'))["VERSION"]
    plugin_path = get_plugin_info(config, mode)
    om_file_name, _ = os.path.splitext(model_file)
    model = Model(model_file, weight_file, framework,
                  om_file_name, plugin_path, version, info=input_info)
    convert_command = model.command
    if mode == 1 and framework == 'tensorflow':
        # add net_format params, when convert single-node model of tensoflow
        convert_command = model.command + ' --net_format=ND'
    print('Convert model...... Please wait')
    ret = subprocess.call(OMG + convert_command, shell=True)
    if ret == 0:
        print('Model convert success.')
        print('D Model : {}'.format(om_file_name + '.om'))
    else:
        print('Model convert failed.')
        verify_file = os.path.join(os.path.abspath(custom_op_path),
                                   framework + '_files')
        get_ops(model.om_model, verify_file, model_file, framework)
        remove_file(model.om_model + '.json')
    return ret


if __name__ == '__main__':

    argc = len(sys.argv)
    if argc == 2:
        if not sys.argv[1].isdigit():
            print(sys.argv[1], "Mode must be digit.")
            sys.exit()
        convert_type = int(sys.argv[1])
    else:
        print("please input mode type.")
        sys.exit()
    config_f = './config.json'
    convert_model(os.path.abspath(config_f), convert_type)
