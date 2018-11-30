FROM ubuntu:16.04

RUN apt-get update
RUN apt-get install -y \
  python python-pip subversion docker \
    && apt-get clean && rm -rf /var/lib/apt/lists/* 

RUN pip install -U wheel setuptools \
    && pip install -U cwltool[deps] PyYAML cwlref-runner

RUN svn co https://github.com/ncbi/pipelines/trunk/amr_finder \
    && ln -s amr_finder/amrfinder /usr/local/bin/
