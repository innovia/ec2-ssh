This is a utility for connecting on ec2to autoscale groups and run multiple commands either parallel sequential or in groups

(based on sshkit https://github.com/capistrano/sshkit)

use it where you need to upload / download / capture output/ exec commands

````txt
seperate commands with a semicolon

default region: us-east-1
default user: ec2-user
default connnection :parallel
````

Groups were designed in this case to relieve problems (mass Git checkouts) where you rely on a contested resource that you don't want to DDOS by hitting it too hard.

Sequential runs were intended to be used for rolling restarts, amongst other similar use-cases.


--terminal will open multiple terminals windows of all servers found (currently only supported on OSX iTerm2)

if the instance is on a private subnet (given you have a VPN connection) it will fallback to connecting using the internal IP address

````bash
Usage:
  ec2-ssh connect

Options:
      [--cmd=CMD]                       # commmand to run on remote servers
      [--profile=PROFILE]               # Aws cli profile name as listed in ~/aws/credentials
                                        # Default: default
      [--region=REGION]                 # region
                                        # Default: us-east-1
  u, [--user=USER]                      # run as user
                                        # Default: ec2-user
  p, [--parallel=PARALLEL]              # run in parallel
  s, [--sequence=SEQUENCE]              # run in sequence
  g, [--groups=GROUPS]                  # run in groups
  l, [--groups-limit=N]                 # limit
  w, [--wait=N]                         # wait
      [--as=AS]                         # filter by autoscale groups
      [--tag-key=TAG_KEY]               # tag key to filter instances by
                                        # Default: Name
      [--tag-value=TAG_VALUE]           # tag value to filter instances by
  t, [--terminal=TERMINAL]              # open terminal tabs for all servers
  c, [--capture-output=CAPTURE_OUTPUT]  # capture output
      [--upload=source,destination]     # upload a file - source,destination (make sure seperate these by comma)
      [--download=source,destination]   # download a file - source,destination (make sure seperate these by comma)

Connect to autoscale instance (random instance), Pass --cmd='whatever' to run a cmd on the server (use ; to seperate commands)
````
