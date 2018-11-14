# BioMizuchi
Pipeline for NGS variant calling from raw sequencing data

# Background

The advent of next generation sequencing (NGS) has allowed for faster processing times and deeper read coverage. The BioMizuchi tool can be summarized in a few steps below: 
1. Demultiplexing of FASTQ file
2. Cleaning and trimming
3. Alignment to the reference genome
4. Convert sam files to binary format (bam files)
5. Generate variant call formatted (vcf) table

# Installation

Requirements:
- sabre https://github.com/najoshi/sabre
- cutadapt https://cutadapt.readthedocs.io/en/stable/installation.html
- bwa https://github.com/lh3/bwa
- samtools https://github.com/samtools/samtools
- htslib http://www.htslib.org/
- bcftools http://samtools.github.io/bcftools/

chmod +x biomizuchi.sh
cd biomizuchi.sh

For debugging, please run: bash -nv biomizuchi.sh

# License
GNU Affero General Public License v3.0

# Code
Bash

# Version
Version 1.0, created 2018-11-13 as part of an assignment
