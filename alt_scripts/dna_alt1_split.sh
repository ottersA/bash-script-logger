#!/usr/bin/env bash
rg -n -F -e 'primers.fasta' -e 'Q5' -e 'site-directed' /tmp/testenv -g '!sequences.fasta'
rg -n -e '>.*primer' /tmp/testenv -g '!sequences.fasta'
