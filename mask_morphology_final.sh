#!/bin/bash


unset PYTHONPATH
unset PYTHONHOME

ma=$1  # original mask
mb=$2  # new mask

echo "  copy"
cp ${ma} ${mb}

echo "  filling holes"
/fsl/fsl5.0-fslmaths ${mb} -fillh ${mb}

echo "  removing disconnected components"
/fsl/fsl5.0-cluster -i ${mb} -t 1 --connectivity=26  --no_table --osize=${mb::-7}_cluster_size.nii.gz
python -c "import nibabel as nb;import numpy as np;a=nb.load('${mb::-7}_cluster_size.nii.gz').get_fdata().astype(int);fi=open('${mb::-7}_cluster_size.txt','w');fi.write(str(np.max(a[:])));fi.close()"
thr=$(head -n 1 ${mb::-7}_cluster_size.txt)
/fsl/fsl5.0-fslmaths ${mb::-7}_cluster_size.nii.gz -thr ${thr} -bin ${mb}
rm ${mb::-7}_cluster_size.nii.gz
rm ${mb::-7}_cluster_size.txt

rm ${ma}
mv ${mb} ${ma}


