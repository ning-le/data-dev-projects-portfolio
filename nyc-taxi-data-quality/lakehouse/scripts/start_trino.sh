#!/usr/bin/env bash
set -euo pipefail

export JAVA_HOME=/opt/module/jre17
export PATH="$JAVA_HOME/bin:$PATH"

/opt/module/trino/bin/launcher start
