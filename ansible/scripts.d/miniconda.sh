#!/bin/bash
# miniconda.sh — install Miniconda3 to /opt/miniconda3
# Architecture-aware: downloads the correct installer for x86_64 or aarch64.
# IMPORTANT: Does NOT add /opt/miniconda3/bin to PATH (would shadow python3 → 3.8
# set by update-alternatives in the python Ansible role).
# Use conda via explicit path: /opt/miniconda3/bin/conda
set -euo pipefail

MINICONDA_DIR="/opt/miniconda3"
ARCH=$(uname -m)   # x86_64 or aarch64

if [ -x "${MINICONDA_DIR}/bin/conda" ]; then
  echo "miniconda.sh: Miniconda3 already installed at ${MINICONDA_DIR}"
  exit 0
fi

INSTALLER="Miniconda3-latest-Linux-${ARCH}.sh"
TMP_DIR=$(mktemp -d)
trap "rm -rf ${TMP_DIR}" EXIT

wget -q -P "${TMP_DIR}" \
  "https://repo.anaconda.com/miniconda/${INSTALLER}"

bash "${TMP_DIR}/${INSTALLER}" -b -p "${MINICONDA_DIR}"

# Make conda accessible system-wide via explicit path (no PATH modification)
# Users invoke conda as: /opt/miniconda3/bin/conda
# Or: source /opt/miniconda3/etc/profile.d/conda.sh (activates conda without shadowing python3)
cat > /etc/profile.d/miniconda.sh << 'EOF'
# Miniconda3 — use explicit path or source conda.sh to activate
# DO NOT add /opt/miniconda3/bin to PATH here — it shadows the system python3
# which is configured as python3.8 via update-alternatives.
# To use conda: /opt/miniconda3/bin/conda
# To use miniconda Python: /opt/miniconda3/bin/python3
export CONDA_ROOT=/opt/miniconda3
EOF

"${MINICONDA_DIR}/bin/pip" install --quiet \
  google-cloud-storage \
  google-cloud-bigquery \
  google-cloud-secret-manager \
  google-cloud-pubsub \
  google-cloud-firestore \
  google-api-python-client \
  keyrings.google-artifactregistry-auth

"${MINICONDA_DIR}/bin/conda" --version
echo "miniconda.sh: Miniconda3 installed at ${MINICONDA_DIR} ($(${MINICONDA_DIR}/bin/conda --version))"
