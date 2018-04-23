#!/usr/bin/env nextflow
/*

========================================================================================
                                SRST2 Pipeline
========================================================================================
 SRST2 nextflow workflow
 #### Authors
 Jeremy Swann <jeremy.swann@ndm.ox.ac.uk>
----------------------------------------------------------------------------------------
*/

// Pipeline version
version = '0.1'

/***************** Setup inputs and channels ************************/
// Defaults for configurable variables
params.paired_read_dir = false
params.pattern_match = false
params.output_dir = false
params.db = false
params.report_all_consensus = false
params.help = false

// print help if required
def helpMessage() {
    log.info"""
    ============================
     SRST2 Pipeline v${version}
    ============================
    Usage:
    The typical command for running the pipeline is as follows:
    nextflow run srst2.nf --paired_read_dir /path/to/read_dir --pattern_match='*_{1,2}.fastq.gz' --output_dir /path/to/output_dir --db /path/to/db.fasta
    Mandatory arguments:
      --output_dir                       Path to output dir "must be surrounded by quotes"
      --pattern_match                    The regular expression that will match files e.g '*_{1,2}.fastq.gz'
      --db                               Path to a fasta used as a database
      --paired_read_dir                  Path to directory containing paired fastq files

   Options:
      --report_all_consensus             passes this through to srst2
   """.stripIndent()
}

// Show help message
if (params.help){
    helpMessage()
    exit 0
}

def check_parameter(params, parameter_name){
   if ( !params[parameter_name]){
      error "You must specifiy a " + parameter_name
   } else {
      variable = params[parameter_name]
      return variable
   }

}

// set up output directory
output_dir = file(check_parameter(params, "output_dir"))
// set up pattern_match
pattern_match = check_parameter(params, "pattern_match")
// set up db
db = file(check_parameter(params, "db"))

if ( params.paired_read_dir ) {
    /*
     * Creates the `read_pairs` channel that emits for each read-pair a tuple containing
     * three elements: the pair ID, the first read-pair file and the second read-pair file
     */
    fastqs = params.paired_read_dir + '/' + pattern_match
    Channel
      .fromFilePairs( fastqs )
      .ifEmpty { error "Cannot find any reads matching: ${fastqs}" }
      .set { read_pairs }
} else {
    error "Please enter a directory of paired input fastq files"
    exit 0
}

if (params.report_all_consensus) {
    process srst2_process {
        echo true
        scratch true

        publishDir output_dir, mode: 'copy'

        input:
        set id, file(reads) from read_pairs
        file db
       
        output:
        file "${id}_SRST.out*" into outputs

        script:
        """
        srst2 --input_pe ${reads[0]} ${reads[1]} --output ${id}_SRST.out --log --gene_db $db --report_all_consensus
        """
    }
} else {
    process srst2_process {
        echo true
        scratch true

        publishDir output_dir, mode: 'copy'

        input:
        set id, file(reads) from read_pairs
        file db

        output:
        file "${id}_SRST.out*" into outputs

        script:
        """
        srst2 --input_pe ${reads[0]} ${reads[1]} --output ${id}_SRST.out --log --gene_db $db ${additionalFlags}
        """
    }
}

workflow.onComplete {
    log.info "Nextflow Version:  $workflow.nextflow.version"
    log.info "Command Line:      $workflow.commandLine"
    log.info "Container:         $workflow.container"
    log.info "Duration:          $workflow.duration"
    log.info "Output Directory:  $params.output_dir"
}

