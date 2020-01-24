#!/usr/bin/env bash
#
# Build a docker image for brittany.
#
# usage:
#   ./build.sh [image_name] [version]
#
# example:
#   ./build.sh herpinc/brittany:0.12.1.1 0.12.1.1
#

set -euo pipefail

cd "$(dirname "$0")"
source ./lib/source.sh

function build_image() {
  local build_image=$1
  local image_name=$2
  local tarball_url="$3"
  local patch="$4"

  docker build "$DOCKERFILE_DIR" \
    -t $image_name \
    --build-arg STACK_IMAGE=$build_image \
    --build-arg TARBALL="$tarball_url" \
    --build-arg PATCH="$patch"
}

function main() {
  local image_name=$1
  local version=$2

  local tarball_url="https://github.com/lspitzner/brittany/archive/$version.tar.gz"
  local resolver=$(curl -sSL https://raw.githubusercontent.com/lspitzner/brittany/$version/stack.yaml | yq read - resolver)

  local patch_file="$PATCHES_DIR/$version.patch"
  local patch="$([ -f "$patch_file" ] && cat "$patch_file")"

  build_image fpco/stack-build:$resolver $image_name "$tarball_url" "$patch"
}

main "$@"
