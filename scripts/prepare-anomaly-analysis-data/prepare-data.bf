
# Example invocation (should be copied into local script and adapted):

# bitflow-pipeline \
#        -files-robust \                                                                                  # Read data from experiments, which is sometimes not cleanly terminated
#        -p go-bitflow-plugins/bitflow-plugin-experiments/bitflow-plugin-experiments \                    # Load the bitflow-plugin-experiments Plugin to get the synchronize_tags() step
#        " { experiment-controller/experiment.csv \                                                       # Read the reference samples from the experiment controller, the "ground truth" about injected anomalies
#                 -> tags(tags={component=controller}) ; \                                                # Give the reference samples a special "component" tag for the synchronize_tags() step below
#          $(find zerops-collector -name '*.bin' -printf '%p ; ') } \                                     # Print all input file names, separated by ";" to read them in parallel
#          $(cat ~/software/testbed-scenarios/scripts/prepare-anomaly-analysis-data/prepare-data.bf) "    # Append this script (prepare-data.bf) to the executed pipeline

# The bitflow-plugin-experiments is in: github.com/antongulenko/go-bitflow-plugins
# Important: the "num" parameter of synchronize_tags() should match the number of input files found by the "find" command above (without the "experiment.csv" reference file).
#            Using a "num" is more than the number of files, but if it is less

-> synchronize_tags(identifier = component, reference = controller, num = 69)
-> split_target_tag()

-> filter(expr = ' has_tag("target") && !has_tag("cls") && tag("component") == tag("injected") && tag("component") != "controller" ')

-> fork_tag(tag = component) {
   * -> rename(metrics = { "libvirt/instance-[^/]*/" = "", "block/io" = "disk-io/all/io" })
}

-> map-tag(from = component, to = group, mapping-file = "mapping-groups.json")
-> map-tag(from = component, to = host, mapping-file = "mapping-hosts.json")

-> fork_tag_template(template = "${anomaly}/${group}") {
   * -> tag-pauses(minPause = 90s, tag = index)
}

-> "files://prepared-data/${anomaly}/${group}/${index}.csv"
