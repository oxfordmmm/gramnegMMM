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

RUN git clone https://github.com/BenLangmead/bowtie2.git && cd bowtie2 && git checkout v2.2.9 &&  make && mv bowtie2* /usr/bin && cd ../ && rm -rf bowtie2

RUN git clone https://github.com/samtools/samtools.git && cd samtools && git checkout 0.1.18 && make && mv samtools /usr/bin && cd ../ && rm -rf samtools

RUN pip install git+https://github.com/katholt/srst2

RUN git clone https://github.com/weizhongli/cdhit.git && cd cdhit && make && make install PREFIX=/usr/bin && cd ../ && rm -rf cdhit

RUN git clone https://bitbucket.org/genomicepidemiology/kma.git && cd kma && gcc -O3 -o kma KMA.c -lm && gcc -O3 -o kma_index KMA_index.c -lm && gcc -O3 -o kma_shm KMA_SHM.c && mv kma /usr/bin && mv kma_index /usr/bin && mv kma_shm /usr/bin && cd .. && rm -rf kma

RUN git clone https://bitbucket.org/genomicepidemiology/kmerresistance.git && cd kmerresistance && gcc -O3 -o kmerresistance KmerResistance.c -lm && mv kmerresistance /usr/bin && cd .. && rm -rf kmerresistance
