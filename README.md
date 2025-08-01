# GROMACS to CHARMM Force Field Converter

This repository contains scripts for converting GROMACS force field parameters to CHARMM format and tools for structure validation.

## Updates

### July 28, 2025
- Fixed force constant conversion in `convert_to_charmm.sh` for bond and angle parameters.
- In GROMACS, bond and angle energies are calculated as V(x) = k*x²/2, while CHARMM uses V(x) = k*x².
- Updated conversion factors to divide bond and angle force constants by 2 when converting from GROMACS to CHARMM format.
- Added Urey-Bradley (UB) terms support to angle parameter conversion.
- GROMACS angle format: atom1 atom2 atom3 func θ0 kθ S0 KUB
- CHARMM angle format: atom1 atom2 atom3 Kθ θ0 KUB S0
- KUB force constants use bond force constant conversion (including divide by 2 from GROMACS to CHARMM).
- S0 distances use length conversion (nm to Å).


## Citation

The force field files used in this repository are from:
```
CHARMM-DYES: Parameterization of Fluorescent Dyes for Use with the CHARMM Force Field
Cite this: J. Chem. Theory Comput. 2020, 16, 12, 7817–7824
```

The original force field files (`ffdyes.itp`, `ffdyesbonded.itp`, `ffdyesnonbonded.itp`, and `merged.rtp`) were developed as part of the CHARMM-DYES force field. This repository provides tools to convert these parameters between GROMACS and CHARMM formats.


## Scripts

### 1. convert_to_charmm.sh

This script converts GROMACS ITP files to CHARMM PRM format. It handles the conversion of:
- ATOMS (mass definitions)
- BONDS (bond parameters)
- ANGLES (angle parameters)
- DIHEDRALS (proper and improper dihedral parameters)
- NONBONDED (Lennard-Jones parameters)

#### Usage:
```bash
./convert_to_charmm.sh
```

The script provides an interactive menu for:
- Configuring input/output files
- Setting conversion factors
- Selecting which sections to process
- Reviewing settings before conversion

#### Input Files:
- `parameters/forcefield/charmm36_dyes.ff/ffdyesnonbonded.itp`
- `parameters/forcefield/charmm36_dyes.ff/ffdyesbonded.itp`
- `parameters/forcefield/charmm36_dyes.ff/ffdyes.itp`

#### Output:
- `dyes.prm` (default name, configurable) - Example output file containing converted CHARMM parameters

### 2. generate_str.sh

This script generates CHARMM stream files (.str) from GROMACS RTP files and PDB structures. It:
- Scans RTP files for available residues
- Allows interactive selection of residues
- Generates topology and parameter files
- Handles bonds, angles, dihedrals, and impropers

#### Usage:
```bash
./generate_str.sh
```

The script will:
1. Show available residues
2. Prompt for residue selection
3. Search for corresponding PDB files
4. Generate STR and temporary PRM files

#### Input Files:
- `parameters/forcefield/charmm36_dyes.ff/merged.rtp`
- PDB files in `parameters/forcefield/pdbs/dyes/` or `parameters/forcefield/pdbs/with_linker/`

#### Output:
- `[residue_name].str` - Example: `CY7.str` contains the CHARMM stream file for the CY7 dye molecule
- `[residue_name].tem.prm` - Temporary parameter file used during generation

### 3. combine_str.sh

This script combines two CHARMM stream files (.str) into a single structure. It:
- Allows deletion of specific atoms from either structure
- Creates new bonds between the two structures
- Maintains proper atom naming and numbering
- Preserves all comments and parameter sections

#### Usage:
```bash
./combine_str.sh
```

The script will:
1. Prompt for two input STR files
2. Ask for a 4-character residue name for the combined structure
3. Allow specification of atoms to delete from each structure
4. Enable creation of new bonds between the structures
5. Generate a combined STR file with proper formatting

#### Example:
- Input files: `CY3.str` and `CY7.str`
- Output file: `CY3_CY7_combine.str` - Contains the combined structure with proper atom naming and bonds

#### Features:
- Preserves comments from both original files
- Maintains proper atom numbering
- Combines parameter sections (BONDS, ANGLES, DIHEDRALS, IMPROPERS)
- Removes duplicates in parameter sections
- Adds clear documentation of which files were combined

## Example Output Files

The repository includes example output files to demonstrate the conversion results:

1. `dyes.prm`: CHARMM parameter file generated by `convert_to_charmm.sh`, containing:
   - Mass definitions
   - Bond parameters
   - Angle parameters
   - Dihedral parameters (both proper and improper)
   - Nonbonded parameters

2. `CY7.str`: CHARMM stream file generated by `generate_str.sh` for the CY7 dye molecule, containing:
   - Residue topology
   - Atom definitions
   - Bond connections
   - Improper dihedral definitions

3. `CY3_CY7_combine.str`: CHARMM stream file generated by `combine_str.sh`, demonstrating:
   - Combined structure of CY3 and CY7 dyes
   - Proper atom naming and numbering
   - New bonds between the structures
   - Combined parameter sections



# Bond Sanity Check Tool

This repository contains tools for checking and validating molecular structure files.

## Bond Sanity Check Script (`bond_sanity_check.sh`)

This script performs a sanity check between STR (structure) and PRM (parameter) files by verifying that all bond definitions in the STR file have corresponding parameter definitions in the PRM files.

### Features

- Interactive prompts for input files
- Checks all BOND definitions in the STR file
- Maps atoms to their atom types using ATOM definitions
- Verifies bond parameters exist in PRM files
- Shows the first 5 missing bonds automatically
- Option to view additional missing bonds
- Displays both original atom names and their corresponding atom types

### Usage

1. Make sure the script is executable:
   ```bash
   chmod +x bond_sanity_check.sh
   ```

2. Run the script:
   ```bash
   ./bond_sanity_check.sh
   ```

3. When prompted:
   - Enter the path to your STR file
   - Enter the paths to one or more PRM files
   - Press Enter without input when done adding PRM files

### Output Format

For each missing bond, the script outputs:
```
Missing bond: ATOM1 ATOM2 (TYPE1 TYPE2)
```
Where:
- `ATOM1 ATOM2`: Original atom names from the STR file
- `TYPE1 TYPE2`: Corresponding atom types from the ATOM definitions

If there are more than 5 missing bonds, the script will prompt:
```
Show next 5 missing bonds? (y/n)
```
This repeats in groups of 5 until all missing bonds are shown or you choose to stop.

### Example

```bash
$ ./bond_sanity_check.sh
Bond Sanity Check Script
=======================
Enter the path to the STR file: molecule.str
Enter the path to a PRM file (or press Enter to finish): params1.prm
Enter the path to a PRM file (or press Enter to finish): params2.prm
Enter the path to a PRM file (or press Enter to finish): 

Missing bond: C1 C2 (CG2R61 CG2R61)
...
```

### Requirements

- Bash shell
- Basic Unix tools (awk, grep)
- Read permissions for input files

## File Structure
```
.
├── Scripts/                    # Conversion and validation scripts
│   ├── convert_to_charmm.sh   # Converts GROMACS parameters to CHARMM format
│   ├── generate_str.sh        # Generates CHARMM stream files from RTP files
│   ├── combine_str.sh         # Combines two CHARMM stream files
│   ├── bond_sanity_check.sh   # Validates bond parameters between STR and PRM files
│   └── parse_rtp.sh          # Helper script for RTP file processing
│
├── Example_output/           # Example output files
│   ├── dyes.prm             # Converted CHARMM parameters
│   ├── CY3.str             # Example stream file for CY3
│   ├── CY7.str             # Example stream file for CY7
│   └── CY3_CY7_combine.str # Combined structure example
│
└── parameters/              # Input parameter files
    └── forcefield/         # GROMACS force field files
        ├── charmm36_dyes.ff/
        │   ├── ffdyesbonded.itp
        │   ├── ffdyesnonbonded.itp
        │   └── merged.rtp
        └── pdbs/
            └── dyes/
                └── cy7.pdb

```

## Requirements

- Bash shell
- bc (for floating-point calculations)
- awk
- grep
- se

## Unit Conventions and Conversion Factors

### GROMACS Units
- Energy: kJ/mol
- Length: nm
- Bond force constant: kJ/mol/nm²
- Angle force constant: kJ/mol/rad²
- Dihedral force constant: kJ/mol
- Nonbonded parameters:
  - ε (epsilon): kJ/mol
  - σ (sigma): nm

### CHARMM Units
- Energy: kcal/mol
- Length: Å
- Bond force constant: kcal/mol/Å²
- Angle force constant: kcal/mol/rad²
- Dihedral force constant: kcal/mol
- Nonbonded parameters:
  - ε (epsilon): kcal/mol
  - Rmin/2: Å

### Default Conversion Factors
The scripts use the following conversion factors:
- Energy: 1 kJ/mol = 0.239005736 kcal/mol
- Length: 1 nm = 10 Å
- Bond force constant: 1 kJ/mol/nm² = 11.9502868 kcal/mol/Å² (divided by 2 for GROMACS→CHARMM)
- Angle force constant: 1 kJ/mol/rad² = 0.119502868 kcal/mol/rad² (divided by 2 for GROMACS→CHARMM)
- Dihedral force constant: 1 kJ/mol = 0.239005736 kcal/mol
- Nonbonded parameters:
  - ε: Convert using energy factor and make negative (CHARMM uses negative epsilon)
  - Rmin/2: σ × 2^(⅙)/2 = σ x 0.5612310241546865 (conversion from sigma to Rmin/2)

**Note:** Bond and angle force constants are divided by 2 when converting from GROMACS to CHARMM because GROMACS uses V(x) = k*x²/2 while CHARMM uses V(x) = k*x².

## Working Directory

The `7_5_2025/` directory contains:
- STR files from ongoing work and development
- Notes and documentation for current projects
- Temporary working files and experimental data

