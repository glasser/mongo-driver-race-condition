#!/bin/bash

while true; do
  date
  echo inserting into 4
  mongo lighthouse.4.mongolayer.com:10615/testdb -u testuser -p testpass --eval 'db.c.insert({x: "hi"})'
  echo inserting into 5
  mongo lighthouse.5.mongolayer.com:10615/testdb -u testuser -p testpass --eval 'db.c.insert({x: "hi"})'
  sleep 1
done
