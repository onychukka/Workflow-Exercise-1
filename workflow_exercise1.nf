#!/usr/bin/env nextflow

/* 
Input parameters that uses the launch directory from where the nextflow pipeline was launched to match the files 
that have '_1.fastq.gz' and '_2.fastq.gz'
*/
params.forwardreads = "${launchDir}/*_1.fastq.gz"
params.reversereads = "${launchDir}/*_2.fastq.gz"

// The out directory will be in the launch directory in a folder called results
params.outdir = "${launchDir}/results" 

/*
Define the process trimmomatic that takes the files from the params.forwardreads and params.reversereads 
and output forward and reverse paired and unpaired files
*/

process trimmomatic {
tag "Running trimmomatic, a fastq read trimmer, to remove adapters and low level reads"

input:
    path forwardreads
    path reversereads

output:
    tuple path("r1.paired.fq.gz"),
          path("r2.paired.fq.gz")

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
    """
}

// Define the process spades that takes the input from trimmomatic process and outputs a contigs.fasta file 
process spades {
input:
    tuple path (r1),
          path (r2)

output:
    path ("contigs.fasta")

script: 

    """
    spades.py -1 ${r1} -2 ${r2} -o ./ --careful --threads 2
    """
}

// Running the workflow with the defined processes 
workflow {
    Channel
        .fromPath(params.forwardreads, checkIfExists: true)
        .set { forward_ch }
    Channel
        .fromPath(params.reversereads, checkIfExists: true)
        .set { reverse_ch }

    trim_ch = trimmomatic(forward_ch, reverse_ch)
    spades(trim_ch)
}
