#!/bin/bash

file="$1"

# Number of sequences
num_sequences=$(grep -c '^>' "$file")

# Total length of sequences
total_length=$(awk '/^>/ {next} {sum += length} END {print sum}' "$file")

# Longest and shortest sequences (calculated efficiently)
longest=$(awk '/^>/ { if (seq_len > 0) { max_len = (seq_len > max_len)? seq_len: max_len } seq_len = 0; next } { seq_len += length($0) } END { print (seq_len > max_len)? seq_len: max_len }' "$file")
shortest=$(awk '/^>/ { if (seq_len > 0) { min_len = (min_len == 0 || seq_len < min_len)? seq_len: min_len } seq_len = 0; next } { seq_len += length($0) } END { print (seq_len < min_len || min_len == 0)? seq_len: min_len }' "$file")

# GC count and content (corrected)
gc_count=$(awk '/^>/ {next} {count += gsub(/[GC]/, "", $0)} END {print count}' "$file")
gc_content=$(awk '/^>/ {next} {count += gsub(/[GC]/, "", $0)} END {printf "%.2f", (count / '$total_length') * 100}' "$file")

average_length=$((total_length / num_sequences))

# Print the results
echo "FASTA File Statistics:"
echo "----------------------"
echo "Number of sequences: $num_sequences"
echo "Total length of sequences: $total_length"
echo "Length of the longest sequence: $longest"
echo "Length of the shortest sequence: $shortest"
echo "Average sequence length: $average_length"
echo "GC Content (%): $gc_content"