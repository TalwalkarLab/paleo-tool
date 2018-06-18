FROM nvidia/cuda:7.5-cudnn4-runtime-ubuntu14.04

WORKDIR /paleo
ADD . /paleo

RUN apt-get update && apt-get install -y \
   vim \
   git \
   python \
   python-pip \
   python-dev

RUN pip install \
   numpy \
   click \
   six

RUN python setup.py install

ENTRYPOINT /bin/bash
