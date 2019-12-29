[EN](README.md)|CN

该目录用于存放 tensorflow自定义算子相关的文件，包括两类：

（1）整网分析模块生成的不支持算子列表；

（2）由get_tf_model_and_data.py生成的只包括输入层和自定义算子层的单算子模型，注意执行get_tf_model_and_data.py会先将本目录下原有的.om和.pb文件都先删除，然后再生成单算子模型的pb文件。

