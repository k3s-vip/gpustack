## 概述

GPUStack 是一个开源的 GPU 集群管理器，用于 AI 模型推理服务和 GPU 实例供应。它配置和编排推理引擎（vLLM、SGLang、TensorRT-LLM
或您自定义的引擎），并支持通过 SSH 访问的 GPU 实例。其核心功能包括：

- **多集群 GPU 管理。** 跨多个环境管理 GPU 集群。这包括本地服务器、Kubernetes 集群和云提供商。
- **可插拔推理引擎。** 自动配置高性能推理引擎，如 vLLM、SGLang，也可以添加自定义推理引擎。
- **Day 0 模型支持。** GPUStack 的可插拔引擎架构能够在新模型发布当天即可部署。
- **性能优化配置。** 提供预调优模式，用于低延迟或高吞吐量。GPUStack 支持扩展的 KV 缓存系统，如 LMCache 和 HiCache，以减少
  TTFT。还包括对推测性解码方法（如 EAGLE3、MTP 和 N-grams）的内置支持。
- **GPU 实例。** 按需启动可通过 SSH 访问的 GPU 实例，适用于开发、微调和交互式工作负载。
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

基于 Kubernetes 安装并启动 GPUStack [Higress](https://higress.ai)：[helm-controller](https://github.com/k3s-io/helm-controller)

```shell
# kubectl create -f k8s/helm-controller.yaml
customresourcedefinition.apiextensions.k8s.io/helmchartconfigs.helm.cattle.io created
customresourcedefinition.apiextensions.k8s.io/helmcharts.helm.cattle.io created
clusterrole.rbac.authorization.k8s.io/helm-controller created
clusterrolebinding.rbac.authorization.k8s.io/helm-controller created
serviceaccount/helm-controller created
deployment.apps/helm-controller created
# kubectl create -f k8s/higress-core.yaml
helmchart.helm.cattle.io/higress-core created
```

基于 Kubernetes 安装并启动 GPUStack [PostgreSQL](https://www.postgresql.org)：[postgres-operator](https://github.com/zalando/postgres-operator)

```shell
# kubectl create -f k8s/postgres-operator.yaml
customresourcedefinition.apiextensions.k8s.io/operatorconfigurations.acid.zalan.do created
customresourcedefinition.apiextensions.k8s.io/postgresqls.acid.zalan.do created
customresourcedefinition.apiextensions.k8s.io/postgresteams.acid.zalan.do created
operatorconfiguration.acid.zalan.do/postgres-operator created
priorityclass.scheduling.k8s.io/postgres-operator-pod created
serviceaccount/postgres-operator created
clusterrole.rbac.authorization.k8s.io/postgres-pod created
clusterrole.rbac.authorization.k8s.io/postgres-operator created
clusterrolebinding.rbac.authorization.k8s.io/postgres-operator created
service/postgres-operator created
deployment.apps/postgres-operator created
# kubectl create ns gpustack-system
namespace/gpustack-system created
# kubectl create -f k8s/postgres-gpustack.yaml
postgresql.acid.zalan.do/postgres-gpustack created
```

基于 Kubernetes 安装并启动 GPUStack：

```shell
# kubectl create -f k8s/gpustack-server.yaml
serviceaccount/gpustack-server created
clusterrole.rbac.authorization.k8s.io/gpustack-server-ingressclass-viewer created
clusterrole.rbac.authorization.k8s.io/gpustack-server-higress-operations created
clusterrolebinding.rbac.authorization.k8s.io/gpustack-server-ingressclass-viewer-binding created
clusterrolebinding.rbac.authorization.k8s.io/gpustack-server-higress-operations-binding created
role.rbac.authorization.k8s.io/gpustack-server created
rolebinding.rbac.authorization.k8s.io/gpustack-server-binding created
service/gpustack-higress-plugins created
service/gpustack-server created
service/gpustack-server-cluster-ip created
deployment.apps/gpustack-higress-plugins created
statefulset.apps/gpustack-server created
ingress.networking.k8s.io/default created
# kubectl get pods -A | grep -E '(postgres-operator|gpustack-higress-plugins|gpustack-server|postgres-gpustack|higress-controller|higress-gateway|helm-controller|helm-install-higress-core)-'
NAMESPACE         NAME                                        READY   STATUS      RESTARTS     AGE
default           postgres-operator-1234567890-12345          1/1     Running     0            2m22s
gpustack-system   gpustack-higress-plugins-1234567890-12345   1/1     Running     0            1m15s
gpustack-system   gpustack-server-0                           1/1     Running     0 (1m ago)   1m15s
gpustack-system   postgres-gpustack-0                         1/1     Running     0            1m55s
gpustack-system   postgres-gpustack-1                         1/1     Running     0            1m35s
higress-system    higress-controller-1234567890-12345         2/2     Running     0            2m34s
higress-system    higress-gateway-12345                       1/1     Running     0            2m34s
kube-system       helm-controller-1234567890-12345            1/1     Running     0            3m21s
kube-system       helm-install-higress-core-12345             0/1     Completed   0            2m43s
```

使用 Docker 安装并启动 GPUStack：

```shell
# GPUStack server
docker \
  run -d --name gpustack --restart unless-stopped --network=host \
  -v /data/gpustack:/var/lib/gpustack \
  -e GPUSTACK_BOOTSTRAP_PASSWORD=passw0rd \
  -e GPUSTACK_SYSTEM_DEFAULT_CONTAINER_REGISTRY=swr.cn-south-1.myhuaweicloud.com \
  swr.cn-south-1.myhuaweicloud.com/gpustack/gpustack:v2.3.0 \
  --port=8000 --tls-port=8443 \
  --disable-openapi-docs \
  --disable-update-check \
  --gateway-mode=embedded
# GPUStack worker
docker \
  run -d --name gpustack-worker --restart unless-stopped --network=host \
  -v /data/gpustack:/var/lib/gpustack \
  -e GPUSTACK_SYSTEM_DEFAULT_CONTAINER_REGISTRY=swr.cn-south-1.myhuaweicloud.com \
  -e GPUSTACK_RUNTIME_DEPLOY_MIRRORED_NAME=gpustack-worker \
  -e GPUSTACK_TOKEN=gpustack_x16_y32 \
  -v /var/run/docker.sock:/var/run/docker.sock --privileged --runtime=nvidia \
  swr.cn-south-1.myhuaweicloud.com/gpustack/gpustack:v2.3.0
```

打开浏览器，访问进入 GPUStack UI。使用默认用户名 `admin` 和上面设置的密码
`passw0rd` 登录。

### 测试模型

```shell
curl -H "Content-Type: application/json" -u admin:passw0rd http://127.0.0.1:8000/v1/chat/completions \
  -d '{"max_tokens":64,"model":"Qwen3","messages":[{"role":"user","content":"自我介绍"},{"role":"assistant","content":"提供简洁、高效的回答"}]}'
```
