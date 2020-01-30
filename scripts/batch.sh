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
  # return code:
  #   0: built
  #   1: skipped
  #   2: failed

  local -r image_name="$1"
  local -r version="$2"

  if $SKIP_BUILT; then
    if check_image_exists "$image_name"; then
      info "$image_name already on Docker Hub. Skipping."
      return 1
    fi
  fi

  info "Building image for brittany $version: $image_name"
  run "$SCRIPTS_DIR/build.sh" "$image_name" "$version" || return 2

  info "Testing $image_name"
  run "$SCRIPTS_DIR/test.sh" "$image_name" || return 2

  if ! $SKIP_PUSH; then
    info "Pushing $image_name"
    run docker push "$image_name" || exit 1
  fi

  return 0
}

function main() {
  local -r image_repo=$1

  local versions latest
  if [ $# -eq 1 ]; then
    read -r -a versions < <(cabal list --simple-output brittany | sed -n 's/brittany \(.*\)/\1/p' | xargs)
    # TODO: Find a canonical way to obtain the latest version from Hackage.
    latest=$(awk '{print $NF}' <<< "${versions[*]}")
  else
    latest=$2
    shift; shift
    versions=( "$@" )
  fi

  info "Building for versions: ${versions[*]}"
  info "Latest version is: $latest"

  local -a completed=()
  local -a built=()

  for v in "${versions[@]}"; do
    local result=0
    try_version "$image_repo:$v" "$v" || result=$?

    case $result in
      0 )
        # built
        built+=( "$v" )
        completed+=( "$v" )
        ;;
      1 )
        # skipped
        completed+=( "$v" )
        ;;
      2 )
        # failed
        ;;
    esac
  done

  if ! $SKIP_PUSH; then
    info "Tagging the latest version ($latest)"
    if [[ " ${built[*]} " == *" $latest "* ]]; then
      run docker tag "$image_repo:$latest" "$image_repo:latest"
      run docker push "$image_repo:latest"
    else
      warn "$image_repo:$latest wasn't built in this run. Skipping."
    fi
  fi

  if [ "${completed[*]}" != "${versions[*]}" ]; then
    error "Some versions could not be built."
    error "Tried:     ${versions[*]}"
    error "Completed: ${completed[*]}"
    exit 1
  fi

  exit 0
}

main "$@"
