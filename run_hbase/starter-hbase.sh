#!/bin/bash

# Set Environment variables in your ~/.bashrc

#export HBASE_HOME=/grand/IBM-GSS/atanikanti/run_hbase/hbase
#export JAVA_HOME=/grand/IBM-GSS/jdk1.8.0_371
#export PATH=$JAVA_HOME/bin:$PATH
# Ensure you stop all before starting this
# /grand/IBM-GSS/atanikanti/run_hbase/stop-hbase.sh

# File to read ipadresses from
input_file=$PBS_NODEFILE

# File to store region server information
worker_file="$HBASE_HOME/conf/regionservers"

# Config file
hbase_site_file="$HBASE_HOME/conf/hbase-site.xml"

# Read first line of input file and fetch its ip to store it as master node ip
first_line=$(head -n 1 "$input_file")
#master_ip=$(nslookup $first_line | grep -m 2 '^Address:' | tail -n 1 | awk '{print $2}')
#master_ip=$(echo "$first_line" | awk -F. '{print $1}')
master_ip=$first_line
echo "Master node IP address> $master_ip"

# Write subsequent ipaddresses to region server file
#readarray -t region_server_nodes < <(tail -n +2 $PBS_NODEFILE)
#> "$worker_file"
#for node in "${region_server_nodes[@]}"
#do
#	ip=$(nslookup $node | grep -m 2 '^Address:' | tail -n 1 | awk '{print $2}')
#	echo "Worker node IP address> $ip"
#	ip="x3006c0s1b0n0"
#	echo "$ip" >> "$worker_file"
#done

> "$worker_file"  # Truncate the output file
#for fqdn in "${region_server_nodes[@]}"
#do
#  hostname=$(echo "$fqdn" | awk -F. '{print $1}')
#   hostname=$(echo "$fqdn")
#   echo "Worker node IP address> $hostname"
#   echo "$hostname" >> "$worker_file"
#done

if [ $(wc -l < $PBS_NODEFILE) -gt 1 ]
then
    sed -n '2,$p' $PBS_NODEFILE > $worker_file
else
    head -n 1 $PBS_NODEFILE > $worker_file
fi



## Populate the config hbase-site.xml with rootdir (shared file system), zookeeper quorum and master ip 

# Replace rootdir with shared file system information
line_number_rootdir=$(grep -n "<name>hbase.rootdir</name>" $hbase_site_file | cut -d ":" -f 1)
next_line_number_rootdir=$(expr $line_number_rootdir + 1)
current_value1=$(sed -n "${next_line_number_rootdir}p" $hbase_site_file | sed 's/<value>\(.*\)<\/value>/\1/')
echo "Root dir old (shared FS)> $current_value1"
# replace the value with a new one
new_value1="file://$HBASE_HOME/data"
echo "Root dir new (shared FS)> $new_value1"
sed -i "${next_line_number_rootdir}s|\(<value>\).*\(</value>\)|\1${new_value1}\2|" $hbase_site_file

# Replace zookeeeper with data directory information
line_number_datadir=$(grep -n "<name>hbase.zookeeper.property.dataDir</name>" $hbase_site_file | cut -d ":" -f 1)
next_line_number_datadir=$(expr $line_number_datadir + 1)
current_value2=$(sed -n "${next_line_number_datadir}p" $hbase_site_file | sed 's/<value>\(.*\)<\/value>/\1/')
echo "Zookeeper data directory current> $current_value2"
# replace the value with a new one
new_value2="$HBASE_HOME/zookeeper-data"
echo "Zookeeper data directory new> $new_value2"
sed -i "${next_line_number_datadir}s|\(<value>\).*\(</value>\)|\1${new_value2}\2|" $hbase_site_file

# Replace zookeeeper quorums ipaddress with master ip
line_number_zookeeper=$(grep -n "<name>hbase.zookeeper.quorum</name>" $hbase_site_file | cut -d ":" -f 1)
next_line_number_zookeeper=$(expr $line_number_zookeeper + 1)
current_value=$(sed -n "${next_line_number_zookeeper}p" $hbase_site_file | sed 's/<value>\(.*\)<\/value>/\1/')
echo "zookeeeper quorums ipaddress current> $current_value"
## replace the value with a new one
new_value="$master_ip"
echo "zookeeeper quorums ipaddress new> $new_value"
sed -i "${next_line_number_zookeeper}s|\(<value>\).*\(</value>\)|\1${new_value}\2|" $hbase_site_file

# Replace master hostname with master ip
line_number_masternode=$(grep -n "<name>hbase.master.hostname</name>" $hbase_site_file | cut -d ":" -f 1)
next_line_number_masternode=$(expr $line_number_masternode + 1)
current_value=$(sed -n "${next_line_number_masternode}p" $hbase_site_file | sed 's/<value>\(.*\)<\/value>/\1/')
echo "Master hostname current> $current_value"
## replace the value with a new one
new_value="$master_ip"
echo "Master hostname new> $new_value"
sed -i "${next_line_number_masternode}s|\(<value>\).*\(</value>\)|\1${new_value}\2|" $hbase_site_file

# Run script
echo "Starting hbase $HBASE_HOME/bin/start-hbase.sh"
$HBASE_HOME/bin/start-hbase.sh
