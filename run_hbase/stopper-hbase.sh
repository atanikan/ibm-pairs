#!/bin/bash

#Stop all
#$RUN_HBASE_HOME/hbase-backup.sh
#cp -r $HBASE_HOME/data $RUN_HBASE_HOME/bkup-data
$HBASE_HOME/bin/stop-hbase.sh
rm -rf $HBASE_HOME/logs/*
rm -rf $HBASE_HOME/data
rm -rf $HBASE_HOME/zookeeper-data
rm -rf $HBASE_HOME/tmp/*
rm -rf /grand/IBM-GSS/atanikanti/tmp/*
#rm -rf /tmp/*
#rm -rf $HBASE_HOME/data/oldWALs/*
#rm -rf $HBASE_HOME/data/archive/*
#Binary file data/MasterData/data/master/store/1595e783b53d99cd5eef43b6debb2682/proc/d18a10fadfbe4026b457368fed2cd759 matches
#Binary file data/oldWALs/x3005c0s7b0n0.hsn.cm.polaris.alcf.anl.gov%2C8082%2C1687912451024.meta.1687912452994.meta matches
#Binary file data/oldWALs/x3005c0s7b0n0.hsn.cm.polaris.alcf.anl.gov%2C8082%2C1687912451024.1687912455917 matches
#Binary file data/archive/data/hbase/meta/1588230740/info/76bf63b710014c2782125a007a6e4200 matches
