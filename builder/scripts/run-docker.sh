#!/bin/bash
set -e

THISDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source ${THISDIR}/common.sh

VM_HOME="/home/builder"
IMAGE_REVISION="20180619"
IMAGE_NAME="aac/ubuntu-base:${IMAGE_REVISION}"
VOLUME_NAME="buildervolume"
VOLUME_MOUNT_POINT="/workdir"

EXTRA_OPTIONS=""
if [ -d ${QNX_BASE} ]; then
	EXTRA_OPTIONS="-v ${QNX_BASE}:${VM_HOME}/qnx700"
fi

execute_command() {
	docker run -it --rm \
	-v ${VOLUME_NAME}:${VOLUME_MOUNT_POINT} \
	-v ${SDK_HOME}:${VM_HOME}/aac \
	-e ANDROID_TOOLCHAIN=${VOLUME_MOUNT_POINT}/android \
	-e HOST_PWD=${PWD} \
	-e HOST_SDK_HOME=${SDK_HOME} \
	${EXTRA_OPTIONS} \
	${IMAGE_NAME} $@
}

if [[ "$(docker images -q ${IMAGE_NAME} 2> /dev/null)" == "" ]]; then
	note "Building Docker image..."
	docker build -t ${IMAGE_NAME} ${BUILDER_HOME}/scripts
fi

if [[ "$(docker volume ls | grep ${VOLUME_NAME} 2> /dev/null)" == "" ]]; then
	note "Creating Docker volume \"${VOLUME_NAME}\"..."
	docker volume create --name ${VOLUME_NAME}
	note "Changing permissions for volume..."
	execute_command sudo chown -R builder:builder ${VOLUME_MOUNT_POINT}
fi

note "Run Docker image..."
execute_command $@