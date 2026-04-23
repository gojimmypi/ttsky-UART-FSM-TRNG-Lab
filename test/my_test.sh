#!/bin/bash

rm -f tb tb.vcd

iverilog -o tb tb.v  ../src/*.v

vvp tb

gtkwave tb.fst
