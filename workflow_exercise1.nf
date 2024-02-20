#!/usr/bin/env nextflow

/* 
Input parameters that uses the launch directory from where the nextflow pipeline was launched to match the files 
that have '_1.fastq.gz' and '_2.fastq.gz'
/*
params.forwardreads = "$launchDir/*_1.fastq.gz"
params.reversereads = "$launchDir/*_2.fastq.gz"

// The out directory will be in the launch directory in a folder called results
params.outdir = "${launchDir}/results" 

/*
Define the process trimmomatic that takes the files from the params.forwardreads and params.reversereads 
and output forward and reverse paired and unpaired files
/*

process trimmomatic {
tag "Running trimmomatic, a fastq read trimmer, to remove adapters and low level reads"

input:
    path (forwardreads) from params.forwardsreads
    path (reversereads) from params.reversereads

output:
    path("r1.paired.fq.gz")
    path("r1.unpaired.fq.gz")
    path("r2.paired.fq.gz")
    path("r2.unpaired.fq.gz")

script:

    """
    trimmomatic \
    PE -phred33 \
    ${forwardreads}\
    ${reversereads} \
    r1.paired.fq.gz \
    r1.unpaired.fq.gz \
    r2.paired.fq.gz \
    r2.unpaired.fq.gz \
    SLIDINGWINDOW:5:30 AVGQUAL:30
    """"""

// Define the process spades that takes the input from trimmomatic process and outputs a contigs.fasta file 
process spades {
input:
    path (r1.paired.fq.gz)
    path (r2.paired.fq.gz)

output:
    path contigs.fasta

script: 

    """
    spades.py -1 r1.paired.fq.gz -2 r2.paired.fq.gz -o ./ --careful --threads 2
    """

// Running the workflow with the defined processes 
workflow {
    trim_ch = trimmomatic({forwardreads}, {reversereads})
    spades_ch = spades(trim_ch)
}
