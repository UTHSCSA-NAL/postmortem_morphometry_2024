#!/bin/bash

unset PYTHONPATH
unset PYTHONHOME


mask=$1
filled=$2
code=$3
ventricles=$4

tmp=${ventricles::-7}_tmp.nii.gz
tmq=${ventricles::-7}_tmq.nii.gz
tmr=${ventricles::-7}_tmr.nii.gz

# difference (filled-original)
python -c "import numpy as np;import nibabel as nb;im=nb.load('${filled}');r=im.get_fdata();s=nb.load('${mask}').get_fdata();r[s>0.5]=0;nb.save(nb.Nifti1Image(r,im.affine,im.header),'${tmp}')"
# erosion
python -c "import numpy as np;import nibabel as nb;from scipy.ndimage import binary_erosion;im=nb.load('${tmp}');a=im.get_fdata();b=binary_erosion(a, structure=np.ones((3,3,3))).astype(a.dtype);nb.save(nb.Nifti1Image(b,im.affine,im.header),'${tmq}')"
# main component
python ${code}/mainComponent.py -m ${tmq} -o ${tmr}
# dilation
python -c "import numpy as np;import nibabel as nb;from scipy.ndimage import binary_dilation;im=nb.load('${tmr}');a=im.get_fdata();b=binary_dilation(a, structure=np.ones((3,3,3))).astype(a.dtype);nb.save(nb.Nifti1Image(b,im.affine,im.header),'${tmr}')"
# product between difference and dilated main component
python -c "import numpy as np;import nibabel as nb;im=nb.load('${tmr}');r=im.get_fdata();s=nb.load('${tmp}').get_fdata();r[s<0.5]=0;nb.save(nb.Nifti1Image(r,im.affine,im.header),'${ventricles}')"


rm -r ${tmp}
rm -r ${tmq}
rm -r ${tmr}


