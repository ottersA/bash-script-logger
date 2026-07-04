#!/usr/bin/env bash
set -euo pipefail
rg -n -F -e 'primers.fasta' -e 'Q5' -e 'site-directed' /tmp/testenv -g '!sequences.fasta'
rg -n -e '>.*primer' /tmp/testenv -g '!sequences.fasta'
