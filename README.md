## 概述

GPUStack 是一个开源的 GPU 集群管理器，专为高效的 AI 模型部署而设计。配置和编排推理引擎（vLLM、SGLang、TensorRT-LLM
或自定义的引擎），以优化跨 GPU 集群的性能。其核心功能包括：

- **多集群 GPU 管理。** 跨多个环境管理 GPU 集群。这包括本地服务器、Kubernetes 集群和云提供商。
- **可插拔推理引擎。** 自动配置高性能推理引擎，如 vLLM、SGLang，也可以添加自定义推理引擎。
- **Day 0 模型支持。** GPUStack 的可插拔引擎架构能够在新模型发布当天即可部署。
- **性能优化配置。** 提供预调优模式，用于低延迟或高吞吐量。GPUStack 支持扩展的 KV 缓存系统，如 LMCache 和 HiCache，以减少
  TTFT。还包括对推测性解码方法（如 EAGLE3、MTP 和 N-grams）的内置支持。
- **企业级运维能力。** 支持自动故障恢复、负载均衡、监控、认证和访问控制。

## 架构

GPUStack 使开发团队、IT 组织和服务提供商能够大规模地提供模型即服务。支持用于 LLM、语音、图像和视频模型的行业标准
API。内置用户认证和访问控制、GPU 性能和利用率的实时监控，以及使用量和请求率的计量。

下图是管理跨本地和云环境的多个 GPU 集群。GPUStack 调度器分配 GPU 以最大化资源利用率，并调度推理引擎以实现最佳性能。通过集成的
Grafana 和 Prometheus 仪表板展示系统运行状况和指标。
![gpustack-v2-architecture](docs/assets/gpustack-v2-architecture.png)

有关详细的要求和设置说明，请参阅[安装要求](https://docs.gpustack.ai/latest/installation/requirements/)文档。

## 快速入门

### 前提条件

1. 一个至少配备一块 NVIDIA GPU 的节点。对于其他类型的 GPU，请在 GPUStack UI 中添加 worker
   时查看指南，或参阅[安装文档](https://docs.gpustack.ai/latest/installation/requirements/)获取更多详细信息。
2. 确保 worker 节点上已安装 NVIDIA 驱动程序、[Docker](https://docs.docker.com/engine/install/)
   和 [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html)。
3. 一个用于托管 GPUStack server 的 CPU 节点。GPUStack server 不需要 GPU，可以在仅有 CPU 的机器上运行。
   GPUStack worker 节点仅支持 Linux。

### 安装部署

[requirements.md#port-requirements](https://github.com/gpustack/gpustack/blob/main/docs/installation/requirements.md#port-requirements)

使用 Docker 安装并启动 GPUStack server：

```bash
docker \
  run -d --name gpustack --restart unless-stopped --network=host \
  -v /var/lib/gpustack:/var/lib/gpustack \
  -v /datapool/models:/var/lib/gpustack/cache \
  -e GPUSTACK_SYSTEM_DEFAULT_CONTAINER_REGISTRY=swr.cn-south-1.myhuaweicloud.com \
  swr.cn-south-1.myhuaweicloud.com/gpustack/gpustack:v2.1.2 \
  --bootstrap-password=passw0rd \
  --port=8000 --tls-port=8443 \
  --disable-openapi-docs \
  --disable-update-check \
  --gateway-mode=embedded \
  --server-external-url=http://192.168.64.64:8000
```

使用 Docker 安装并启动 GPUStack worker：

```bash
docker \
  run -d --name gpustack-worker --restart unless-stopped --network=host \
  -v /var/lib/gpustack:/var/lib/gpustack \
  -v /datapool/models:/var/lib/gpustack/cache \
  -e GPUSTACK_SYSTEM_DEFAULT_CONTAINER_REGISTRY=swr.cn-south-1.myhuaweicloud.com \
  -e GPUSTACK_RUNTIME_DEPLOY_MIRRORED_NAME=gpustack-worker \
  -e GPUSTACK_SERVER_URL=http://192.168.64.64:8000 \
  -e GPUSTACK_TOKEN=gpustack_x16_y32 \
  -v /var/run/docker.sock:/var/run/docker.sock --privileged --runtime=nvidia \
  swr.cn-south-1.myhuaweicloud.com/gpustack/gpustack:v2.1.2
```

打开浏览器，访问进入 GPUStack UI。使用默认用户名 `admin` 和上面设置的密码
`passw0rd` 登录。

### 测试模型

```bash
curl -u admin:passw0rd http://127.0.0.1:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
  "seed": null,
  "stop": null,
  "temperature": 1,
  "top_p": 1,
  "max_tokens": 16384,
  "frequency_penalty": 0,
  "presence_penalty": 0,
  "model": "DeepSeek",
  "messages": [
    {
      "role": "user",
      "content": "自我介绍"
    },
    {
      "role": "assistant",
      "content": "提供简洁、高效的回答"
    }
  ]
}'
```

### 部署截图

基于 DaemonSet 自动安装 [NVIDIA Container Toolkit](k3s/nvidia-container-toolkit.yaml)
![](k3s/nvidia-container-toolkit.png)
使用 deviceQuery 校验 GPU 可用性
![](k3s/nvidia-cuda-sample.png)
