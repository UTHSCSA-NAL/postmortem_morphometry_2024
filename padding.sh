#!/bin/bash

unset PYTHONPATH
unset PYTHONHOME

in=$1
ou=$2
p=$3

python -c "import numpy as np;import nibabel as nb;im=nb.load('${in}');a=im.get_fdata();r=np.zeros((a.shape[0]+2*$p,a.shape[1]+2*$p,a.shape[2]+2*$p));r[$p:($p+a.shape[0]),$p:($p+a.shape[1]),$p:($p+a.shape[2])]=a;nb.save(nb.Nifti1Image(r,im.affine,im.header),'${ou}')"


