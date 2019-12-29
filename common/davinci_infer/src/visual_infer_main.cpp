/*
 * License: Copyright (c) Huawei Technologies Co., Ltd. 2012-2019. All rights reserved.
 * Description: host侧入口代码
 * Date: 2019-02-28
 * LastEditTime: 2019-09-24 17:17:28
 */
#include <unistd.h>
#include <thread>
#include <fstream>
#include <sstream>
#include <algorithm>
#include <string>
#include "hiaiengine/api.h"
#include "inc/error_code.h"
#include "inc/common.h"
#include "inc/data_recv.h"
#include "inc/util.h"
#include "config_parser/config_parser.h"


uint32_t g_count = 0;
std::string g_resultSavePath = "";
int g_state = -1;
/**
* ingroup HIAI_InitAndStartGraph
* brief 初始化并创建Graph
* param [in]
*/
HIAI_StatusT HIAI_InitAndStartGraph(int deviceId)
{
    // Step1: 初始化HiaiEngine
    HIAI_StatusT status = HIAI_Init(deviceId);
    HIAI_ENGINE_LOG("[DEBUG] Go to start Graph");
    // Step2: 根据proto文件配置创建Graph
    status = hiai::Graph::CreateGraph(engine_config_path);
    if (status != HIAI_OK) {
        HIAI_ENGINE_LOG(status, "Fail to start graph");
        return status;
    }
    HIAI_ENGINE_LOG("[DEBUG] Start Graph success");

    // Step3: 对DST Engine设置Call Back回调
    std::shared_ptr<hiai::Graph> graph = hiai::Graph::GetInstance(graph_id);
    if (nullptr == graph) {
        HIAI_ENGINE_LOG("Fail to get the graph-%u", graph_id);
        return status;
    }

    HIAI_ENGINE_LOG("Graph ID: %d, DST Engine ID: %d", graph_id, des_engine_id);

    // 配置目标数据： 目标Graph、目标Engine、目标Port
    hiai::EnginePortID targetPortConfig;
    targetPortConfig.graph_id = graph_id;
    targetPortConfig.engine_id = des_engine_id;
    targetPortConfig.port_id = DEST_PORT_ID_0;
    graph->SetDataRecvFunctor(targetPortConfig, std::shared_ptr<InferDataRecvInterface>(new InferDataRecvInterface("null")));

    HIAI_ENGINE_LOG("SetDataRecvFunctor set finished !!!");
    return HIAI_OK;
}

/**
* ingroup CheckAllSamplesProcessFinished
* brief 检查所有样本处理是否完成
*/
void CheckAllProcessFinished()
{
    while (g_count != g_SendCount) {
        ;
    }

    // 文件已经生成，通知主线程继续执行
    std::unique_lock <std::mutex> lck(g_local_test_mutex);
    is_test_result_ready = true;
    g_local_test_cv_.notify_all();
}

/**
* ingroup main
* brief 程序主函数
* param [in]: argc, argv
*/
int main(int argc, char* argv[])
{
    if (argc != 3) {
        std::cout << "Command format is incorrect!" << std::endl \
                  << "./DavinciInfer deviceId config.ini" << std::endl;
        return -1;
    }

    std::stringstream ss;
    ss << argv[1];
    int deviceId;
    ss >> deviceId;
  
    // parser ini file
    map<string, string> iniCfg;
    ReadConfig(argv[2], iniCfg);
    PrintConfig(iniCfg);

    engine_config_path = iniCfg["engine_config_path"];
    test_img_list_path = iniCfg["test_img_list_path"];
    g_resultSavePath = iniCfg["result_file_path"];

    ss.clear();
    ss << iniCfg["graph_id"];
    ss >> graph_id;
    
    ss.clear();
    ss << iniCfg["src_engine_id"];
    ss >> src_engine_id;
    
    ss.clear();
    ss << iniCfg["des_engine_id"];
    ss >> des_engine_id;

    // 获取测试图像的总数目
    vector<shared_ptr<string>> fileList = Util::GetFilenameList(shared_ptr<string>(new string(test_img_list_path)));
    g_SendCount = fileList.size();

    std::cout << "engine_config_path: " << engine_config_path << std::endl;
    std::cout << "test_img_list_path: " << test_img_list_path << std::endl;
    std::cout << "g_resultSavePath: " << g_resultSavePath << std::endl;
    std::cout << "g_SendCount: " << g_SendCount << std::endl;
    
    std::cout << "graph_id: " << graph_id << std::endl;
    std::cout << "src_engine_id: " << src_engine_id << std::endl;
    std::cout << "des_engine_id: " << des_engine_id << std::endl;

    // 初始化并创建Graph
    HIAI_StatusT ret = HIAI_OK;
    ret = HIAI_InitAndStartGraph(deviceId);
    if (ret != HIAI_OK) {
        HIAI_ENGINE_LOG("Fail to start graph");
        return -1;
    }

    std::shared_ptr<hiai::Graph> graph = hiai::Graph::GetInstance(graph_id);
    if (nullptr == graph) {
        HIAI_ENGINE_LOG("Fail to get the graph-%u", graph_id);
        return -1;
    }

    // 发送数据到Source Engine
    hiai::EnginePortID targetEngine;
    targetEngine.graph_id = graph_id;
    targetEngine.engine_id = src_engine_id;
    targetEngine.port_id = SRC_PORT_ID;

    std::shared_ptr<std::string> srcString = std::shared_ptr<std::string>(new std::string(test_img_list_path));
    graph->SendData(targetEngine, "string", std::static_pointer_cast<void>(srcString));

    // 等待处理结果
    std::thread checkThread(CheckAllProcessFinished);
    checkThread.join();
    std::unique_lock <std::mutex> lck(g_local_test_mutex);
    g_local_test_cv_.wait_for(lck, std::chrono::seconds(MAX_SLEEP_TIMER), [] { return is_test_result_ready; });

    // 销毁Graph
    hiai::Graph::DestroyGraph(graph_id);
    
    return g_state;
}
