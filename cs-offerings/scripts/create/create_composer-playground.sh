#!/bin/bash

if [ "${PWD##*/}" == "create" ]; then
    KUBECONFIG_FOLDER=${PWD}/../../kube-configs
elif [ "${PWD##*/}" == "scripts" ]; then
    KUBECONFIG_FOLDER=${PWD}/../kube-configs
else
    echo "Please run the script from 'scripts' or 'scripts/create' folder"
fi

PAID=false

Parse_Arguments() {
	while [ $# -gt 0 ]; do
		case $1 in
			--paid)
				echo "Configured to setup a paid storage on ibm-cs"
				PAID=true
				;;
		esac
		shift
	done
}

Parse_Arguments $@

if [ "${PAID}" == "true" ]; then
	OFFERING="paid"
else
	OFFERING="free"
fi

echo "Creating composer-card-import pod"
# Default to "channel1" if not defined
if [ -z "${CHANNEL_NAME}" ]; then
	echo "CHANNEL_NAME not defined. I will use \"channel1\"."
	echo "I will wait 5 seconds before continuing."
	sleep 5
fi
CHANNEL_NAME=${CHANNEL_NAME:-channel1}

# Default to "localhost" if not defined
#if [ -z "${HLFV_IP_ADDRESS}" ]; then
#	echo "HLFV_IP_ADDRESS not defined. I will use \"localhost\"."
#	echo "I will wait 5 seconds before continuing."
#	sleep 5
#fi
#HLFV_IP_ADDRESS=${HLFV_IP_ADDRESS:-localhost}

echo "Preparing yaml file for creating composer-card-import pod"
sed -e "s/%CHANNEL_NAME%/${CHANNEL_NAME}/g" ${KUBECONFIG_FOLDER}/composer-card-import.yaml.base > ${KUBECONFIG_FOLDER}/composer-card-import.yaml.base
#sed -e "s/%HLFV_IP_ADDRESS%/${HLFV_IP_ADDRESS}/g" ${KUBECONFIG_FOLDER}/composer-card-import.yaml.base2 > ${KUBECONFIG_FOLDER}/composer-card-import.yaml


echo "Running: kubectl create -f ${KUBECONFIG_FOLDER}/composer-card-import.yaml"
kubectl create -f ${KUBECONFIG_FOLDER}/composer-card-import.yaml

while [ "$(kubectl get pod -a composer-card-import | grep composer-card-import | awk '{print $3}')" != "Completed" ]; do
    echo "Waiting for composer-card-import container to be Completed"
    sleep 1;
done

if [ "$(kubectl get pod -a composer-card-import | grep composer-card-import | awk '{print $3}')" == "Completed" ]; then
	echo "Composer Card Import Completed Successfully"
fi

if [ "$(kubectl get pod -a composer-card-import | grep composer-card-import | awk '{print $3}')" != "Completed" ]; then
	echo "Composer Card Import Failed"
fi

echo "Deleting composer-card-import pod"
echo "Running: kubectl delete -f ${KUBECONFIG_FOLDER}/composer-card-import.yaml"
kubectl delete -f ${KUBECONFIG_FOLDER}/composer-card-import.yaml

while [ "$(kubectl get svc | grep composer-card-import | wc -l | awk '{print $1}')" != "0" ]; do
	echo "Waiting for composer-card-import pod to be deleted"
	sleep 1;
done

echo "Creating composer-playground deployment"
echo "Running: kubectl create -f ${KUBECONFIG_FOLDER}/composer-playground.yaml"
kubectl create -f ${KUBECONFIG_FOLDER}/composer-playground.yaml

if [ "$(kubectl get svc | grep composer-playground | wc -l | awk '{print $1}')" == "0" ]; then
    echo "Creating composer-playground service"
    echo "Running: kubectl create -f ${KUBECONFIG_FOLDER}/composer-playground-${OFFERING}.yaml"
    kubectl create -f ${KUBECONFIG_FOLDER}/composer-playground-services-${OFFERING}.yaml
fi

echo "Checking if all deployments are ready"

NUMPENDING=$(kubectl get deployments | grep composer-playground | awk '{print $5}' | grep 0 | wc -l | awk '{print $1}')
while [ "${NUMPENDING}" != "0" ]; do
    echo "Waiting on pending deployments. Deployments pending = ${NUMPENDING}"
    NUMPENDING=$(kubectl get deployments | grep composer-playground | awk '{print $5}' | grep 0 | wc -l | awk '{print $1}')
done

echo "Composer playground created successfully"
