#!/bin/bash
# apptainer.sh — verify apptainer is installed and functional
# Apptainer is installed via ppa:apptainer/ppa in the conception Ansible role.
# This script runs as a post-install smoke test.
set -euo pipefail

apptainer --version || { echo "ERROR: apptainer not found — check conception Ansible role apptainer PPA task"; exit 1; }
echo "apptainer: OK ($(apptainer --version))"
