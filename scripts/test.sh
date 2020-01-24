#!/usr/bin/env bash

set -euo pipefail


readonly TEST_SAMPLE_FILE="./.tmp/sample.hs"

function main() {
  local image_name=$1

  mkdir -p "$(dirname "$TEST_SAMPLE_FILE")"
  cat > "$TEST_SAMPLE_FILE" << EOF
main =    print      "ok"
EOF

  local expected=$(cat << EOF
main = print "ok"
EOF
)

  local output=$(docker run --rm -i $image_name brittany < "$TEST_SAMPLE_FILE")
  if [ "$output" != "$expected" ]; then
    echo "test failed for image $image_name"
    echo "Expected: $expected"
    echo "But got: $output"
    exit 1
  fi

  rm "$TEST_SAMPLE_FILE"
  exit 0
}

main "$@"
