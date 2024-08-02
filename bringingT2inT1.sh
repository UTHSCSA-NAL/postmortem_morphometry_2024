#!/bin/bash

t1=$1
t2=$2
t2int1=$3
t2orig=$4
t2origint1=$5


t2f=${t2int1::-7}_rescale.nii.gz
t2origf=${t2origint1::-7}_rescale.nii.gz


/ants/ResampleImage 3 ${t2} ${t2f} 0.5x0.5x0.5 windowedSinc
/ants/ResampleImage 3 ${t2orig} ${t2origf} 0.5x0.5x0.5 windowedSinc


reg=${t2int1::-7}_ants
reg_aff=${reg}_0GenericAffine.mat
[ ! -e ${reg_aff} ] || rm ${reg_aff}


/ants/antsRegistration -d 3 -u -w [0.005,0.995] -r [${t1},${t2f},1] -t Rigid[0.2] -m MI[${t1},${t2f},1,32,None] -c [1000x750x500x250x100,1e-8,10] -f 8x6x4x2x1 -s 4x3x2x1x0vox -o ${reg}_


/ants/antsApplyTransforms -d 3 -n BlackmanWindowedSinc -i ${t2f} -r ${t1} -o ${t2int1} -t ${reg_aff}
/ants/antsApplyTransforms -d 3 -n BlackmanWindowedSinc -i ${t2origf} -r ${t1} -o ${t2origint1} -t ${reg_aff}

rm ${t2f}
rm ${t2origf}

echo "done:  ${t2int1}"

