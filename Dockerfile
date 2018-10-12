FROM nvidia/cuda:7.5-cudnn4-devel-ubuntu14.04

WORKDIR /paleo
ADD . /paleo

RUN apt-get update && apt-get install -y \
   vim \
   git \
   python \
   python-pip \
   python-dev \
   python-numpy \
   wget \
   unzip \
   swig \
   curl \
   software-properties-common \
   python-software-properties \
   pkg-config \
   zip

RUN pip install \
   click 

RUN python setup.py install

# Setup env for bazel
ENV LD_LIBRARY_PATH="/usr/local/nvidia/lib:/usr/local/nvidia/lib64"
ENV PATH="$PATH:$HOME/bin"
ENV TF_NEED_CUDA=1
ENV TF_CUDA_VERSION=7.5
ENV CUDNN_INSTALL_PATH="/usr/lib/x86_64-linux-gnu"
# Java install
RUN  add-apt-repository ppa:webupd8team/java
RUN  echo oracle-java7-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections \
     && apt-get update \
     && sudo apt-get install -y --force-yes oracle-java8-installer
# Bazel install
RUN apt-get install -y --no-install-recommends \
    bash-completion \
    g++ \
    zlib1g-dev \
    && curl -LO "https://github.com/bazelbuild/bazel/releases/download/0.3.0/bazel_0.3.0-linux-x86_64.deb" \
    && dpkg -i bazel_*.deb
# DL tf
RUN wget https://github.com/tensorflow/tensorflow/archive/v0.9.0.zip
RUN unzip v0.9.0.zip
# Fix DL error
RUN wget http://www.ijg.org/files/jpegsrc.v9a.tar.gz
RUN tar -xf jpegsrc.v9a.tar.gz
#RUN diff -u tensorflow-0.9.0/tensorflow/workspace.bzl tensorflow-0.9.0/tensorflow/workspace.bzl.new > tf-wk.patch
ADD tf-wk.patch .
RUN patch tensorflow-0.9.0/tensorflow/workspace.bzl -i tf-wk.patch -o tensorflow-0.9.0/tensorflow/workspace.bzl.patched
RUN mv tensorflow-0.9.0/tensorflow/workspace.bzl.patched tensorflow-0.9.0/tensorflow/workspace.bzl 
# tensorflow-9.0-gup build and install 
RUN cd tensorflow-0.9.0 \
    && ./configure \
    && bazel build -c opt --config=cuda //tensorflow/tools/pip_package:build_pip_package \
    && bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg \
    && pip install /tmp/tensorflow_pkg/tensorflow-0.9.0-cp27-none-linux_x86_64.whl

# python-six version is too low for tf and prevents pip version being found
# Slightly inelegant workaround but pip install numpy was more problematic
RUN apt-get remove -y python-six
RUN easy_install pip
RUN python -m pip install six


ENTRYPOINT /bin/bash
CMD []
