#!/bin/sh

set -e
set -o errexit

ddclient -verbose -noquiet -debug

OUTPUT_FILE=output.log

touch "$OUTPUT_FILE"
tail -f "$OUTPUT_FILE" &

Merc/StandaloneLinux64 -logFile "$OUTPUT_FILE" -batchmode -nographics
