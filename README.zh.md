[EN](README.md)|CN

# 自定义算子高效开发工具

本文介绍高效开发 TBE 自定义算子的算子开发工具。当前算子开发工具适用于 tensorflow 和 caffe 算子，运行于 Atlas 300 产品。业界的 tensorflow 和 caffe 模型转换为适用于 Ascend 310 芯片对应的模型时可能会遇到不支持的算子，这是整网分析的过程；对于不支持的算子可以开发自定义算子，并同步生成算子对应的插件，就完成了自定义算子开发，这是算子和插件自动化开发的过程；针对已开发的算子进行算子验证，对算子在 Ascend 310 上跑出的数据与 tensorflow/caffe 跑出的数据进行比较验证，是算子验证的过程；对已开发的插件通过合入自定义算子的OMG 转换，是插件验证的过程。 本工具能实现以上流程的自动开发与验证.

[TOC]

## 支持的产品

Atlas 300 (Model 3010) - 本工具的全模块均支持

Atlas 300 (Model 3000) - 本工具的算子工程与插件生成模块支持

## 支持的版本

1.3.2.B893

1.31.T15.B150

通过如下命令获取：

```bash
npu-smi info
```

## 工具依赖

jq, tensorflow / caffe, make, cmake, python2

## 目录结构

算子高效开发工具目录结构如下：

```bash
.
├── common
│   ├── customOp
│   ├── davinci_infer
│   ├── __init__.py
│   ├── op_develop_files
│   └── op_verify_files
├── config.json
├── convert2davinci.py
├── env.conf
├── get_caffe_model.py
├── get_tf_model_and_data.py
├── op_verify.py
├── net_verify.py
├── README.md
├── README.zh.md
└── run.sh
```

以上每个文件/目录的作用见下表。

| 文件/目录名              | 作用                                                         |
| :----------------------- | ------------------------------------------------------------ |
| customOp                 | 存放自定义算子模板                                           |
| davinci_infer            | 基于 Ascend 310 推理的C++代码，用户不用关注，会被net_verify.py调用 |
| op_develop_files         | 用户不用关注，会被run.sh调用                                 |
| op_verify_files          | 存放get_caffe_model.py和get_tf_model_and_data.py生成的单算子模型 |
| config.json              | 工具的配置文件，用户需要修改                                 |
| convert2davinci.py       | 用于模型分析生成不支持算子及其参数权值列表与模型转换         |
| env.conf                 | 环境变量配置文件，对于C31 ddk用户可能要修改（详见FAQ）       |
| get_caffe_model.py       | 从caffe整网中抽取自定义算子这一层，生成单算子模型            |
| get_tf_model_and_data.py | 用户需要修改，用户生成 tensorflow 算子的单算子模型           |
| op_verify.py             | 用于验证算子本身的正确性（单算子验证）                       |
| net_verify.py            | 用于验证算子与插件的正确性（单算子网络验证）                 |
| run.sh                   | 用于生成自定义算子工程与插件                                 |

因此，本工具包括六个模块：

（1）整网分析模块：模型分析生成不支持算子及其参数权值列表与模型转换。

（2）插件自动化生成模块：生成算子工程与插件。

（3）算子验证模块：单独对算子的正确性进行验证。

（4）插件验证模块：通过模型转换验证插件的正确性。

（5）算子整网（依赖插件）模块：会根据算子与插件对单算子模型进行模型转换与基于 Ascend 310 的推理，能够同时验证算子与插件的正确性。

（6）自定义算子参考模板：一系列的已经实现好的自定义算子工程用于参考。

下面依次介绍（1）~（5）模块的使用流程。

## 工具使用流程

（1）~（5）模块之间相对独立，用户可以根据实际需要使用其中的一部分或者全部都使用。如果只开发算子，可直接跳到第二个模块: 算子工程与插件生成模块。

这五个模块都需要首先设置环境变量，即首先修改config.json中的DDK_PATH字段为安装好的ddk，然后执行

```bash
source env.conf
```

对于C30 版本ddk，直接执行上述命令即可；但对于C31版本，用户可能需要修改 env.conf 的内容（详见FAQ）。

### 整网模型分析模块

#### caffe 算子

下面介绍 caffe 整网模型分析的自动化流程。

**1 配置 config.json**

在 config.json 中整体配置，需要配置的字段为：

- framework                                     输入 caffe
- pycaffe_path                                 设置 pycaffe 路径
- net_prototxt                                  输入整网 prototxt 路径。
- net_caffemodel                             输入整网 caffemodel 路径。

**2 整网 OMG 转换**

执行命令

```bash
python convert2davinci.py 0
```

1）执行完成后，如果整网所有算子都支持，会给出如下提示：

```
convert model...... Please wait
Model convert success.
D Model : /home/xxx   
```

D Model 为 net_prototxt 所在的路径。

2）执行完成后，如果由算子不支持导致的 OMG 失败，会给出如下提示：

```bash
convert model...... Please wait
Model convert failed.
Unsupported ops list:
xxx
xxx
You could check all ops in /home/xxx/xxx_ops.txt
```

xxx_ops.txt 为不支持算子列表，放置在路径 “./common/op_verify_files/caffe_files” 下，当然该路径下还会放置以 json 文件呈现的不支持算子的详细参数和权值信息。不支持算子也会打印在界面，用户可选择需要实现的自定义算子，并在 config.json 中配置，开始自定义算子工程创建和验证。

#### tensorflow 算子

下面介绍 tensorflow 整网模型分析的自动化流程。

**1 配置 config.json**

在 config.json 中整体配置，需要配置的字段为：

- framework                                     输入 tensorflow
- net_pb                                            整网 pb 路径。

**2 整网 OMG 转换**

执行命令

```bash
python convert2davinci.py 0
```

1）执行完成后，如果整网所有算子都支持，会给出如下提示：

```
convert model...... Please wait
Model convert success.
D Model : /home/xxx   
```

D Model 为 net_pb 所在的路径。

2）执行完成后，如果由算子不支持导致的 OMG 失败，会给出如下提示：

```bash
convert model...... Please wait
Model convert failed.
Unsupported ops list:
xxx
xxx
You could check all ops in /home/xxx/xxx_ops.txt
```

xxx_ops.txt 为不支持算子列表，放置在路径 “./common/op_verify_files/tensorflow_files” 下， 当然该路径下还会放置以 json 文件呈现的不支持算子的详细参数信息。不支持算子也会打印在界面，用户可选择需要实现的自定义算子，并在 config.json 中配置，开始自定义算子工程创建和验证。

### 算子工程与插件生成模块

#### 不带权值的 caffe 算子工程

caffe 算子工程自动生成步骤简洁流程如下：

步骤一：修改配置文件 config.json

```bash
    "operator_name":               "custom_Upsample",
    "framework":                   "caffe",
    "DDK_PATH":                    "/home/mindstudio/tools/che/ddk/ddk",
    "custom_caffe_proto_file":     "/home/mindstudio/caffe.proto",
    "same_input_output_shape":     "False",
    "input_num":                   "1",
```

步骤一配置了自定义算子名称，算子框架为 caffe 自定义算子，配置了 DDK 路径和自定义的 caffe.proto 的文件路径，输入个数 input_num 配置为 1。 由于输入输出 shape 不同，将 same_input_output_shape 字段配置为 False. 这里指定的 caffe.proto 包含了要开发的自定义算子的参数信息。配置以上信息后即可完成算子工程的自动生成，其它参数可不配置。

步骤二： 执行命令 "bash run.sh" 或 " . run.sh" 生成算子工程

```bash
.
├── operator
│   ├── custom_UpsampleOutputWeightShape.py
│   └── custom_Upsample.py
└── plugin
    ├── custom_Upsample_parser_C30.cpp
    ├── libcaffe_custom_Upsample_layer.so
    ├── lib_caffe_parser.so
    ├── Makefile
    ├── proto
    │   └── caffe
    │       ├── caffe.pb.cc
    │       ├── caffe.pb.h
    │       ├── caffe.pb.o
    │       └── caffe.proto
    └── tmp
        └── obj
            └── custom_Upsample_parser_C30.o
```

接下来只需开发 operator 目录下的算子文件 custom_Upsample.py 和 输出权值 shape 文件 custom_UpsampleOutputWeightShape.py。 plugin 目录不用修改。operator 目录下的文件都开发完成后，可继续执行 “. run.sh” 完成插件编译。

步骤三：开发算子文件后，再次执行命令 " . run.sh" 完成插件编译

另外，如果该自定义算子输入输出的 shape 是相同的，则 config.json 中的 same_input_output_shape 需设置为 True, 这样在步骤二即可完成插件的完整编译，步骤三只需开发算子文件即可。

算子开发完成，插件也编译完成，即可将该自定义算子合入整网进行模型转换或进行算子和插件验证 （参见下文）。

#### 带权值的 caffe 算子工程

带权值的算子工程也是以上三个步骤，但是步骤一配置的选项需增加权值信息，如下所示：

```bash
    "operator_name":               "custom_Upsample",
    "framework":                   "caffe",
    "DDK_PATH":                    "/home/mindstudio/tools/che/ddk/ddk",
    "custom_caffe_proto_file":     "/home/mindstudio/caffe.proto",
    "same_input_output_shape":     "False",
    "input_num":                   "2",
    "weight_num":                  "2",
    "weight_num_param":            [
        {
            "weight_1":            "5",
            "weight_2":            "3"
        }
                                   ],
    "filter_caffe_param":          ["min_size", "img_w", "img_size", "flip", "max_size"],

```

这里配置了权值的个数 weight_num 为 2， 对于第一个权值配置了它的 shape 维度 weight_1 为 5，第二个权值配置了它的 shape 维度为 3. 本工具基于 caffe.proto 中该自定义算子的参数生成，如果参数过多，可以对参数进行过滤，需要过滤的参数配置在 filter_caffe_param 字段中。 当然如果不需要参数过滤功能，可将字段 filter_caffe_param 删除或不配置。　 

filter_caffe_param 指定的要过滤的算子参数，可参照上文整网模型分析输出的 json 文件。模型分析既输出 caffe 网络的不支持算子列表，又会以 json 文件形式给出不支持算子的详细参数和权值信息。

#### tensorflow 算子工程

步骤一： 修改配置文件 config.json

```bash
    "operator_name":               "batch_matmul",
    "framework":                   "tensorflow",
    "DDK_PATH":                    "/home/mindstudio/tools/che/ddk/ddk",
    "same_input_output_shape":     "False",
    "input_num":                   "2",
    "tf_op_origin_name":           "BatchMatMul",
    "tensorflow_param":            [
        {
            "param":               "adj_x",
            "type":                "bool"
        },
        {
            "param":               "adj_y",
            "type":                "bool"
        }
```

tf_op_origin_name 设置 tensorflow 中的原生算子名称， tensorflow_param 设置该自定义算子包含的参数以及参数的数据类型。

步骤二：  执行命令 "bash run.sh" 或 " . run.sh" 生成算子工程

```bash
.
├── operator
│   ├── batch_matmulOutputWeightShape.py
│   └── batch_matmul.py
└── plugin
    ├── batch_matmul_tf_parser.cpp
    ├── libtf_batch_matmul.so
    ├── makefile
    ├── proto
    │   └── tensorflow
    │       ├── attr_value.pb.cc
    │       ├── attr_value.pb.h
    │       ├── function.pb.cc
    │       ├── function.pb.h
    │       ├── graph.pb.cc
    │       ├── graph.pb.h
    │       ├── node_def.pb.cc
    │       ├── node_def.pb.h
    │       ├── op_def.pb.cc
    │       ├── op_def.pb.h
    │       ├── resource_handle.pb.cc
    │       ├── resource_handle.pb.h
    │       ├── tensor.pb.cc
    │       ├── tensor.pb.h
    │       ├── tensor_shape.pb.cc
    │       ├── tensor_shape.pb.h
    │       ├── types.pb.cc
    │       ├── types.pb.h
    │       ├── versions.pb.cc
    │       └── versions.pb.h
    └── tmp
        └── obj
            └── batch_matmul_tf_parser.o
```

同理只需开发算子文件 batch_matmul.py 和输出 shape 文件 batch_matmulOutputWeightShape.py。 如果输入输出 shape 相同，也即 same_input_output_shape 是设置为 True，此时步骤二即可完成插件的完整编译，否则需要继续执行步骤三。

 步骤三：开发算子文件后，再次执行命令 " . run.sh" 完成插件编译

另外， 这里的 input_num 除了可配置为正整数，也可以配置为 auto， 表示输入个数是不定的，但是具体输入的 shape 维度是固定为四维的。input_num 也可以配置为 autoAll， 表示输入个数是不定的，具体输入 shape 的维度也是不定的。 

tensorflow_param 指定的算子参数可参照下文整网模型分析输出的 json 文件，模型分析既输出不支持算子列表，也会以 json 文件形式给出不支持算子的详细参数信息。

算子开发完成，插件也编译完成，即可将该自定义算子合入整网进行模型转换或进行算子和插件验证 （参见下文）。

### 算子验证模块

本模块用于在算子开发完毕后，验证算子文件本身的正确性。

#### caffe 算子

下面详细介绍对于caffe 算子的自动化验证流程。

**1 配置 config.json**

 config.json 中需要配置的字段为：

- framework                                     配置为 caffe。

- DDK_PATH                                     DDK 的安装目录。

- caffe_operator_type                    caffe 自定义算子类型名。

- pycaffe_path                                 caffe 的 python 路径。

- net_prototxt                                  整网 prototxt 路径。

- operator_path                               单算子路径。

- single_operator_run_cfg              单算子验证的配置。

  其中的precision_deviation表示精度偏差，表示单数据相对误差允许范围，数值范围为（0，1），精度偏差越小表示精度越高。Statistical Discrepancy表示统计偏差，整个数据集中精度偏差不满足门限的数据量占比，数值范围（0，1），统计偏差越小表示精度越高。本工具会根据这两个误差指标来判断是否通过验证。

**2 生成单算子模型**

执行命令

```bash
python get_caffe_model.py
```

get_caffe_model.py 会根据整网 net_prototxt 和 caffe_operator_type，在 common/op_verify_files/caffe_files目录下生成单算子模型的 prototxt 和对应随机权重的 caffemodel。

因此，生成 caffe 单算子模型，需要首先配置 pycaffe_path，net_prototxt 和 caffe_operator_type。

**3 在算子文件中增加测试用例**

用户需要在开发的 TBE 算子文件中增加测试用例，该测试用例的参数应和由第 2 步生成的单算子模型的自定义算子层的参数一致，参数中的 dtype 需要和 single_operator_run_cfg 的 dtype 一致。

特别注意的是，测试用例中的算子接口参数、输入 shape 均来自第三步生成的单算子模型，测试用例和单算子模型不匹配会导致单算子验证失败, 需要时可使用 npu-smi 工具来重启芯片。

**4 单算子验证**

执行命令

```bash
python op_verify.py
```

执行成功后，会打印出 Ascend 310 上的输出数据和 caffe 上的期望输出数据，平均相对误差率和最大相对误差率，以及是否满足 config.json 配置的精度要求（即 precision_deviation 和 statistical_discrepancy）。同时会在算子路径 operator_path 同级目录新建 single_op_run 目录，在该目录写入 Ascend 310 上的结果和 caffe 上的结果的文本文件。

#### tensorflow 算子

下面介绍对于 tensorflow 算子的自动化验证流程。

**1 配置 config.json**

对于 tensorflow 算子的单算子验证，在 config.json 中需要配置的字段为：

- framework                                需要配置为 tensorflow。

- DDK_PATH                                DDK 的安装目录。

- operator_path                         算子路径。

- single_operator_run_cfg        单算子验证的配置。

**2 修改 get_tf_model_and_data.py**

用户需要修改 get_tf_model_and_data.py 文件中的 TFGenModelData() 接口，它在 op_verify.py 中会被调用， 用于生成 tensorflow 算子的输入与期望输出和单算子模型。单算子模型的生成路径为：common/op_verify_files/tensorflow_files/。

用户需要修改get_tf_model_and_data.py 的地方包括：

1） 输入tensor的数量与shape

```python
# 自行构造输入tensor的数量与shape
shape_x = (7, 2, 3, 4)
shape_y = (7, 2, 3, 4)
x = tf.placeholder(tf.float32, shape=shape_x, name='x')
y = tf.placeholder(tf.float32, shape=shape_y, name='y')
```

2）修改tensorflow算子的函数

```python
# 修改tensorflow算子的函数
name = "pow"
op = tf.pow(x, y, name=name)
```

3）配置输入的数据（通常为随机数据）

```python
# 配置输入的数据（通常为随机数据）
input_x = np.random.randint(1, 5, size=shape_x).astype(np.float32, copy=False) - 8
input_y = np.random.randint(1, 5, size=shape_y).astype(np.float32, copy=False)
```

4）根据输入、输出的数量修改return语句

```python
# 该例子中有两个输入，一个输入
return [input_x, input_y], [expect,]
```

注意，本工具只支持单输出的算子。

**3 在算子文件中增加测试用例**

用户需要在开发的 TBE 算子文件中增加测试用例，该测试用例的参数应和由第 2 步 TFGenModelData() 的接口一致，参数中的 dtype 需要和 single_operator_run_cfg 的 dtype 一致。

特别注意的是，测试用例中的算子接口参数、输入 shape 均来自第 2 步生成的单算子模型，测试用例和单算子模型不匹配会导致单算子验证失败。

**4 单算子验证**

执行命令

```bash
python op_verify.py
```

执行成功后，会打印出 Ascend 310 上的结果和 tensorflow 上的结果，平均相对误差率和最大相对误差率，以及是否满足 config.json 中配置的精度要求（即 precision_deviation 和 statistical_discrepancy）。同时会在算子路径 operator_path 同级目录新建 single_op_run 目录，在该目录写入 Ascend 310 上的结果和 tensorflow 上的结果的文本文件。

### 插件验证模块

插件验证默认算子和插件已完成开发。 如果算子验证已完成 ，在 config.json 中配置完 plugin_path 选项后，即可直接执行

```
python convert2davinci.py 1
```

如果算子验证还未完成，直接执行插件验证，需按如下步骤：

#### caffe 算子

下面介绍对于 caffe 算子插件的自动化验证流程。

**1 配置环境变量**

执行以下命令配置环境变量：

```bash
source env.conf
```

该环境变量可应用于算子验证和插件验证。

**2 配置 config.json**

对于 caffe 算子的单算子验证，假设算子和插件文件已开发好，可以在 config.json 中整体配置，需要配置的字段为：

- framework                                      配置为 caffe。
- DDK_PATH                                      DDK 的安装目录，需要配置到： $home/tools/che/ddk/ddk 。
- caffe_operator_type                     caffe 自定义算子类型名。
- pycaffe_path                                  caffe 的 python 路径。
- net_prototxt                                   整网 prototxt 路径。
- operator_path                               单算子路径。
- plugin_path                                    单算子插件路径。
- single_operator_run_cfg              单算子验证的配置。

**3 生成单算子模型**

执行命令

```bash
python get_caffe_model.py
```

get_caffe_model.py 会根据整网 net_prototxt 和 caffe_operator_type，在 common/op_verify_files/caffe_files目录下生成单算子模型的 prototxt 和对应随机权重的 caffemodel 。

**4 单算子插件验证**

执行命令

```bash
python convert2davinci.py 1
```

入参 1 表示 convert2davinci.py 文件将应用于合入自定义算子的单算子模型 OMG 转换。转换后的模型将放置在

common/op_verify_files/caffe_files/ 路径下，并将提示此 om 文件的路径。

#### tensorflow 算子

下面介绍对于 tensorflow 算子插件的自动化验证流程。

**1 配置环境变量**

执行以下命令配置环境变量：

```bash
source env.conf
```

**2 配置 config.json**

对于 tensorflow 算子的单算子验证，在 config.json 中需要配置的字段为：

- framework                                 需要配置为 tensorflow。
- DDK_PATH                                 DDK 的安装目录。
- operator_path                          算子路径。
- plugin_path                              单算子插件路径。
- single_operator_run_cfg        单算子验证的配置。

**3 修改 get_tf_model_and_data.py** 

执行以下命令可生成单算子模型：

```shell
python get_tf_model_and_data.py
```

用户需要修改 get_tf_model_and_data.py 文件中的 TFGenModelData() 接口，它在 op_verify.py 中会被调用， 用于生成 tensorflow 算子的输入与期望输出和单算子模型。单算子模型的生成路径为：common/op_verify_files/tensorflow_files/。

**5 单算子插件验证**

执行命令

```bash
python convert2davinci.py 1
```

执行成功后，转换后的模型将放置在 common/op_verify_files/caffe_files/ 路径下，并将提示此 om 文件的路径。

备注： 如果要改变单算子模型的 format，需修改 convert2davinci.py 文件中的 net_format.

### 算子整网（依赖插件）验证模块

该工具用于在算子和插件都已经开发完毕后，验证自定义算子与插件的正确性。

本模块会执行三个步骤：

（1）生成caffe/tensorflow的单算子模型。对于caffe算子，需要调用get_caffe_model.py，在common/op_verify_files/caffe_files目录下生成单算子模型的 prototxt 和对应随机权重的 caffemodel；对于tensorflow算子，会调用get_tf_model_and_data.py（用户需要修改该文件），在common/op_verify_files/tensorflow_files/目录下生成单算子模型的pb文件。

（2）对（1）的单算子模型根据算子和插件进行OMG模型转换，生成om模型。

（3）构造随机数据，分别送入om模型和caffe/tensorflow模型，打印两者的结果并得出相对误差。

无论是caffe算子还是tensorflow算子，用户首先都需要编译davinci_infer：

**1 编译davinci_infer**

在 common/davinci_infer目录下，执行

```bash
sh build.sh
```

#### caffe算子

在执行完以上步骤后，caffe 算子的整网（依赖插件）验证的步骤如下。

**1 配置 config.json**

对于 caffe 算子的单算子验证，需要配置的字段为：

- framework                                     配置为 caffe。
- DDK_PATH                                     DDK 的安装目录 。
- caffe_operator_type                    caffe 自定义算子类型名。
- pycaffe_path                                 caffe 的 python 路径。
- net_prototxt                                  整网 prototxt 路径。
- single_operator_run_cfg              单算子验证的配置。只需要配置其中的precision_deviation和statistical_discrepancy。
- plugin_path                                    算子插件的路径。注意插件应该已经编译好。

**2 生成单算子模型**

执行命令

```bash
python get_caffe_model.py
```

get_caffe_model.py 会根据config.json中的net_prototxt 字段和 caffe_operator_type字段，在 common/op_verify_files/caffe_files目录下生成单算子模型的 prototxt 和对应随机权重的 caffemodel。

**3 单算子模型OMG、D推理及其验证**

执行命令

```
python net_verify.py
```

执行成功后，会在common/op_verify_files/caffe_files对单算子模型（即第2步生成的prototxt 和caffemodel）进行模型转换，在该目录下生成与caffe_operator_type同名的om模型。

接着，会构造随机输入，同时送入om模型和caffe模型分别进行推理，在控制台打印om模型和caffe模型的输出与两者的平均误差率、最大误差率，并且会在算子工程新建net_verify目录，将om模型和caffe模型的输出写入该目录中。

#### tensorflow算子

在配置环境变量和编译davinci_infer之后，tensorflow算子的整网（依赖插件）验证的步骤如下。

**1 配置 config.json**

需要配置的字段为：

- framework                                     配置为 tensorflow。
- DDK_PATH                                     DDK 的安装目录 。
- single_operator_run_cfg              单算子验证的配置。只需要配置其中的precision_deviation和statistical_discrepancy。
- plugin_path                                    算子插件的路径。注意插件应该已经编译好。

**2 修改get_tf_model_and_data.py文件**

该文件用于生成tensorflow算子的输入、期望输出和单算子的pb模型。

用户需要修改的地方包括：

1） 输入tensor的数量与shape

```python
# 自行构造输入tensor的数量与shape
shape_x = (7, 2, 3, 4)
shape_y = (7, 2, 3, 4)
x = tf.placeholder(tf.float32, shape=shape_x, name='x')
y = tf.placeholder(tf.float32, shape=shape_y, name='y')
```

2）修改tensorflow算子的函数

```python
# 修改tensorflow算子的函数
name = "pow"
op = tf.pow(x, y, name=name)
```

3）配置输入的数据（通常为随机数据）

```python
# 配置输入的数据（通常为随机数据）
input_x = np.random.randint(1, 5, size=shape_x).astype(np.float32, copy=False) - 8
input_y = np.random.randint(1, 5, size=shape_y).astype(np.float32, copy=False)
```

4）根据输入、输出的数量修改return语句

```python
# 该例子中有两个输入，一个输出
return [input_x, input_y], [expect,]
```

注意，本工具只支持单输出的算子。

**4 单算子模型OMG、D推理及其验证**

执行命令

```
python net_verify.py
```

执行成功后，会在common/op_verify_files/tensorflow_files生成单算子的pb模型，并对该单算子模型进行模型转换，在该目录下生成同名的om模型。注意，这会首先清空common/op_verify_files/tensorflow_files中的原有的pb和om模型。

接着，工具会构造随机输入，同时送入om模型和pb模型分别进行推理，在控制台打印om模型和pb模型的输出，以及两者之间的平均误差率、最大误差率，并且会在算子工程新建net_verify目录，将om模型和pb模型的输出写入该目录中。

### Demo

1. 给定一个整网，这里通过 get_tf_model_and_data.py 生成单算子模型来代替整网，该文件做如下修改：

   ```bash
   import os
   import numpy as np
   import tensorflow as tf
   def TFGenModelData(gen_pb_model=True):
       os.environ["CUDA_VISIBLE_DEVICES"] = ''
       with tf.Session(graph=tf.Graph()) as sess:
           shape_x = (7, 2, 6, 9)
           shape_y = (7, 2, 9, 6)
           x = tf.placeholder(tf.float32, shape=shape_x, name='x')
           y = tf.placeholder(tf.float32, shape=shape_y, name='y')
           name = "batch_matmul"
           op = tf.matmul(x, y, name=name)
           input_x = np.random.randint(1, 5, size=shape_x).astype(np.float32,
                                                                  copy=False) - 8
           input_y = np.random.randint(1, 5, size=shape_y).astype(np.float32,
                                                                  copy=False)
           feed_dict = {x: input_x, y: input_y}
           sess.run(tf.global_variables_initializer())
           expect = sess.run(op, feed_dict)
           if gen_pb_model:
               pWord = os.getcwd()
               os.chdir("./common/op_verify_files/tensorflow_files")
               for filename in os.listdir("./"):
                   if filename.endswith(".om") or filename.endswith(".pb"):
                       os.remove(filename)
               graph = tf.compat.v1.graph_util.convert_variables_to_constants(
                   sess, sess.graph_def, [name])
               with tf.gfile.FastGFile('tf_' + name + '.pb', mode='wb') as f:
                   f.write(graph.SerializeToString())
               os.chdir(pWord)
       return [input_x, input_y], [expect, ]
   if __name__ == "__main__":
       TFGenModelData()
   ```

2. **执行 ： python get_tf_model_and_data.py **

   在路径： ./common/op_verify_files/tensorflow_files  下得到如下文件：

   ```bash
   .
   ├── README.md
   ├── README.zh.md
   └── tf_batch_matmul.pb
   ```

   单算子模型  tf_batch_matmul.pb 作为要分析的整网。

3. 【模型分析】配置 config.json 的两个字段：

   ```bash
   "framework":                   "tensorflow",
    "net_pb":                     "./common/op_verify_files/tensorflow_files/tf_batch_matmul.pb",
   ```

   **执行： python convert2davinci.py 0**

   对 “net_pb” 配置的模型进行分析，界面显示如下信息：

   ```bash
   Unsupported ops list:
   BatchMatMulV2
   ```

   同时，在路径： ./common/op_verify_files/tensorflow_files  下得到如下文件：

   ```bash
   .
   ├── README.md
   ├── README.zh.md
   ├── support_tf_batch_matmul.json
   ├── tf_batch_matmul_ops.txt
   ├── tf_batch_matmul.pb
   └── unsupport_tf_batch_matmul.json
   ```

   tf_batch_matmul.pb 是作为整网分析的模型。unsupport_tf_custom_batch_matmul.json 给出了该网络的不支持算子列表及参数信息：

   ```bash
   [
     {
       "tensorflow_param": [
         {
           "default": "false",
           "type": "bool",
           "param": "adj_y"
         },
         {
           "default": "false",
           "type": "bool",
           "param": "adj_x"
         }
       ],
       "tf_op_origin_name": "BatchMatMulV2"
     }
   ```

   并且得到模型  tf_batch_matmul.pb 中的不支持算子 "BatchMatMulV2" 和它的两个参数 "adj_x" 和 "adj_y"。   **至此，整网模型分析模块完成！**

   BatchMatMulV2 是OMG转换后不支持的 tensorflow 算子，计划基于TBE开发 BatchMatMulV2 算子，并且命名为 custom_batch_matmul. 

4.  【开发算子】在 config.json 中新增或修改如下字段：

   ```bash
    "operator_name":               "custom_batch_matmul",
    "DDK_PATH":                    "/home/xx/C31/ddk/ddk/",
    "same_input_output_shape":     "False",
    "input_num":                   "2",
    "tf_op_origin_name":           "BatchMatMul",
    "tensorflow_param":            [
           {
               "param":               "adj_x",
               "type":                "bool"
           },
           {
               "param":               "adj_y",
               "type":                "bool"
           }
                                      ],
     "project_path":               "/home/xxx/mindstudio",                               
   ```

   **执行：  bash run.sh**

   在 "/home/xxx/mindstudio" 路径下能得到 custom_batch_matmul 的算子工程：

   ```bash
   ├── operator
   │   ├── custom_batch_matmulOutputWeightShape.py
   │   └── custom_batch_matmul.py
   └── plugin
       ├── custom_batch_matmul_tf_parser.cpp
       ├── libtf_custom_batch_matmul.so
       ├── makefile
       ├── proto
       └── tmp
   ```

   开发算子文件： custom_batch_matmul.py

   参照：  ./common/customOp/tensorflowOp/custom_batch_matmul/operator/custom_batch_matmul.py

   因为 same_input_output_shape 设置为 False 表示输入输出shape 不相同，因此需要开发输出shape逻辑，它取自于 custom_batch_matmul.py 中的代码。custom_batch_matmulOutputWeightShape.py 文件限制输出shape 是四维的，输出 shape 逻辑可如下描述：

   ```python
   def OutputShapecustom_batch_matmul(shape_1, shape_2, adj_x, adj_y):
       """
       TODO:
       Please add code here to obtain the output shape.
       """
       if not adj_x and not adj_y:
           output_shape = (shape_1[0], shape_1[1], shape_1[2], shape_2[3])
       elif not adj_x and adj_y:
           output_shape = (shape_1[0], shape_1[1], shape_1[2], shape_2[2])
       elif adj_x and not adj_y:
           output_shape = (shape_1[0], shape_1[1], shape_1[3], shape_2[3])
       else:
           output_shape = (shape_1[0], shape_1[1], shape_1[3], shape_2[2])
       return output_shape
   ```

   算子文件和算子输出shape逻辑文件开发完成后，回到工具根目录，进行算子验证和插件验证。为了验证插件，需要生成该算子的单算子模型，因此需要修改 get_tf_model_and_data.py 文件，而这个文件已经在步骤 1修改好了。

5. 【插件验证】新增config.json 的如下字段：

   ```bash
   "plugin_path":                 "/home/xxx/mindstudio/custom_batch_matmul/plugin"
   ```

   **执行： source env.conf **

   **再执行： python convert2davinci.py 1 **

   得到如下结果表示模型转换成功：

   ```bash
   Model parsing is complete. (1/4)
   Graph optimization is complete. (2/4)
   Model building is complete. (3/4)
   Offline model saving is complete. (4/4)
   OMG generate offline model success.
   Model convert success.
   ```

   至此，通过OMG 模型转换验证了插件的正确性。

6.  【算子验证】新增 config.json 的如下字段：

   ```bash
   "operator_path":           "/home/xxx/mindstudio/custom_batch_matmul/operator/custom_batch_matmul.py",
   "single_operator_run_cfg":     {
               "dtype":                    "float32",
               "precision_deviation":      "0.2",
               "statistical_discrepancy":  "0.2"
                                       }
   ```

   在算子文件末尾增加测试用例：

   ```python
   if __name__ == "__main__":
        shape_1 = (7, 2, 6, 9)
        shape_2 = (7, 2, 9, 6)
        adj_x = False
        adj_y = False
        dtype = "float32"
        custom_batch_matmul(shape_1, shape_2, dtype, adj_x, adj_y, need_build = True)
   ```

   测试用例中的 dtype 需要和 config.json 中的 dtype 保持一致, 测试用例中的 shape_1 和 shape2 也需要和单算子模型中的数据保持一致，也即与 get_tf_model_and_data.py 文件中的数据保持一致。

   **执行： python op_verify.py**

   结果会打印出该算子（不依赖插件）在Ascend 310 和 tensorflow 下的运行数据及比较结果。

7. 【依赖插件的算子验证】在 “./common/davinci_infer” 目录下，进行编译。 该模块只支持四维的输入输出。

   **执行： bash build.sh**

   ```
   - do [do_pre_build]
   [CC] src/out/visual_infer_main.o
   [CC] src/out/host/data_recv.o
   [CC] src/out/host/visual_infer_host.o
   [CC] src/out/host/util.o
   [CC] src/out/host/raw_data_host.o
   [CC] src/out/host/raw_data_mutil_input_host.o
   [CC] src/out/device/sample_data.o
   [CC] src/out/config_parser/config_parser.o
   [LD] src/out/DavinciInfer
   - do [do_build]
   make success
   copy success
   ```

   得到如上所示正确的编译结果。推理模块编译完成后，回到工具根目录：

   **执行： python net_verify.py**

   结果会打印出该算子（依赖插件）在Ascend 310 和 tensorflow 下的数据及比较结果。

   另外， 如果算子输出 shape 不是四维的，可自行修改插件代码。如果想在插件中直接开发输出shape逻辑，可将 same_input_output_shape 置为 True，然后修改插件。

   至此，算子和插件验证模块完成。



## FAQ

（1）使用算子验证模块时，提示RuntimeError: ('compile cce error : ', OSError(2, 'No such file or directory'))，或者是使用算子整网（依赖插件）模块在Davinci上进行推理时，提示权限不足？

有两种方法，一是用root或HwHiAiUser用户来执行工具；

另一种方法是将当前用户加入到HwHiAiUser 组，然后再将当前用户默认的用户组切换到HwHiAiUser来执行工具。

（2）C31 DDK版本编译工具发生失败？

这是因为C31的DDK单独划分出来了一个lib库，该lib库可以解压到任意路径，而本工具需要用到该lib库中的so。因此，对于C31版本，需要修改env.conf文件中的NPU_HOST_LIB和NPU_DEVICE_LIB环境变量，将它们指向正确的路径，然后再执行source env.conf。

（3）配置文件 config.json 包含哪些字段，又有哪些注意事项？

config.json 所有配置字段及注意事项介绍如下所示：

```None
{
    "operator_name":               配置caffe/tf算子名称
    "framework":                   只能配置为 "tensorflow" 或 "caffe"
    "DDK_PATH":                    配置DDK路径，参考 "/home/muser/tools/che/ddk/ddk"
    "custom_caffe_proto_file":     配置为含自定义算子的caffe.proto的文件路径
    "same_input_output_shape":     只能配置为 "False" 或 "True"
    "input_num":                   只能配置为正整数如"2", "auto" 和 "autoAll"
    "weight_num":                  只能配置为非负整数，可以配置为 0，可删;仅支持 caffe 算子
    "weight_num_param"             [ 无权值,可删除；仅支持 caffe 算子
        {
        "weight_1":                 只能配置为非负整数，可删             
        "weight_2":                 只能配置为非负整数，可删
        } 
                                   ]
    "filter_caffe_param":          过滤 caffe.proto 中的该 caffe 算子参数
    "tf_op_origin_name":           对应 tensorflow 中的算子名
    "tensorflow_param":            [ 无参数, 可删除
        {
            "param":               算子的第一个参数名  
            "type":                算子第一个参数的数据类型
        }，
        {
            "param":               算子的第二个参数名  
            "type":                算子第二个参数的数据类型
        }
                                   ]
     "project_path":               指定算子工程的生成路径，也可删除（默认生成在工具根目录）
     "caffe_operator_type":        对应 caffe 中的算子名，用于算子验证，数据校对
     "pycaffe_path":               用于设置 pycaffe 路径
     "net_prototxt":               caffe 整网 prototxt 文件路径， 用于整网模型分析
     "net_caffemodel":             caffe 整网 caffemodel 文件路径， 用于整网模型分析
     "net_pb":                     tensorflow 整网 pb 文件路径， 用于整网模型分析
     "operator_path":              caffe/tf 算子文件路径，用于不依赖插件的算子验证
     "plugin_path":                caffe/tf 插件文件路径，用于模型转换进行插件验证和算子整网验证
     "single_operator_run_cfg":    { 算子验证和算子整网验证模块的配置参数
         "dtype":                   
         "precision_deviation":
         "statistical_discrepancy":
                                   }
}                                      
```

