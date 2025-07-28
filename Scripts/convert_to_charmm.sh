#!/bin/bash

# Default conversion factors
# Energy: kJ/mol to kcal/mol
ENERGY_CONV=0.239005736


# Length: nm to Å
LENGTH_CONV=10

# Force constants:
# Bond: kJ/mol/nm² to kcal/mol/Å²
# (1 kJ/mol/nm² = ENERGY_CONV * 100 kcal/mol/Å²)
# Function to count decimal places
count_decimals() {
    local num="$1"
    echo "$num" | awk -F. '{if (NF>1) print length($2); else print 0}'
}

# Get decimal places for ENERGY_CONV
ENERGY_DECIMALS=$(count_decimals "$ENERGY_CONV")

# Note: GROMACS uses V(x) = k*x²/2, CHARMM uses V(x) = k*x², so divide by 2
# Bond: ENERGY_DECIMALS + 2 decimal places
BOND_DECIMALS=$((ENERGY_DECIMALS + 2))
BOND_FORCE_CONV=$(awk -v e="$ENERGY_CONV" -v d="$BOND_DECIMALS" 'BEGIN {printf "%.*f", d, e * 0.01 / 2}')

# Angle: kJ/mol/rad² to kcal/mol/rad²
# (1 kJ/mol/rad² = ENERGY_CONV kcal/mol/rad²)
# Note: GROMACS uses V(x) = k*x²/2, CHARMM uses V(x) = k*x², so divide by 2
# Angle: same decimal places as ENERGY_CONV
ANGLE_FORCE_CONV=$(awk -v e="$ENERGY_CONV" -v d="$ENERGY_DECIMALS" 'BEGIN {printf "%.*f", d, e / 2}')

# Dihedral: kJ/mol to kcal/mol
# (1 kJ/mol = ENERGY_CONV kcal/mol)
DIHEDRAL_FORCE_CONV=0.239005736

# Default values for section processing
process_atoms=true
process_bonds=true
process_angles=true
process_dihedrals=true
process_nonbonded=true

# Default file locations
DEFAULT_NONBONDED_ITP="parameters/forcefield/charmm36_dyes.ff/ffdyesnonbonded.itp"
DEFAULT_BONDED_ITP="parameters/forcefield/charmm36_dyes.ff/ffdyesbonded.itp"
DEFAULT_COMBINED_ITP="parameters/forcefield/charmm36_dyes.ff/ffdyes.itp"
DEFAULT_OUTPUT_PRM="dyes.prm"

# Function to get user confirmation
get_confirmation() {
    local prompt="$1"
    local default="$2"
    read -p "$prompt [$default]: " response
    response=${response:-$default}
    if [[ $response =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to get numeric input with default
get_numeric_input() {
    local prompt="$1"
    local default="$2"
    read -p "$prompt [$default]: " response
    response=${response:-$default}
    echo "$response"
}

# Function to get file path with default
get_file_path() {
    local prompt="$1"
    local default="$2"
    read -p "$prompt [$default]: " response
    response=${response:-$default}
    if [ ! -f "$response" ]; then
        echo "Error: File '$response' does not exist"
        return 1
    fi
    echo "$response"
}

# Function to show file configuration menu
show_file_menu() {
    while true; do
        echo ""
        echo "Current file configuration:"
        echo "1. Nonbonded ITP file: $NONBONDED_ITP"
        echo "2. Bonded ITP file: $BONDED_ITP"
        echo "3. Combined ITP file: $COMBINED_ITP"
        echo "4. Output PRM file: $OUTPUT_PRM"
        echo "5. None (proceed to next section)"
        echo ""
        read -p "Select a file to configure (1-5): " choice
        
        case $choice in
            1)
                NONBONDED_ITP=$(get_file_path "Enter path to nonbonded ITP file" "$NONBONDED_ITP")
                ;;
            2)
                BONDED_ITP=$(get_file_path "Enter path to bonded ITP file" "$BONDED_ITP")
                ;;
            3)
                COMBINED_ITP=$(get_file_path "Enter path to combined ITP file" "$COMBINED_ITP")
                ;;
            4)
                OUTPUT_PRM=$(get_file_path "Enter path for output PRM file" "$OUTPUT_PRM")
                ;;
            5)
                break
                ;;
            *)
                echo "Invalid choice. Please select 1-5."
                ;;
        esac
    done
}

# Function to show conversion factors menu
show_conversion_menu() {
    while true; do
        echo ""
        echo "Current conversion factors:"
        echo "1. Energy (kJ/mol to kcal/mol): $ENERGY_CONV"
        echo "2. Length (nm to Å): $LENGTH_CONV"
        echo "3. Bond force constant (kJ/mol/nm² to kcal/mol/Å², divided by 2 for GROMACS→CHARMM): $BOND_FORCE_CONV"
        echo "4. Angle force constant (kJ/mol/rad² to kcal/mol/rad², divided by 2 for GROMACS→CHARMM): $ANGLE_FORCE_CONV"
        echo "5. Dihedral force constant (kJ/mol to kcal/mol): $DIHEDRAL_FORCE_CONV"
        echo "6. None (proceed to next section)"
        echo ""
        read -p "Select a conversion factor to modify (1-6): " choice
        
        case $choice in
            1)
                ENERGY_CONV=$(get_numeric_input "Enter new energy conversion factor" "$ENERGY_CONV")
                ENERGY_DECIMALS=$(count_decimals "$ENERGY_CONV")
                BOND_DECIMALS=$((ENERGY_DECIMALS + 2))
                BOND_FORCE_CONV=$(awk -v e="$ENERGY_CONV" -v d="$BOND_DECIMALS" 'BEGIN {printf "%.*f", d, e * 0.01 / 2}')
                ANGLE_FORCE_CONV=$(awk -v e="$ENERGY_CONV" -v d="$ENERGY_DECIMALS" 'BEGIN {printf "%.*f", d, e / 2}')
                DIHEDRAL_FORCE_CONV=$ENERGY_CONV
                ;;
            2)
                LENGTH_CONV=$(get_numeric_input "Enter new length conversion factor" "$LENGTH_CONV")
                ;;
            3)
                BOND_FORCE_CONV=$(get_numeric_input "Enter new bond force constant conversion factor" "$BOND_FORCE_CONV")
                ;;
            4)
                ANGLE_FORCE_CONV=$(get_numeric_input "Enter new angle force constant conversion factor" "$ANGLE_FORCE_CONV")
                ;;
            5)
                DIHEDRAL_FORCE_CONV=$(get_numeric_input "Enter new dihedral force constant conversion factor" "$DIHEDRAL_FORCE_CONV")
                ;;
            6)
                break
                ;;
            *)
                echo "Invalid choice. Please select 1-6."
                ;;
        esac
    done
}

# Function to show section processing menu
show_section_menu() {
    while true; do
        echo ""
        echo "Current section processing settings:"
        echo "1. Process ATOMS section: $process_atoms"
        echo "2. Process BONDS section: $process_bonds"
        echo "3. Process ANGLES section: $process_angles"
        echo "4. Process DIHEDRALS section: $process_dihedrals"
        echo "5. Process NONBONDED section: $process_nonbonded"
        echo "6. None (proceed to next section)"
        echo ""
        read -p "Select a section to toggle (1-6): " choice
        
        case $choice in
            1)
                process_atoms=$(get_confirmation "Process ATOMS section?" "$process_atoms" && echo "true" || echo "false")
                ;;
            2)
                process_bonds=$(get_confirmation "Process BONDS section?" "$process_bonds" && echo "true" || echo "false")
                ;;
            3)
                process_angles=$(get_confirmation "Process ANGLES section?" "$process_angles" && echo "true" || echo "false")
                ;;
            4)
                process_dihedrals=$(get_confirmation "Process DIHEDRALS section?" "$process_dihedrals" && echo "true" || echo "false")
                ;;
            5)
                process_nonbonded=$(get_confirmation "Process NONBONDED section?" "$process_nonbonded" && echo "true" || echo "false")
                ;;
            6)
                break
                ;;
            *)
                echo "Invalid choice. Please select 1-6."
                ;;
        esac
    done
}

# Initialize file variables
NONBONDED_ITP=$DEFAULT_NONBONDED_ITP
BONDED_ITP=$DEFAULT_BONDED_ITP
COMBINED_ITP=$DEFAULT_COMBINED_ITP
OUTPUT_PRM=$DEFAULT_OUTPUT_PRM

# Show file configuration menu
show_file_menu

# Show conversion factors menu
show_conversion_menu

# Show section processing menu
show_section_menu

# Show final settings and ask for confirmation
echo ""
echo "Final settings:"
echo "File configuration:"
echo "1. Nonbonded ITP: $NONBONDED_ITP"
echo "2. Bonded ITP: $BONDED_ITP"
echo "3. Combined ITP: $COMBINED_ITP"
echo "4. Output PRM: $OUTPUT_PRM"
echo ""
echo "Conversion factors:"
echo "1. Energy: $ENERGY_CONV"
echo "2. Length: $LENGTH_CONV"
echo "3. Bond force (divided by 2): $BOND_FORCE_CONV"
echo "4. Angle force (divided by 2): $ANGLE_FORCE_CONV"
echo "5. Dihedral force: $DIHEDRAL_FORCE_CONV"
echo ""
echo "Section processing:"
echo "1. ATOMS: $process_atoms"
echo "2. BONDS: $process_bonds"
echo "3. ANGLES: $process_angles"
echo "4. DIHEDRALS: $process_dihedrals"
echo "5. NONBONDED: $process_nonbonded"
echo ""

if ! get_confirmation "Proceed with these settings?" "Y"; then
    echo "Conversion cancelled by user"
    exit 0
fi

# Create output file with header
echo "! CHARMM parameter file converted from GROMACS ITP files" > $OUTPUT_PRM
echo "! Generated by convert_to_charmm.sh" >> $OUTPUT_PRM
echo "! Date: $(date)" >> $OUTPUT_PRM
echo "" >> $OUTPUT_PRM

# Function to get section from file
get_section() {
    local file="$1"
    local section="$2"
    awk "/\[ $section \]/{flag=1;next}/\[/{flag=0}flag && NF" "$file"
}

# Process ATOMS section
if [ "$process_atoms" = true ]; then
    echo "Processing ATOMS section..."
    echo "ATOMS" >> $OUTPUT_PRM
    echo "! Mass definitions" >> $OUTPUT_PRM
    
    # Try to get atom types from nonbonded ITP first, then from combined ITP
    if [ -f "$NONBONDED_ITP" ]; then
        get_section "$NONBONDED_ITP" "atomtypes" | while read line; do
            atomtype=$(echo $line | awk '{print $1}')
            mass=$(echo $line | awk '{print $3}')
            mass=$(printf "%.5f" $mass)
            printf "MASS  -1  %-8s  %s  ! Converted from GROMACS\n" "$atomtype" "$mass" >> $OUTPUT_PRM
        done
    elif [ -f "$COMBINED_ITP" ]; then
        get_section "$COMBINED_ITP" "atomtypes" | while read line; do
            atomtype=$(echo $line | awk '{print $1}')
            mass=$(echo $line | awk '{print $3}')
            mass=$(printf "%.5f" $mass)
            printf "MASS  -1  %-8s  %s  ! Converted from GROMACS\n" "$atomtype" "$mass" >> $OUTPUT_PRM
        done
    else
        echo "Warning: No ITP file found containing atom types"
    fi
    echo "" >> $OUTPUT_PRM
fi

# Process BONDS section
if [ "$process_bonds" = true ]; then
    echo "Processing BONDS section..."
    echo "BONDS" >> $OUTPUT_PRM
    echo "!" >> $OUTPUT_PRM
    echo "!V(bond) = Kb(b - b0)**2" >> $OUTPUT_PRM
    echo "!" >> $OUTPUT_PRM
    echo "!Kb: kcal/mole/A**2" >> $OUTPUT_PRM
    echo "!b0: A" >> $OUTPUT_PRM
    echo "!" >> $OUTPUT_PRM
    echo "!atom type Kb          b0" >> $OUTPUT_PRM
    echo "" >> $OUTPUT_PRM
    
    # Try to get bond types from bonded ITP first, then from combined ITP
    if [ -f "$BONDED_ITP" ]; then
        get_section "$BONDED_ITP" "bondtypes" | while read line; do
            atom1=$(echo $line | awk '{print $1}')
            atom2=$(echo $line | awk '{print $2}')
            k=$(echo $line | awk '{print $5}')
            k=$(echo "scale=2; $k * $BOND_FORCE_CONV" | bc)
            r0=$(echo $line | awk '{print $4}')
            r0=$(echo "scale=4; $r0 * $LENGTH_CONV" | bc)
            printf "%-8s  %-8s  %8.2f  %8.4f  ! Converted from GROMACS\n" "$atom1" "$atom2" "$k" "$r0" >> $OUTPUT_PRM
        done
    elif [ -f "$COMBINED_ITP" ]; then
        get_section "$COMBINED_ITP" "bondtypes" | while read line; do
            atom1=$(echo $line | awk '{print $1}')
            atom2=$(echo $line | awk '{print $2}')
            k=$(echo $line | awk '{print $5}')
            k=$(echo "scale=2; $k * $BOND_FORCE_CONV" | bc)
            r0=$(echo $line | awk '{print $4}')
            r0=$(echo "scale=4; $r0 * $LENGTH_CONV" | bc)
            printf "%-8s  %-8s  %8.2f  %8.4f  ! Converted from GROMACS\n" "$atom1" "$atom2" "$k" "$r0" >> $OUTPUT_PRM
        done
    else
        echo "Warning: No ITP file found containing bond types"
    fi
    echo "" >> $OUTPUT_PRM
fi

# Process ANGLES section
if [ "$process_angles" = true ]; then
    echo "Processing ANGLES section..."
    echo "ANGLES" >> $OUTPUT_PRM
    echo "!" >> $OUTPUT_PRM
    echo "!V(angle) = Ktheta(Theta - Theta0)**2" >> $OUTPUT_PRM
    echo "!" >> $OUTPUT_PRM
    echo "!V(Urey-Bradley) = Kub(S - S0)**2" >> $OUTPUT_PRM
    echo "!" >> $OUTPUT_PRM
    echo "!Ktheta: kcal/mole/rad**2" >> $OUTPUT_PRM
    echo "!Theta0: degrees" >> $OUTPUT_PRM
    echo "!Kub: kcal/mole/A**2 (Urey-Bradley)" >> $OUTPUT_PRM
    echo "!S0: A" >> $OUTPUT_PRM
    echo "!" >> $OUTPUT_PRM
    echo "!atom types     Ktheta    Theta0   Kub     S0" >> $OUTPUT_PRM
    echo "" >> $OUTPUT_PRM
    
    # Try to get angle types from bonded ITP first, then from combined ITP
    if [ -f "$BONDED_ITP" ]; then
        get_section "$BONDED_ITP" "angletypes" | while read line; do
            atom1=$(echo $line | awk '{print $1}')
            atom2=$(echo $line | awk '{print $2}')
            atom3=$(echo $line | awk '{print $3}')
            k=$(echo $line | awk '{print $6}')
            k=$(echo "scale=2; $k * $ANGLE_FORCE_CONV" | bc)
            theta=$(echo $line | awk '{print $5}')
            
            # Parse Urey-Bradley terms (columns 7 and 8)
            kub=$(echo $line | awk '{print $8}')
            s0=$(echo $line | awk '{print $7}')
            
            if [ -n "$kub" ] && [ "$kub" != "0" ] && [ "$kub" != "" ]; then
                # Convert KUB using bond force constant conversion (divided by 2)
                kub=$(awk -v e="$kub" -v f="$BOND_FORCE_CONV" -v d="5" 'BEGIN {printf "%.*f", d, e * f}')
                # Convert S0 using length conversion
                s0=$(awk -v e="$s0" -v f="$LENGTH_CONV" -v d="2" 'BEGIN {printf "%.*f", d, e * f}')
                printf "%-8s  %-8s  %-8s  %8s  %8s  %8s  %8s  ! Converted from GROMACS\n" "$atom1" "$atom2" "$atom3" "$k" "$theta" "$kub" "$s0" >> $OUTPUT_PRM
            else
                printf "%-8s  %-8s  %-8s  %8s  %8s  ! Converted from GROMACS\n" "$atom1" "$atom2" "$atom3" "$k" "$theta" >> $OUTPUT_PRM
            fi
        done
    elif [ -f "$COMBINED_ITP" ]; then
        get_section "$COMBINED_ITP" "angletypes" | while read line; do
            atom1=$(echo $line | awk '{print $1}')
            atom2=$(echo $line | awk '{print $2}')
            atom3=$(echo $line | awk '{print $3}')
            k=$(echo $line | awk '{print $6}')
            k=$(echo "scale=2; $k * $ANGLE_FORCE_CONV" | bc)
            theta=$(echo $line | awk '{print $5}')
            
            # Parse Urey-Bradley terms (columns 7 and 8)
            kub=$(echo $line | awk '{print $8}')
            s0=$(echo $line | awk '{print $7}')
            
            if [ -n "$kub" ] && [ "$kub" != "0" ] && [ "$kub" != "" ]; then
                # Convert KUB using bond force constant conversion (divided by 2)
                kub=$(awk -v e="$kub" -v f="$BOND_FORCE_CONV" -v d="5" 'BEGIN {printf "%.*f", d, e * f}')
                # Convert S0 using length conversion
                s0=$(awk -v e="$s0" -v f="$LENGTH_CONV" -v d="2" 'BEGIN {printf "%.*f", d, e * f}')
                printf "%-8s  %-8s  %-8s  %8s  %8s  %8s  %8s  ! Converted from GROMACS\n" "$atom1" "$atom2" "$atom3" "$k" "$theta" "$kub" "$s0" >> $OUTPUT_PRM
            else
                printf "%-8s  %-8s  %-8s  %8s  %8s  ! Converted from GROMACS\n" "$atom1" "$atom2" "$atom3" "$k" "$theta" >> $OUTPUT_PRM
            fi
        done
    else
        echo "Warning: No ITP file found containing angle types"
    fi
    echo "" >> $OUTPUT_PRM
fi

# Process DIHEDRALS section
if [ "$process_dihedrals" = true ]; then
    echo "Processing DIHEDRALS section..."
    echo "DIHEDRALS" >> $OUTPUT_PRM
    echo "!" >> $OUTPUT_PRM
    echo "!V(dihedral) = Kchi(1 + cos(n(chi) - delta))" >> $OUTPUT_PRM
    echo "!" >> $OUTPUT_PRM
    echo "!Kchi: kcal/mole" >> $OUTPUT_PRM
    echo "!n: multiplicity" >> $OUTPUT_PRM
    echo "!delta: degrees" >> $OUTPUT_PRM
    echo "!" >> $OUTPUT_PRM
    echo "!atom types             Kchi    n   delta" >> $OUTPUT_PRM
    echo "" >> $OUTPUT_PRM
    
    # Try to get dihedral types from bonded ITP first, then from combined ITP
    if [ -f "$BONDED_ITP" ]; then
        get_section "$BONDED_ITP" "dihedraltypes" | while read line; do
            atom1=$(echo $line | awk '{print $1}')
            atom2=$(echo $line | awk '{print $2}')
            atom3=$(echo $line | awk '{print $3}')
            atom4=$(echo $line | awk '{print $4}')
            dihedral_type=$(echo $line | awk '{print $5}')
            
            if [ "$dihedral_type" = "9" ]; then
                angle=$(echo $line | awk '{print $6}')
                k=$(echo $line | awk '{print $7}')
                n=$(echo $line | awk '{print $8}')
                k=$(echo "scale=4; $k * $DIHEDRAL_FORCE_CONV" | bc)
                printf "%-8s  %-8s  %-8s  %-8s  %8.4f  %2d  %6.1f  ! Converted from GROMACS\n" "$atom1" "$atom2" "$atom3" "$atom4" "$k" "$n" "$angle" >> $OUTPUT_PRM
            fi
        done
    elif [ -f "$COMBINED_ITP" ]; then
        get_section "$COMBINED_ITP" "dihedraltypes" | while read line; do
            atom1=$(echo $line | awk '{print $1}')
            atom2=$(echo $line | awk '{print $2}')
            atom3=$(echo $line | awk '{print $3}')
            atom4=$(echo $line | awk '{print $4}')
            dihedral_type=$(echo $line | awk '{print $5}')
            
            if [ "$dihedral_type" = "9" ]; then
                angle=$(echo $line | awk '{print $6}')
                k=$(echo $line | awk '{print $7}')
                n=$(echo $line | awk '{print $8}')
                k=$(echo "scale=4; $k * $DIHEDRAL_FORCE_CONV" | bc)
                printf "%-8s  %-8s  %-8s  %-8s  %8.4f  %2d  %6.1f  ! Converted from GROMACS\n" "$atom1" "$atom2" "$atom3" "$atom4" "$k" "$n" "$angle" >> $OUTPUT_PRM
            fi
        done
    else
        echo "Warning: No ITP file found containing dihedral types"
    fi
    echo "" >> $OUTPUT_PRM

    echo "IMPROPER" >> $OUTPUT_PRM
    echo "!" >> $OUTPUT_PRM
    echo "!V(improper) = Kpsi(psi - psi0)**2" >> $OUTPUT_PRM
    echo "!" >> $OUTPUT_PRM
    echo "!Kpsi: kcal/mole/rad**2" >> $OUTPUT_PRM
    echo "!psi0: degrees" >> $OUTPUT_PRM
    echo "!note that the second column of numbers (0) is ignored" >> $OUTPUT_PRM
    echo "!" >> $OUTPUT_PRM
    echo "!atom types           Kpsi                   psi0" >> $OUTPUT_PRM
    echo "" >> $OUTPUT_PRM
    
    if [ -f "$BONDED_ITP" ]; then
        get_section "$BONDED_ITP" "dihedraltypes" | while read line; do
            atom1=$(echo $line | awk '{print $1}')
            atom2=$(echo $line | awk '{print $2}')
            atom3=$(echo $line | awk '{print $3}')
            atom4=$(echo $line | awk '{print $4}')
            dihedral_type=$(echo $line | awk '{print $5}')
            
            if [ "$dihedral_type" = "2" ]; then
                angle=$(echo $line | awk '{print $6}')
                k=$(echo $line | awk '{print $7}')
                k=$(echo "scale=4; $k * $DIHEDRAL_FORCE_CONV" | bc)
                printf "%-8s  %-8s  %-8s  %-8s  %8.4f  0  %6.1f  ! Converted from GROMACS\n" "$atom1" "$atom2" "$atom3" "$atom4" "$k" "$angle" >> $OUTPUT_PRM
            fi
        done
    elif [ -f "$COMBINED_ITP" ]; then
        get_section "$COMBINED_ITP" "dihedraltypes" | while read line; do
            atom1=$(echo $line | awk '{print $1}')
            atom2=$(echo $line | awk '{print $2}')
            atom3=$(echo $line | awk '{print $3}')
            atom4=$(echo $line | awk '{print $4}')
            dihedral_type=$(echo $line | awk '{print $5}')
            
            if [ "$dihedral_type" = "2" ]; then
                angle=$(echo $line | awk '{print $6}')
                k=$(echo $line | awk '{print $7}')
                k=$(echo "scale=4; $k * $DIHEDRAL_FORCE_CONV" | bc)
                printf "%-8s  %-8s  %-8s  %-8s  %8.4f  0  %6.1f  ! Converted from GROMACS\n" "$atom1" "$atom2" "$atom3" "$atom4" "$k" "$angle" >> $OUTPUT_PRM
            fi
        done
    else
        echo "Warning: No ITP file found containing improper dihedral types"
    fi
    echo "" >> $OUTPUT_PRM
fi

# Process NONBONDED section
if [ "$process_nonbonded" = true ]; then
    echo "Processing NONBONDED section..."
    echo "NONBONDED nbxmod  5 atom cdiel shift vatom vdistance vswitch -" >> $OUTPUT_PRM
    echo "cutnb 14.0 ctofnb 12.0 ctonnb 10.0 eps 1.0 e14fac 1.0 wmin 1.5" >> $OUTPUT_PRM
    echo "                !adm jr., 5/08/91, suggested cutoff scheme" >> $OUTPUT_PRM
    echo "!" >> $OUTPUT_PRM
    echo "!V(Lennard-Jones) = Eps,i,j[(Rmin,i,j/ri,j)**12 - 2(Rmin,i,j/ri,j)**6]" >> $OUTPUT_PRM
    echo "!" >> $OUTPUT_PRM
    echo "!epsilon: kcal/mole, Eps,i,j = sqrt(eps,i * eps,j)" >> $OUTPUT_PRM
    echo "!Rmin/2: A, Rmin,i,j = Rmin/2,i + Rmin/2,j" >> $OUTPUT_PRM
    echo "!" >> $OUTPUT_PRM
    echo "!atom  ignored    epsilon      Rmin/2   ignored   eps,1-4       Rmin/2,1-4" >> $OUTPUT_PRM
    echo "" >> $OUTPUT_PRM
    
    # Try to get nonbonded parameters from nonbonded ITP first, then from combined ITP
    if [ -f "$NONBONDED_ITP" ]; then
        get_section "$NONBONDED_ITP" "atomtypes" | while read line; do
            atomtype=$(echo $line | awk '{print $1}')
            sigma=$(echo $line | awk '{print $6}')
            sigma=$(echo "scale=3; $sigma * $LENGTH_CONV" | bc)
            rmin2=$(echo "scale=3; $sigma * 0.5612310241546865" | bc)
            epsilon=$(echo $line | awk '{print $7}')
            epsilon=$(echo "scale=3; -1 * $epsilon * $ENERGY_CONV" | bc)
            printf "%-8s  %6.1f  %7.3f  %6.3f  ! Converted from GROMACS\n" "$atomtype" "0.0" "$epsilon" "$rmin2" >> $OUTPUT_PRM
        done
    elif [ -f "$COMBINED_ITP" ]; then
        get_section "$COMBINED_ITP" "atomtypes" | while read line; do
            atomtype=$(echo $line | awk '{print $1}')
            sigma=$(echo $line | awk '{print $6}')
            sigma=$(echo "scale=3; $sigma * $LENGTH_CONV" | bc)
            rmin2=$(echo "scale=3; $sigma * 0.5612310241546865" | bc)
            epsilon=$(echo $line | awk '{print $7}')
            epsilon=$(echo "scale=3; -1 * $epsilon * $ENERGY_CONV" | bc)
            printf "%-8s  %6.1f  %7.3f  %6.3f  ! Converted from GROMACS\n" "$atomtype" "0.0" "$epsilon" "$rmin2" >> $OUTPUT_PRM
        done
    else
        echo "Warning: No ITP file found containing nonbonded parameters"
    fi
fi

echo "END" >> $OUTPUT_PRM
echo "Conversion complete. Output written to $OUTPUT_PRM" 