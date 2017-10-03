#!/bin/bash

set -eu

export MONGO_OPLOG_URL='mongodb://testuser:testpass@lighthouse.5.mongolayer.com:10615,lighthouse.4.mongolayer.com:10615/local?authSource=testdb&replicaSet=set-59d2c65e61320f48ba000da1'

cd "$(dirname "$0")"/pure-node || exit

npm install

node index.js
