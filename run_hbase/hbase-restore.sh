#!/bin/bash

# Set the backup directory path
BACKUP_DIR=$HBASE_HOME/bkup-data

# Get the list of tables from the backup directory
TABLES=$(ls $BACKUP_DIR)

# Loop through each table and import it back into HBase
for TABLE in $TABLES
do
  # Check if the table already exists in HBase
  if echo "exists '$TABLE'" | hbase shell | grep -q 'does exist'; then
    # Delete the table
    echo "disable '$TABLE'" | hbase shell
    echo "drop '$TABLE'" | hbase shell
  fi

  # Recreate the table
  echo "create '$TABLE', 'column_family'" | hbase shell

  # Import the data
  hbase org.apache.hadoop.hbase.mapreduce.Import "$TABLE" "$BACKUP_DIR/$TABLE"
done
