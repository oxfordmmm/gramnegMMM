FROM ubuntu:16.04

RUN apt-get update
RUN apt-get install -y --no-install-recommends \
  emboss bioperl ncbi-blast+ gzip unzip \
  libjson-perl libtext-csv-perl libfile-slurp-perl liblwp-protocol-https-perl libwww-perl \
  git \
  liblist-moreutils-perl \
    && apt-get clean && rm -rf /var/lib/apt/lists/* 

ENV PATH="/abricate/bin:${PATH}"
RUN git clone https://github.com/tseemann/abricate.git && abricate --check && abricate --setupdb && abricate ./abricate/test/assembly.fa
