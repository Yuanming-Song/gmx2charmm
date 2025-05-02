#!/bin/bash

# Function to read and process files
process_files() {
    local str_file=$1
    shift
    local prm_files=("$@")
    
    # Check if files exist
    if [ ! -f "$str_file" ]; then
        echo "Error: STR file '$str_file' not found!"
        exit 1
    fi
    
    for prm_file in "${prm_files[@]}"; do
        if [ ! -f "$prm_file" ]; then
            echo "Error: PRM file '$prm_file' not found!"
            exit 1
        fi
    done
    
    # Create temporary files
    tmp_bonds=$(mktemp)
    tmp_atoms=$(mktemp)
    
    # Extract BOND lines from str file
    awk '/^BOND/{print $2, $3}' "$str_file" > "$tmp_bonds"
    
    # Extract ATOM lines and create mapping
    awk '/^ATOM/{print $2, $3}' "$str_file" > "$tmp_atoms"
    
    # Process each bond
    count=0
    missing_bonds=()
    while read -r atom1 atom2; do
        # Get atom types from the mapping
        atom1_type=$(grep "^$atom1 " "$tmp_atoms" | awk '{print $2}')
        atom2_type=$(grep "^$atom2 " "$tmp_atoms" | awk '{print $2}')
        
        if [ -z "$atom1_type" ] || [ -z "$atom2_type" ]; then
            continue
        fi
        
        # Check if bond exists in any prm file
        bond_found=0
        for prm_file in "${prm_files[@]}"; do
            # Modified grep pattern to handle variable whitespace and be more lenient
            if awk -v type1="$atom1_type" -v type2="$atom2_type" '
                {gsub(/[[:space:]]+/, " "); $0 = " " $0 " "}
                $0 ~ " " type1 "[[:space:]]+" type2 "[[:space:]]+" || 
                $0 ~ " " type2 "[[:space:]]+" type1 "[[:space:]]+" {found=1; exit}
                END {exit !found}' "$prm_file"; then
                bond_found=1
                break
            fi
        done
        
        if [ $bond_found -eq 0 ]; then
            missing_bonds+=("$atom1 $atom2 ($atom1_type $atom2_type)")
        fi
    done < "$tmp_bonds"

    total_missing=${#missing_bonds[@]}
    if [ $total_missing -eq 0 ]; then
        echo "All clear! No missing bonds found."
    else
        idx=0
        while [ $idx -lt $total_missing ]; do
            for ((i=0; i<5 && idx<total_missing; i++, idx++)); do
                echo "Missing bond: ${missing_bonds[$idx]}"
            done
            if [ $idx -lt $total_missing ]; then
                read -p "Show next 5 missing bonds? (y/n) " answer
                if [[ $answer != "y" ]]; then
                    break
                fi
            fi
        done
    fi
    
    # Cleanup
    rm -f "$tmp_bonds" "$tmp_atoms"
}

# Main script
echo "Bond Sanity Check Script"
echo "======================="

# Get STR file
read -p "Enter the path to the STR file: " str_file

# Get PRM files
prm_files=()
while true; do
    read -p "Enter the path to a PRM file (or press Enter to finish): " prm_file
    if [ -z "$prm_file" ]; then
        break
    fi
    prm_files+=("$prm_file")
done

if [ ${#prm_files[@]} -eq 0 ]; then
    echo "Error: At least one PRM file is required!"
    exit 1
fi

# Process the files
process_files "$str_file" "${prm_files[@]}" 