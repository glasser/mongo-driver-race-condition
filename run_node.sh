#!/bin/bash

set -eu

export MONGO_OPLOG_URL='mongodb://testuser:testpass@127.0.0.1:21000,127.0.0.1:21001/local?replicaSet=rs0&authSource=admin'

cd "$(dirname "$0")"/pure-node || exit

node index.js
