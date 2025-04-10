#!/bin/bash

# Initialize git repository if not already initialized
if [ ! -d .git ]; then
    git init
fi

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

# Interactive GitHub setup
echo "GitHub Repository Setup"
echo "----------------------"
read -p "Enter your GitHub username: " github_username
read -p "Enter your repository name: " repo_name

# Check if remote already exists and remove it
if git remote get-url origin &>/dev/null; then
    echo "Remote 'origin' already exists. Removing it..."
    git remote remove origin
fi

# Set up remote and push using HTTPS
git remote add origin "https://github.com/$github_username/$repo_name.git"
git branch -M main

echo "Now you'll need to authenticate with GitHub..."
echo "You can use either:"
echo "1. Personal Access Token (recommended)"
echo "2. GitHub username and password"
echo ""
echo "To create a Personal Access Token:"
echo "1. Go to GitHub.com → Settings → Developer settings → Personal access tokens"
echo "2. Generate new token with 'repo' scope"
echo "3. Copy the token and use it as your password when prompted"
echo ""
echo "Press Enter when ready to push..."
read

git push -u origin main

echo "Repository has been pushed to GitHub!"
echo "You can now visit: https://github.com/$github_username/$repo_name" 