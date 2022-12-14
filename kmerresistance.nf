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
params.single_read_dir = false
params.pattern_match = false
params.output_dir = false
params.template_db = false
params.species_db = false
params.idthres = 70
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
      --single_read_dir                  Path to directory containing non-paired fastq files
      --idthres                               ID threshhold (default 70)
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
     * three elements: the pair name, the first read-pair file and the second read-pair file
     */
    fastqs = params.paired_read_dir + '/' + pattern_match
    Channel
      .fromFilePairs( fastqs )
      .ifEmpty { error "Cannot find any reads matching: ${fastqs}" }
      .set { read_pairs }
} else if ( params.single_read_dir ) {
    fastqs = params.single_read_dir + '/' + pattern_match
    Channel
      .fromPath( fastqs )
      .ifEmpty { error "Cannot find any bam files matching: ${fastqs}" }
      .set {reads}
} else {
    error "Please enter a directory of paired input fastq files"
    exit 0
}

// set up template db
if (params.template_db) {
    template_db_prefix = file(params.template_db).baseName
    template_db_b = file(params.template_db+".b")
    template_db_comp_b = file(params.template_db+".comp.b")
    template_db_index_b = file(params.template_db+".index.b")
    template_db_length_b = file(params.template_db+".length.b")
    template_db_name = file(params.template_db+".name")
    template_db_seq_b = file(params.template_db+".seq.b")
} else {
    error "Please enter a path for the template database"
    exit 0
}

// set up species db
if (params.species_db) {
    species_db_prefix = file(params.species_db).baseName
    species_db_b = file(params.species_db+".b")
    species_db_comp_b = file(params.species_db+".comp.b")
    species_db_fsa_b = file(params.species_db+".fsa.b")
    species_db_length_b = file(params.species_db+".length.b")
    species_db_name = file(params.species_db+".name")
} else {
    error "Please enter a path for the species database"
    exit 0
}

idthres = params.idthres

if (params.paired_read_dir) {
    process kmerresistance_process {
        scratch true

        publishDir output_dir, mode: 'copy'

        input:
        set name, file(reads) from read_pairs
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
        file "${name}.*" into outputs

        script:
        """
        kmerresistance -i ${reads[0]} ${reads[1]} -o ${name} -t_db $template_db_prefix -s_db $species_db_prefix -id $idthres
        """
    }
} else {
    process kmerresistance_process {
        scratch true

        publishDir output_dir, mode: 'copy'

        input:
        file(read) from reads
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
        file "${suffix}.*" into outputs

        script: 
        suffix = read.baseName
        """
        kmerresistance -i ${read} -o ${suffix} -t_db $template_db_prefix -s_db $species_db_prefix -id $idthres
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

