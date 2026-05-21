# Dockerfile for Mendelian Randomization Analysis
# Using Rocky Linux as the base image from Docker Hub

FROM --platform=linux/amd64 rockylinux/rockylinux:9

# Set metadata
LABEL maintainer="senabouth"
LABEL description="Mendelian Randomization software in a Rocky Linux environment"
LABEL version="2.0"

# Update system, enable CRB, install EPEL, R, and required dependencies in a single layer
RUN dnf -y update && \
    dnf -y install dnf-plugins-core && \
    dnf config-manager --set-enabled crb && \
    dnf -y install epel-release && \
    dnf -y install \
    R \
    python3 \
    python3-pip \
    gcc \
    gcc-c++ \
    gcc-gfortran \
    make \
    patch \
    openssl-devel \
    libcurl-devel \
    libxml2-devel \
    libffi-devel \
    zlib-devel \
    sqlite-devel \
    bzip2-devel \
    xz-devel \
    readline-devel \
    git \
    wget \
    which \
    unzip \
    openblas-devel \
    gmp-devel \
    mpfr-devel \
    && dnf clean all && \
    rm -rf /var/cache/dnf

# Configure R library paths before installing packages
RUN mkdir -p /usr/share/R/library && \
    chmod 755 /usr/share/R/library && \
    R CMD javareconf || true

ENV R_LIBS="/usr/share/R/library"

# Install pyenv and Python 3.11 to global location for Singularity compatibility
RUN git clone https://github.com/pyenv/pyenv.git /opt/pyenv && \
    git clone https://github.com/pyenv/pyenv-virtualenv.git /opt/pyenv/plugins/pyenv-virtualenv && \
    chmod 755 /opt && \
    chmod -R a+rX /opt/pyenv

ENV PYENV_ROOT="/opt/pyenv" \
    PATH="/opt/pyenv/bin:/opt/pyenv/shims:$PATH"

RUN bash -c 'eval "$(pyenv init --path)" && \
    eval "$(pyenv init -)" && \
    pyenv install 3.11.0 && \
    pyenv global 3.11.0 && \
    python -m pip install --upgrade pip'


# Install PLINK 1.9
RUN wget --tries=3 --timeout=30 https://s3.amazonaws.com/plink1-assets/plink_linux_x86_64_20231211.zip && \
    unzip plink_linux_x86_64_20231211.zip -d /usr/local/bin/ && \
    rm plink_linux_x86_64_20231211.zip && \
    chmod +x /usr/local/bin/plink

# Install SMR (Summary-data-based Mendelian Randomization)
RUN wget --tries=3 --timeout=30 https://yanglab.westlake.edu.cn/software/smr/download/smr-1.4.0-linux-x86_64.zip && \
    unzip smr-1.4.0-linux-x86_64.zip && \
    mv smr-1.4.0-linux-x86_64/smr /usr/local/bin/ && \
    chmod +x /usr/local/bin/smr && \
    rm -rf smr-1.4.0-linux-x86_64.zip smr-1.4.0-linux-x86_64

# Install GCTA (Genome-wide Complex Trait Analysis)
RUN wget --tries=3 --timeout=30 https://yanglab.westlake.edu.cn/software/gcta/bin/gcta-1.95.0-linux-kernel-3-x86_64.zip && \
    unzip -q gcta-1.95.0-linux-kernel-3-x86_64.zip && \
    cd gcta-1.95.0-linux-kernel-3-x86_64 && \
    mv gcta64 /usr/local/bin/gcta64 && \
    chmod +x /usr/local/bin/gcta64 && \
    cd / && \
    rm -rf gcta-1.95.0-linux-kernel-3-x86_64.zip gcta-1.95.0-linux-kernel-3-x86_64

# Install common R packages for Mendelian Randomization
RUN R -e "install.packages(c('remotes', 'devtools', 'data.table', 'tidyverse', 'arrow'), repos='https://cran.csiro.au/', lib='/usr/share/R/library', dependencies=TRUE)" && \
    R -e "install.packages(c('TwoSampleMR', 'genetics.binaRies'), repos = c('https://mrcieu.r-universe.dev', 'https://cran.csiro.au/'), lib='/usr/share/R/library', dependencies=TRUE)" && \
    R -e "install.packages('BiocManager', repos='https://cran.csiro.au/', lib='/usr/share/R/library')" && \
    R -e "BiocManager::install(lib='/usr/share/R/library')" && \
    R -e "BiocManager::install(c('GenomicRanges', 'IRanges', 'liftOver', 'S4Vectors', 'qvalue'), lib='/usr/share/R/library')" && \
    R -e "install.packages('MendelianRandomization', repos='https://cran.csiro.au/', lib='/usr/share/R/library', dependencies=TRUE)"

# Create a non-root user for running analysis work
RUN useradd -m -s /bin/bash mruser && \
    mkdir -p /workspace && \
    mkdir -p /data && \
    mkdir -p /genotypes && \
    mkdir -p /code && \
    chown -R mruser:mruser /workspace /data /genotypes /code && \
    chmod 755 /home/mruser

# Install Python packages using pyenv environment
RUN bash -c 'eval "$(pyenv init --path)" && \
    eval "$(pyenv init -)" && \
    pip install numpy scipy pandas bitarray pytest duckdb pyarrow rpy2'

# Install MR-link-2
RUN cd /opt && \
    git clone https://github.com/adriaan-vd-graaf/mrlink2.git

# Set working directory
WORKDIR /workspace

# Switch to non-root user
USER mruser

# Use /workspace as runtime home in Singularity
ENV HOME="/workspace" \
    PATH="/opt/pyenv/bin:/opt/pyenv/shims:/opt/mrlink2:${PATH}"

# Default command
CMD ["/bin/bash"]