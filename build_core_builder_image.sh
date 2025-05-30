#! /bin/bash

usage() {
cat <<_EOF_
Usage: ./build_core_builder_image.sh [OPTIONS]...

Builds an iRODS core builder image.

Example:

    ./build_core_builder_image.sh --image-name <arg> ...

Available options:

    --image-tag             Desired tag for the new docker image
    --dockerfile            Dockerfile to build (required)
    --no-cache              Do not use cached images when building
    -h, --help              This message
_EOF_
    exit
}

# defaults
image_name=irods-core-builder
build_args=
docker_build_args=
dockerfile=

while [ -n "$1" ]; do
    case "$1" in
        --image-name)       shift; image_name=${1};;
        --dockerfile)       shift; dockerfile=${1};;
        --no-cache)         shift; docker_build_args="--no-cache";;
        -h|--help)          usage;;
    esac
    shift
done

DOCKER_BUILDKIT=1 docker build $docker_build_args -f $dockerfile -t $image_name $build_args .
