#!/bin/bash

# Function to parse ATOM lines and create mapping
parse_atoms() {
    local str_file="$1"
    local counters_name="$2"
    local mapping_name="$3"
    local delete_list_name="$4"
    local first_counters_name="$5"  # Add parameter for first file's counters
    
    # Initialize arrays
    eval "$counters_name=()"
    eval "$mapping_name=()"
    
    # Copy counters from first file if provided
    if [[ -n "$first_counters_name" ]]; then
        eval "for i in \"\${!$first_counters_name[@]}\"; do
            $counters_name+=(\"\${$first_counters_name[\$i]}\")
        done"
    fi
    
    # Read the file line by line
    while IFS= read -r line; do
        if [[ $line =~ ^ATOM[[:space:]]+([A-Za-z]+)([0-9]*)[[:space:]]+([A-Za-z0-9]+)[[:space:]]+(-?[0-9.]+) ]]; then
            element="${BASH_REMATCH[1]}"
            number="${BASH_REMATCH[2]}"
            type="${BASH_REMATCH[3]}"
            charge="${BASH_REMATCH[4]}"
            
            # Check if this atom should be deleted
            should_delete=0
            eval "for atom in \"\${$delete_list_name[@]}\"; do
                if [[ \"\$atom\" == \"${element}${number}\" ]]; then
                    should_delete=1
                    break
                fi
            done"
            
            if [[ $should_delete -eq 0 ]]; then
                # Find or create counter for this element
                found=0
                eval "for i in \"\${!$counters_name[@]}\"; do
                    if [[ \"\${$counters_name[\$i]%%:*}\" == \"$element\" ]]; then
                        count=\${$counters_name[\$i]#*:}
                        $counters_name[\$i]=\"$element:\$((count + 1))\"
                        found=1
                        break
                    fi
                done"
                
                if [[ $found -eq 0 ]]; then
                    eval "$counters_name+=(\"$element:1\")"
                fi
                
                # Get the current count for this element
                eval "for i in \"\${!$counters_name[@]}\"; do
                    if [[ \"\${$counters_name[\$i]%%:*}\" == \"$element\" ]]; then
                        count=\${$counters_name[\$i]#*:}
                        break
                    fi
                done"
                
                # Create mapping
                if [[ -n "$number" ]]; then
                    eval "$mapping_name+=(\"${element}${number}:${element}${count}\")"
                else
                    eval "$mapping_name+=(\"$element:${element}${count}\")"
                fi
            fi
        fi
    done < "$str_file"
}

# Function to get count for an element
get_count() {
    local counters_name="$1"
    local element="$2"
    local count=0
    
    eval "for i in \"\${!$counters_name[@]}\"; do
        if [[ \"\${$counters_name[\$i]%%:*}\" == \"$element\" ]]; then
            count=\${$counters_name[\$i]#*:}
            break
        fi
    done"
    
    echo "$count"
}

# Function to get new name from mapping
get_new_name() {
    local mapping_name="$1"
    local old_name="$2"
    local new_name="$old_name"
    
    
    eval "for i in \"\${!$mapping_name[@]}\"; do
        old=\${$mapping_name[\$i]%%:*}
        new=\${$mapping_name[\$i]#*:}
        if [[ \"\$old\" == \"$old_name\" ]]; then
            new_name=\"\$new\"
            break
        fi
    done"
    
    # If no mapping found, try without number
    if [[ "$new_name" == "$old_name" && "$old_name" =~ ([A-Za-z]+)([0-9]+) ]]; then
        element="${BASH_REMATCH[1]}"
        eval "for i in \"\${!$mapping_name[@]}\"; do
            old=\${$mapping_name[\$i]%%:*}
            new=\${$mapping_name[\$i]#*:}
            if [[ \"\$old\" == \"$element\" ]]; then
                new_name=\"\$new\"
                echo \"Found mapping for element: \$old -> \$new\" >&2
                break
            fi
        done"
    fi
    
    echo "$new_name"
}

# Function to update atom names in a line
update_atom_names() {
    local line="$1"
    local mapping_name="$2"
    
    if [[ $line =~ ^(ATOM|BOND|IMPR)[[:space:]]+([A-Za-z]+[0-9]*)([[:space:]]+([A-Za-z]+[0-9]*))?([[:space:]]+([A-Za-z]+[0-9]*))?([[:space:]]+([A-Za-z]+[0-9]*))? ]]; then
        type="${BASH_REMATCH[1]}"
        atoms=()
        for i in 2 4 6 8; do
            if [[ ${BASH_REMATCH[$i]} ]]; then
                atoms+=("${BASH_REMATCH[$i]}")
            fi
        done
        
        # Build new line with updated atom names
        new_line="$type"
        for atom in "${atoms[@]}"; do
            new_atom=$(get_new_name "$mapping_name" "$atom")
            new_line="$new_line  $new_atom"
        done
        
        # Add comment for new bonds
        if [[ $type == "BOND" && $line == *"!new bond"* ]]; then
            new_line="$new_line    !new bond"
        fi
        
        echo "$new_line"
    else
        echo "$line"
    fi
}

# Function to combine parameter sections
combine_parameters() {
    local file1="$1"
    local file2="$2"
    local section="$3"
    
    # Extract parameter lines from both files
    local params1=()
    local params2=()
    
    # Read first file
    in_section=0
    while IFS= read -r line; do
        if [[ $line =~ ^$section$ ]]; then
            in_section=1
            continue
        elif [[ $line =~ ^(ANGLES|DIHEDRALS|IMPROPERS|END)$ ]]; then
            in_section=0
        fi
        
        if [[ $in_section -eq 1 && -n "$line" ]]; then
            params1+=("$line")
        fi
    done < "$file1"
    
    # Read second file
    in_section=0
    while IFS= read -r line; do
        if [[ $line =~ ^$section$ ]]; then
            in_section=1
            continue
        elif [[ $line =~ ^(ANGLES|DIHEDRALS|IMPROPERS|END)$ ]]; then
            in_section=0
        fi
        
        if [[ $in_section -eq 1 && -n "$line" ]]; then
            params2+=("$line")
        fi
    done < "$file2"
    
    # Combine parameters, removing duplicates
    local combined=()
    for param in "${params1[@]}" "${params2[@]}"; do
        # Skip if already in combined
        skip=0
        for c in "${combined[@]}"; do
            if [[ "$c" == "$param" ]]; then
                skip=1
                break
            fi
        done
        if [[ $skip -eq 0 ]]; then
            combined+=("$param")
        fi
    done
    
    # Output the section
    echo "$section"
    for param in "${combined[@]}"; do
        echo "$param"
    done
    echo ""
}

# Function to check if an atom should be deleted
should_delete_atom() {
    local atom="$1"
    local delete_list_name="$2"
    local should_delete=0
    
    eval "for del_atom in \"\${$delete_list_name[@]}\"; do
        if [[ \"\$del_atom\" == \"$atom\" ]]; then
            should_delete=1
            break
        fi
    done"
    
    echo "$should_delete"
}

# Function to check if a line contains any atoms that should be deleted
should_skip_line() {
    local line="$1"
    local delete_list_name="$2"
    local should_skip=0
    
    if [[ $line =~ ^(BOND|IMPR)[[:space:]]+([A-Za-z]+[0-9]*)([[:space:]]+([A-Za-z]+[0-9]*))?([[:space:]]+([A-Za-z]+[0-9]*))?([[:space:]]+([A-Za-z]+[0-9]*))? ]]; then
        for i in 2 4 6 8; do
            if [[ ${BASH_REMATCH[$i]} ]]; then
                if [[ $(should_delete_atom "${BASH_REMATCH[$i]}" "$delete_list_name") -eq 1 ]]; then
                    should_skip=1
                    break
                fi
            fi
        done
    fi
    
    echo "$should_skip"
}

# Main script
echo "STR File Combiner"
echo "----------------------"

# Get input files
read -p "Enter path to first STR file: " str_file1
read -p "Enter path to second STR file: " str_file2
read -p "Enter name for combined STR file: " output_file

# Get 4-character residue name
while true; do
    read -p "Enter 4-character residue name for combined structure: " newresname
    if [[ ${#newresname} -eq 4 ]]; then
        break
    else
        echo "Error: Residue name must be exactly 4 characters long"
    fi
done

# Get atoms to delete
echo "Enter atoms to delete from first file (space-separated):"
read -a delete_atoms1
echo "Enter atoms to delete from second file (space-separated):"
read -a delete_atoms2

# Get new linkages
echo "Enter new linkages between the two structures."
echo "Format: space-separated pairs (e.g., 'C1 C4 C29 C18' means C1 from first file bonds to C4 from second file, and C29 from first file bonds to C18 from second file)"
echo "Press Enter to skip (no linkages will be added)"
read -p "Linkage pairs: " linkage_pairs

# Parse first file
counters1=()
mapping1=()
parse_atoms "$str_file1" "counters1" "mapping1" "delete_atoms1"

# Parse second file, passing first file's counters
counters2=()
mapping2=()
parse_atoms "$str_file2" "counters2" "mapping2" "delete_atoms2" "counters1"

# Check for elements that need renumbering in first file
for i in "${!counters1[@]}"; do
    element="${counters1[$i]%%:*}"
    count1="${counters1[$i]#*:}"
    count2=$(get_count "counters2" "$element")
    
    # If element appears only once in first file and appears again in second file
    if [[ $count1 -eq 1 && $count2 -gt 0 ]]; then
        # Find the mapping entry for this element in first file
        for j in "${!mapping1[@]}"; do
            if [[ "${mapping1[$j]%%:*}" == "$element" && "${mapping1[$j]#*:}" == "$element" ]]; then
                # Update the mapping to use ${element}1
                mapping1[$j]="$element:${element}1"
                break
            fi
        done
    fi
done

# Create combined file
{
    # Write topology reading line and format
    echo "read rtf card append"
    echo "*"
    echo "* Generated using combine_str.sh from gmx2charmm"
    echo "* For more details, visit: https://github.com/Yuanming-Song/gmx2charmm"
    echo "*"
    
    # Write combination information
    echo "* Combined structure created by combine_str.sh"
    echo "* Original files:"
    echo "*   - $str_file1"
    echo "*   - $str_file2"
    echo "*"
    
    # Copy comments from first file
    echo "* Comments from first file ($str_file1):"
    while IFS= read -r line; do
        if [[ $line =~ ^\*|^! ]]; then
            echo "$line"
        elif [[ $line =~ ^RESI ]]; then
            break
        fi
    done < "$str_file1"
    echo "*"
    
    # Copy comments from second file
    echo "* Comments from second file ($str_file2):"
    while IFS= read -r line; do
        if [[ $line =~ ^\*|^! ]]; then
            echo "$line"
        elif [[ $line =~ ^RESI ]]; then
            break
        fi
    done < "$str_file2"
    echo "*"
    
    # Write RESI line with new residue name
    echo "RESI $newresname          0.000 "
    
    # Write GROUP line
    echo "GROUP            ! CHARGE   CH_PENALTY"
    
    # Write atoms from first file
    while IFS= read -r line; do
        if [[ $line =~ ^ATOM[[:space:]]+([A-Za-z]+)([0-9]*)[[:space:]]+([A-Za-z0-9]+)[[:space:]]+(-?[0-9.]+) ]]; then
            element="${BASH_REMATCH[1]}"
            number="${BASH_REMATCH[2]}"
            type="${BASH_REMATCH[3]}"
            charge="${BASH_REMATCH[4]}"
            
            # Check if this atom should be deleted
            should_delete=0
            for atom in "${delete_atoms1[@]}"; do
                if [[ "$atom" == "${element}${number}" ]]; then
                    should_delete=1
                    break
                fi
            done
            
            if [[ $should_delete -eq 0 ]]; then
                old_name="${element}${number}"
                new_name=$(get_new_name "mapping1" "$old_name")
                echo "ATOM $new_name     $type   $charge"
            fi
        fi
    done < "$str_file1"
    
    # Write atoms from second file
    while IFS= read -r line; do
        if [[ $line =~ ^ATOM[[:space:]]+([A-Za-z]+)([0-9]*)[[:space:]]+([A-Za-z0-9]+)[[:space:]]+(-?[0-9.]+) ]]; then
            element="${BASH_REMATCH[1]}"
            number="${BASH_REMATCH[2]}"
            type="${BASH_REMATCH[3]}"
            charge="${BASH_REMATCH[4]}"
            
            # Check if this atom should be deleted
            should_delete=0
            for atom in "${delete_atoms2[@]}"; do
                if [[ "$atom" == "${element}${number}" ]]; then
                    should_delete=1
                    break
                fi
            done
            
            if [[ $should_delete -eq 0 ]]; then
                old_name="${element}${number}"
                new_name=$(get_new_name "mapping2" "$old_name")
                echo "ATOM $new_name     $type   $charge"
            fi
        fi
    done < "$str_file2"
    
    # Write empty line
    echo ""
    
    # Write bonds from first file
    while IFS= read -r line; do
        if [[ $line =~ ^BOND[[:space:]]+[A-Za-z]+[0-9]*[[:space:]]+[A-Za-z]+[0-9]* ]]; then
            if [[ $(should_skip_line "$line" "delete_atoms1") -eq 0 ]]; then
                update_atom_names "$line" "mapping1"
            fi
        fi
    done < "$str_file1"
    
    # Write bonds from second file
    while IFS= read -r line; do
        if [[ $line =~ ^BOND[[:space:]]+[A-Za-z]+[0-9]*[[:space:]]+[A-Za-z]+[0-9]* ]]; then
            if [[ $(should_skip_line "$line" "delete_atoms2") -eq 0 ]]; then
                update_atom_names "$line" "mapping2"
            fi
        fi
    done < "$str_file2"
    
    # Process and write linkage bonds if any
    if [ -n "$linkage_pairs" ]; then
        # Split the input into pairs
        read -ra pairs <<< "$linkage_pairs"
        if [ $(( ${#pairs[@]} % 2 )) -ne 0 ]; then
            echo "Error: Number of atoms in linkage pairs must be even"
            exit 1
        fi
        
        # Process each pair
        for ((i=0; i<${#pairs[@]}; i+=2)); do
            atom1="${pairs[$i]}"
            atom2="${pairs[$i+1]}"
            
            new_atom1=$(get_new_name "mapping1" "$atom1")
            
            new_atom2=$(get_new_name "mapping2" "$atom2")
            
            # Add the bond to the output
            echo "BOND $new_atom1  $new_atom2    !new bond"
        done
    fi
    
    # Write impropers from first file
    while IFS= read -r line; do
        if [[ $line =~ ^IMPR[[:space:]]+[A-Za-z]+[0-9]*[[:space:]]+[A-Za-z]+[0-9]*[[:space:]]+[A-Za-z]+[0-9]*[[:space:]]+[A-Za-z]+[0-9]* ]]; then
            if [[ $(should_skip_line "$line" "delete_atoms1") -eq 0 ]]; then
                update_atom_names "$line" "mapping1"
            fi
        fi
    done < "$str_file1"
    
    # Write impropers from second file
    while IFS= read -r line; do
        if [[ $line =~ ^IMPR[[:space:]]+[A-Za-z]+[0-9]*[[:space:]]+[A-Za-z]+[0-9]*[[:space:]]+[A-Za-z]+[0-9]*[[:space:]]+[A-Za-z]+[0-9]* ]]; then
            if [[ $(should_skip_line "$line" "delete_atoms2") -eq 0 ]]; then
                update_atom_names "$line" "mapping2"
            fi
        fi
    done < "$str_file2"
    
    # Write END
    echo "END"
    
    # Write parameter sections
    echo "read param card flex append"
    echo "* Parameters generated by analogy by"
    echo "* CHARMM General Force Field (CGenFF) program version 2.4.0"
    echo "*"
    echo ""
    echo "! Penalties lower than 10 indicate the analogy is fair; penalties between 10"
    echo "! and 50 mean some basic validation is recommended; penalties higher than"
    echo "! 50 indicate poor analogy and mandate extensive validation/optimization."
    echo ""
    
    # Combine and write each parameter section
    combine_parameters "$str_file1" "$str_file2" "BONDS"
    combine_parameters "$str_file1" "$str_file2" "ANGLES"
    combine_parameters "$str_file1" "$str_file2" "DIHEDRALS"
    combine_parameters "$str_file1" "$str_file2" "IMPROPERS"
    
    # Write final END and RETURN
    echo "END"
    echo "RETURN"
} > "$output_file"

echo "Combined STR file created: $output_file" 