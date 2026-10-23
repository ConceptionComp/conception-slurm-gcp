#!/bin/bash
# bismark-arm.sh — aarch64 only: Bismark pipeline tools for c4a nodes.
# Installs under $PREFIX (default /opt/conda-envs), not /opt/apps: nodes NFS-mount the
# x86 controller's /opt/apps over it at boot. Versions match the x86 tools used by
# /data/pipelines/bismark/pipeline_scripts/bismark_pipe.sh (bedtools: x86 has 2.27.1,
# no aarch64 build older than 2.31.1).
# Same script builds the shared copy: PREFIX=/data/software_downloads_arm64 (run on a c4a node).
# Self-contained (own micromamba): scripts.d has no run order, so miniconda.sh may not have run.
# Each part is skipped when already installed; rerun to add what is missing.
set -euo pipefail

[ "$(uname -m)" = aarch64 ] || { echo "bismark-arm.sh: skipping on $(uname -m)"; exit 0; }

PREFIX=${PREFIX:-/opt/conda-envs}
SAMTOOLS_VERSION=1.16.1   # no aarch64 build on bioconda; compiled below
SEQTK_VERSION=1.3         # same
export MAMBA_ROOT_PREFIX=${PREFIX}/.mamba
MAMBA=${MAMBA_ROOT_PREFIX}/bin/micromamba
TMP_DIR=$(mktemp -d)
trap "rm -rf ${TMP_DIR}" EXIT

# bismark pulls an unpinned samtools; the compiled one goes first on PATH instead.
# multiqc: the system one (python3.10) picks up x86 numpy from ~/.local over NFS.
# R is for run_bismark.py's rmarkdown QC report (methylation_bismark_initialReport.Rmd).
ENV_SPEC="bismark=0.22.3 bowtie2=2.5.4 trim-galore=0.6.7 fastqc=0.11.9 fastq-screen=0.15.2
  cutadapt=4.9 pandoc=2.19.2 bedtools=2.31.1 multiqc=1.27
  r-base=4.2.3 r-rmarkdown r-knitr r-ggplot2 r-gplots r-stringr r-dplyr r-reshape2 r-kableextra"
# Recreated whenever ENV_SPEC changes
if [ "$(cat "${PREFIX}/bismark/.spec" 2>/dev/null)" != "${ENV_SPEC}" ]; then
  if [ ! -x "${MAMBA}" ]; then
    mkdir -p "${MAMBA_ROOT_PREFIX}/bin"
    curl -Ls https://micro.mamba.pm/api/micromamba/linux-aarch64/latest | tar -xj -C "${MAMBA_ROOT_PREFIX}" bin/micromamba
  fi
  # shellcheck disable=SC2086
  "${MAMBA}" create -y -p "${PREFIX}/bismark" -c conda-forge -c bioconda ${ENV_SPEC}
  "${MAMBA}" clean -a -y
  echo "${ENV_SPEC}" > "${PREFIX}/bismark/.spec"
fi

if [ ! -x "${PREFIX}/samtools-${SAMTOOLS_VERSION}/bin/samtools" ]; then
  curl -Ls "https://github.com/samtools/samtools/releases/download/${SAMTOOLS_VERSION}/samtools-${SAMTOOLS_VERSION}.tar.bz2" \
    | tar -xj -C "${TMP_DIR}"
  (cd "${TMP_DIR}/samtools-${SAMTOOLS_VERSION}" \
    && ./configure --prefix="${PREFIX}/samtools-${SAMTOOLS_VERSION}" \
    && make -j"$(nproc)" && make install)
fi

if [ ! -x "${PREFIX}/seqtk-${SEQTK_VERSION}/seqtk" ]; then
  curl -Ls "https://github.com/lh3/seqtk/archive/refs/tags/v${SEQTK_VERSION}.tar.gz" | tar -xz -C "${TMP_DIR}"
  make -C "${TMP_DIR}/seqtk-${SEQTK_VERSION}"
  install -D "${TMP_DIR}/seqtk-${SEQTK_VERSION}/seqtk" "${PREFIX}/seqtk-${SEQTK_VERSION}/seqtk"
fi

# Curated PATH dir: pipeline tools only. The env's bin also has python3/pip/curl,
# which would shadow the system ones the pipeline's python3 steps rely on.
mkdir -p "${PREFIX}/bin"
ln -sf "${PREFIX}/samtools-${SAMTOOLS_VERSION}/bin/samtools" "${PREFIX}/seqtk-${SEQTK_VERSION}/seqtk" "${PREFIX}/bin/"
for t in "${PREFIX}"/bismark/bin/{bismark*,coverage2cytosine,deduplicate_bismark,filter_non_conversion,NOMe_filtering,bam2nuc,bowtie2*,bowtie,bowtie-*,hisat2*,trim_galore,cutadapt,fastqc,fastq_screen,multiqc,pandoc,perl,java,bedtools,R,Rscript}; do
  if [ -e "$t" ]; then ln -sf "$t" "${PREFIX}/bin/"; fi
done

echo "bismark-arm.sh: ${PREFIX}: bismark $(${PREFIX}/bin/bismark --version | grep -o 'v[0-9.]*' | head -1)," \
  "$(${PREFIX}/bin/samtools --version | head -1), $(${PREFIX}/bin/bedtools --version)," \
  "$(${PREFIX}/bin/R --version | head -1), seqtk $(${PREFIX}/bin/seqtk 2>&1 | grep -o 'Version: [^ ]*')"
