#!/bin/bash

t1=$1
t2=$2  
ma=$3
ou=$4
ouu=$5
tissues=$6
resolution=$7
gm=$8
wm=$9


# removing low-frequency sptial components
mb=${ma::-7}_smoothed.nii.gz
/fsl/fsl5.0-fslmaths ${ma} -s ${resolution} ${mb}
/fsl/fsl5.0-fslmaths ${mb} -mul ${ma} ${mb}

ov=${ou::-7}_smoothed.nii.gz
#ow=${ou::-7}_product.nii.gz



/fsl/fsl5.0-fslmaths ${t1} -s ${resolution} ${ov}
#/fsl/fsl5.0-fslmaths ${t1} -mul ${t2} ${ow}
#/fsl/fsl5.0-fslmaths ${ow} -s ${resolution} ${ov}


/fsl/fsl5.0-fslmaths ${ov} -div ${mb} ${ov}
/fsl/fsl5.0-fslmaths ${ov} -mul ${ma} ${ov}
me=`python -c "import numpy as np;import nibabel as nb;a=nb.load('${ov}').get_fdata();m=nb.load('${ma}').get_fdata().astype(int);print(np.mean(a*m)/np.mean(m))"`
/fsl/fsl5.0-fslmaths ${t1} -div ${ov} ${ou}
#/fsl/fsl5.0-fslmaths ${ow} -div ${ov} ${ou}

/fsl/fsl5.0-fslmaths ${ou} -mul ${ma} ${ou}
/fsl/fsl5.0-fslmaths ${ou} -mul ${me} ${ou}
rm ${ov}
#rm ${ow}

ovv=${ouu::-7}_smoothed.nii.gz
/fsl/fsl5.0-fslmaths ${t2} -s ${resolution} ${ovv}
/fsl/fsl5.0-fslmaths ${ovv} -div ${mb} ${ovv}
/fsl/fsl5.0-fslmaths ${ovv} -mul ${ma} ${ovv}
mee=`python -c "import numpy as np;import nibabel as nb;a=nb.load('${ovv}').get_fdata();m=nb.load('${ma}').get_fdata().astype(int);print(np.mean(a*m)/np.mean(m))"`
/fsl/fsl5.0-fslmaths ${t2} -div ${ovv} ${ouu}
/fsl/fsl5.0-fslmaths ${ouu} -mul ${ma} ${ouu}
/fsl/fsl5.0-fslmaths ${ouu} -mul ${mee} ${ouu}
rm ${ovv}

rm ${mb}




# tissue segmentation
/fsl/fsl5.0-fast -n 2 -t 1 -N --nopve -o ${tissues} ${ouu}    # T2 segmentation
#/fsl/fsl5.0-fast -n 2 -t 1 -N --nopve -o ${tissues} ${ou}    # T1 segmentation
[ ! -e ${tissues::-7}_seg.nii.gz ] || mv ${tissues::-7}_seg.nii.gz ${tissues}

# thresholding
/fsl/fsl5.0-fslmaths ${tissues} -thr 1.5 -bin ${gm}
/fsl/fsl5.0-fslmaths ${tissues} -thr 0.5 -uthr 1.5 -bin ${wm}


echo ${gm}
echo ${wm}

# interverting labels to get label 1 for GM and 2 for WM
#python -c "import numpy as np;import nibabel as nb;im=nb.load('${tissues}');r=im.get_fdata().astype(int);r[r==2]=3;r[r==1]=2;r[r==3]=1;nb.save(nb.Nifti1Image(r,im.affine,im.header),'${tissues}')"



