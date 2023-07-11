#!/bin/bash

# Read the nodefile into an array
readarray -t nodes < $PBS_NODEFILE

# Loop over the nodes and print their IP addresses
for node in "${nodes[@]}"
do
  #ip=$(nslookup $node | grep '^Address:' | awk '{print $2}')
  ip=$(nslookup $node | grep -m 2 '^Address:' | tail -n 1 | awk '{print $2}')
  echo "$ip"
done
