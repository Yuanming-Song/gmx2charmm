#!/bin/bash

rtp_file="parameters/forcefield/charmm36_dyes.ff/merged.rtp"
resname="AX6"

echo "Looking for residue $resname in $rtp_file"

# Parse RTP file for atom information
in_residue=false
in_atoms=false
in_bonds=false
in_impropers=false
line_number=0

while IFS= read -r line; do
     # Check for impropers section
    if [[ $line =~ ^[[:space:]]*\[[[:space:]]*impropers[[:space:]]*\] ]]; then
        in_impropers=true
        echo "Found impropers section at line $line_number: $line"
        # Read next line
        read -r line
        line_number=$((line_number + 1))
        echo "First improper line at line $line_number: $line"
        continue
    fi
    
    # Explicitly check line 216
    if [ $line_number -eq 216 ]; then
        echo "Line 216: $line"
    fi
    line_number=$((line_number + 1))
    
    # Skip empty lines and comments
    if [[ -z "$line" || $line =~ ^[[:space:]]*# ]]; then
        continue
    fi
    
    # Check for any new residue section - if we're in a section and hit a new residue, stop
    if [[ $line =~ ^\[[[:space:]]*[A-Za-z0-9]+[[:space:]]*\] ]] && [[ $in_atoms == true || $in_bonds == true || $in_impropers == true ]]; then
        break
    fi
    
    # Check for residue section
    if [[ $line =~ ^\[[[:space:]]*$resname[[:space:]]*\] ]]; then
        in_residue=true
        echo "Found residue section at line $line_number: $line"
        continue
    fi
    
    # Only process if we're in the correct residue
    if ! $in_residue; then
        continue
    fi
    
    # Check for atoms section
    if [[ $line =~ ^[[:space:]]*\[[[:space:]]*atoms[[:space:]]*\] ]]; then
        in_atoms=true
        echo "Found atoms section at line $line_number: $line"
        # Read next line
        read -r line
        line_number=$((line_number + 1))
        echo "First atom line at line $line_number: $line"
        continue
    fi
    
    # Check for bonds section
    if [[ $line =~ ^[[:space:]]*\[[[:space:]]*bonds[[:space:]]*\] ]]; then
        in_bonds=true
        echo "Found bonds section at line $line_number: $line"
        # Read next line
        read -r line
        line_number=$((line_number + 1))
        echo "First bond line at line $line_number: $line"
        continue
    fi
    
  
    
done < "$rtp_file" 