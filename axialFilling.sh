#!/bin/bash

unset PYTHONPATH
unset PYTHONHOME


in=$1
ou=$2
code=$3

cp ${in} ${ou}
for niter in 0 1; do
  for dim in 0 1 2; do
    python ${code}/axialFill.py -i ${ou} -d ${dim}
  done
done

