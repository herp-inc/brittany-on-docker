#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")"
# shellcheck source=scripts/lib/source.sh
source ./lib/source.sh

readonly SKIP_BUILT=${SKIP_BUILT:-false}
readonly SKIP_PUSH=${SKIP_PUSH:-false}

function run() {
  local command="$*"
  progress "$command"
  bash -c "$command"
  return $?
}

function check_image_exists() {
  local -r image_name="$1"
  DOCKER_CLI_EXPERIMENTAL=enabled docker manifest inspect "$image_name" > /dev/null 2>&1
  return $?
}

function try_version() {
  local -r image_name="$1"
  local -r version="$2"

  if $SKIP_BUILT; then
    if check_image_exists "$image_name"; then
      info "$image_name already on Docker Hub. skipping."
      return 0
    fi
  fi

  info "Building image for brittany $version: $image_name"
  run "$SCRIPTS_DIR/build.sh" "$image_name" "$version" || return 1

  info "Testing $image_name"
  run "$SCRIPTS_DIR/test.sh" "$image_name" || return 1

  if ! $SKIP_PUSH; then
    info "Pushing $image_name"
    run docker push "$image_name" || exit 1
  fi
}

function main() {
  local -r image_repo=$1

  local versions latest
  if [ $# -eq 1 ]; then
    versions=$(cabal list --simple-output brittany | sed -n 's/brittany \(.*\)/\1/p' | tr '\n' ' ')
    # TODO: Find a canonical way to obtain the latest version from Hackage.
    latest=$(echo "$versions" | awk '{print $NF}')
  else
    latest=$2
    shift
    versions="$*"
  fi

  info "Building for versions: $versions"
  info "Latest version is: $latest"

  local completed=""
  for v in $versions; do
    try_version "$image_repo:$v" "$v" || continue
    completed="$completed $v"
  done

  if [ "$completed" != "$versions" ]; then
    error "Some versions could not be built."
    error "Tried: $versions"
    error "Completed: $completed"
    exit 1
  fi

  if ! try_version "$image_repo:latest" "$latest"; then
    error "Could not build the latest version: $latest"
    exit 1
  fi
}

main "$@"
