#!/bin/bash

# Create COMBINED-DATA directory (or clear if it exists)
rm -rf COMBINED-DATA
mkdir COMBINED-DATA

# Determine the correct 'sed' command based on the operating system
if [[ "$OSTYPE" == "darwin"* ]]; then  # macOS (BSD sed)
    SED_COMMAND="sed -i ''"
else                                  # Linux (GNU sed)
    SED_COMMAND="sed -i"
fi

# Process each DNAxx directory
for dna_dir in RAW-DATA/DNA*; do
    culture_name=$(basename "$dna_dir")
    new_culture_name=$(grep "$culture_name" RAW-DATA/sample-translation.txt | awk '{print $2}')

    # Copy checkm and taxonomy files
    cp "$dna_dir/checkm.txt" "COMBINED-DATA/$new_culture_name-CHECKM.txt"
    cp "$dna_dir/gtdb.gtdbtk.tax" "COMBINED-DATA/$new_culture_name-GTDB-TAX.txt"

    mag_count=1
    bin_count=1

    # Process each FASTA file
    for fasta_file in "$dna_dir/bins/"*.fasta; do
        bin_name=$(basename "$fasta_file".fasta)

        # Extract completion and contamination (handling potential non-numeric values)
        completion=$(grep "$bin_name" "$dna_dir/checkm.txt" | awk '{print $13}' | grep -oE '[0-9.]+')
        contamination=$(grep "$bin_name" "$dna_dir/checkm.txt" | awk '{print $14}' | grep -oE '[0-9.]+')

        # Debugging: Print values (comment out after testing)
        echo "Bin: $bin_name, Completion: $completion, Contamination: $contamination"

        if [[ -n "$completion" && -n "$contamination" ]]; then
            if [[ "$bin_name" == "bin-unbinned" ]]; then
                new_name="${new_culture_name}_UNBINNED.fa"
            elif (( $(echo "$completion >= 50" | bc -l) && $(echo "$contamination < 5" | bc -l) )); then
                new_name=$(printf "${new_culture_name}_MAG_%03d.fa" "$mag_count")
                mag_count=$((mag_count + 1))
            else
                new_name=$(printf "${new_culture_name}_BIN_%03d.fa" "$bin_count")
                bin_count=$((bin_count + 1))
            fi

            # Update checkm and taxonomy files with new bin name
            $SED_COMMAND "s/ms.*${bin_name}/$(basename "$new_name".fa)/g" "COMBINED-DATA/$new_culture_name-CHECKM.txt"
            $SED_COMMAND "s/ms.*${bin_name}/$(basename "$new_name".fa)/g" "COMBINED-DATA/$new_culture_name-GTDB-TAX.txt"

            # Reformat FASTA file (anvi-script-reformat-fasta must be in your PATH)
            cp "$fasta_file" "COMBINED-DATA/$new_name" # Or use anvi-script-reformat-fasta if available
            awk -v prefix="$new_culture_name" '/^>/ {print ">" prefix "_" ++count; next} {print}' "$fasta_file" > "COMBINED-DATA/$new_name"
        fi
    done
done

echo "Script completed."