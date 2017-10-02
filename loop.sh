#!/bin/bash

while true; do
  date
  echo -n '4: '
  mongo --quiet lighthouse.4.mongolayer.com:10615/testdb -u testuser -p testpass --eval 'db.c.insert({x: "hi"})'
  echo -n '5: '
  mongo --quiet lighthouse.5.mongolayer.com:10615/testdb -u testuser -p testpass --eval 'db.c.insert({x: "hi"})'
  echo
  sleep 1
done
