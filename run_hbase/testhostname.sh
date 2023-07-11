#!/bin/bash

# File to read ipadresses from
input_file=$PBS_NODEFILE

# Read first line of input file and fetch its ip to store it as master node ip
first_line=$(head -n 1 "$input_file")

hostname=$(echo "$first_line" | awk -F. '{print $1}')

echo "Hostname: $hostname"
