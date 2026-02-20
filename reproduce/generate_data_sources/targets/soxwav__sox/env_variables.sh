#!/bin/bash

export PROG_BIN="/project/binary"
export PROG_PREFIX="--single-threaded"
export PROG_POSTFIX="-b 16 -t aiff /dev/null channels 1 rate 16k fade 3 norm"

export TARGET=soxwav__sox
