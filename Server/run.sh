#!/bin/sh

set -e
set -o errexit
set -x

rm -f /var/cache/ddclient/ddclient.cache
ddclient -verbose -noquiet -debug -foreground

OUTPUT_FILE=output.log

touch "$OUTPUT_FILE"
tail -f "$OUTPUT_FILE" &

Merc/StandaloneLinux64 -logFile "$OUTPUT_FILE" -batchmode -nographics
