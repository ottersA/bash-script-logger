#!/bin/sh
rg -n ">.*primer|primers.fasta|Q5|site-directed" /tmp/testenv -g '!sequences.fasta'
