#!/bin/false
# shellcheck shell=bash

cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

# shellcheck source=scripts/lib/config.sh
source ./config.sh

# shellcheck source=scripts/lib/path.sh
source ./path.sh
# shellcheck source=scripts/lib/log.sh
source ./log.sh
