#!/bin/sh
grep -RInF --exclude='sequences.fasta' -e 'primers.fasta' -e 'Q5' -e 'site-directed' /tmp/testenv
grep -RInE --exclude='sequences.fasta' '>.*primer' /tmp/testenv
