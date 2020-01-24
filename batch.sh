#!/usr/bin/env bash

set -euo pipefail


readonly SKIP_BUILT=${SKIP_BUILT:-false}
readonly SKIP_PUSH=${SKIP_BUILT:-false}

function check_image_exists() {
  local image_name=$1
  DOCKER_CLI_EXPERIMENTAL=enabled docker manifest inspect $image_name > /dev/null 2>&1
  return $?
}

function try_version() {
  local image_name=$1
  local version=$2

  if $SKIP_BUILT; then
    if check_image_exists ${image_name}; then
      echo "$image_name already on Docker Hub. skipping."
      return 0
    fi
  fi

  echo "Building image for brittany $version: $image_name"
  ./build.sh $image_name $version || return -1

  echo "Testing $image_name"
  ./test.sh $image_name || return -1

  if ! $SKIP_PUSH; then
    echo "Pushing $image_name"
    docker push $image_name || exit -1
  fi
}

function main() {
  local image_repo=$1
  if [ $# -eq 1 ]; then
    local versions=$(cabal list --simple-output brittany | sed -n 's/brittany \(.*\)/\1/p' | tr '\n' ' ')
    # TODO: Find a canonical way to obtain the latest version from Hackage.
    local latest=$(echo "$versions" | awk '{print $NF}')
  else
    local latest=$2
    shift
    local versions="$@"
  fi

  echo "Building for versions: $versions (latest: $latest)"

  local completed=""
  for v in $versions; do
    try_version $image_repo:$v $v || continue
    completed="$completed $v"
  done

  if [ "$completed" != "$versions" ]; then
    echo "Some versions could not be built."
    echo "Tried: $versions"
    echo "Completed: $completed"
    exit 1
  fi

  if ! try_version $image_repo:latest $latest; then
    echo "Could not build the latest version: $latest"
    exit 1
  fi
}

main "$@"
