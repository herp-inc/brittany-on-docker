#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")"
source ./lib/source.sh

function main() {
  local image_name=$1

  local sample_file="$LOCAL_TMP_DIR/sample.hs"

  cat > "$sample_file" << EOF
main =    print      "ok"
EOF

  local expected=$(cat << EOF
main = print "ok"
EOF
)

  local output=$(docker run --rm -i $image_name brittany < "$sample_file")
  if [ "$output" != "$expected" ]; then
    echo "test failed for image $image_name"
    echo "Expected: $expected"
    echo "But got: $output"
    exit 1
  fi

  rm "$sample_file"
  exit 0
}

main "$@"
