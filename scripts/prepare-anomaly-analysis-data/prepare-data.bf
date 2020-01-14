
# Example invocation (should be copied into local script and adapted):

# The bitflow-plugin-experiments is in: github.com/antongulenko/go-bitflow-plugins
# Important: the "num" parameter of synchronize_tags() should match the number of input files found by the "find" command above (without the "experiment.csv" reference file).

-> synchronize_tags(identifier = component, reference = controller, num = NUMBER_OF_COMPONENTS)
-> split_target_tag()

# Not required anymore after synchronize_tags
-> filter(expr='tag("component") != "controller"')

-> fork_tag(tag=cls, regex=true) {
    # Anomaly samples: do some sanity-check filtering
    "^$" -> filter(expr = ' has_tag("target") && tag("component") == tag("injected") ');
    
    # Give normal data a special "anomaly" tag to put them in the same directory structure
    ".+" -> tags(tags={anomaly=normal})
}

-> fork_tag(tag = component) {
   * -> rename(metrics = { "libvirt/instance-[^/]*/" = "", "block/io" = "disk-io/all/io" })
}

-> map-tag(from = component, to = group, mapping-file = "hosts/mapping-groups.json")
-> map-tag(from = component, to = host, mapping-file = "hosts/mapping-hosts.json")
-> map-tag(from = anomaly, to = anomaly, mapping-file = "hosts/mapping-anomalies.json")

-> fork_tag_template(template = "${anomaly}/${host}") {
   * -> tag-pauses(minPause = 90s, tag = index)
}

-> fork_tag(tag="cls", regex=true) {
    "^$" -> "files://prepared-data/${anomaly}/${group}/${index}.csv" ;
    ".+" -> "files://prepared-data/${anomaly}/${host}/${index}.csv"
}

