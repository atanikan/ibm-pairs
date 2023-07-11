#!/bin/bash

 echo "create 'students','account','address'" | hbase shell
 echo "create 'clicks','clickinfo','iteminfo'" | hbase shell
 cat testdata.txt | hbase shell


