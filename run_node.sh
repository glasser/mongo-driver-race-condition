#!/bin/bash

set -eu

prefix='mongodb://testuser:testpass@lighthouse.5.mongolayer.com:10615,lighthouse.4.mongolayer.com:10615'
suffix='replicaSet=set-59d2c65e61320f48ba000da1'

cd "$(dirname "$0")"/pure-node || exit

npm install

MONGO_OPLOG_URL="${prefix}/local?authSource=testdb&${suffix}" node index.js
