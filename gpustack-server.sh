pg_dump -h 127.0.0.1 -U root -d gpustack -f gpustack.bak
cat <<EOF >gpustack.sql
TRUNCATE TABLE model_providers, model_routes, model_route_targets RESTART IDENTITY CASCADE;
COPY model_providers (id, name, description, api_tokens, timeout, config, models, proxy_url, proxy_timeout, created_at, updated_at, deleted_at) FROM stdin;
1	Ling	\N	["gpustack_x16_y32"]	120	{"type": "openai", "openaiCustomUrl": "https://api-inference.modelscope.cn/v1"}	[{"name": "inclusionAI/Ling-2.6-1T", "category": "llm"}]	\N	\N	2023-07-17 12:34:56	2023-07-17 12:34:56	\N
2	LingFlash	\N	["gpustack_x16_y32"]	120	{"type": "openai", "openaiCustomUrl": "https://api-inference.modelscope.cn/v1"}	[{"name": "inclusionAI/Ling-2.6-flash", "category": "llm"}]	\N	\N	2023-07-17 12:34:56	2023-07-17 12:34:56	\N
3	DeepSeek	\N	["gpustack_x16_y32"]	120	{"type": "openai", "openaiCustomUrl": "https://api-inference.modelscope.cn/v1"}	[{"name": "deepseek-ai/DeepSeek-V4-Pro", "category": "llm"}]	\N	\N	2023-07-17 12:34:56	2023-07-17 12:34:56	\N
4	DeepSeekFlash	\N	["gpustack_x16_y32"]	120	{"type": "openai", "openaiCustomUrl": "https://api-inference.modelscope.cn/v1"}	[{"name": "deepseek-ai/DeepSeek-V4-Flash", "category": "llm"}]	\N	\N	2023-07-17 12:34:56	2023-07-17 12:34:56	\N
\.
COPY model_routes (id, name, description, categories, meta, created_by_model, targets, ready_targets, access_policy, generic_proxy, created_at, updated_at, deleted_at) FROM stdin;
1	Ling	\N	["llm"]	{}	f	1	1	AUTHED	f	2023-07-17 12:34:56	2023-07-17 12:34:56	\N
2	Ling-Flash	\N	["llm"]	{}	f	1	1	AUTHED	f	2023-07-17 12:34:56	2023-07-17 12:34:56	\N
3	DeepSeek	\N	["llm"]	{}	f	1	1	AUTHED	f	2023-07-17 12:34:56	2023-07-17 12:34:56	\N
4	DeepSeek-Flash	\N	["llm"]	{}	f	1	1	AUTHED	f	2023-07-17 12:34:56	2023-07-17 12:34:56	\N
\.
COPY model_route_targets (id, name, route_id, route_name, provider_id, provider_model_name, model_id, weight, fallback_status_codes, state, created_at, updated_at, deleted_at) FROM stdin;
1	modelscope	1	AI	1	inclusionAI/Ling-2.6-1T	\N	100	null	ACTIVE	2023-07-17 12:34:56	2023-07-17 12:34:56	\N
2	modelscope	2	AI	2	inclusionAI/Ling-2.6-Flash	\N	100	null	ACTIVE	2023-07-17 12:34:56	2023-07-17 12:34:56	\N
3	modelscope	3	AI	3	deepseek-ai/DeepSeek-V4-Pro	\N	100	null	ACTIVE	2023-07-17 12:34:56	2023-07-17 12:34:56	\N
4	modelscope	4	AI	4	deepseek-ai/DeepSeek-V4-Flash	\N	100	null	ACTIVE	2023-07-17 12:34:56	2023-07-17 12:34:56	\N
\.
EOF
psql -h 127.0.0.1 -U root -d gpustack <gpustack.sql
curl -H "Content-Type: application/json" http://admin:GPUStack@127.0.0.1:8000/v1/chat/completions \
  -d '{"seed":null,"stop":null,"temperature":1,"top_p":1,"max_tokens":1024,"frequency_penalty":0,"presence_penalty":0,"model":"DeepSeek","messages":[{"role":"user","content":"自我介绍"},{"role":"assistant","content":"提供简洁、高效的回答"}]}'
curl -H 'Content-Type: application/json' http://admin:GPUStack@127.0.0.1:8000/v2/api-keys \
  -d '{"name":"admin","expires_in":0,"description":"gpustack_x16_y32","allowed_model_names":[]}'
# Ubuntu
systemctl stop unattended-upgrades apt-daily.timer apt-daily-upgrade.timer
systemctl disable unattended-upgrades apt-daily.timer apt-daily-upgrade.timer
cat /etc/apt/apt.conf.d/20auto-upgrades
lvextend -l +100%FREE /dev/mapper/ubuntu--vg-ubuntu--lv
resize2fs /dev/mapper/ubuntu--vg-ubuntu--lv
LD_LIBRARY_PATH=$NVIDIA_CTK_LIBCUDA_DIR:$LD_LIBRARY_PATH
nerdctl -a /run/k3s/containerd/containerd.sock -n k8s.io exec -it gpustack bash

for i in api-server higress pilot gateway console; do j=higress-registry.cn-hangzhou.cr.aliyuncs.com/higress/${i}:latest && echo $j && crane config $j | yq -P ".history[].created_by" && echo; done
