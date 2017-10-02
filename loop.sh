#!/bin/bash

while true; do
  time
  echo inserting
  mongo lighthouse.4.mongolayer.com:10615/testdb -u testuser -p testpass --eval 'db.c.insert({x: "hi"})'
  echo inserted
  sleep 1
done
