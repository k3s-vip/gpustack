#!/usr/bin/env sh

pg_dump -h 127.0.0.1 -U root -d gpustack -f gpustack.bak
cat <<EOF >gpustack.sql
TRUNCATE TABLE model_providers, model_routes, model_route_targets RESTART IDENTITY CASCADE;
COPY model_providers (id, name, description, api_tokens, timeout, config, models, proxy_url, proxy_timeout, created_at, updated_at, deleted_at, owner_principal_id) FROM stdin;
1	gpustack	\N	["token_43"]	120	{"type": "openai", "openaiCustomUrl": "https://server.gpustack.ai/v1"}	[{"name": "Qwen3.6-27B", "category": "llm"}, {"name": "Qwen3-VL-32B-Instruct", "category": "llm"}, {"name": "Qwen3-VL-32B-Thinking", "category": "llm"}]	\N	\N	2006-01-02 15:04:05	2006-01-02 15:04:05	\N	1
\.
COPY model_routes (id, name, description, categories, meta, targets, ready_targets, access_policy, generic_proxy, created_at, updated_at, deleted_at, created_model_id, owner_principal_id) FROM stdin;
1	Qwen3	\N	["llm"]	{}	2	2	AUTHED	f	2006-01-02 15:04:05	2006-01-02 15:04:05	\N	\N	1
2	Qwen3-VL	\N	["llm"]	{}	3	3	AUTHED	f	2006-01-02 15:04:05	2006-01-02 15:04:05	\N	\N	1
\.
COPY model_route_targets (id, name, route_id, route_name, provider_id, overridden_model_name, model_id, weight, fallback_status_codes, state, created_at, updated_at, deleted_at) FROM stdin;
1	Qwen3-27B	1	Qwen3	1	Qwen3.6-27B	\N	100	null	ACTIVE	2006-01-02 15:04:05	2006-01-02 15:04:05	\N
2	Qwen3-32B	1	Qwen3	1	Qwen3-VL-32B-Instruct	\N	0	["5xx", "4xx"]	ACTIVE	2006-01-02 15:04:05	2006-01-02 15:04:05	\N
3	Qwen3-VL-32B	2	Qwen3-VL	1	Qwen3-VL-32B-Instruct	\N	100	null	ACTIVE	2006-01-02 15:04:05	2006-01-02 15:04:05	\N
4	Qwen3-VL-32B	2	Qwen3-VL	1	Qwen3-VL-32B-Thinking	\N	50	null	ACTIVE	2006-01-02 15:04:05	2006-01-02 15:04:05	\N
5	Qwen3-VL-27B	2	Qwen3-VL	1	Qwen3.6-27B	\N	0	["5xx", "4xx"]	ACTIVE	2006-01-02 15:04:05	2006-01-02 15:04:05	\N
\.
EOF
psql -h 127.0.0.1 -U root -d gpustack <gpustack.sql
curl -H "Content-Type: application/json" http://admin:passw0rd@127.0.0.1:8000/v1/chat/completions \
  -d '{"max_tokens":1024,"model":"Qwen3","messages":[{"role":"user","content":"自我介绍"},{"role":"assistant","content":"提供简洁、高效的回答"}]}'
# Ubuntu
systemctl stop unattended-upgrades apt-daily.timer apt-daily-upgrade.timer
systemctl disable unattended-upgrades apt-daily.timer apt-daily-upgrade.timer
cat /etc/apt/apt.conf.d/20auto-upgrades
lvextend -l +100%FREE /dev/mapper/ubuntu--vg-ubuntu--lv
resize2fs /dev/mapper/ubuntu--vg-ubuntu--lv
LD_LIBRARY_PATH=$NVIDIA_CTK_LIBCUDA_DIR:$LD_LIBRARY_PATH

for i in api-server higress pilot gateway console; do j=higress-registry.cn-hangzhou.cr.aliyuncs.com/higress/${i}:latest && echo $j && crane config $j | yq -P ".history[].created_by" && echo; done

# 查看access日志
kubectl -n higress-system logs ds/higress-gateway | grep x_forwarded_for | sed 's~"~\n~g' | grep -E "^[0-9].+:[0-9]+$" | awk -F: '{print $1}' | sort -u
directADDR=127.0.0.1
directPORT=30080
directBEARER=token_43
proxyADDR=server.gpustack.ai
proxyPORT=8000
proxyBEARER=token_43
echo
echo "$directPORT=$directBEARER"
curl -H "host: $proxyADDR" -sH "Content-Type: application/json" "$directADDR:$directPORT/v1/models" -H "Authorization: Bearer $directBEARER" | yq '.data[].id' -P && curl -H "host: $proxyADDR" -sH "Content-Type: application/json" "$directADDR:$directPORT/v1/chat/completions" -H "Authorization: Bearer $directBEARER" \
  -d '{"max_tokens":64,"model":"Qwen3","messages":[{"role":"user","content":"自我介绍"},{"role":"assistant","content":"提供简洁、高效的回答"}]}' | yq '.choices[].message.content' -P
echo
echo "$proxyPORT=$proxyBEARER"
curl -H "host: $proxyADDR" -sH "Content-Type: application/json" "$directADDR:$proxyPORT/v1/models" -H "Authorization: Bearer $proxyBEARER" | yq '.data[].id' -P && curl -H "host: $proxyADDR" -sH "Content-Type: application/json" "$directADDR:$proxyPORT/v1/chat/completions" -H "Authorization: Bearer $proxyBEARER" \
  -d '{"max_tokens":64,"model":"Qwen3","messages":[{"role":"user","content":"自我介绍"},{"role":"assistant","content":"提供简洁、高效的回答"}]}' | yq '.choices[].message.content' -P
