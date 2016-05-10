#!/bin/bash -e

wget --quiet http://icl.cs.utk.edu/projectsfiles/magma/downloads/magma-2.0.2.tar.gz

tar -xf magma-2.0.2.tar.gz
cd magma-2.0.2

echo "
GPU_TARGET = $NV_ARCH

CC        = gcc
NVCC      = /usr/local/cuda/bin/nvcc
FORT      = gfortran

ARCH      = ar
ARCHFLAGS = cr
RANLIB    = ranlib

FPIC      = -fPIC
OPTS      = -fPIC -O3 -DADD_ -Wall -fno-strict-aliasing -fopenmp -DMAGMA_SETAFFINITY
F77OPTS   = -fPIC -O3 -DADD_ -Wall
FOPTS     = -fPIC -O3 -DADD_ -Wall -x f95-cpp-input
NVOPTS    = -O3 -DADD_ -Xcompiler -fno-strict-aliasing,-fPIC
LDOPTS    = -fPIC -fopenmp

# gcc with MKL 10.3, Intel threads
LIB       = -lopenblas -lpthread -lcublas -lcusparse -lcudart -lstdc++ -lm -lgfortran

CUDADIR   = /usr/local/cuda

LIBDIR    = -L/usr/local/lib -L/usr/local/cuda/lib64
INC       = -I/usr/local/cuda/include
" > make.inc

make -j `nproc` shared

cd lib
cp *.so /usr/local/lib
cd ../
cp include/*.h /usr/local/include/

rm -rf /usr/local/magma-2.0.2
rm -f /usr/local/magma-2.0.2.tar.gz
