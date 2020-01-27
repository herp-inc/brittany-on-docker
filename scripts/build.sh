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
  local -r patch_path="$4"

  local relative_patch_path
  relative_patch_path="$(realpath --relative-to="$DOCKERFILE_DIR" "$patch_path")"

  docker build "$DOCKERFILE_DIR" \
    -t "$image_name" \
    --build-arg STACK_IMAGE="$build_image" \
    --build-arg TARBALL="$tarball_url" \
    --build-arg PATCH_FILE="$relative_patch_path"
}

function main() {
  local -r image_name="$1"
  local -r version="$2"

  local -r tarball_url="https://github.com/lspitzner/brittany/archive/$version.tar.gz"
  local resolver
  resolver=$(curl -sSL https://raw.githubusercontent.com/lspitzner/brittany/"$version"/stack.yaml | yq read - resolver)

  local -r patch_file="$PATCHES_DIR/$version.patch"
  local -r patch_dest_file="$LOCAL_TMP_DIR/fix.patch"

  if [ -f "$patch_file" ]; then
    cp "$patch_file" "$patch_dest_file"
  else
    touch "$patch_dest_file"
  fi

  build_image "fpco/stack-build:$resolver" "$image_name" "$tarball_url" "$patch_dest_file"

  rm -f "$patch_dest_file"

  exit 0
}

main "$@"
