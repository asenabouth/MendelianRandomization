# MendelianRandomization
Docker image for MR analysis. Contains the following:

## Software
OS base: Rocky Linux 9
- R

Genomics/MR tools:
- PLINK 1.9
- SMR
- GCTA (gcta64)

## R Packages
CRAN:
- remotes
- devtools
- data.table
- tidyverse
- TwoSampleMR (via mrcieu r-universe)
- BiocManager

Bioconductor:
- MendelianRandomization
- GenomicRanges
- IRanges
- liftOver
- S4Vectors

# Bind paths
- /workspace: Bind path for pipeline outputs
- /data: Bind path for MR resource files
- /genotypes: Bind path for PLINK files
- /code: Bind path for your code
- /eqtl: Bind path for eQTL summary statistics
