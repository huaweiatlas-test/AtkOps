[EN](README.md)|CN

该目录用于存放 caffe 自定义算子相关的文件，包括两类：

（1）整网分析模块生成的不支持算子列表；

（2）由get_caffe_model.py生成的只包括输入层和自定义算子层的单算子模型。op_verify.py和net_verify.py会根据config.json中的caffe_operator_type字段选择对应的单算子模型。



