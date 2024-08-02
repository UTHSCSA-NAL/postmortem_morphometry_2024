# Overview
Postmortem image processing pipeline. 
To gain some space, only five downsampled OASIS-TRT atlases are provided. The other atlases can be downloaded from [1,2].

## Requirements

- Linux operating system
- Singularity (https://sylabs.io/docs/)
- SLURM workload manager (https://slurm.schedmd.com/documentation.html)

## Building the containers

Go into the "containers" folder and execute the "containers_preparation.sh" script
```
cd containers
./containers_preparation.sh
```

## Processing data

The data processing is conducted by the script
```
processing_postmortem.sh
```

In this script, please note that:

- The first variable "project" should be set to point to the folder currently containing this README file.
  
- The variable "debug" should be set to 1 to prevent the use of SLURM, and 0 to submit jobs to the worklad manager.
   
- The "nolog" variable suppresses the generation of log files by the SLURM workload manager.

- The script processes data stored in the "data_exvivo" folder. In this folder, each subfolder corresponds to a different brain identified using an anonymized index, and each brain folder contains a T1-weighted and a T2-weighted MRI scan.

We have provided the MRI scans of 3 postmortem brains in the "data" folders to test the scripts.


[1] S. Marcus, T. H. Wang, J. Parker, J. G. Csernansky,
J. C. Morris, R. L. Buckner, Open access series of imag-
ing studies (OASIS): Cross-sectional mri data in young,
middle aged, nondemented, and demented older adults,
Journal of Cognitive Neuroscience 19 (2007) 1498 –
1507.

[2] A. Klein, J. Tourville, 101 labeled brain images and a
consistent human cortical labeling protocol, Frontiers
in neuroscience 6 (2012) 171.
