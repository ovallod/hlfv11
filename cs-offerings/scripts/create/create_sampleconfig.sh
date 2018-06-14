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

echo "Creating Persistent Volumes"
if [ "${PAID}" == "true" ]; then
	echo "not yet covered"
else
	if [ "$(kubectl get pvc | grep sampleconfig-pvc | awk '{print $2}')" != "Bound" ]; then
		echo "The Persistant Volume does not seem to exist or is not bound"
		echo "Creating Persistant Volume"
		
		# making a pv on kubernetes
		echo "Running: kubectl create -f ${KUBECONFIG_FOLDER}/sampleconfig.yaml"
		kubectl create -f ${KUBECONFIG_FOLDER}/sampleconfig.yaml
		sleep 5
		if [ "kubectl get pvc | grep sampleconfig-pvc | awk '{print $3}'" != "sampleconfig-pv" ]; then
			echo "Success creating PV"
		else
			echo "Failed to create PV"
		fi
		echo "Waiting for sampleconfig pvc creation"
		while [ "$(kubectl get pvc | grep sampleconfig-pvc | awk '{print $2}')" != "Bound"  ]; do
			echo -n "."
			sleep 10
		done;
	fi
	echo
	echo "The Persistant Volume exists, copying sampleconfig file"
	kubectl create -f ${KUBECONFIG_FOLDER}/tools.yaml

	echo "Waiting to for tools deployment"
	while [ "$(kubectl get pods | awk '/utils/ { print $3 }')" != "Running" ]; do
		echo -n "."
		sleep 2
	done;
	echo "Copying crypto files"
	kubectl cp ${KUBECONFIG_FOLDER}/../../sampleconfig utils:.

	kubectl delete pods utils
	
	while [ "$(kubectl get pods | grep utils | wc -l | awk '{print $1}')" != "0" ]; do
        echo "Waiting for util pod to be deleted."
        sleep 1;
	done

fi

