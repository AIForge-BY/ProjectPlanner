#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
HOME=/tmp/project-planner swift build -c release
scripts/build-app.sh >/dev/null
/usr/bin/pkill -x ProjectPlanner 2>/dev/null || true
/usr/bin/open -n ".build/ProjectPlanner.app"
