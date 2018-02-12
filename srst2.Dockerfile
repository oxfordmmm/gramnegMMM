FROM ubuntu:16.04

RUN apt-get update
RUN apt-get install -y --no-install-recommends \
  build-essential \
  gcc \
  make \
  python-dev \
  python-setuptools \
  python-pip \
  git \
  zlib1g-dev \
  libtbb-dev \
  libncurses5-dev \
  libncursesw5-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/* 

RUN pip install scipy

RUN git clone https://github.com/BenLangmead/bowtie2.git && cd bowtie2 && make && cp bowtie2* /usr/bin

RUN git clone https://github.com/samtools/samtools.git && cd samtools && git checkout 0.1.18 && make && cp samtools /usr/bin

RUN pip install git+https://github.com/katholt/srst2
