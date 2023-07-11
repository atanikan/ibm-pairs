#!/bin/bash


hbase shell <<EOF
tables = list
tables.each { |table| snapshot(table, "#{table}-snapshot--#{Time.now.strftime('%Y%m%d%H%M%S%L')}")}
EOF


# Set the backup directory path
#BACKUP_DIR=$HBASE_HOME/bkup-data

# Get the list of tables from HBase
#TABLES=$(echo "list" | hbase shell | awk '{print $1}' | grep -v "^$")

# Loop through each table and copy it to the backup directory
#for TABLE in $TABLES
#do
 # hbase org.apache.hadoop.hbase.mapreduce.Export $TABLE $BACKUP_DIR/$TABLE
#done
