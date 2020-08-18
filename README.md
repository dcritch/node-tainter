# node-tainter
## (un)taint a node under certain conditions

Hypothetically speaking, you may find yourself in a spot where:
* a thing you deploy in kubernetes does not tolerate a taint on a node you set
* there is another thing, say an operator, that will immediately revert any attempts to modify that thing's daemonset/deployment/pod/etc to tolerate your taint

If you have found yourself in such a situation, this repo will might help.

## details

These steps will deploy a DaemonSet to run a very simple [script](check_taint.sh) that will check if a given pod in a namespace is running and if not, briefly untaint the node long enough for that pod to spin up.

Modify the node-tainter [DaemonSet yaml](node-tainter-ds.yaml) to suit your namespace/pod/taint combo, e.g.:

```python
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-tainter
  namespace: node-tainter
spec:
  selector:
    matchLabels:
      name: node-tainter
  template:
    metadata:
      labels:
        name: node-tainter
    spec:
      tolerations:
      - key: worker
        value: load-balancer
      containers:
      - name: node-tainter
        image: quay.io/dcritch/node-tainter
        imagePullPolicy: IfNotPresent
        env:
        - name: INSPECT_NS
          value: "openshift-dns"
        - name: NODE_NAME
          valueFrom:
            fieldRef:
              apiVersion: v1
              fieldPath: spec.nodeName
        - name: TAINT_KEY
          value: "worker"
        - name: TAINT_VALUE
          value: "load-balancer"
        - name: POD_NAME
          value: "openshift-dns"
        - name: SLEEP_MINUTES
          value: "10"
        command:
        - /bin/bash
        - -c
        - |
          while /bin/true; do
            /check_taint.sh
            echo checking again in $SLEEP_MINUTES minutes
            sleep $(expr 60 \* $SLEEP_MINUTES)
          done
      temintationGracePeriodSeconds: 10
      nodeSelector:
        node-role.kubernetes.io/load-balancer: ""
```

Deploy on kubernetes:
```
kubectl create namespace node-tainter
kubectl create -f node-tainter-role.yaml
kubectl create -f node-tainter-role-binding.yaml
kubectl create -f node-tainter-ds.yaml --validate=false
```

or OpenShift:
```
oc new-project node-tainter
oc create -f node-tainter-role.yaml
oc create -f node-tainter-role-binding.yaml
oc create -f node-tainter-ds.yaml
```
