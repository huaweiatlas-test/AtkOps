import json
import os
import sys
from google.protobuf import text_format

PATH = 'common/op_verify_files/caffe_files/'


def load_json(json_file):
    data = {}
    with open(json_file, 'r') as j_f:
        data = json.load(j_f)
    return data


def read_prototxt(BEFORE_MODIFY_DEPLOY_NET):
    net = caffe_pb2.NetParameter()
    with open(BEFORE_MODIFY_DEPLOY_NET, 'r') as net_f:
        net = text_format.Merge(str(net_f.read()), net)
    return net


if __name__ == '__main__':
    te_json = load_json("./config.json")
    caffePath = te_json["pycaffe_path"]
    if not os.path.exists(caffePath):
        raise RuntimeError("caffe_path doesn't exist!")
    TARGET_OP = te_json["caffe_operator_type"] \
        .encode('raw_unicode_escape')
    SAVE_WEIGHTS = TARGET_OP + '.caffemodel'
    BEFORE_MODIFY_DEPLOY_NET = te_json["net_prototxt"] \
        .encode('raw_unicode_escape')
    if not os.path.exists(BEFORE_MODIFY_DEPLOY_NET):
        raise RuntimeError("prototxt doesn't exist!")
    sys.path.insert(1, caffePath)
    import caffe
    from caffe.proto import caffe_pb2

    caffe.set_mode_cpu()
    caffe_net = caffe.Net(BEFORE_MODIFY_DEPLOY_NET, caffe.TEST)
    net = read_prototxt(BEFORE_MODIFY_DEPLOY_NET)
    op_check = 0

    for op in net.layer:
        if op.type == TARGET_OP:
            ret = op
            bottom = op.bottom
            op_check = 1
            break

    if op_check == 0:
        raise RuntimeError("The operator_type in config.json \
                          is not in net_prototxt_file!")

    input_shape = [0] * len(bottom)

    for i in range(len(bottom)):
        for op_name, blob in caffe_net.blobs.items():
            if op_name == bottom[i].encode('raw_unicode_escape'):
                input_shape[i] = caffe_net.blobs[op_name].data.shape
                break

    with open(PATH + TARGET_OP + '.prototxt', "w+") as fo:
        fo.write('name: "' + TARGET_OP + '"\n')
        for i in range(len(bottom)):
            fo.write('layer {\n')
            fo.write('    name: "' + bottom[i] + '"\n')
            fo.write('    type: "Input"\n')
            fo.write('    top: "' + bottom[i] + '"\n')
            fo.write('    input_param {\n')
            fo.write('        shape {\n')
            for j in range(len(input_shape[i])):
                fo.write('        dim: ' + str(input_shape[i][j]) + '\n')
            fo.write('        }\n')
            fo.write('    }\n')
            fo.write('}\n')
        fo.write('layer{ \n')
        fo.write(str(ret))
        fo.write('}')
    singleop_net = caffe.Net(PATH + TARGET_OP + '.prototxt', caffe.TEST)
    singleop_net.save(PATH + SAVE_WEIGHTS)
