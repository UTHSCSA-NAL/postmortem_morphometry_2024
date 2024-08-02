#!/bin/bash


# project and data locations, should be set to your new project location
project=/home/honnorat2
data=${project}/data_exvivo


source ${project}/h2.sh


debug=1				# set to 0 to used SLURM scheduler, to 1 to run the processing step by step in command line
nolog=0				# set to 0 to write logs, to 1 to write no logs
slots=1				# keep ip at 1
logsFolder=${project}/slurm		# folder where the logs will be written (when nolog=0)
jobsFolder=${project}/jobs		# folder where the slurm job scripts will be generated
idPrevious=-1
containers=${project}/containers
common4="4 ${slots} ${jobsFolder} ${logsFolder} ${nolog} ${debug}"
common6="6 ${slots} ${jobsFolder} ${logsFolder} ${nolog} ${debug}"
common8="8 ${slots} ${jobsFolder} ${logsFolder} ${nolog} ${debug}"
common10="10 ${slots} ${jobsFolder} ${logsFolder} ${nolog} ${debug}"
common12="12 ${slots} ${jobsFolder} ${logsFolder} ${nolog} ${debug}"
common16="16 ${slots} ${jobsFolder} ${logsFolder} ${nolog} ${debug}"
common20="20 ${slots} ${jobsFolder} ${logsFolder} ${nolog} ${debug}"
common20_4="20 4 ${jobsFolder} ${logsFolder} ${nolog} ${debug}"
common24="24 ${slots} ${jobsFolder} ${logsFolder} ${nolog} ${debug}"
common28="28 ${slots} ${jobsFolder} ${logsFolder} ${nolog} ${debug}"


code=${project}



######################################################################
# PIPELINE
######################################################################

templates=${project}/atlases


scanList=${project}/list.lst
ls -d ${data}/* > ${scanList}


modelx=${project}/models/all_multi_x_model.h5
modely=${project}/models/all_multi_y_model.h5
modelz=${project}/models/all_multi_z_model.h5


nb=$(wc -l < "${scanList}")
exec 3< "${scanList}"


for ii in $(seq 1 1 ${nb}); do
	read sub <&3
	sub=$(basename ${sub} )
	idPrevious=-1
	
	echo "processing folder ${sub}"
	
	t1=${data}/${sub}/${sub}_t1.nii.gz
	t2=${data}/${sub}/${sub}_t2.nii.gz
	t1n4=${data}/${sub}/${sub}_t1_n4.nii.gz
	t2n4=${data}/${sub}/${sub}_t2_n4.nii.gz
	if [ ! -e ${t1n4} ] ; then
		echo "${sub}_biascorrection_t1"
		execute "/ants/N4BiasFieldCorrection -i ${t1} -o ${t1n4}" ${containers}/ants.sif "${sub}_biascorrection_t1" ${common4} ${idPrevious}
	fi
	if [ ! -e ${t2n4} ] ; then
		echo "${sub}_biascorrection_t2"
		execute "/ants/N4BiasFieldCorrection -i ${t2} -o ${t2n4}" ${containers}/ants.sif "${sub}_biascorrection_t2" ${common4} ${idPrevious}
	fi
	
	t1denoised=${data}/${sub}/${sub}_t1_denoised.nii.gz
	t2denoised=${data}/${sub}/${sub}_t2_denoised.nii.gz
	if [ ! -e ${t1denoised} ] ; then
		echo "${sub}_denoising_t1"
		execute "/naonlm3d/naonlm3d -i ${t1n4} -o ${t1denoised}" ${containers}/naonlm.sif "${sub}_denoising_t1" ${common4} ${idPrevious}
	fi
	if [ ! -e ${t2denoised} ] ; then
		echo "${sub}_denoising_t2"
		execute "/naonlm3d/naonlm3d -i ${t2n4} -o ${t2denoised}" ${containers}/naonlm.sif "${sub}_denoising_t2" ${common4} ${idPrevious}
	fi
	
	t2int1_denoised=${data}/${sub}/${sub}_t2_in_t1_denoised.nii.gz
	t2int1=${data}/${sub}/${sub}_t2_in_t1.nii.gz
	if [ ! -e ${t2int1} ] ; then
		echo "${sub}_t2_in_t1"
		execute "${code}/bringingT2inT1.sh ${t1denoised} ${t2denoised} ${t2int1_denoised} ${t2} ${t2int1}" ${containers}/ants.sif "${sub}_t2_in_t1" ${common8} ${idPrevious}
	fi
	
	t1mask=${data}/${sub}/${sub}_t1_mask.nii.gz	
	t1manual=${data}/${sub}/${sub}_t1_mask_manual.nii.gz
	t1brain=${data}/${sub}/${sub}_t1_brain.nii.gz
	t2brain=${data}/${sub}/${sub}_t2_brain.nii.gz
	if [ ! -e ${t2brain} ] ; then
		if [ ! -e ${t1manual} ]; then
			echo "${sub}_skullstripping"
			execute "python3 ${code}/deepmirNH.py -mx ${modelx} -my ${modely} -mz ${modelz} -t1 ${t1} -t2 ${t2int1} -o ${t1mask}" ${containers}/python_DeepLearning.sif "${sub}_skullstripping" ${common12} ${idPrevious}
			execute "/fsl/fsl5.0-fslmaths ${t1mask} -thr 0.0 -bin ${t1mask}" ${containers}/fsl.sif "${sub}_skullstripping2" ${common4} ${idPrevious}
			execute "${code}/mask_morphology_final.sh ${t1mask} ${t1mask::-7}_tmp.nii.gz" ${containers}/fsl.sif "${sub}_morphomath" ${common4} ${idPrevious}
			execute "/fsl/fsl5.0-fslmaths ${t1denoised} -mul ${t1mask} ${t1brain}" ${containers}/fsl.sif "${sub}_mult" ${common4} ${idPrevious}
			execute "/fsl/fsl5.0-fslmaths ${t2int1_denoised} -mul ${t1mask} ${t2brain}" ${containers}/fsl.sif "${sub}_mult" ${common4} ${idPrevious}
		else
			execute "/fsl/fsl5.0-fslmaths ${t1denoised} -mul ${t1manual} ${t1brain}" ${containers}/fsl.sif "${sub}_mult" ${common4} ${idPrevious}
			execute "/fsl/fsl5.0-fslmaths ${t2int1_denoised} -mul ${t1manual} ${t2brain}" ${containers}/fsl.sif "${sub}_mult" ${common4} ${idPrevious}
		fi
	fi
	
	
	t1corr=${data}/${sub}/${sub}_t1_brain_corrected.nii.gz
	t2corr=${data}/${sub}/${sub}_t2_brain_corrected.nii.gz
	gmwm=${data}/${sub}/${sub}_gmwm.nii.gz
	gm=${data}/${sub}/${sub}_gm.nii.gz
	wm=${data}/${sub}/${sub}_wm.nii.gz
	resolution=2.0
	if [ ! -e ${wm} ] ; then
		echo "${sub}_segmentation"
		if [ ! -e ${t1manual} ]; then
			execute "${code}/gmwm.sh ${t1brain} ${t2brain} ${t1mask} ${t1corr} ${t2corr} ${gmwm} ${resolution} ${gm} ${wm}" ${containers}/fsl.sif "${sub}_segmentation" ${common12} ${idPrevious}
		else
			execute "${code}/gmwm.sh ${t1brain} ${t2brain} ${t1manual} ${t1corr} ${t2corr} ${gmwm} ${resolution} ${gm} ${wm}" ${containers}/fsl.sif "${sub}_segmentation" ${common12} ${idPrevious}
		fi
	fi

	
	t1corr_pad=${data}/${sub}/${sub}_t1_brain_corrected_padded.nii.gz
	t2corr_pad=${data}/${sub}/${sub}_t2_brain_corrected_padded.nii.gz
	gm_pad=${data}/${sub}/${sub}_gm_padded.nii.gz
	wm_pad=${data}/${sub}/${sub}_wm_padded.nii.gz
	pad=5
	if [ ! -e ${wm_pad} ] ; then
		echo "${sub}_padding"
		execute "${code}/padding.sh ${t1corr} ${t1corr_pad} ${pad}" ${containers}/python.sif "${sub}_pad1" ${common4} ${idPrevious}
		execute "${code}/padding.sh ${t2corr} ${t2corr_pad} ${pad}" ${containers}/python.sif "${sub}_pad2" ${common4} ${idPrevious}
		execute "${code}/padding.sh ${gm} ${gm_pad} ${pad}" ${containers}/python.sif "${sub}_pad3" ${common4} ${idPrevious}
		execute "${code}/padding.sh ${wm} ${wm_pad} ${pad}" ${containers}/python.sif "${sub}_pad3" ${common4} ${idPrevious}
	fi


	
	nextId=
	all=${data}/${sub}/allParcellations.lst
	parc=${data}/${sub}/parcellation.nii.gz
	[ ! -e ${all} ] || rm ${all}
	if [ ! -e ${parc} ] ; then
		for j in $(seq 1 1 5); do
			atlasLeft=${templates}/OASIS-TRT-20-${j}/t1weighted.MNI152_left.nii.gz
			atlasMaskLeft=${templates}/OASIS-TRT-20-${j}/mask.MNI152_left_noventricle.nii.gz
			labelsLeft=${templates}/OASIS-TRT-20-${j}/labels.DKT31.manual+aseg.MNI152_left.nii.gz
			reg_j=${data}/${sub}/ants_${j}
			parc_j=${parc::-7}_${j}.nii.gz
			atlas_in_subject=${data}/${sub}/OASIS-TRT-20-${j}_in_${sub}_space.nii.gz
			atlas_mask_in_subject=${data}/${sub}/OASIS-TRT-20-${j}_mask_in_${sub}_space.nii.gz
			landmarks=${templates}/OASIS-TRT-20-${j}/landmarks.nii.gz
			if [ ! -e ${parc_j} ]; then
				echo "${sub}_registration_${j}"
executeInParralel "${code}/dualRegistration_4.sh ${atlasLeft} ${atlasMaskLeft} ${t2corr_pad} ${gm_pad} ${wm_pad} ${reg_j} ${labelsLeft} ${parc_j} ${atlas_in_subject} ${atlas_mask_in_subject} ${code} ${landmarks}" ${containers}/ants_c3d.sif "${sub}_reg_${j}" ${common20_4} ${idPrevious} ${nextId}
			fi
			echo ${parc_j} >> ${all}
		done
		if [ "${debug}" -eq "0" ] && ! [ "${nextId}" == "" ]; then
			nextId=${nextId::-1}
			idPrevious=${nextId}
		fi
		constraints=${templates}/OASIS-TRT-20-constraints.txt
		if [ ! -e ${parc} ] ; then
			echo "${sub}_voting"
			execute "python ${code}/votingConstraintsOASIS.py -i ${all} -o ${parc} -gm ${gm_pad} -wm ${wm_pad} -c ${constraints}" ${containers}/python.sif "${sub}_voting" ${common4} ${idPrevious}
		fi
	fi
	
	# ventricles
	filledt1mask=${data}/${sub}/${sub}_t1_mask_filled.nii.gz
	ventricles=${data}/${sub}/${sub}_t1_mask_ventricles.nii.gz
	if [ ! -e ${ventricles} ] ; then
		echo "${sub}_filling"
		execute "${code}/axialFilling.sh ${t1mask} ${filledt1mask} ${code}" ${containers}/python.sif "${sub}_filling" ${common4} ${idPrevious}
		execute "${code}/ventricles.sh ${t1mask} ${filledt1mask} ${code} ${ventricles}" ${containers}/python.sif "${sub}_ventricles" ${common4} ${idPrevious}
	fi
	
done
exec 3<&-



