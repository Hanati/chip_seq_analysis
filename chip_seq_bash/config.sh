## config file for input and program binary

## in and output folder
PIPE_DIR="/home/hanat/WorkStations/chip_seq_bash"
INPUT_DIR="/home/hanat/ncbi/public/sra"
OUTPUT_DIR="/home/hanat/WorkStations/massimo_chip"
PROJECT="histone_marks"

if [ ! -z $PROJECT ]
then
	if [ ! -d $OUTPUT_DIR/$PROJECT ]
	then
		mkdir $OUTPUT_DIR/$PROJECT
	fi
	OUTPUT_DIR=$OUTPUT_DIR/$PROJECT
fi

## run process
QC=0
MAPPING=0
PEAKCALLING=1

## Tools Sepecification
FASTQC_BIN=/usr/bin/fastqc
QC_ADAPTER=$PIPE_DIR/fastqc_config/adapter_list.txt
QC_CONTAMINATION=$PIPE_DIR/fastqc_config/contaminant_list.txt 
QC_LIMIT=$PIPE_DIR/fastqc_config/limits.txt

SAMTOOLS_BIN=/usr/local/bin/samtools
BWA_BIN=/usr/local/bin/bwa
NUM_OF_PROCESS_BWA=2
REF_GENOME=/home/hanat/WorkStations/hg19/hg19_ercc92.fa
BEDTOOLS_BIN=/usr/local/bin/bedtools
DECOMPRESS=/bin/zcat
MACS2_BIN=/home/hanat/anaconda2/bin/macs2
