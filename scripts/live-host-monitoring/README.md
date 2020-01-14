# Use 
Create configuration file *.lst (see host.lst.template as reference)
For each file a seperate tmux window will be created.
First line is number of tmux splits per target (this amount of splits will be created per each target IP or hostname)
Second line is the command that should be run on each split of each target host (e.g. bmon, htop for monitoring or soething else)
List of target hosts (IP or hostname) --> one IP or hostname per line!
Adjusted the parameters in start_monitoring.sh
Execute start_monitoring.sh
