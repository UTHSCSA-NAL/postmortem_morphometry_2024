################################################################################
## FUNCTIONS 
################################################################################

createJob(){
	job=$1
	mem=$2
	sif=$3
	script=$4
	outp=$5
	slots=$6	
	nolog=$7
	echo "#!/bin/bash" > $job
	echo "" >> $job
	echo "#----------------------------------------------------" >> $job
	echo "# Slurm job script for GENIE" >> $job
	echo "#----------------------------------------------------" >> $job
	echo "" >> $job
	echo "#SBATCH -J PMBM                     # Job name" >> $job

	if [ "$nolog" -eq "1" ]; then
		echo "#SBATCH -o /dev/null  # no output" >> $job
		echo "#SBATCH -e /dev/null  # no error" >> $job
	else
		echo "#SBATCH -o ${outp}_%j.out  # output" >> $job
		echo "#SBATCH -e ${outp}_%j.err  # error" >> $job
	fi

	echo "#SBATCH -p compute" >> $job


	echo "#SBATCH -n 1" >> $job
	echo "#SBATCH -N 1" >> $job
	echo "#SBATCH -c ${slots}" >> $job
	echo "#SBATCH --mem=${mem}" >> $job
	
	echo "#SBATCH -w nal-lambda3" >> $job
	
	
	echo "" >> $job
	echo "singularity exec ${sif} ${script}" >> $job	
}

execute(){
	commande=$1
	container=$2
	prefix=$3
	memory=$4
	slots=$5
	jobsFolder=$6
	logsFolder=$7
	nolog=$8
	debug=$9
	idPrevious=${10}

	[ -e ${jobsFolder} ] || mkdir ${jobsFolder}
	[ -e ${logsFolder} ] || mkdir ${logsFolder}

	createJob ${jobsFolder}/${prefix}.job ${memory}G ${container} "${commande}" ${logsFolder}/${prefix} ${slots} $nolog
	if [ "$debug" -eq "0" ]; then
		if [[ "${idPrevious}" != *":"* ]] && [[ "$idPrevious" -eq "-1" ]]; then
			ie=$(sbatch --parsable ${jobsFolder}/${prefix}.job)			
		else
			ie=$(sbatch --parsable --dependency=afterany:${idPrevious} ${jobsFolder}/${prefix}.job)
		fi
		echo "job $ie submitted (${prefix})"
		idPrevious=$ie
	else
		cmd=$(tail -n 1 ${jobsFolder}/${prefix}.job)
               	$cmd
        fi
}

executeInParralel(){
        commande=$1
        container=$2
        prefix=$3
        memory=$4
        slots=$5
        jobsFolder=$6
        logsFolder=$7
        nolog=$8
        debug=$9
        idPrevious=${10}
	nextId=${11}

        [ -e ${jobsFolder} ] || mkdir ${jobsFolder}
        [ -e ${logsFolder} ] || mkdir ${logsFolder}

        createJob ${jobsFolder}/${prefix}.job ${memory}G ${container} "${commande}" ${logsFolder}/${prefix} ${slots} $nolog
        if [ "$debug" -eq "0" ]; then
		re='^[0-9]+$'
                if [[ $idPrevious =~ $re ]] && [[ "$idPrevious" -eq "-1" ]]; then
                        ie=$(sbatch --parsable ${jobsFolder}/${prefix}.job)
                else
                        ie=$(sbatch --parsable --dependency=afterany:${idPrevious} ${jobsFolder}/${prefix}.job)
                fi
                echo "job $ie submitted (${prefix})"
                nextId=${nextId}${ie}:
        else
                cmd=$(tail -n 1 ${jobsFolder}/${prefix}.job)
                $cmd
        fi
}

