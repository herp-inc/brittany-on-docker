#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")"
# shellcheck source=scripts/lib/source.sh
source ./lib/source.sh

function main() {
  local -r image_name="$1"
  local -r sample_file="$LOCAL_TMP_DIR/sample.hs"

  cat > "$sample_file" << EOF
-- 日本語
main =    print      "ok"
EOF

  local expected
  expected=$(cat << EOF
-- 日本語
main = print "ok"
EOF
)

  local output
  output=$(docker run --rm -i "$image_name" brittany < "$sample_file")
  if [ "$output" != "$expected" ]; then
    error "Test failed for image $image_name"
    error "Expected: $expected"
    error "But got: $output"
    exit 1
  fi

  rm -f "$sample_file"

  exit 0
}

main "$@"
