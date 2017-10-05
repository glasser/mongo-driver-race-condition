#!/bin/bash

cd "$(dirname "$0")" || exit

./mongo --host mongodb://127.0.0.1:21000,127.0.0.1:21001/admin?replicaSet=rs0 -u testuser -p testpass --eval 'printjson(rs.stepDown())'
