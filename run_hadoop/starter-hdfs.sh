#!/bin/bash

#Stop all
#rm -rf $PROJECT_HOME/tmp
#rm -rf $HADOOP_HOME/logs
#rm -rf /tmp/*
#rm -rf $HADOOP_HOME/hdfs
# Input file to read from
input_file=$PBS_NODEFILE

# Output file for first line

master_file="$HADOOP_HOME/etc/hadoop/masters"

# Output file for subsequent lines
worker_file="$HADOOP_HOME/etc/hadoop/workers"

# Read first line of input file
first_line=$(head -n 1 "$input_file")

#config file
core_site_file="$HADOOP_HOME/etc/hadoop/core-site.xml"
yarn_site_file="$HADOOP_HOME/etc/hadoop/yarn-site.xml"
hdfs_site_file="$HADOOP_HOME/etc/hadoop/hdfs-site.xml"
mapred_site_file="$HADOOP_HOME/etc/hadoop/mapred-site.xml"

# Overwrite output file with first line
echo "$first_line" > "$master_file"

# Write subsequent lines to other file
tail -n +2 "$input_file" > "$worker_file"

#echo "$first_line"
#sed -i "s#<value>.*</value>#<value>hdfs://$first_line</value>#" "$config_file"
sed -i "0,/<value>/s#<value>.*</value>#<value>hdfs://$first_line:8085</value>#" "$core_site_file"
sed -i "0,/<value>/s#<value>.*</value>#<value>$first_line</value>#" "$yarn_site_file"
sed -i "0,/<value>/s#<value>.*</value>#<value>$first_line:9870</value>#" "$hdfs_site_file"
sed -i "0,/<value>/s#<value>.*</value>#<value>$first_line:8086</value>#" "$mapred_site_file"
#sed -i -e "/<value>/!b" -e ":a" -e '$!N;s/\(<value>[^<]*<\/value>.*\)\n<value>/\1\n/;ta' -e "s|<value>[^<]*</value>|<value>$first_line</value>|2" "$hdfs_site_file"


#Run script
$HADOOP_HOME/bin/hdfs namenode -format
$HADOOP_HOME/bin/hdfs datanode -format
#bash $HADOOP_HOME/sbin/start-all.sh
#$HADOOP_HOME/bin/hdfs --daemon start namenode
#$HADOOP_HOME/bin/hdfs --daemon start datanode
$HADOOP_HOME/sbin/start-dfs.sh
#$HADOOP_HOME/bin/yarn --daemon start resourcemanager
#$HADOOP_HOME/bin/yarn --daemon start nodemanager
#$HADOOP_HOME/bin/yarn --daemon start proxyserver
$HADOOP_HOME/sbin/start-yarn.sh
$HADOOP_HOME/bin/mapred --daemon start historyserver
