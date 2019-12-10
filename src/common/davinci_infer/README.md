[EN](README_en.md)|CN

# Davinci模型端对端测试框架

---------------------------------------------------------

## 使用说明
- 执行build.sh构建工程：
  ```bash
  ./build.sh
  ```

  若提示找不到编译器，可能为DDK_PATH环境变量未配置

- 跟目录会生成可执行文件DavinciInfer，带config.ini参数执行：

  ```
  DavinciInfer deviceId ./config.ini
  ```

## 配置文件说明
- config.ini配置文件说明

  ```
  graph_id = 100
  src_engine_id = 1000
  des_engine_id = 1001
  test_img_list_path = /home/xxx/img_files.txt
  engine_config_path = /home/xxx/davinci_infer/test_data/config/graph_sample.prototxt
  result_file_path = /home/xxx//davinci_infer/result
  ```

  test_img_list_path参数为测试图像（数据）的文件名列表，图像文件名最好给绝对路径

  engine_config_path参数为graph_config路径，用于配置引擎关系

  result_file_path参数为结果数据保存路径

- graph_sample.prototxt配置文件说明

  ```
    engines {
      id: 1005
      engine_name: "RawDataMutilInferEngine"
      side: DEVICE
      so_name:"/home/xxx/davinci_infer/libai_engine.so"
      thread_num: 1
      ai_config{
        items{
            name: "model_path"
            value:"/home/xxx/davinci_infer/test_data/model/sub_graph.om"
            sub_items{
              name: "batchsize"
              value:"1"
            }
        }
        
      }
  ```
  

需要设置om模型的文件路径model_path

- 输入数据说明

  测试数据以文件的形式输入，格式为：

  | 输入个数 | 输入1长度 | 输入2长度 | ......                  | 输入1数据           | ......       |
  | -------- | --------- | --------- | ----------------------- | ------------------- | ------------ |
  | 4字节    | 4字节     | 4字节     | 每个输入对应4字节的长度 | 对应输入1长度的数据 | 后续输入类似 |

## 其他
支持版本:1.31.T15.B150 / 1.3.2.B893

操作系统：Ubuntu16.04

异常情况：

1、若提示device权限不足，则可能为用户权限问题，请尝试将当前用户加入HwHiAiUser用户组并切换到该用户组

2、若提示输入数据与模型输入不匹配，则应排查输入数据大小是否与模型输入对应

3、若提示graph初始化失败，则应排查配置的om模型是否存在问题

4、若提示device id错误，则可能为输入参数中的device id无效

5、若提示输入数据路径错误，则可能为输入数据文件列表中的文件路径存在问题