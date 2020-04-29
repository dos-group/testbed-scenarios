#!/bin/bash

docker run -ti -v "$PWD:/evaluate" -w /evaluate teambitflow/zerops-analysis -files-robust \
    "{" \
        brain/events-* " -> batch() { sort() } -> tags(tags={zerops=brain}); " \
        experiment-controller/experiment.csv " -> batch() { sort() } -> tags(tags={zerops=controller});" \
    "}" \
    "

    # Allow to input extra Bitflow script here
    $@

    -> split_target_tag() 
    -> map-tag(from = injected, to = group, mapping-file = hosts/mapping-groups.json)
    -> map-tag(from = injected, to = host, mapping-file = hosts/mapping-hosts.json)
    -> map-tag(from = injected, to = layer, mapping-file = hosts/mapping-layers.json)
    -> map-tag(from = anomaly, to = anomaly, mapping-file = hosts/mapping-anomalies.json)

    -> evaluate-zerops-experiment(eval-groups = [ 'all', 'layer-\${layer}', 'anomaly-\${anomaly}', 'host-\${host}', 'group-\${group}', 'layer-\${layer}-anomaly-\${anomaly}' ])

    "

