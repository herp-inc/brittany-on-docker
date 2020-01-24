cd "$(dirname "$BASH_SOURCE")"
source ./config.sh

readonly PROJECT_DIR="$(git rev-parse --show-toplevel)"

readonly SCRIPTS_DIR="$PROJECT_DIR/$CONFIG_SCRIPTS_DIR"
readonly PATCHES_DIR="$PROJECT_DIR/$CONFIG_PATCHES_DIR"
readonly DOCKERFILE_DIR="$PROJECT_DIR/$CONFIG_DOCKERFILE_DIR"

readonly LOCAL_TMP_DIR="$PROJECT_DIR/$CONFIG_LOCAL_TMP_DIR"
mkdir -p "$LOCAL_TMP_DIR"
