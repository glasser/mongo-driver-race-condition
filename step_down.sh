#!/bin/bash

cd "$(dirname "$0")" || exit

./mongo --host rs0/127.0.0.1:21000,127.0.0.1:21001 -u testuser -p testpass --authenticationDatabase admin --eval 'printjson(rs.stepDown())'
