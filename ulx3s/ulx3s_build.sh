#!/bin/bash

make clean

make 2>&1 | tee error.log

grep -i error error.log