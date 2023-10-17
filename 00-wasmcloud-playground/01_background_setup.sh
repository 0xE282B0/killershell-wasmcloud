#!/bin/bash

# Stop k8s services
# systemctl list-unit-files | grep enabled
DISABLE_K8S="systemctl disable --now kubepods.slice; systemctl disable --now kubelet; rm -rf /root/.kube"
ssh node01 $DISABLE_K8S &
ssh controlplane $DISABLE_K8S &

# Setup wash cli
SETUP_WASH_CLI="curl -s https://packagecloud.io/install/repositories/wasmcloud/core/script.deb.sh | bash && \
DEBIAN_FRONTEND=noninteractive apt-get install -y wash openssl"
ssh controlplane $SETUP_WASH_CLI &
ssh node01 $SETUP_WASH_CLI &

SET_SEED="export WASMCLOUD_CLUSTER_SEED=$(openssl rand -hex 29 | tr '[:lower:]' '[:upper:]')"
echo $SET_SEED >> ~/.bashrc && $SET_SEED

bash ~/multinode-setup.sh
wait

#echo "WASMCLOUD_CLUSTER_SEED: $WASMCLOUD_CLUSTER_SEED"
#wash up --nats-port 4223 --cluster-seed $WASMCLOUD_CLUSTER_SEED --detach
#
#scp /root/.local/share/nats/nsc/keys/creds/local/APP/wash.creds 172.30.2.2:
#nohup ssh 172.30.2.2 "wash up --detach --nats-remote-url nats://172.30.1.2 --nats-port 4223 --nats-credsfile wash.creds --cluster-seed $WASMCLOUD_CLUSTER_SEED"
#
touch /tmp/finished
