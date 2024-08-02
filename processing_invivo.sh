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
common8_4="8 4 ${jobsFolder} ${logsFolder} ${nolog} ${debug}"
common8p8="8 8 ${jobsFolder} ${logsFolder} ${nolog} ${debug}"
common10="10 ${slots} ${jobsFolder} ${logsFolder} ${nolog} ${debug}"
common12="12 ${slots} ${jobsFolder} ${logsFolder} ${nolog} ${debug}"
common16="16 ${slots} ${jobsFolder} ${logsFolder} ${nolog} ${debug}"
common20="20 ${slots} ${jobsFolder} ${logsFolder} ${nolog} ${debug}"
common20p4="20 4 ${jobsFolder} ${logsFolder} ${nolog} ${debug}"
common24="24 ${slots} ${jobsFolder} ${logsFolder} ${nolog} ${debug}"
common24p8="24 8 ${jobsFolder} ${logsFolder} ${nolog} ${debug}"
common26="26 ${slots} ${jobsFolder} ${logsFolder} ${nolog} ${debug}"
common32="32 ${slots} ${jobsFolder} ${logsFolder} ${nolog} ${debug}"
common36="36 ${slots} ${jobsFolder} ${logsFolder} ${nolog} ${debug}"
common40="40 ${slots} ${jobsFolder} ${logsFolder} ${nolog} ${debug}"

  

code=${project}



######################################################################
# PIPELINE
######################################################################

#folderIn=/home/honnorat/postmortem/invivo
#folder=/home/honnorat/postmortem/invivoResults

templates=${project}/atlases

atlasFolder=${templates}/mni_icbm152_nlin_sym_09c
atlasT1=${atlasFolder}/mni_icbm152_t1_tal_nlin_sym_09c.nii
atlasMASK=${atlasFolder}/mni_icbm152_t1_tal_nlin_sym_09c_mask.nii


museTemplates=${templates}/muse


# lists of scans
scans=${folderIn}/all.lst
[ ! -e ${scans} ] || rm ${scans}
ls ${folderIn}/PMBM*.nii.gz > ${scans}

python ${code}/invivoIDs.py -l ${scans}

exec 4< "${scans}"
nc=$(wc -l < "${scans}")
for i in $(seq 1 1 ${nc});do
  read scan <&4
  ls ${folderIn}/PMBM${scan}_* > ${folderIn}/PMBM${scan}.lst
done
exec 4<&-

# test on a single subject
#scans=/home/honnorat/postmortem/tms.lst


# processing
exec 4< "${scans}"
nc=$(wc -l < "${scans}")
for i in $(seq 1 1 ${nc});do
#for i in $(seq 1 1 1);do
  read scan <&4
  
  
  echo ${scan}


  
  # LIST OF SCANS
  lis=${folderIn}/PMBM${scan}.lst

  # RESOLUTION
  #ax=`head -1 ${lis}`
  #res=`python -c "import numpy as np;import nibabel as nb;h=nb.load('${ax}').header;sx=h['pixdim'][1];sy=h['pixdim'][2];sz=h['pixdim'][3];r=np.min([sx,sy,sz]);print(r)"`
  #res=${res}x${res}x${res}
  
 
  idPrevious=-1

  final=${folder}/PMBM${scan}_combined.nii.gz

 
  # RESAMPLING
  cpt=1
  nb=$(wc -l < "${lis}")
  exec 3< "${lis}"
  for i in $(seq 1 1 ${nb});do
    read t1 <&3
    resampled=`echo ${t1} | sed -e 's/invivo/invivoResults/g'`
    resampled=${resampled::-7}_resampled.nii.gz
    if [ ! -e ${resampled} ]; then   
      if [ ! -e ${final} ]; then
        #execute "/ants/ResampleImage 3 ${t1} ${resampled} ${res} windowedSinc" ${containers}/ants.sif "${scan}_resample${cpt}" ${common4} ${idPrevious}
        execute "${code}/mriSynthesize.sh ${t1} ${resampled}" ${containers}/freesurfer.sif "${scan}_synth${cpt}" ${common4} ${idPrevious}
      fi
      cpt=$((${cpt}+1))
    fi
  done
  exec 3<&-




  # REGISTRATIONS
  cpt=1
  base=
  exec 3< "${lis}"
  for i in $(seq 1 1 ${nb});do
    read t1 <&3
    resampled=`echo ${t1} | sed -e 's/invivo/invivoResults/g'`
    resampled=${resampled::-7}_resampled.nii.gz
    registered=`echo ${t1} | sed -e 's/invivo/invivoResults/g'`
    registered=${registered::-7}_registered.nii.gz
    reg=`echo ${t1} | sed -e 's/invivo/invivoResults/g'`
    reg=${reg::-7}_ants
    if [ "${cpt}" -eq "1" ]; then
      base=${resampled}
    else
      if [ ! -e ${registered} ]; then
        if [ ! -e ${final} ]; then
          execute "${code}/invivoRegistration.sh ${base} ${resampled} ${reg} ${registered}" ${containers}/ants.sif "${scan}_registration" ${common8p8} ${idPrevious}
        fi
      fi
    fi
    cpt=$((${cpt}+1))
  done
  exec 3<&-



  # COMBINATION
  lst=
  msk=
  final=${folder}/PMBM${scan}_combined.nii.gz
  if [ ! -e ${final} ]; then
    cpt=1 
    exec 3< "${lis}"
    nb=$(wc -l < "${lis}")
    for i in $(seq 1 1 ${nb});do
      read t1 <&3
      resampled=`echo ${t1} | sed -e 's/invivo/invivoResults/g'`
      resampled=${resampled::-7}_resampled.nii.gz
      registered=`echo ${t1} | sed -e 's/invivo/invivoResults/g'`
      registered=${registered::-7}_registered.nii.gz
      if [ "${cpt}" -eq "1" ]; then
        lst=${resampled}
        msk=${resampled::-7}_mask.nii.gz
      else
        lst=${lst},${registered}
        msk=${msk},${registered::-7}_mask.nii.gz
      fi
      cpt=$((${cpt}+1))
    done
    exec 3<&-
    execute "python ${code}/invivoCombination.py -i ${lst} -m ${msk} -o ${final} -n 2" ${containers}/python.sif "${scan}_combination" ${common8} ${idPrevious}
  fi


#  denoised=${folder}/PMBM${scan}_combined_denoised.nii.gz
#  if [ ! -e ${denoised} ]; then
#    execute "/naonlm3d/naonlm3d -i ${final} -o ${denoised}" ${containers}/naonlm.sif "${scan}_naonlm" ${common6} ${idPrevious}
#  fi

  smooth=${folder}/PMBM${scan}_combined_smooth.nii.gz
  if [ ! -e ${smooth} ]; then
#	execute "/ants/N4BiasFieldCorrection -i ${denoised} -o ${smooth}" ${containers}/ants.sif "${scan}_bias" ${common6} ${idPrevious}
#	execute "/ants/N4BiasFieldCorrection -i ${final} -o ${smooth}" ${containers}/ants.sif "${scan}_bias" ${common6} ${idPrevious}
	execute "cp ${final} ${smooth}" ${containers}/python.sif "${scan}_bias" ${common4} ${idPrevious}
  fi

#  mask=${folder}/PMBM${scan}_combined_smooth_mask.nii.gz
#  brain=${folder}/PMBM${scan}_combined_smooth_brain.nii.gz
#  if [ ! -e ${brain} ]; then
#    execute "${code}/invivoSK.sh ${smooth} ${mask} ${brain} ${atlasT1} ${atlasMASK} ${code}" ${containers}/ants_fsl.sif "${scan}_sk" ${common8_4} ${idPrevious}
#  fi



  mask=${folder}/PMBM${scan}_combined_smooth_mask.nii.gz
  brain=${folder}/PMBM${scan}_combined_smooth_brain.nii.gz
  brain_c3d=${folder}/PMBM${scan}_combined_smooth_brain_c3d.nii.gz
  musedir=${folder}/PMBM${scan}_MUSE
  musedirtmp=${folder}/PMBM${scan}_MUSEtmp
  ntemplates=15
  if [ ! -e ${brain} ] ; then
    execute "${code}/MUSEskullstripping.sh ${smooth} ${mask:: -7}.txt ${museTemplates} ${ntemplates}" ${containers}/cbica_1.0.sif "skull_${scan}_a" ${common40} ${idPrevious}
    execute "${code}/MUSEmask.sh ${mask}" ${containers}/python.sif "skull_${scan}_b" ${common4} ${idPrevious}
    execute "${code}/MUSEmaskCorrection.sh ${mask}" ${containers}/fsl.sif "skull_${scan}_c" ${common4} ${idPrevious}
    execute "python ${code}/masking.py -i ${smooth} -m ${mask} -o ${brain}" ${containers}/python.sif "skull_${scan}_d" ${common4} ${idPrevious}
    execute "rm -r ${musedir} ${musedirtmp}" ${containers}/python.sif "skull_${scan}_e" ${common4} ${idPrevious}
    execute "/c3d/c3d ${brain} -type float -o ${brain_c3d}" ${containers}/c3d.sif "skull_${scan}_f" ${common4} ${idPrevious}
  fi




  brain_n4=${folder}/PMBM${scan}_combined_smooth_brain_n4.nii.gz
  if [ ! -e ${brain_n4} ]; then
	execute "/ants/N4BiasFieldCorrection -i ${brain_c3d} -o ${brain_n4}" ${containers}/ants.sif "${scan}_denoise_a" ${common8} ${idPrevious}
#	execute "/ants/N4BiasFieldCorrection -i ${brain_c3d} -x ${mask} -o ${brain_n4}" ${containers}/ants.sif "${scan}_denoise_a" ${common8} ${idPrevious}
  fi



  gm=${folder}/PMBM${scan}_combined_smooth_gm.nii.gz
  wm=${folder}/PMBM${scan}_combined_smooth_wm.nii.gz
  tissues=${folder}/PMBM${scan}_combined_smooth_tissues.nii.gz
  if [ ! -e ${wm} ] ; then
    execute "${code}/fslFast.sh ${brain_n4} ${gm} ${wm} ${tissues}" ${containers}/fsl.sif "${scan}_tissues" ${common4} ${idPrevious}
  fi


  brain_flip=${folder}/PMBM${scan}_combined_smooth_brain_flip.nii.gz
  gm_flip=${folder}/PMBM${scan}_combined_smooth_gm_flip.nii.gz
  wm_flip=${folder}/PMBM${scan}_combined_smooth_wm_flip.nii.gz
  if [ ! -e ${wm_flip} ] ; then
#    execute "python3 ${code}/flippingDirect.py -i ${brain} -o ${brain_flip} -c ",1,-3,2" -p 15" ${containers}/python.sif "PMBM${scan}_flip1" ${common8} ${idPrevious}
#    execute "python3 ${code}/flippingDirect.py -i ${gm} -o ${gm_flip} -c ",1,-3,2" -p 15" ${containers}/python.sif "PMBM${scan}_flip2" ${common8} ${idPrevious}
#    execute "python3 ${code}/flippingDirect.py -i ${wm} -o ${wm_flip} -c ",1,-3,2" -p 15" ${containers}/python.sif "PMBM${scan}_flip3" ${common8} ${idPrevious}

    execute "python3 ${code}/flippingDirect.py -i ${brain} -o ${brain_flip} -c ",1,2,3" -p 15" ${containers}/python.sif "PMBM${scan}_flip1" ${common8} ${idPrevious}
    execute "python3 ${code}/flippingDirect.py -i ${gm} -o ${gm_flip} -c ",1,2,3" -p 15" ${containers}/python.sif "PMBM${scan}_flip2" ${common8} ${idPrevious}
    execute "python3 ${code}/flippingDirect.py -i ${wm} -o ${wm_flip} -c ",1,2,3" -p 15" ${containers}/python.sif "PMBM${scan}_flip3" ${common8} ${idPrevious}

  fi



  nextId=
  all=${folder}/PMBM${scan}_combined_smooth_allParcellations.lst
  parc=${folder}/PMBM${scan}_combined_smooth_parcellation.nii.gz
  lgm=${templates}/mindboggle_labels_leftGM.txt
  rgm=${templates}/mindboggle_labels_rightGM.txt
  [ ! -e ${all} ] || rm ${all}
  if [ ! -e ${parc} ] ; then
    for j in $(seq 1 1 20); do
    #for j in $(seq 1 1 1); do
      atlas=${templates}/OASIS-TRT-20-${j}/t1weighted.MNI152_leftright.nii.gz
      atlasMask=${templates}/OASIS-TRT-20-${j}/mask.MNI152_leftright_noventricle.nii.gz
      labels=${templates}/OASIS-TRT-20-${j}/labels.DKT31.manual+aseg.MNI152_leftright.nii.gz
      reg_j=${folder}/PMBM${scan}_combined_smooth_ants_${j}
      parc_j=${parc::-7}_${j}.nii.gz
      atlas_in_subject=${folder}/PMBM${scan}_combined_smooth_OASIS-TRT-20-${j}_in_sub_space.nii.gz
      atlas_mask_in_subject=${folder}/PMBM${scan}_combined_smooth_OASIS-TRT-20-${j}_mask_in_sub_space.nii.gz
      landmarks=${templates}/OASIS-TRT-20-${j}/landmarks.nii.gz
      if [ ! -e ${parc_j} ]; then
#        echo "PMBM${scan}_registration_${j}"

#executeInParralel "${code}/dualRegistration_4lr.sh ${atlas} ${atlasMask} ${brain_flip} ${gm_flip} ${wm_flip} ${reg_j} ${labels} ${parc_j} ${atlas_in_subject} ${atlas_mask_in_subject} ${code} ${landmarks} ${lgm} ${rgm}" ${containers}/ants_c3d.sif "PMBM${scan}p${j}" ${common24} ${idPrevious} ${nextId}

execute "${code}/dualRegistration_4lr_noerosion.sh ${atlas} ${atlasMask} ${brain_flip} ${gm_flip} ${wm_flip} ${reg_j} ${labels} ${parc_j} ${atlas_in_subject} ${atlas_mask_in_subject} ${code} ${landmarks} ${lgm} ${rgm}" ${containers}/ants_c3d.sif "PMBM${scan}reg${j}" ${common24p8} ${idPrevious}

      fi
      echo ${parc_j} >> ${all}
    done
    if [ "${debug}" -eq "0" ] && ! [ "${nextId}" == "" ]; then
      nextId=${nextId::-1}
      idPrevious=${nextId}
    fi
    constraints=${templates}/OASIS-TRT-20-constraints_lr.txt
    if [ ! -e ${parc} ] ; then
#      echo "PMBM${scan}_voting"
execute "python ${code}/votingConstraintsOASIS_lr.py -i ${all} -o ${parc} -gm ${gm_flip} -wm ${wm_flip} -c ${constraints}" ${containers}/python.sif "PMBM${scan}_voting" ${common8} ${idPrevious}
execute "rm ${folder}/PMBM${scan}_combined_smooth_OASIS-TRT-20-* ${folder}/PMBM${scan}_combined_smooth_parcellation_* ${folder}/PMBM${scan}_*_resampled.nii.gz " ${containers}/python.sif "PMBM${scan}_cleaning" ${common4} ${idPrevious}
    fi
  fi


done
exec 4<&-




