#!/bin/bash
#PBS -P xf3
#PBS -q express 
#PBS -l walltime=24:00:00,mem=120GB,ncpus=16
#PBS -l jobfs=500GB

set -vx

#define some variables at the start
#give this job a name
name=
###
INPUT=/short/xf3/rn5305/MinION_raw_data/Pst79MinIon_Run1
OUTPUT=/short/xf3/rn5305/MinION_QC_analysis/Pst79MinIon_Run1
ASSEMBLY_BASE_FOLDER=/short/xf3/rn5305/032017_assembly
threads=16
mem_size='120G'

#for basecalling change here 
flowcellID="FLO-MIN107"
kitID="SQK-LSK308"

#make the output folder
mkdir -p ${OUTPUT}

##this is a script to do basecalling and basic QC of your reads

#now move everything to the node so we can get started
cd $PBS_JOBFS
mkdir TAR_FILES
mkdir albacore_output
cp ${INPUT}/*tar.gz TAR_FILES/.

#go ahead with unziping and basecalling
cd TAR_FILES
for x in *.tar.gz
do
tar -xopf ${x}
done

mkdir fast5s
#check if this makes sense
mv */fast5 fast5s/.

#modules to load for basecalling 
module load albacore/1.2.6

# basecall with albacore
full_1dsq_basecaller.py -i fast5s -t $threads -s $PBS_JOBFS/albacore_output -f $flowcellID -k $kitID -r -n 0 -q 99999999999999999 -o fastq,fast5

#now pull out fastq and summary files before zipping up stuff

cd $PBS_JOBFS
mkdir albacore_fastq
cp albacore_output/sequencing_summary.txt albacore_fastq/.
cat albacore_output/workspace/*.fastq > albacore_fastq/${name}.all.fastq


#remove TAR_FILES and zip up stuff
rm -r TAR_FILES
tar -cvzf albacore_output.tar.gz albacore_output
rm -r albacore_output

#now move everything from this step down already
mv albacore_output.tar.gz ${OUTPUT}/.

cp -r albacore_fastq ${OUTPUT}/.

cd ${PBS_JOBFS}
mv * ${OUTPUT}/.


