# Dockerfile for Mendelian Randomization Analysis
# Using Rocky Linux as the base image from Docker Hub

FROM --platform=linux/amd64 rockylinux/rockylinux:9

# Set metadata
LABEL maintainer="MendelianRandomizationImg"
LABEL description="Docker image for Mendelian Randomization analysis based on Rocky Linux"
LABEL version="1.0"

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
    openssl-devel \
    libcurl-devel \
    libxml2-devel \
    git \
    wget \
    which \
    unzip \
    openblas-devel \
    gmp-devel \
    mpfr-devel \
    && dnf clean all && \
    rm -rf /var/cache/dnf


# Install common R packages for Mendelian Randomization
RUN R -e "install.packages(c('remotes', 'devtools', 'data.table', 'tidyverse', 'arrow'), repos='https://cran.csiro.au/', dependencies=TRUE)" && \
    R -e "install.packages(c('TwoSampleMR', 'genetics.binaRies'), repos = c('https://mrcieu.r-universe.dev', 'https://cran.csiro.au/'), dependencies=TRUE)" && \
    R -e "install.packages('BiocManager', repos='https://cran.csiro.au/')" && \
    R -e "BiocManager::install()" && \
    R -e "BiocManager::install(c('GenomicRanges', 'IRanges', 'liftOver', 'S4Vectors', 'qvalue'))" && \
    R -e "install.packages('MendelianRandomization', repos='https://cran.csiro.au/', dependencies=TRUE)"

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

# Install MR-link-2
RUN pip3 install --no-cache-dir git+https://github.com/zhwm/MR_link_2.git

# Create a non-root user for running analysis work
RUN useradd -m -s /bin/bash mruser && \
    mkdir -p /workspace && \
    mkdir -p /data && \
    mkdir -p /genotypes && \
    mkdir -p /code && \
    chown -R mruser:mruser /workspace /data /genotypes /code

# Set working directory
WORKDIR /workspace

# Switch to non-root user
USER mruser

# Default command
CMD ["/bin/bash"]
