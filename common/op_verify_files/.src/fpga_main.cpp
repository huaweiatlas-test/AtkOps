/*
 * Copyright © Huawei Technologies Co., Ltd. 2012-2019. All rights reserved.
 * Description: Definition of fpga_main
 */
#include <unistd.h>
#include <thread>
#include <fstream>
#include <algorithm>
#include <hiaiengine/graph.h>
#include "hiaiengine/api.h"
#include "error_code.h"
#include "custom_common.h"

namespace config {

const static std::string GRAPH_CONFIG_PROTO_FILE = "./graph.config";
const static uint32_t GRAPH_ID = 101;
const static uint32_t SRC_ENGINE_ID = 1000;
const static uint32_t SRC_PORT_ID = 0;
const static uint32_t DST_ENGINE_ID = 1002;
const static uint32_t DEST_PORT_ID = 0;
const static uint32_t MAX_SLEEP_TIMER = 1800;  // time 30 * 60;
const static int MAX_TIMES = 30;

const int RT_DEV_BINARY_MAGIC_ELF = 0;
const int RT_DEV_BINARY_MAGIC_ELF_AICPU = 1;
const int RT_DEV_BINARY_MAGIC_ELF_AICPU_OPERATOR = 2;
const int FP32 = 0;
const int FP16 = 1;
const int FLOAT32 = 0;
const int FLOAT16 = 1;
const int SUCCESS = 0;
const int FAILED = -1;  // op run related

static std::string g_name = "";
static int32_t g_type = RT_DEV_BINARY_MAGIC_ELF_AICPU_OPERATOR;  // 0: ai core ; 1: ai cpu
static std::vector<uint32_t> g_outputSizeList = {};
const static std::string CONFIG_FILE = "./custom_op.cfg";
static std::string g_binFile = "";
static std::vector<std::string> g_inputFileList = {};
static std::vector<std::string> g_outputFileList = {};
static std::vector<int> g_datatypeList = {};  
// compare related
static float g_precisionDeviation = 0.8;
static float g_statisticalDiscrepancy = 0.8;
static std::vector<std::string> g_expectFileList = {};

#define BASE_NAME std::string("custom_op_run_temp_file_")
static std::mutex g_localTestMutex;
static std::condition_variable g_localTestCv;
static bool g_isTestResultReady = false;

}  // namespace config

using namespace config;

// Define Data Recv Interface
class DdkDataRecvInterface : public hiai::DataRecvInterface {
public:
    DdkDataRecvInterface() : fileName("")
    {
    }
    ~DdkDataRecvInterface()
    {
    }

    /**
    * @ingroup hiaiengine
    * @brief
    * @param [in]
    * @return HIAI Status
 */
    HIAI_StatusT RecvData(const std::shared_ptr<void> &message)
    {
        HIAI_ENGINE_LOG(HIAI_IDE_INFO, "Receive data.");

        std::shared_ptr<CustomOutput> customOutput =
            std::static_pointer_cast<CustomOutput>(message);
        if (customOutput == nullptr) {
            HIAI_ENGINE_LOG(HIAI_IDE_ERROR, "Fail to receive data");
            std::unique_lock<std::mutex> lck(g_localTestMutex);
            g_isTestResultReady = true;
            return HIAI_INVALID_INPUT_MSG;
        }
        if (config::g_outputFileList.size() != customOutput->outputList.size()) {
            HIAI_ENGINE_LOG(HIAI_IDE_ERROR, "Config output file list: %d != customOutput size: %d",
                            config::g_outputFileList.size(), customOutput->outputList.size());
            std::unique_lock<std::mutex> lck(g_localTestMutex);
            g_isTestResultReady = true;
            return HIAI_INVALID_INPUT_MSG;
        }

        for (uint32_t i = 0; i < customOutput->outputList.size(); i++) {
            WriteFile(config::g_outputFileList[i].c_str(), customOutput->outputList[i].data.get(),
                      customOutput->outputList[i].size);
            HIAI_ENGINE_LOG(HIAI_IDE_INFO, "Write output file %d success! s%", i, config::g_outputFileList[i].c_str());
        }
        std::string vertifyResultFileName = "./output/vertifyResult.txt";
        std::ofstream tfile(vertifyResultFileName);
        if (tfile.is_open()) {
            uint32_t indFile = 0;
            for (auto compareResult : customOutput->compareResultList) {
                if (indFile < config::g_outputFileList.size()) {
                    tfile << "Output file " << config::g_outputFileList[indFile] << " compare result ";
                    tfile << (compareResult ? "true" : "false") << std::endl;
                    indFile++;
                } else {
                    HIAI_ENGINE_LOG(HIAI_IDE_ERROR, "indFile is %d, outputFileList size is %d!", indFile,
                                    config::g_outputFileList.size());
                    tfile.close();
                    std::unique_lock<std::mutex> lck(g_localTestMutex);
                    g_isTestResultReady = true;
                    return HIAI_ERROR;
                }
            }
            if (0 == customOutput->compareResultList.size()) {
                tfile << "None vertification result!" << std::endl;
                tfile << "If you prefer to vertify output(s), please set vertify configuration." << std::endl;
            }
            tfile.close();
        } else {
            HIAI_ENGINE_LOG(HIAI_IDE_ERROR, "Failed to open vertifResult file %s!", vertifyResultFileName.c_str());
            std::unique_lock<std::mutex> lck(g_localTestMutex);
            g_isTestResultReady = true;
            return HIAI_ERROR;
        }

        std::unique_lock<std::mutex> lck(g_localTestMutex);
        g_isTestResultReady = true;

        HIAI_ENGINE_LOG(HIAI_IDE_INFO, "Receive data ok.");
        return HIAI_OK;
    }

private:
    std::string fileName;
};

// if device is disconnected, destroy the graph
HIAI_StatusT DeviceDisconnectCallBack()
{
    g_localTestMutex.lock();
    g_isTestResultReady = true;
    g_localTestMutex.unlock();
    return HIAI_OK;
}

// Init and create graph
HIAI_StatusT HIAI_InitAndStartGraph()
{
    // Step1: Global System Initialization before using HIAI Engine
    HIAI_StatusT status = HIAI_Init(0);

    // Step2: Create and Start the Graph
    status = hiai::Graph::CreateGraph(GRAPH_CONFIG_PROTO_FILE);
    if (status != HIAI_OK) {
        HIAI_ENGINE_LOG(HIAI_IDE_ERROR, "Failed to start graph.");
        return status;
    }

    // Step3: create graph
    std::shared_ptr<hiai::Graph> graph = hiai::Graph::GetInstance(GRAPH_ID);
    if (nullptr == graph) {
        HIAI_ENGINE_LOG(HIAI_IDE_ERROR, "Failed to get the graph-%u.", GRAPH_ID);
        return status;
    }

    hiai::EnginePortID targetPortConfig { .graph_id = GRAPH_ID, .engine_id = DST_ENGINE_ID, .port_id = DEST_PORT_ID };

    DdkDataRecvInterface *ddkRecv = nullptr;
    try {
        ddkRecv = new DdkDataRecvInterface();
    } catch (const std::bad_alloc &e) {
        return HIAI_ERROR;
    }
    graph->SetDataRecvFunctor(targetPortConfig,
                              std::shared_ptr<DdkDataRecvInterface>(ddkRecv));
    if ((config::g_type == RT_DEV_BINARY_MAGIC_ELF) || (config::g_type == RT_DEV_BINARY_MAGIC_ELF_AICPU)) {
        graph->RegisterEventHandle(hiai::HIAI_DEVICE_DISCONNECT_EVENT,
                                   DeviceDisconnectCallBack);
    }
    return HIAI_OK;
}

void CheckDestFileExist()
{
    int i = 0;
    while (true) {
        i++;
        HIAI_ENGINE_LOG(HIAI_IDE_WARNING, "Check result, go into sleep 1s.");
        sleep(1);
        std::unique_lock<std::mutex> lck(g_localTestMutex);
        if (g_isTestResultReady) {
            g_localTestCv.notify_all();
            break;
        }
        if (i > MAX_TIMES) {
            HIAI_ENGINE_LOG(HIAI_IDE_ERROR, "Get output file failed. ");
            HIAI_ENGINE_LOG(HIAI_IDE_ERROR, "Please stop and check input and output data.");
        }
    }
}

int ReadCommonFile(std::string path, FILE *stream, std::string &newPath)
{
    std::string inputData = "";
    // read file
    ifstream openFile(path);
    if (openFile.fail()) {
        fprintf(stream, "[Error] Open file failed.\n");
        return FAILED;
    }
    if (!getline(openFile, inputData)) {
        fprintf(stream, "[Error] Illegal input.\n");
        return FAILED;
    }
    const int HEAD_WORD_LENGTH = 9;
    if (inputData.length() <= HEAD_WORD_LENGTH) {
        fprintf(stream, "[Error] Illegal input.\n");
        return FAILED;
    }
    if (inputData.find("dataPath=", 0) == string::npos) {
        fprintf(stream, "[Error] Illegal input.\n");
        return FAILED;
    }
    newPath = "";
    for (unsigned int i = HEAD_WORD_LENGTH; i < inputData.length(); i++) {
        newPath = newPath + inputData[i];
    }
    return SUCCESS;
}

int ReadInputFile(std::string path, FILE *stream)
{
    std::string newPath = "";
    if (ReadCommonFile(path, stream, newPath) == FAILED) {
        return FAILED;
    }
    config::g_inputFileList.push_back(newPath);
    fprintf(stream, "input file path :%s\n", newPath.c_str());
    return SUCCESS;
}

int InputFileInit(std::string inputString, FILE *stream)
{
    int initResult = SUCCESS;
    std::string path = "";
    // read multiple input files
    for (unsigned int i = 0; i < inputString.length(); i++) {
        if (inputString[i] == ',') {
            initResult = ReadInputFile(path, stream);
            path = "";
            i++;
            if (initResult == FAILED) {
                return FAILED;
            }
        }
        path = path + inputString[i];
    }
    initResult = ReadInputFile(path, stream);
    if (initResult == FAILED) {
        return FAILED;
    }
    return SUCCESS;
}

int GetSizeData(std::string inputData, FILE *stream)
{
    const int HEAD_WORD_LENGTH_SIZE = 5;
    if (inputData.length() <= HEAD_WORD_LENGTH_SIZE) {
        fprintf(stream, "[Error] Illegal input.\n");
        return FAILED;
    }
    if (inputData.find("size=", 0) == string::npos) {
        fprintf(stream, "[Error] Illegal input.\n");
        return FAILED;
    }
    std::string inputSize = "";

    for (unsigned int i = HEAD_WORD_LENGTH_SIZE; i < inputData.length(); i++) {
        inputSize = inputSize + inputData[i];
        if (!isdigit(inputData[i])) {
            fprintf(stream, "[Error] Illegal input.\n");
            return FAILED;
        }
    }

    uint32_t intSize = stoi(inputSize);
    config::g_outputSizeList.push_back(intSize);
    fprintf(stream, "output size :%d\n", intSize);
    return SUCCESS;
}

int GetDataPath(std::string inputData, FILE *stream)
{
    const int HEAD_WORD_LENGTH_PATH = 9;
    if (inputData.length() <= HEAD_WORD_LENGTH_PATH) {
        fprintf(stream, "[Error] Illegal input.\n");
        return FAILED;
    }
    if (inputData.find("dataPath=", 0) == string::npos) {
        fprintf(stream, "[Error] Illegal input.\n");
        return FAILED;
    }
    std::string newPath = "";
    for (unsigned int j = HEAD_WORD_LENGTH_PATH; j < inputData.length(); j++) {
        newPath = newPath + inputData[j];
    }
    config::g_outputFileList.push_back(newPath);
    fprintf(stream, "output file path :%s\n", newPath.c_str());
    return SUCCESS;
}

int GetDtype(std::string inputData, FILE *stream)
{
    const int HEAD_WORD_LENGTH_DTYPE = 6;
    if (inputData.length() <= HEAD_WORD_LENGTH_DTYPE) {
        fprintf(stream, "[Error] Illegal input.\n");
        return FAILED;
    }
    if (inputData.find("dtype=", 0) == string::npos) {
        fprintf(stream, "[Error] Illegal input.\n");
        return FAILED;
    }
    std::string inputType = "";
    for (unsigned int k = HEAD_WORD_LENGTH_DTYPE; k < inputData.length(); k++) {
        inputType = inputType + inputData[k];
        if (!isdigit(inputData[k])) {
            fprintf(stream, "[Error] Illegal input.\n");
            return FAILED;
        }
    }

    int32_t intType = stoi(inputType);
    if ((intType != 0) && (intType != 1)) {
        fprintf(stream, "[Error] Illegal input.\n");
        return FAILED;
    }
    config::g_datatypeList.push_back(intType);
    fprintf(stream, "output type path :%d\n", intType);
    return SUCCESS;
}

int ReadOutputFile(std::string path, FILE *stream)
{
    ifstream outputFile(path);
    if (outputFile.fail()) {
        return FAILED;
    }

    // get size data
    std::string inputData = "";
    if (!getline(outputFile, inputData)) {
        return FAILED;
    }
    if (GetSizeData(inputData, stream) != SUCCESS) {
        return FAILED;
    }
    if (!getline(outputFile, inputData)) {
        return FAILED;
    }
    if (GetDataPath(inputData, stream) != SUCCESS) {
        return FAILED;
    }
    if (!getline(outputFile, inputData)) {
        return FAILED;
    }
    if (GetDtype(inputData, stream) != SUCCESS) {
        return FAILED;
    }
    return SUCCESS;
}

int OutputFileInit(std::string outputString, FILE *stream)
{
    std::string path = "";
    for (unsigned int i = 0; i < outputString.length(); i++) {
        if (outputString[i] == ',') {
            if (!ReadOutputFile(path, stream)) {
                fprintf(stream, "[Error] Open file failed.\n");
                return FAILED;
            }
            path = "";
            i++;
        }
        path = path + outputString[i];
    }
    int initResult = ReadOutputFile(path, stream);
    if (initResult == FAILED) {
        return FAILED;
    }
    return SUCCESS;
}

int ReadExpectFile(std::string path, FILE *stream)
{
    std::string newPath = "";
    if (ReadCommonFile(path, stream, newPath) == FAILED) {
        return FAILED;
    }
    config::g_expectFileList.push_back(newPath);
    fprintf(stream, "expect path :%s\n", newPath.c_str());
    return SUCCESS;
}

int ExpectFileInit(std::string expectString, FILE *stream)
{
    int initResult = SUCCESS;
    std::string path = "";
    for (unsigned int i = 0; i < expectString.length(); i++) {
        if (expectString[i] == ',') {
            initResult = ReadExpectFile(path, stream);
            if (initResult == FAILED) {
                return FAILED;
            }
            path = "";
            i++;
        }
        path = path + expectString[i];
    }
    initResult = ReadExpectFile(path, stream);
    if (initResult == FAILED) {
        return FAILED;
    }
    return SUCCESS;
}

int BinFileInit(std::string binString, FILE *stream)
{
    config::g_binFile = binString;
    fprintf(stream, "BinFile :%s\n", config::g_binFile.c_str());
    return SUCCESS;
}

int KernalNameInit(std::string nameString, FILE *stream)
{
    config::g_name = nameString;
    fprintf(stream, "KernalNameInit :%s\n", config::g_name.c_str());
    return SUCCESS;
}

bool IsFloat(std::string inputString)
{
    if ((inputString[0] != '1') && (inputString[0] != '0')) {
        return false;
    }
    if (inputString.length() == 1) {
        return true;
    }
    if (inputString[1] != '.') {
        return false;
    }
    for (unsigned int i = 2; i < inputString.length(); i++) {
        if ((inputString[i] < '0') || (inputString[i] > '9')) {
            return false;
        }
    }
    return true;
}

bool IsType(std::string inputString)
{
    if (inputString.length() != 1) {
        return false;
    }
    if ((inputString[0] < '0') || (inputString[0] > '2')) {
        return false;
    }
    return true;
}

int PrecisionDeviationInit(std::string deviationString, FILE *stream)
{
    // check if the input is illegal
    if (!IsFloat(deviationString)) {
        fprintf(stream, "[Error] Sorry, your input is illegal, please try again.\n"
                "\tExample:\n"
                "\t./op_run --help\n"
                "\t./op_run --inputTensor input1,input2 --outputTensor output1,output2 --expectTensor expect1,expect2 --binFile aicpu.so --precisionDeviation 0.8 --statisticalDiscrepancy 0.8 --kernalName Reduction --type 0\n"
                "\t./op_run -i input1,input2 -o output1,output2 -e expect1,expect2 -b aicpu.so -p 0.8 -d 0.8 -k Reduction -t 0\n"

                "Options:\n"
                "  --precisionDeviation     \n"
                "  -p                   Precision, optional if expect file exist, default(0.8) with no settings.\n");
        return FAILED;
    }
    config::g_precisionDeviation = stof(deviationString);
    fprintf(stream, "DeviationString :%f\n", config::g_precisionDeviation);
    return SUCCESS;
}

int StatisticalDiscrepancyInit(std::string discrepancyString, FILE *stream)
{
    // check if the input is illegal
    if (!IsFloat(discrepancyString)) {
        fprintf(stream, "[Error] Sorry, your input is illegal, please try again.\n"
                "\tExample:\n"
                "\t./op_run --help\n"
                "\t./op_run --inputTensor input1,input2 --outputTensor output1,output2 --expectTensor expect1,expect2 --binFile aicpu.so --precisionDeviation 0.8 --statisticalDiscrepancy 0.8 --kernalName Reduction --type 0\n"
                "\t./op_run -i input1,input2 -o output1,output2 -e expect1,expect2 -b aicpu.so -p 0.8 -d 0.8 -k Reduction -t 0\n"

                "Options:\n"
                "  --statisticalDiscrepancy     \n"
                "  -d                   Statistic, optional if expect file exist, default(0.8) with no settings.\n");
        return FAILED;
    }
    config::g_statisticalDiscrepancy = stof(discrepancyString);
    fprintf(stream, "DiscrepancyString :%f\n", config::g_statisticalDiscrepancy);
    return SUCCESS;
}

int TypeInit(std::string typeString, FILE *stream)
{
    // check if the input is illegal
    if (!IsType(typeString)) {
        fprintf(stream, "[Error] Sorry, your input is illegal, please try again.\n"
                "\tExample:\n"
                "\t./op_run --help\n"
                "\t./op_run --inputTensor input1,input2 --outputTensor output1,output2 --expectTensor expect1,expect2 --binFile aicpu.so --precisionDeviation 0.8 --statisticalDiscrepancy 0.8 --kernalName Reduction --type 0\n"
                "\t./op_run -i input1,input2 -o output1,output2 -e expect1,expect2 -b aicpu.so -p 0.8 -d 0.8 -k Reduction -t 0\n"

                "Options:\n"
                "  --type     \n"
                "  -t                   Operator type: 0 for TE operators, 1 for TE aicpu operators, 2 for C++ operators.\n");
        return FAILED;
    }
    config::g_type = stof(typeString);
    fprintf(stream, "Type :%d\n", config::g_type);
    return SUCCESS;
}

void UpgradeCmdUsage(FILE *stream)
{
    if (NULL == stream) {
        fprintf(stderr, "stream is null\n.");
        return;
    }

    fprintf(stream, "Usage:./op_run [OPTIONS]\n"
            "\tExample:\n"
            "\t./op_run --help\n"
            "\t./op_run --inputTensor input1,input2 --outputTensor output1,output2 --binFile aicpu.so --kernalName Reduction --type 0\n"
            "\t./op_run -i input1,input2 -o output1,output2 -b aicpu.so -k Reduction -t 0\n"
            "\t./op_run --inputTensor input1,input2 --outputTensor output1,output2 --expectTensor expect1,expect2 --binFile aicpu.so --kernalName Reduction --type 0\n"
            "\t./op_run -i input1,input2 -o output1,output2 -e expect1,expect2 -b aicpu.so -k Reduction -t 0\n"
            "\t./op_run --inputTensor input1,input2 --outputTensor output1,output2 --expectTensor expect1,expect2 --binFile aicpu.so --precisionDeviation 0.8 --statisticalDiscrepancy 0.8 --kernalName Reduction --type 0\n"
            "\t./op_run -i input1,input2 -o output1,output2 -e expect1,expect2 -b aicpu.so -p 0.8 -d 0.8 -k Reduction -t 0\n"

            "Options:\n"
            "  --inputTensor       \n"
            "  -i                   Input file, support for multiple files, separated by commas.\n"
            "  --outputTensor     \n"
            "  -o                   Output file, support for multiple files, separated by commas.\n"
            "  --expectTensor          \n"
            "  -e                   Expected output, optional, support for multiple files, amount is the same as output file, separated by commas.\n"
            "  --binFile               \n"
            "  -b                   Operator, .so file.\n"
            "  --precisionDeviation     \n"
            "  -p                   Precision, optional if expect file exist, default(0.8) with no settings.\n"
            "  --statisticalDiscrepancy     \n"
            "  -d                   Statistic, optional if expect file exist, default(0.8) with no settings.\n"
            "  --kernalName     \n"
            "  -k                   Kernal name, which first letter should be capital, TE operators can be customized, C++ operators will be the same as the operator type.\n"
            "  --type     \n"
            "  -t                   Operator type: 0 for TE operators, 1 for TE aicpu operators, 2 for C++ operators.\n");
}

int ReadFile(std::string param, const char *argv, FILE *stream)
{
    if ((param == "--inputTensor") || (param == "-i")) {
        if (InputFileInit(argv, stream) == SUCCESS) {
            return SUCCESS;
        }
    } else if ((param == "--outputTensor") || (param == "-o")) {
        if (OutputFileInit(argv, stream) == SUCCESS) {
            return SUCCESS;
        }
    } else if ((param == "--expectTensor") || (param == "-e")) {
        if (ExpectFileInit(argv, stream) == SUCCESS) {
            return SUCCESS;
        }
    }
    return FAILED;
}

int ReadParameter(std::string param, const char *argv, FILE *stream)
{
    if ((param == "--binFile") || (param == "-b")) {
        if (BinFileInit(argv, stream) == SUCCESS) {
            return SUCCESS;
        }
    } else if ((param == "--precisionDeviation") || (param == "-p")) {
        if (PrecisionDeviationInit(argv, stream) == SUCCESS) {
            return SUCCESS;
        }
    } else if ((param == "--statisticalDiscrepancy") || (param == "-d")) {
        if (StatisticalDiscrepancyInit(argv, stream) == SUCCESS) {
            return SUCCESS;
        }
    }
    return FAILED;
}

int ReadType(std::string param, const char *argv, FILE *stream)
{
    if ((param == "--kernalName") || (param == "-k")) {
        if (KernalNameInit(argv, stream) == SUCCESS) {
            return SUCCESS;
        }
    } else if ((param == "--type") || (param == "-t")) {
        if (TypeInit(argv, stream) == SUCCESS) {
            return SUCCESS;
        }
    }
    return FAILED;
}

int Initialization(unsigned int argc, char *argv[], FILE *stream)
{
    if ((argc & 1) == 0) {
        fprintf(stream, "[Error] Illegal command, please use --help for more tips.\n");
        return FAILED;
    }
    // handle the command line
    for (unsigned int i = 1; i < argc; i++) {
        std::string param(argv[i]);
        i++;
        if (ReadFile(param, argv[i], stream) == SUCCESS) {
            continue;
        }
        if (ReadParameter(param, argv[i], stream) == SUCCESS) {
            continue;
        }
        if (ReadType(param, argv[i], stream) == SUCCESS) {
            continue;
        }
        fprintf(stream, "[Error] Illegal param:%s.\n", param.c_str());
        return FAILED;
    }
    return SUCCESS;
}
// main
int main(int argc, char *argv[])
{
    if (argc > 1 && argv != NULL) {
        std::string param(argv[1]);
        if (param == "--help") {
            UpgradeCmdUsage(stdout);
            return SUCCESS;
        }
    }

    if (argv != NULL) {
        if (Initialization(argc, argv, stdout) != SUCCESS) {
            return FAILED;
        }
    }

    std::cout << "If you prefer to see log, please open log tab in MindStudio.";
    HIAI_ENGINE_LOG(HIAI_IDE_INFO, "Start to run ...");

    // Perform Initialziation
    HIAI_StatusT ret = HIAI_InitAndStartGraph();
    if (HIAI_OK != ret) {
        HIAI_ENGINE_LOG(HIAI_IDE_ERROR, "Failed to start graph.");
        // Now Stop the whole graph
        hiai::Graph::DestroyGraph(GRAPH_ID);
        return FAILED;
    }

    std::shared_ptr<hiai::Graph> graph = hiai::Graph::GetInstance(GRAPH_ID);
    if (nullptr == graph) {
        HIAI_ENGINE_LOG(HIAI_IDE_ERROR, "Failed to get the graph-%u.", GRAPH_ID);
        hiai::Graph::DestroyGraph(GRAPH_ID);
        return FAILED;
    }
    HIAI_ENGINE_LOG(HIAI_IDE_INFO, "Successed to to start graph.");

    // SourceEngine 0 port
    hiai::EnginePortID engineId { .graph_id = GRAPH_ID, .engine_id = SRC_ENGINE_ID, .port_id = SRC_PORT_ID };

    shared_ptr<CustomInfo> customInfo = make_shared<CustomInfo>();
    customInfo->name = config::g_name;
    customInfo->type = config::g_type;
    customInfo->outputSizeList = config::g_outputSizeList;
    uint32_t bufferSize = 0;
    char *binFile = ReadFile(config::g_binFile.c_str(), &bufferSize);
    customInfo->binFile = { bufferSize, shared_ptr<char>(binFile) };

    if (config::g_type == RT_DEV_BINARY_MAGIC_ELF_AICPU_OPERATOR) {
        char *configFile = ReadFile(config::CONFIG_FILE.c_str(), &bufferSize);
        customInfo->configFile = { bufferSize, shared_ptr<char>(configFile) };
    }
    for (auto &in_file : config::g_inputFileList) {
        char *input1 = ReadFile(in_file.c_str(), &bufferSize);
        customInfo->inputList.push_back({ bufferSize, shared_ptr<char>(input1) });
    }

    customInfo->dataTypeList = config::g_datatypeList;
    customInfo->precisionDeviation = 1.0 - config::g_precisionDeviation;
    customInfo->statisticalDiscrepancy = 1.0 - config::g_statisticalDiscrepancy;
    for (auto &e_file : config::g_expectFileList) {
        char *expexct = ReadFile(e_file.c_str(), &bufferSize);
        customInfo->expectFileList.push_back({ bufferSize, shared_ptr<char>(expexct) });
    }

    graph->SendData(engineId, "string", std::static_pointer_cast<void>(customInfo));

    // Wait for result
    std::thread check_thread(CheckDestFileExist);
    check_thread.join();
    std::unique_lock<std::mutex> lck(g_localTestMutex);
    g_localTestCv.wait_for(lck, std::chrono::seconds(MAX_SLEEP_TIMER), [] { return g_isTestResultReady; });

    // Now Stop the whole graph
    hiai::Graph::DestroyGraph(GRAPH_ID);
    std::cout << "RUN Finished." << std::endl;
    HIAI_ENGINE_LOG(HIAI_IDE_INFO, "RUN Finished.");
    return SUCCESS;
}


