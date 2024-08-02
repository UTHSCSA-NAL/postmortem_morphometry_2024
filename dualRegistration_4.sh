#!/bin/bash

unset PYTHONPATH
unset PYTHONHOME

atlas_orig=${1}
atlas_mask=$2
t1=$3
gm=$4
wm=$5
reg=$6
labels_orig=$7
parcellation=$8
atlas_in_subject=$9
atlas_mask_in_subject=${10}
code=${11}
landmarks=${12}


export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=4

reg1=${reg}_step1_
reg1_warp=${reg}_step1_1Warp.nii.gz
reg1_iwarp=${reg}_step1_1InverseWarp.nii.gz
reg1_aff=${reg}_step1_0GenericAffine.mat
#reg1_all="${reg1_warp} ${reg1_aff}"
reg1_all="${reg1_aff}"


reg2=${reg}_step2_
reg2_warp=${reg}_step2_1Warp.nii.gz
reg2_iwarp=${reg}_step2_1InverseWarp.nii.gz
reg2_aff=${reg}_step2_0GenericAffine.mat
reg2b_warp=${reg}_step2_0Warp.nii.gz
reg2b_iwarp=${reg}_step2_0InverseWarp.nii.gz

#reg2_all="${reg2b_warp} ${reg1_warp} ${reg1_aff}"
reg2_all="${reg2b_warp} ${reg1_aff}"


[ ! -e ${reg1_warp} ] || rm ${reg1_warp}
[ ! -e ${reg1_iwarp} ] || rm ${reg1_iwarp}
[ ! -e ${reg1_aff} ] || rm ${reg1_aff}
[ ! -e ${reg2_warp} ] || rm ${reg2_warp}
[ ! -e ${reg2_iwarp} ] || rm ${reg2_iwarp}
[ ! -e ${reg2_aff} ] || rm ${reg2_aff}
[ ! -e ${reg2b_warp} ] || rm ${reg2b_warp}
[ ! -e ${reg2b_iwarp} ] || rm ${reg2b_iwarp}



#####################################################
echo "first step"
echo "  cerebellum erosion"

atlas=${atlas_in_subject::-7}_atlas.nii.gz
labels=${atlas_in_subject::-7}_labels.nii.gz
cp ${atlas_orig} ${atlas}
cp ${labels_orig} ${labels}
python ${code}/oasisCerebellumErosion.py -a ${atlas} -l ${labels}



manual=${t1::-7}_manual.nii.gz
if [ ! -e ${manual} ]; then

	echo "  registration"
	/ants/antsRegistration -d 3 -u -r [ ${t1},${atlas},1 ] -t Rigid[ 0.2 ] -m MI[ ${t1},${atlas},1,16,None ] -c [ 1000x1000x1000x750,1e-9,10 ] -f 8x6x4x2 -s 4x3x2x1vox -t Affine[ 0.2 ] -m MI[ ${t1},${atlas},1,16,None ] -c [ 1000x1000x1000x750,1e-9,10 ] -f 8x6x4x2 -s 4x3x2x1vox -o ${reg1}


	check=${atlas_in_subject::-7}_check.nii.gz
	/ants/antsApplyTransforms -d 3 -n GenericLabel -i ${atlas} -r ${t1} -o ${check} -t ${reg1_all}

else
	echo "  manual registration"

	reg1=${reg}_step1_
	reg1_warp=${reg}_step1_1Warp.nii.gz
	reg1_iwarp=${reg}_step1_1InverseWarp.nii.gz
	reg1_aff=${reg}_step1_0GenericAffine.mat
	#reg1_all="${reg1_warp} ${reg1_aff}"
	#reg1_all="${reg1_warp}"
	reg1_all="${reg1_aff}"


	/ants/antsLandmarkBasedTransformInitializer 3 ${manual} ${landmarks} affine ${reg1_all}
	#/ants/antsLandmarkBasedTransformInitializer 3 ${manual} ${landmarks} bspline ${reg1_warp}



	check=${atlas_in_subject::-7}_check.nii.gz
        /ants/antsApplyTransforms -d 3 -n GenericLabel -i ${atlas} -r ${t1} -o ${check} -t ${reg1_all}	
	
fi



####################################################
echo "second step"


atlas_tmp=${atlas_in_subject::-7}_tmp.nii.gz
/ants/antsApplyTransforms -d 3 -n BlackmanWindowedSinc -i ${atlas} -r ${t1} -o ${atlas_tmp} -t ${reg1_all}



#/ants/antsRegistration -d 3 -u -w [ 0.005,0.995 ] -t Syn[ 0.1 ] -m MI[ ${t1},${atlas_tmp},1,8,None ] -c [ 1000x1000x1000x1000,1e-9,10 ] -f 8x6x4x2 -s 4x3x2x1vox -o ${reg2}
/ants/antsRegistration -d 3 -u -w [ 0.005,0.995 ] -t Syn[ 0.1 ] -m MI[ ${t1},${atlas_tmp},1,16,None ] -c [ 1000x1000x1000x1000,1e-9,10 ] -f 8x6x4x2 -s 4x3x2x1vox -o ${reg2}


#####################################################
#echo "transforms application"


/ants/antsApplyTransforms -d 3 -n BlackmanWindowedSinc -i ${atlas} -r ${t1} -o ${atlas_in_subject} -t ${reg2_all} 
#/ants/antsApplyTransforms -d 3 -n GenericLabel -i ${atlas_mask} -r ${t1} -o ${atlas_mask_in_subject} -t ${reg2_all} 
#/ants/antsApplyTransforms -d 3 -n GenericLabel -i ${labels} -r ${t1} -o ${parcellation} -t ${reg2_all} 


/ants/antsApplyTransforms -d 3 -n NearestNeighbor -i ${atlas_mask} -r ${t1} -o ${atlas_mask_in_subject} -t ${reg2_all}
/c3d/c3d ${atlas_mask_in_subject} -type short -o ${atlas_mask_in_subject}
/ants/antsApplyTransforms -d 3 -n NearestNeighbor -i ${labels} -r ${t1} -o ${parcellation} -t ${reg2_all}
/c3d/c3d ${parcellation} -type short -o ${parcellation}



echo "cleaning the parcellation"
cp ${parcellation} ${parcellation::-7}_raw.nii.gz
python ${code}/cleanParcellation.py -p ${parcellation} -gm ${gm} -wm ${wm}


[ ! -e ${reg1_warp} ] || rm ${reg1_warp}
[ ! -e ${reg1_iwarp} ] || rm ${reg1_iwarp}
[ ! -e ${reg1_aff} ] || rm ${reg1_aff}
[ ! -e ${reg2_warp} ] || rm ${reg2_warp}
[ ! -e ${reg2_iwarp} ] || rm ${reg2_iwarp}
[ ! -e ${reg2_aff} ] || rm ${reg2_aff}
[ ! -e ${reg2b_warp} ] || rm ${reg2b_warp}
[ ! -e ${reg2b_iwarp} ] || rm ${reg2b_iwarp}


