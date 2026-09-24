#!/usr/bin/env bash
# Quick check that everyone on the team has the required tooling installed.
# Usage: ./scripts/check-prereqs.sh

set -uo pipefail

check() {
  local name="$1"
  local cmd="$2"
  if command -v "$cmd" >/dev/null 2>&1; then
    echo "✅ $name found: $("$cmd" --version 2>&1 | head -n 1)"
  else
    echo "❌ $name NOT found - install it before continuing"
  fi
}

echo "Checking prerequisites for the StyleSync project..."
echo ""
check "Docker"  docker
check ".NET SDK" dotnet
check "Node.js"  node
check "npm"      npm
check "Python 3" python3
check "Flutter"  flutter

echo ""
echo "If anything is missing, see docs/setup/*.md for install links."
