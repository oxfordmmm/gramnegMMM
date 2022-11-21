#!/usr/bin/env nextflow
/*

========================================================================================
                                  amrfinder Pipeline
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
params.read_dir = false
params.pattern_match = false
params.output_dir = false
params.proteinInput = false
params.nucleotideInput = false
params.gff_dir = false
params.help = false

// print help if required
def helpMessage() {
    log.info"""
    =====================================
     AMRfinder Pipeline v${version}
    =====================================
    Usage:
    The typical command for running the pipeline is as follows:
    nextflow run amr_finder.nf --read_dir /path/to/read_dir --pattern_match='*.fastq.gz' --output_dir /path/to/output_dir
    Mandatory arguments:
      --paired_read_dir                  Path to directory containing paired fastq files
      --output_dir                       Path to output dir "must be surrounded by quotes"
      --pattern_match                    The regular expression that will match files e.g '*.fastq.gz'. 
                                         Note that paired files are handled individually
      
    Options:
    One of these must be specified
      --protein                          Input fastas are protein 
      --nucleotide                       Input fastas are nucleotides
    
    Optional:
    These may be optionally selected
      --gff_dir                          Directory containing gff files for input fastas
      
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

if ( params.read_dir ) {
    fastqs = params.read_dir + '/' + pattern_match
    Channel
      .fromPath( fastqs )
      .ifEmpty { error "Cannot find any fastqs files matching: ${fastqs}" }
      .set {reads}
} else {
    error "Please enter a directory of input fastq files"
    exit 0
}

if ( params.gff_dir ) {
    gff_files = params.gff_dir + '/*.gff'
    Channel
      .fromPath( gff_files )
      .ifEmpty { error "Cannot find any fastqs files matching: ${gff_files}" }
      .set {gffs}
} 

if (params.protein) {
    if (params.gff_dir) {
        process amr_finder_protein {
            label 'amr_finder'

            publishDir output_dir, mode: 'copy'

            input:
            set file(fasta) from reads
            set file(gff) from gffs

            output:
            file "*.tsv"

            script:
            suffix = fasta.baseName
            """
            amrfinder.pl -p ${fasta} -g ${gff} -o ${suffix}.tsv
            """
        }
    } else {
        process amr_finder_protein {
            label 'amr_finder'

            publishDir output_dir, mode: 'copy'

            input:
            set file(fasta) from reads

            output:
            file "*.tsv"

            script:
            suffix = fasta.baseName
            """
            amrfinder.pl -p ${fasta} -o ${suffix}.tsv
            """
        }
    }
} else if (params.nucleotide) {
    if (params.gff_dir) {
        process amr_finder_nucleotide {
            label 'amr_finder'

            publishDir output_dir, mode: 'copy'

            input:
            set file(fasta) from reads

            output:
            file "*.tsv"

            script:
            suffix = fasta.baseName
            """
            amrfinder.pl -n ${fasta} -o ${suffix}.tsv
            """
        }
    } else {
        process amr_finder_nucleotide {
            label 'amr_finder'

            publishDir output_dir, mode: 'copy'

            input:
            set file(fasta) from reads

            output:
            file "*.tsv"
            script:
            suffix = fasta.baseName
            """
            amrfinder.pl -n ${fasta} -o ${suffix}.tsv
            """
        }
    }
} else {
    error "Please enter a suitable fasta type"
    exit 0
}

workflow.onComplete {
	log.info "Nextflow Version:  $workflow.nextflow.version"
  	log.info "Command Line:      $workflow.commandLine"
	log.info "Container:         $workflow.container"
	log.info "Duration:          $workflow.duration"
	log.info "Output Directory:  $params.output_dir"
}

