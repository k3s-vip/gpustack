pg_dump -h 127.0.0.1 -U root -d gpustack -f gpustack.bak
cat <<EOF >gpustack.sql
TRUNCATE TABLE model_providers, model_routes, model_route_targets RESTART IDENTITY CASCADE;
COPY model_providers (id, name, description, api_tokens, timeout, config, models, proxy_url, proxy_timeout, created_at, updated_at, deleted_at) FROM stdin;
1	GLM	\N	["ai_x16_y32"]	120	{"type": "openai", "openaiCustomUrl": "https://api-inference.modelscope.cn/v1"}	[{"name": "ZhipuAI/GLM-5.1", "category": "llm"}]	\N	\N	2026-01-23 12:34:56	2026-01-23 12:34:56	\N
2	Kimi	\N	["ai_x16_y32"]	120	{"type": "openai", "openaiCustomUrl": "https://api-inference.modelscope.cn/v1"}	[{"name": "moonshotai/Kimi-K2.5", "category": "llm"}]	\N	\N	2026-01-23 12:34:56	2026-01-23 12:34:56	\N
3	DeepSeek	\N	["ai_x16_y32"]	120	{"type": "openai", "openaiCustomUrl": "https://api-inference.modelscope.cn/v1"}	[{"name": "deepseek-ai/DeepSeek-V3.2", "category": "llm"}]	\N	\N	2026-01-23 12:34:56	2026-01-23 12:34:56	\N
\.
COPY model_routes (id, name, description, categories, meta, created_by_model, targets, ready_targets, access_policy, generic_proxy, created_at, updated_at, deleted_at) FROM stdin;
1	GLM-5.1	\N	["llm"]	{}	f	1	1	AUTHED	f	2026-01-23 12:34:56	2026-01-23 12:34:56	\N
2	Kimi-K2.5	\N	["llm"]	{}	f	1	1	AUTHED	f	2026-01-23 12:34:56	2026-01-23 12:34:56	\N
3	DeepSeek-V3.2	\N	["llm"]	{}	f	1	1	AUTHED	f	2026-01-23 12:34:56	2026-01-23 12:34:56	\N
\.
COPY model_route_targets (id, name, route_id, route_name, provider_id, provider_model_name, model_id, weight, fallback_status_codes, state, created_at, updated_at, deleted_at) FROM stdin;
1	modelscope	1	AI1	1	ZhipuAI/GLM-5.1	\N	100	null	ACTIVE	2026-01-23 12:34:56	2026-01-23 12:34:56	\N
2	modelscope	2	AI2	2	moonshotai/Kimi-K2.5	\N	100	null	ACTIVE	2026-01-23 12:34:56	2026-01-23 12:34:56	\N
3	modelscope	3	AI3	3	deepseek-ai/DeepSeek-V3.2	\N	100	null	ACTIVE	2026-01-23 12:34:56	2026-01-23 12:34:56	\N
\.
EOF
psql -h 127.0.0.1 -U root -d gpustack <gpustack.sql
curl -H "Content-Type: application/json" http://admin:GPUStack@127.0.0.1:8080/v1/chat/completions \
  -d '{"seed":null,"stop":null,"temperature":1,"top_p":1,"max_tokens":1024,"frequency_penalty":0,"presence_penalty":0,"model":"DeepSeek-V3.2","messages":[{"role":"user","content":"自我介绍"},{"role":"assistant","content":"提供热情、细腻的回答"}]}'
curl -H 'Content-Type: application/json' http://admin:GPUStack@127.0.0.1:8080/v2/api-keys \
  -d '{"name":"admin","expires_in":0,"description":"ai_x16_y32","allowed_model_names":[]}'
# Ubuntu
systemctl stop unattended-upgrades apt-daily.timer apt-daily-upgrade.timer
systemctl disable unattended-upgrades apt-daily.timer apt-daily-upgrade.timer
cat /etc/apt/apt.conf.d/20auto-upgrades
lvextend -l +100%FREE /dev/mapper/ubuntu--vg-ubuntu--lv
resize2fs /dev/mapper/ubuntu--vg-ubuntu--lv
LD_LIBRARY_PATH=$NVIDIA_CTK_LIBCUDA_DIR:$LD_LIBRARY_PATH
nerdctl -a /run/k3s/containerd/containerd.sock -n k8s.io exec -it gpustack bash

for i in api-server higress pilot gateway console; do j=higress-registry.cn-hangzhou.cr.aliyuncs.com/higress/${i}:latest && echo $j && crane config $j | yq -P ".history[].created_by" && echo; done
/apiserver
/usr/local/bin/higress
/usr/local/bin/pilot-discovery
# gateway
/usr/local/bin/envoy
/var/lib/istio/envoy/envoy_bootstrap_lite_tmpl.json
/var/lib/istio/envoy/envoy_bootstrap_tmpl.json
/var/lib/istio/envoy/golang-filter.so
/usr/local/bin/pilot-agent
/usr/local/bin/supercronic-linux-amd64 # supercronic
# console(java)
/app/higress-console.jar
/app/tools/mcp/main
/app/tools/mcp/openapiToMcpserver.sh
