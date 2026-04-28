#!/usr/bin/env bash
# jp-slot NUI の JS 構文チェック（コミット前・CI 用）
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
for f in html/js/*.js; do
  echo "checking $f"
  node --check "$f"
done
echo "All JS files OK"
