#!/usr/bin/env bash

set -x
if [[ -z $INSPECT_NS || -z $INSPECT_NS || -z $TAINT_KEY || -z $TAINT_VALUE ]]; then
	echo "one or more environment variables are not defined. bailing."
        exit 1
fi
echo "checking for taint on $NODE_NAME"
if [[ $(oc get node $NODE_NAME -o json | jq '.spec.taints | length') -eq 0 ]]; then
	echo "taint not present on $NODE_NAME. skipping"
	exit
fi
if [[ $(oc get node $NODE_NAME -o json | jq '.spec.taints[]  | select(.key==env.TAINT_KEY and .value==env.TAINT_VALUE)' | wc -l) -eq 0 ]]; then
	echo "taint not present on $NODE_NAME. skipping"
	exit
fi
echo "checking $INSPECT_NS status on $NODE_NAME"
pod_count=$(oc get pods -n $INSPECT_NS -o wide | grep -c $NODE_NAME)
if [[ $pod_count -eq 0 ]]; then
	oc adm taint node $NODE_NAME worker:NoSchedule-
	while [[ $(oc get pods -n $INSPECT_NS -o wide | grep -c $NODE_NAME) -ne 1 ]]; do
		continue	
	done
	oc adm taint node $NODE_NAME worker=load-balancer:NoSchedule
fi
