#
set -e
set -x

fastq_qc_check(){
	local fastq_in=$1
	header=`echo $fastq_in | cut -d'.' -f1`
	if [ ! -d $OUTPUT_DIR/QC ]
	then
		mkdir $OUTPUT_DIR/QC
	fi
	$FASTQC_BIN -o $OUTPUT_DIR/QC -c $QC_CONTAMINATION -a $QC_ADAPTER -l $QC_LIMIT $INPUT_DIR/$fastq_in
}
bwa_mem_map(){
	local fastq_in=$1
	header=`echo $fastq_in | cut -d'.' -f1`
	## set up directorys
	if [ ! -d $OUTPUT_DIR/tmps ]
	then
		mkdir $OUTPUT_DIR/tmps
	fi
	
	if [ ! -d $OUTPUT_DIR/alignment ]
	then
		mkdir $OUTPUT_DIR/alignment
	fi

	## create fifo file
	fifo_file=$OUTPUT_DIR/tmps/${header}.fifo
	if [ -p $fifo_file ]
	then
		rm $fifo_file
	fi
	mkfifo $fifo_file

	$DECOMPRESS -c $INPUT_DIR/$fastq_in >$fifo_file & pid1=$!
	$BWA_BIN mem -t $NUM_OF_PROCESS_BWA -T 0 -L 0 $REF_GENOME $fifo_file | $SAMTOOLS_BIN view -Shu - | $SAMTOOLS_BIN sort -T $OUTPUT_DIR/tmps/${header} -o - - | $SAMTOOLS_BIN rmdup -s - - >$OUTPUT_DIR/alignment/${header}.bam

	wait $pid1;
	rm $fifo_file
}

run_macs2(){
	local treat=$1
	local control=$2
	local experiment=$3
	
	if [ ! -d $OUTPUT_DIR/macs2 ]
	then
		mkdir $OUTPUT_DIR/macs2
	fi

	if [ $control == "NA" ]
	then
		$MACS2_BIN callpeak -t $OUTPUT_DIR/alignment/${treat}.bam -n $experiment -q 0.1 -g hs --outdir $OUTPUT_DIR/macs2
	else
		$MACS2_BIN callpeak -t $OUTPUT_DIR/alignment/${treat}.bam -c $OUTPUT_DIR/alignment/${control}.bam -n $experiment -q 0.1 -g hs --outdir $OUTPUT_DIR/macs2
	fi
}

run_main() {
	if [ $# -ne 2 ]
	then
		echo " needs two arguments, config_file and input_list"
		exit 1;
	fi
	local config_file=$1
	local input_list_fq=$2

	if [ ! -f $config_file ] || [ ! -s $config_file ]
	then
		echo ${config_file}" not found or empty!" 
		exit 1;
	fi

	if [ ! -f $input_list_fq ]  || [ ! -s $input_list_fq ]
	then
		echo ${input_list_fq}" not found or empty!"
		exit 1;
	fi

	source $config_file
	## QC and Mapping
	for fq in `cat $input_list_fq | cut -f1`
	do
		if [ $QC -eq 1 ]
		then
			echo "running QC "$fq
			fastq_qc_check $fq
		fi
		
		if [ $MAPPING -eq 1 ]
		then
			echo "running mapping "$fq
			bwa_mem_map $fq
		fi
		
	done


	if [ $PEAKCALLING -eq 1 ]
	then
		for e_name in `cat $input_list_fq | cut -f3`
		do
			count_e=`cat $input_list_fq | grep $e_name | wc -l`
			if [ $count_e -eq 2 ]
			then
			## experiment contains treat and input
				treat=`cat $input_list_fq | grep $e_name | awk '$2=="T"' | cut -f1 | cut -d'.' -f1`
				control=`cat $input_list_fq | grep $e_name | awk '$2=="C"' | cut -f1  | cut -d'.' -f1`
				if [ ! -z $treat ] && [ ! -z $control ]
				then
					run_macs2 $treat $control $e_name
				fi
			else
			## experiment contain treat
				treat=`cat $input_list_fq | grep $e_name | awk '$2=="T"' | cut -f1 | cut -d'.' -f1`
				if [ ! -z $treat ]
				then
					run_macs2 $treat "NA" $e_name
				fi
			fi
		done
	fi
}

run_main $1 $2
