FROM nvidia/cuda:7.5

# Install Python and Jupyter
RUN apt-get update \
 && apt-get install -y python3 python3-setuptools python3-dev
RUN easy_install3 pip \
 && pip install 'notebook>=4.1.0' jupyter

# Install build dependencies
RUN apt-get update \
 && apt-get install -y \
    python curl git libssl-dev libcurl4-openssl-dev wget libzmq3-dev \
    gfortran libreadline-dev

# hwloc
RUN cd /usr/local \
 && wget --quiet http://www.open-mpi.org/software/hwloc/v1.7/downloads/hwloc-1.7.2.tar.gz \
 && tar -xf hwloc-1.7.2.tar.gz \
 && cd hwloc-1.7.2 \
 && ./configure --prefix=/usr/local \
 && make -j `nproc` \
 && make install \
 && cd .. && rm -rf hwloc-1.7.2 && rm hwloc-1.7.2.tar.gz

# OpenBLAS
RUN cd /usr/local \
 && git clone https://github.com/xianyi/OpenBLAS \
 && cd OpenBLAS \
 && git checkout 12ab1804b6ebcd38b26960d65d254314d8bc33d6 \
 && sed -i 's/# NO_AFFINITY = 1/NO_AFFINITY = 1/' Makefile.rule \
 && make -j `nproc` \
 && make PREFIX=/usr/local install \
 && cd .. && rm -rf OpenBLAS

ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib

# PLASMA
RUN cd /usr/local \
 && wget --quiet http://icl.cs.utk.edu/projectsfiles/plasma/pubs/plasma-installer_2.6.0.tar.gz \
 && tar -xf plasma-installer_2.6.0.tar.gz \
 && cd plasma-installer_2.6.0 \
 && export OPENBLAS_NUM_THREADS=1 \
 && ./setup.py --prefix="/usr/local" --blaslib="-L/usr/local/lib -lopenblas" --cflags="-O3 -fPIC" --fflags="-O3 -fPIC" --noopt="-fPIC" --notesting --downlapc \
 && cd /usr/local/lib \
 && gcc -shared -o libplasma.so -Wl,-whole-archive libplasma.a -Wl,-no-whole-archive -L. -lhwloc -llapacke \
 && gcc -shared -o libcoreblas.so -Wl,-whole-archive libcoreblas.a -Wl,-no-whole-archive -L. -llapacke \
 && gcc -shared -o libquark.so -Wl,-whole-archive libquark.a -Wl,-no-whole-archive \
 && gcc -shared -o libcoreblasqw.so -Wl,-whole-archive libcoreblasqw.a -Wl,-no-whole-archive -L. -llapacke \
 && cd /usr/local && rm -rf plasma-installer_2.6.0 && rm plasma-installer_2.6.0.tar.gz

# MAGMA
ARG nv_arch=Maxwell
ENV NV_ARCH=$nv_arch
COPY install-magma.sh /tmp/
RUN /tmp/install-magma.sh

# Install patched version of R
RUN cd /usr/local \
 && wget --quiet http://www.hiplar.org/downloads/R-3.0.2.patched.tar.gz \
 && tar -xf R-3.0.2.patched.tar.gz \
 && cd R-3.0.2 \
 && ./configure --with-x=no --prefix=/usr/local --enable-R-shlib --enable-BLAS-shlib \
 && make -j `nproc` \
 && make install \
 && cp /usr/local/lib/libopenblas.so /usr/local/lib/R/lib/libRblas.so \
 && cp /usr/local/lib/libopenblas.so /usr/local/lib/R/lib/libRlapack.so \
 && cd /usr/local && rm -rf R-3.0.2 && rm -f R-3.0.2.patched.tar.gz

# Install HiPLARb
RUN cd /usr/local \
 && wget --quiet http://www.hiplar.org/downloads/HiPLARb_0.1.4.tar.gz \
 && tar xzf HiPLARb_0.1.4.tar.gz \
 && sed -i '/magma_print_devices/d' HiPLARb/src/magma_wrapper_init.c \
 && tar czvf HiPLARb_0.1.4.tar.gz HiPLARb \
 && rm -rf HiPLARb \
 && export R_PLASMA_NUM_THREADS=`nproc` \
 && R CMD INSTALL --no-test-load --configure-args="--with-lapack='-L/usr/local/lib -lopenblas' --with-plasma-lib=/usr/local --with-cuda-home=/usr/local/cuda --with-magma-lib=/usr/local" HiPLARb_0.1.4.tar.gz \
 && rm -f HiPLARb_0.1.4.tar.gz

# Install R devtools
RUN R -q -e 'install.packages("devtools", repos="http://cran.r-project.org")'

# Install IRPython
COPY install-irkernel.r /tmp/
RUN cd /tmp \
 && git clone https://github.com/rgbkrk/rzmq.git --recursive \
 && cd rzmq/src \
 && echo "CXX_STD = CXX11\nPKG_CPPFLAGS = -std=c++11 -I../inst/cppzmq\nPKG_LIBS = -lzmq" > Makevars \
 && cd /tmp && Rscript install-irkernel.r \
 && rm -rf /tmp/*

# Install rpud
RUN cd /tmp \
 && wget --quiet http://www.r-tutor.com/sites/default/files/rpud/rpux_0.5.2_linux.tar.gz \
 && tar --strip-components=1 -xzf rpux_0.5.2_linux.tar.gz \
 && R -e 'library("devtools")'  -e 'install.packages("rpud_0.5.2.tar.gz", repos=NULL)' \
 && rm -rf /tmp/*

# Set working dir
VOLUME /root/notebook
WORKDIR /root/notebook

# Clean up
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Jupyter config
RUN jupyter notebook --generate-config \
 && echo "\nimport os\nfrom IPython.lib import passwd\npassword = os.environ.get('JUPYTER_PASSWORD')\nif password:\n  c.NotebookApp.password = passwd(password)\n" \
    >> ~/.jupyter/jupyter_notebook_config.py \
 && echo '\nos.environ["R_PLASMA_NUM_THREADS"] = "1"\n' \
    >> ~/.jupyter/jupyter_notebook_config.py
COPY notebook.json /root/.jupyter/nbconfig/

# Expose Jupyter port
EXPOSE 8888

CMD ["jupyter", "notebook", "--no-browser", "--ip=0.0.0.0"]
