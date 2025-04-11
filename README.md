# GROMACS to CHARMM Force Field Converter

This repository contains scripts for converting GROMACS force field parameters to CHARMM format. 

## Citation

The force field files used in this repository are from:
```
CHARMM-DYES: Parameterization of Fluorescent Dyes for Use with the CHARMM Force Field
Cite this: J. Chem. Theory Comput. 2020, 16, 12, 7817–7824
```

The original force field files (`ffdyes.itp`, `ffdyesbonded.itp`, `ffdyesnonbonded.itp`, and `merged.rtp`) were developed as part of the CHARMM-DYES force field. This repository provides tools to convert these parameters between GROMACS and CHARMM formats.

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
- Bond force constant: 1 kJ/mol/nm² = 23.9005736 kcal/mol/Å²
- Angle force constant: 1 kJ/mol/rad² = 0.239005736 kcal/mol/rad²
- Dihedral force constant: 1 kJ/mol = 0.239005736 kcal/mol
- Nonbonded parameters:
  - ε: Convert using energy factor and make negative (CHARMM uses negative epsilon)
  - Rmin/2: σ × 2^(⅙)/2 = σ x 0.5612310241546865 (conversion from sigma to Rmin/2)

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

## File Structure

```
.
├── convert_to_charmm.sh
├── generate_str.sh
├── combine_str.sh
├── parameters/
│   └── forcefield/
│       ├── charmm36_dyes.ff/
│       │   ├── ffdyes.itp
│       │   ├── ffdyesbonded.itp
│       │   ├── ffdyesnonbonded.itp
│       │   └── merged.rtp
│       └── pdbs/
│           ├── dyes/
│               └── cy7.pdb
├── dyes.prm           # Example output from convert_to_charmm.sh
├── CY7.str           # Example output from generate_str.sh
├── CY3.str           # Input file for combine_str.sh
└── CY3_CY7_combine.str  # Example output from combine_str.sh
```

## Requirements

- Bash shell
- bc (for floating-point calculations)
- awk
- grep
- se
