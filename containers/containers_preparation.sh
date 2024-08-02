#!/bin/bash


echo "BUILDING CONTAINERS"
singularity build --fakeroot ants.sif ants.def

wget -O software/c3d-nightly-Linux-gcc64.tar.gz  https://sourceforge.net/projects/c3d/files/c3d/Nightly/c3d-nightly-Linux-gcc64.tar.gz/download
singularity build --fakeroot ants_c3d.sif ants_c3d.def

singularity build --fakeroot fsl.sif fsl.def

singularity build --fakeroot naonlm.sif naonlm.def

singularity build --fakeroot python.sif python.def

singularity build --fakeroot python_DeepLearning.sif python_DeepLearning.def 



echo "CHECKING CONTAINERS"
singularity exec ants.sif /ants/antsRegistration -h

singularity exec ants_c3d.sif /ants/antsRegistration -h
singularity exec ants_c3d.sif /c3d/c3d -h

singularity exec fsl.sif /fsl/fsl5.0-fslmaths -h

singularity exec naonlm.sif /naonlm3d/naonlm3d -h

singularity exec python.sif python --version

singularity exec python_DeepLearning.sif python -c "import tensorflow as tf;print(tf.__version__)"
singularity exec python_DeepLearning.sif python -c "import keras; print(keras.__version__)"




