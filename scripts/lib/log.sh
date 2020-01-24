readonly HEADER_LENGTH=16

function _log() {
  local header="$1"
  local color=$2
  local message="$3"
  printf "%-${HEADER_LENGTH}s $message\n" "$(tput setaf $color)$header$(tput sgr0)" >&2
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
