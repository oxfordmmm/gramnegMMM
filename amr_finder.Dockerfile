FROM continuumio/miniconda

#RUN apt-get update
#RUN apt-get install -y \
#  python python-pip subversion \
#    && apt-get clean && rm -rf /var/lib/apt/lists/* 

RUN conda config --add channels defaults && conda config --add channels bioconda && conda config --add channels conda-forge
RUN conda install -y blast hmmer perl

RUN mkdir amrfinder && cd amrfinder && curl -sL https://github.com/ncbi/amr/releases/download/amrfinder_v1.02/amrfinder_binaries_v1.02.tar.gz | tar xvz \
    && ./amrfinder.pl -U \
    && ./amrfinder.pl -p test_prot.fa

RUN ln -s /amrfinder/amrfinder.pl /usr/local/bin