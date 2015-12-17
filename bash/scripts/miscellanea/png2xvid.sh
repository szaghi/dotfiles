#!/bin/bash
path_in=$1
fps_in=$2
bitrate_in=$3
file_out=$4
mencoder mf://${path_in}*.png -mf fps=${fps_in} -xvidencopts bitrate=${bitrate_in} -o ${file_out} -ovc xvid
