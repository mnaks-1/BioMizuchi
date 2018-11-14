#!/bin/bash
# Assignment 2 by Mbita Nakazwe 2018-11-13

# Welcome message

echo "
   _   _   _   _   _   _   _   _   _   _  
  / \ / \ / \ / \ / \ / \ / \ / \ / \ / \ 
 ( B | I | O | M | I | Z | U | C | H | I )
  \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ "
echo
echo "~~~~~~~~~ WELCOME TO BIOMIZUCHI v1.0 ~~~~~~~~~"
echo "~~~ Created by Mbita Nakazwe for BINF6410 ~~~"
echo 
echo "Let's get to work! For starters, I'm going to create a results directory for you."
echo
# Create results directory, including folder for log files
mkdir -p results-biomiz/log
cd results-biomiz
################################################################################
echo "STEP 1 - DEMULTIPLEXING WITH SABRE"
echo

# Define variables
echo "Firstly, I'm going to need the location of some files. Where is your fastq file?"
read FASTQ
DATA1=$FASTQ
echo
echo "Thanks, what about the path to Sabre?"
read SABRE
TOOL1=$SABRE
echo
echo "Awesome! And where are the barcodes?"
read BAR
BARCODE=$BAR
echo

# Option for single or paired end reads
echo "Lastly, are you using single or paired end reads today (se or pe)?"
read MODE
SABRE_MODE=$MODE
# If pe selected, ask for File2
if [ "$SABRE_MODE" == "pe" ]
	then
	echo "Please provide the path to the second data file."
	read FASTQ2
	FASTQ2=$DATA2
fi

# Run SABRE
# Options: -f (fasta file1), -r (fasta file2 for pe), -b (barcode file), -u (unknown barcodes1), 
#		   -w (unknown barcodes2)
# Results are .fq files
echo
echo "Running Sabre now..."
if [ "$SABRE_MODE" == "se" ] 
	then 
		$TOOL1 se -f $DATA1 -b $BARCODE -u unknown.fastq > sabre.log
	elif [ "$SABRE_MODE" == "pe" ] 
	then
		$TOOL1 pe -f $DATA1 -r $DATA2 -b $BARCODE -u unknown1.fastq -w unknown2.fastq > log/sabre.log
	else
		if [ $? -ne 0 ]
   		then
        	printf "Oops! There's an error with Sabre."
        	echo
        	exit 1
        fi
fi
echo
echo "Yes! Step 1 complete!"
echo
################################################################################
echo "STEP 2 - CLEANING AND TRIMMING WITH CUTADAPT"
echo
#echo "What is the path to Cutadapt?"
#read CUT
#TOOL2=$CUTAD
echo
# Adapter example
ADAP=AGATCGGAA

# Run CUTADAPT
# Options: 	--debug (print debugging info) -j 0 (auto detect # CPU of cores), -a (adapters),
# 			-m (minimum length filter), -o (output format)
# Results are: fq.fastq files
echo "Running Cutadapt now..."
for i in *.fq;
        do
                cutadapt --debug -j 0 -a $ADAP -m 50 -o $i.fastq $i > log/cutadapt.log
                if [ $? -ne 0 ]
                then
                    printf "Oops! There's an error with Cutadapt."
                    echo
                    exit 1
                fi
        done
echo
echo "Now that wasn't so bad was it? Step 2 complete!"
echo
################################################################################
echo "STEP 3 - MAPPING TO REFERENCE GENOME WITH SAMTOOLS"
echo
echo "What is the path to your reference genome? Ensure you're indicating file."
read REFGEN
REFGEN=$REF
# For parallel processing
echo "How many CPUs would you like to use?"
read CORES
CORES=$CPU
echo "How many threads would you like to use?"
read THREAD
THREAD=$THR

# Run BWA
# Options: -j (# of cores used), -mem (BWA-MEM algorithm), -t (thread #)
# Results in .sam file
echo "Fantastic! Running BWA now..."
parallel -j $CPU bwa mem -t $THR $REF {}.fastq ">" {}.sam ::: $(ls -1 *.fastq | sed 's/.fastq//') > log/bwa.log
                if [ $? -ne 0 ]
                        then
                                printf "Oh no! There's an alignment error."
                                echo
                                exit 1
                fi
echo
echo "Awesome! Step 3 complete!"
echo
################################################################################
echo "STEP 4 - CONVERT SAM TO BAM FORMAT"
echo
echo "Running Samtools now..."
# Run Samtools
# Convert sam files to bam format
# Options: -j (# of cores used), view (format conversion), -b (output BAM file), -S (autodetect input format)
#		-h (include header in SAM output)
echo "...converting files from sam to bam.."
parallel -j $CPU samtools view -b -S -h {}.sam ">" {}.temp.bam ::: $(ls -1 *.sam | sed 's/.sam//') > log/sam.log
                if [ $? -ne 0 ]
                        then
                                printf "Oops! There's a problem with the sam-to-bam step."
                                echo
                                exit 1
                fi
                
# Sort BAM files
# Options: -j (# of cores used), sort (sort alignment file), -o (output format)
# Append samtools log file
echo "...sorting bam files.."
parallel -j $CPU samtools sort {}.temp.bam -o {}.sort.bam ::: $(ls -1 *.temp.bam | sed 's/.temp.bam//') >> log/sam.log
                if [ $? -ne 0 ]
                        then
                                printf "Oops! There's a problem in the samtools-sort step."
                                echo
                                exit 1
                fi

# Index BAM files
# Options: -j (# of cores used), index (index alignment)
# Append samtools log file
echo "...indexing bam files.."
parallel -j $CPU samtools index {} ::: $(ls -1 *.sort.bam) >> log/sam.log
                if [ $? -ne 0 ]
                        then
                                printf "Oops! There's a problem in the samtools-index step."
                                echo
                                exit 1
                fi

# Create a list of BAM files with corresponding paths
echo "...creating bam list.."
for i in $(ls -1 *.sort.bam)
                        do
                                printf "$PWD/${i}\n" >> "bamlist"
                                if [ $? -ne 0 ]
                                        then
                                        printf "Oops! There's a problem making the BAM list."
                                        echo
                                        exit 1
                                fi
                        done
echo
echo "Step 4 is now complete."
echo
################################################################################
echo "STEP 5 - VARIANT CALLING WITH SAMTOOLS"
# Unable to run Platypus on Mac, using samtools
echo
echo "Please provide the path to your bamlist."
read BLIST
BLIST=$LIST
OUT=varianttable

# Create separate directory for vcf results
mkdir results-var
cd results-var

echo "Thank you, a variant results directory has been made."
echo
echo "Running samtools mpileup..."
# Options: mpileup (generate bcf files), -g (), -f (indexed reference file)
samtools mpileup -g -f $REF -b $LIST > variants.bcf
        if [ $? -ne 0 ]
                    then
                    printf "Oh no! There is a problem at the samtools_mpileup step."
                	echo
                	exit 1
		fi

echo "Running bcftools call..."
# Options: call (convert bcf to vcf), -mv (multiallelic caller; variants only)
bcftools call -mv variants.bcf > variants.vcf

        if [ $? -ne 0 ]
                    then
                    printf "Oh no! There is a problem at the bcf to vcf step."
                    echo
                	exit 1
        fi
echo
echo "BioMizuchi analysis complete!! Please find your vcf table in the results folder."
