#!/usr/bin/env nextflow
/*

========================================================================================
                                Abricate Pipeline
========================================================================================
 Abricate nextflow workflow
 #### Authors
 Jeremy Swann <jeremy.swann@ndm.ox.ac.uk>
----------------------------------------------------------------------------------------
*/

// Pipeline version
version = '0.1'

/***************** Setup inputs and channels ************************/
// Defaults for configurable variables
params.input_dir = false
params.pattern_match = false
params.output_dir = false
params.input_db_dir = false
params.input_db_included = false
params.minid = 75
params.mincov = 0
params.help = false

// print help if required
def helpMessage() {
    log.info"""
    ============================
     Abricate Pipeline v${version}
    ============================
    Usage:
    The typical command for running the pipeline is as follows:
    nextflow run abricate.nf --input_dir /path/to/read_dir --pattern_match='*.fasta' --output_dir /path/to/output_dir
    Mandatory arguments:
      --output_dir                       Path to output dir "must be surrounded by quotes"
      --pattern_match                    The regular expression that will match files e.g '*.fasta'
      --input_dir                        Path to directory containing paired fastq files

    Optional arguments:
      --input_db_dir                     Path to directory containing sequences file for the database
      --input_db_included                Name of included database to use
      --minid                            Minimum DNA %identity (default '75').
      --mincov                           Minimum DNA %coverage (default '0').
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

if (params.input_dir){  
  fastas = params.input_dir + '/' + params.pattern_match

  Channel
    .fromPath( fastas )
    .ifEmpty { error "Cannot find any fasta files matching: ${fastas}" }
    .set {fasta_files}
} else {
    error "Please enter a directory of input fasta files"
    exit 0
}

/*
process abricate_checkIncluded {
    output:
    stdout into includedDBs

    script:
    """
    ls /abricate/db/
    """
}
*/

minid = params.minid
mincov = params.mincov

if (params.input_db_dir) {
    input_db_dir = params.input_db_dir
    input_db_name = file(input_db_dir).baseName

    process abricate_process {
       scratch true
       label 'abricate'
       containerOptions "-B ${input_db_dir}:/abricate/db/${input_db_name}"

       publishDir output_dir, mode: 'copy'

       input:
       set file(assemblies) from fasta_files

       output:
       file "*.tab" into abricate_tabs

       script:
       id = assemblies.baseName
       """
       abricate --setupdb > /dev/null
       abricate --db ${input_db_name} ${assemblies} --minid $minid --mincov $mincov  > ${id}.tab
       """
    }
} else {
    if (params.input_db_included) {
        input_db_included = params.input_db_included
    } else {
        input_db_included = 'resfinder'
    }

    process abricate_process {
       scratch true
       label 'abricate'

       publishDir output_dir, mode: 'copy'

       input:
       set file(assemblies) from fasta_files
       
       output:
       file "*.tab" into abricate_tabs

       script:
       id = assemblies.baseName
       """
       abricate --db ${input_db_included} ${assemblies} --minid $minid --mincov $mincov > ${id}.tab
       """
   }
}

process abricate_summarise {
   scratch true
   label 'abricate'

   publishDir output_dir, mode: 'copy'

   input:
   set summary_out from abricate_tabs.collect()

   output:
   file "summary.tab"

   script:
   """
   abricate --summary ${summary_out} > summary.tab
   """
}

workflow.onComplete {
	log.info "Nextflow Version:  $workflow.nextflow.version"
  	log.info "Command Line:      $workflow.commandLine"
	log.info "Container:         $workflow.container"
	log.info "Duration:          $workflow.duration"
	log.info "Output Directory:  $params.output_dir"
}

