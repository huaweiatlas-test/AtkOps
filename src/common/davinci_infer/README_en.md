EN|[CN](README.md)

# Davinci Model Inference Test Framework 

---------------------------------------------------------

## Introduction
- Execute build.sh to construct the project：
  ```bash
  ./build.sh
  ```
- Then execute DavinciInfer with params below, devieId means the chip Id, and config.ini is the path of config file：
  ```
  DavinciInfer deviceId ./config.ini
  ```

## Configuration Introduction
- config.ini

  ```
  graph_id = 100
  src_engine_id = 1000
  des_engine_id = 1001
  test_img_list_path = /home/xxx/img_files.txt
  engine_config_path = /home/xxx/davinci_infer/test_data/config/graph_sample.prototxt
  result_file_path = /home/xxx//davinci_infer/result
  ```

  test_img_list_path is the list of test image files，multi batch input should offer multi files for each batch

  engine_config_path is the path of graph_config，to config the relation of engines

  result_file_path is the path of result file

- graph_sample.prototxt

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
  

the model_path should be set which means the path of om model file

- input data

  the structure of the input data file:

  | input num | input1 length | input2 length | ......                       | input1 data         | ...... |
  | --------- | ------------- | ------------- | ---------------------------- | ------------------- | ------ |
  | 4bytes    | 4bytes        | 4bytes        | 4bytes for each input length | input1 length bytes | ...... |


## Others
- Supported Version:1.31.T15.B150 / 1.3.2.B893
- Supported OS：Ubuntu16.04
- Error cases:

1. hdc open device fail, permission denied:  caused by the limitation of user rights, try to add the current user to HwHiAiUser user group and switch to it.
2. CheckDataLen failed: the input data length doesn't match the model input.
3. engine init failed: the om model maybe wrong, check the model path and the model.
4. get device id error: the input device id maybe wrong.
5. file path is invalid: the path of input data maybe wrong.
