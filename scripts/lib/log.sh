#!/bin/false
# shellcheck shell=bash

readonly HEADER_LENGTH=16

function _log() {
  local -r header="$1"
  local -r color="$2"
  local -r message="$3"

  # should we colorize the output?
  if [ -t 1 ] && [ -v TERM ] && type tput > /dev/null 2>&1; then
    local -r set_color="$(tput setaf "$color")"
    local -r reset_color="$(tput sgr0)"
  else
    local -r set_color=""
    local -r reset_color=""
  fi

  printf "%-${HEADER_LENGTH}s $message\n" "${set_color}${header}${reset_color}" >&2
}

function progress() {
  _log "  >>>" 2 "$1"
}

function info() {
  _log "[INFO]" 2 "$1"
}

function warn() {
  _log "[WARN]" 3 "$1"
}

function error() {
  _log "[ERROR]" 1 "$1"
}
