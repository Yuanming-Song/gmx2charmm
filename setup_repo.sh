#!/bin/bash

# Initialize git repository
git init

# Create .gitignore file
cat > .gitignore << EOF
# Temporary files
*.tem.prm
*.prm
*.str

# Backup files
*~
*.bak

# System files
.DS_Store
EOF

# Make scripts executable
chmod +x convert_to_charmm.sh
chmod +x generate_str.sh

# Create directory structure
mkdir -p parameters/forcefield/charmm36_dyes.ff
mkdir -p parameters/forcefield/pdbs/dyes
mkdir -p parameters/forcefield/pdbs/with_linker

# Add and commit files
git add README.md
git add convert_to_charmm.sh
git add generate_str.sh
git add setup_repo.sh
git add .gitignore

# Create initial commit
git commit -m "Initial commit: Add conversion scripts and documentation"

# Add force field files
git add parameters/forcefield/charmm36_dyes.ff/ffdyes.itp
git add parameters/forcefield/charmm36_dyes.ff/ffdyesbonded.itp
git add parameters/forcefield/charmm36_dyes.ff/ffdyesnonbonded.itp
git add parameters/forcefield/charmm36_dyes.ff/merged.rtp

# Add PDB files
git add parameters/forcefield/pdbs/dyes/cy7.pdb

# Commit force field and PDB files
git commit -m "Add force field files and PDB structures"

# Create GitHub repository
echo "Please create a new repository on GitHub and then run:"
echo "git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git"
echo "git push -u origin main" 