# Overview
Postmortem image processing pipeline. 
To gain some space, only five downsampled OASIS-TRT atlases are provided. The other atlases can be downloaded from [1,2].

## Requirements

- Singularity (https://sylabs.io/docs/)
- SLURM workload manager (https://slurm.schedmd.com/documentation.html)

## Building the containers

Go into the "containers" folder and execute the "containers_preparation.sh" script
```
cd containers
./containers_preparation.sh
```



[1] S. Marcus, T. H. Wang, J. Parker, J. G. Csernansky,
J. C. Morris, R. L. Buckner, Open access series of imag-
ing studies (OASIS): Cross-sectional mri data in young,
middle aged, nondemented, and demented older adults,
Journal of Cognitive Neuroscience 19 (2007) 1498 –
1507.

[2] A. Klein, J. Tourville, 101 labeled brain images and a
consistent human cortical labeling protocol, Frontiers
in neuroscience 6 (2012) 171.
