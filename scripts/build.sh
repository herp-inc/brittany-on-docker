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
# shellcheck source=scripts/lib/source.sh
source ./lib/source.sh

function build_image() {
  local -r build_image="$1"
  local -r image_name="$2"
  local -r tarball_url="$3"
  local -r patch="$4"

  docker build "$DOCKERFILE_DIR" \
    -t "$image_name" \
    --build-arg STACK_IMAGE="$build_image" \
    --build-arg TARBALL="$tarball_url" \
    --build-arg PATCH="$patch"
}

function main() {
  local -r image_name="$1"
  local -r version="$2"

  local tarball_url resolver patch_file patch

  tarball_url="https://github.com/lspitzner/brittany/archive/$version.tar.gz"
  resolver=$(curl -sSL https://raw.githubusercontent.com/lspitzner/brittany/"$version"/stack.yaml | yq read - resolver)

  patch_file="$PATCHES_DIR/$version.patch"
  # shellcheck disable=SC2015
  patch="$([ -f "$patch_file" ] && cat "$patch_file" || true)"

  build_image "fpco/stack-build:$resolver" "$image_name" "$tarball_url" "$patch"
}

main "$@"
