# Gaussian-File-Generator
These files are used to create numerous Gaussian files that should work on slurm systems. It is not finished yet as it is still personalized and not for general use

HOW TO USE:

1.  Copy the files to any folder within your working slurm system, preferrably to a new folder so that it is easily accessible
2.  In the Gau_File_Gen.com, change the directory to specify where these files are
3.  Similarly, change in the sender file the directory where you are going to work
4.  Use chmod +x Gau_File_Gen.com and sender so that they become executables
5.  Execute the program and follow the steps.
6.  Once it finished creating the files, check that they are what you intended to.
7.  Prepare the Geometry.xyz files for each molecule
8.  Execute the sender program with the name of the file you want to send (i.e. ./sender H2O_b3lyp.6-311G)
9.  Wait the calculation to finish and collect the data


Thanks for reading.
