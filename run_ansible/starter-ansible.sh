#!/bin/bash

# Input file to read from
input_file=$PBS_NODEFILE
# Output file for subsequent lines
output_file="inventory.yaml"
counter=1

echo "virtualmachines:" > "$output_file"
echo "  hosts:" >> "$output_file"

while IFS= read -r ip_address; do
  vm_name="vm$(printf "%02d" "$counter")"
  echo "    $vm_name:" >> "$output_file"
  echo "      ansible_host: $ip_address" >> "$output_file"
  counter=$((counter + 1))
done < "$input_file"

