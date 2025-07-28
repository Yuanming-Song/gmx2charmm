Within the ZIP archive are residues and parameters that make up the CHARMM-DYES force field in machine readable format. These are in GROMACS format, and structured as follows. The GROMACS-compatible force field is in the directory charmm36-dyes.ff, which should be copied either to your working directory or directly into your GMXLIB folder before use. Within this directory you can find:

* new atom types in the atomtypes.atp file;
* new residues in merged.rtp, for each dye by itself, with a linker, and attached to thymine;
* new bonded parameters in ffdyesbonded.itp;
* new-by-analogy non-bonded parameters in ffdyesnonbonded.itp.

In the parent directory, there is also a dyes.rtp file containing just the dye residues, for reference, and a residuetypes.dat file which needs to be added to the global GMXDATA/top directory. In addition, we have provided a pdbs folder containing correctly-labelled PDB files for each of the dyes by themselves, and with the linker attached.

If you wish to create new residues, perhaps by attaching the dyes to different nucleobases or amino acids, you will need to update each of the above files. Guidance on how to do this can be found in the GROMACS documentation.