#!/bin/bash

home=`dirname $(readlink -e $0)`

if [ -z "$1" ]; then
    echo "Data source as only parameter required."
fi

RESULT_PLOT_DIR="$home/results/plots"


bitflow-pipeline "$1 -> remap(header = [ 'cpu', 'mem/percent', 'net-io/tx_bytes', 'net-io/rx_bytes', 'disk-io/all/writeBytes', 'disk-io/all/readBytes' ])
    -> batch(flush-time-diff = 60s) {
        aggregate(type='avg')
    }
    -> multiplex() {
        0 -> remap(header = [ 'cpu' ]) -> plot(file=$RESULT_PLOT_DIR/cpu.png, plot_type='linepoint', force_time='true');
        1 -> remap(header = [ 'mem/percent' ]) -> plot(file=$RESULT_PLOT_DIR/mem.png, plot_type='linepoint', force_time='true');
        2 -> remap(header = [ 'net-io/tx_bytes', 'net-io/rx_bytes' ]) -> plot(file=$RESULT_PLOT_DIR/net.png, plot_type='linepoint', force_time='true');
        3 -> remap(header = [ 'disk-io/all/writeBytes', 'disk-io/all/readBytes' ]) -> plot(file=$RESULT_PLOT_DIR/disk.png, plot_type='linepoint', force_time='true');
    }"
