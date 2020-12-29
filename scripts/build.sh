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

function build_image_from_source() {
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

function build_image_from_binary() {
  local -r build_image="$1"
  local -r image_name="$2"
  local -r executable_path="$3"

  local relative_executable_path
  relative_executable_path="$(realpath --relative-to="$DOCKERFILE_DIR" "$executable_path")"

  docker build "$DOCKERFILE_DIR" \
    -f "$DOCKERFILE_DIR/Dockerfile-bin" \
    -t "$image_name" \
    --build-arg HASKELL_IMAGE="$build_image" \
    --build-arg EXECUTABLE_FILE="$relative_executable_path"
}

function from_binary() {
  local -r image_name="$1"
  local -r version="$2"
  local -r zip_path="$3"

  local -r executable_path="$LOCAL_TMP_DIR/brittany"

  unzip -q "$zip_path" -d "$LOCAL_TMP_DIR"
  if [ ! -f "$executable_path" ]; then
    warn "Could not locate brittany executable in $zip_path; Trying a build from source"
    from_source "$image_name" "$version"
    exit 0
  fi

  # TODO: Find a canonical way to obtain GHC version from the binary
  local ghc_version
  ghc_version=$(strings "$executable_path" | { grep -o 'ghc-[[:digit:]]\+\.[[:digit:]]\+\.[[:digit:]]\+' || true; } | head -n1 | cut -d- -f2)
  if [ -z "$ghc_version" ]; then
    warn "Could not detect GHC version of $executable_path; Trying a build from source"
    from_source "$image_name" "$version"
    exit 0
  fi

  info "Detected a prebuilt binary for GHC $ghc_version"
  build_image_from_binary "haskell:$ghc_version" "$image_name" "$executable_path"

  exit 0
}

function from_source() {
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

  build_image_from_source "fpco/stack-build:$resolver" "$image_name" "$tarball_url" "$patch_dest_file"

  rm -f "$patch_dest_file"

  exit 0
}

function main() {
  local -r image_name="$1"
  local -r version="$2"

  local -r binary_url="https://github.com/lspitzner/brittany/releases/download/$version/brittany-$version-linux.zip"

  local binary_tmp
  binary_tmp=$(mktemp)
  if curl -fsL -o "$binary_tmp" "$binary_url"; then
    from_binary "$image_name" "$version" "$binary_tmp"
  else
    from_source "$image_name" "$version"
  fi

  exit 0
}

main "$@"
