# GROMACS to CHARMM Force Field Converter

This repository contains scripts for converting GROMACS force field parameters to CHARMM format. 

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
- `dyes.prm` (default name, configurable)

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
- `[residue_name].str`
- `[residue_name].tem.prm`

## File Structure

```
.
├── convert_to_charmm.sh
├── generate_str.sh
├── parameters/
│   └── forcefield/
│       ├── charmm36_dyes.ff/
│       │   ├── ffdyes.itp
│       │   ├── ffdyesbonded.itp
│       │   ├── ffdyesnonbonded.itp
│       │   └── merged.rtp
│       └── pdbs/
│           ├── dyes/
│           │   └── cy7.pdb
│           └── with_linker/
└── README.md
```

## Requirements

- Bash shell
- bc (for floating-point calculations)
- awk
- grep
- sed

