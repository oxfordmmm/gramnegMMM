#!/usr/bin/env nextflow
/*

========================================================================================
                            kmerresistance Pipeline
========================================================================================
 kmmerresitance nextflow workflow
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
params.template_db = false
params.species_db = false
params.help = false

// print help if required
def helpMessage() {
    log.info"""
    =====================================
     kmerresistance Pipeline v${version}
    =====================================
    Usage:
    The typical command for running the pipeline is as follows:
    nextflow run kmerrestiance.nf --paired_read_dir /path/to/read_dir --pattern_match='*_{1,2}.fastq.gz' --output_dir /path/to/output_dir --template_db /path/to/dir/file_prefix --species_db /path/to/dir/file_prefix
    Mandatory arguments:
      --output_dir                       Path to output dir "must be surrounded by quotes"
      --pattern_match                    The regular expression that will match files e.g '*_{1,2}.fastq.gz'
      --template_db                      Path the template database
      --species_db                       Path to the species database

    Options:
    One of these must be specified
      --paired_read_dir                  Path to directory containing paired fastq files
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

// set up template db
if (params.template_db) {
/*
    Channel
      .fromPath(params.template_db + ".*")
      .ifEmpty { error "Cannot find any files for template db ${params.template_db} " }
      .dump()
      .set { template_db }
*/
    template_db_prefix = file(params.template_db).baseName
    template_db_b = file(params.template_db+".b")
    template_db_comp_b = file(params.template_db+".comp.b")
    template_db_index_b = file(params.template_db+".index.b")
    template_db_length_b = file(params.template_db+".length.b")
    template_db_name = file(params.template_db+".name")
    template_db_seq_b = file(params.template_db+".seq.b")
}

// set up species db
if (params.species_db) {
/*
    Channel
      .fromPath(params.species_db + ".*")
      .ifEmpty { error "Cannot find any files for species db ${params.species_db} " }
      .dump()
      .set { species_db  }
*/
    species_db_prefix = file(params.species_db).baseName
    species_db_b = file(params.species_db+".b")
    species_db_comp_b = file(params.species_db+".comp.b")
    species_db_fsa_b = file(params.species_db+".fsa.b")
    species_db_length_b = file(params.species_db+".length.b")
    species_db_name = file(params.species_db+".name")
}

process kmerresistance_process {
    echo true
    scratch true

    publishDir output_dir, mode: 'copy'

    input:
    set id, file(reads) from read_pairs
    file template_db_b 
    file template_db_comp_b
    file template_db_index_b
    file template_db_length_b
    file template_db_name
    file template_db_seq_b
    file species_db_b
    file species_db_comp_b
    file species_db_fsa_b
    file species_db_length_b
    file species_db_name
       
    output:
    file "${id}.*" into outputs

    script: 
    """
    kmerresistance -i ${reads[0]} ${reads[1]} -o ${id} -t_db $template_db_prefix -s_db $species_db_prefix
    """
}

workflow.onComplete {
	log.info "Nextflow Version:  $workflow.nextflow.version"
  	log.info "Command Line:      $workflow.commandLine"
	log.info "Container:         $workflow.container"
	log.info "Duration:          $workflow.duration"
	log.info "Output Directory:  $params.output_dir"
}

