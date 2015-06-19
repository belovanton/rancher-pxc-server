#!/bin/bash

set -e

[ "$DEBUG" == "1" ] && set -x && set +e

PXC_NODES=$1
PXC_SST_PASSWORD=`etcdctl --no-sync -C ${ETCD_IP}:4001 get /pxcsstpassword`
PXC_ROOT_PASSWORD=`etcdctl --no-sync -C ${ETCD_IP}:4001 get /pxcrootpassword`

if [ "${PXC_NODES}" == "**ChangeMe**" ]; then
   echo "ERROR: You did not specify "PXC_NODES_ADDRESS" environment variable - Exiting..."
   exit 1
fi
if [ "${PXC_SST_PASSWORD}" == "**ChangeMe**" ]; then
   echo "ERROR: You did not specify "PXC_SST_PASSWORD" environment variable - Exiting..."
   exit 1
fi

PXC_NODES=`echo ${PXC_NODES} | sed "s/ //g"`

echo "=> Configuring PXC cluster"
MY_RANCHER_IP=`ip addr | grep inet | grep 10.42 | tail -1 | awk '{print $2}' | awk -F\/ '{print $1}'`
for node in `echo ${PXC_NODES} | sed "s/,/ /"g`; do
   echo "=> Updating PXC cluster to add my IP to the cluster"
   echo "=> Trying to update configuration on node $node ..."
   sshpass -p ${PXC_ROOT_PASSWORD} ssh ${SSH_OPTS} root@$node "change_pxc_nodes.sh \"${PXC_NODES}\""
done
etcdctl --no-sync -C ${ETCD_IP}:4001 set /pxcnodes ${PXC_NODES}
echo "PXC_NODES=\"${PXC_NODES}\"" > ${PXC_CONF_FLAG}
