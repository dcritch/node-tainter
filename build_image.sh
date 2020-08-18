#!/usr/bin/env bash

set -ex
source env_build

wget -O oc.tar.gz https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/stable/openshift-client-linux.tar.gz
tar -xzvf oc.tar.gz oc

export IMAGE=node-tainter
export TAG=${1:-latest}
export REGISTRY=quay.io/dcritch

echo building $IMAGE:$TAG

podman login -u $REDHAT_USER -p $REDHAT_PW registry.redhat.io
container=$(buildah from registry.redhat.io/ubi8-minimal)
echo "building container with id $container"
buildah config --label maintainer="David Critch <dcritch@gmail.com>" $container
#buildah run $container dnf -y install jq
buildah run $container microdnf -y install jq
buildah copy $container ./oc /usr/local/bin
buildah copy $container ./check_taint.sh /
buildah config --cmd /copy-image.sh $container
buildah commit --format docker $container $IMAGE:$TAG

podman login -u $QUAY_USER -p $QUAY_PW quay.io
podman tag localhost/$IMAGE:$TAG $REGISTRY/$IMAGE:$TAG
podman push $REGISTRY/$IMAGE:$TAG

