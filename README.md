# stableConnection

Verifies with kubernetes connection is stable with a job. Uses arping and ping to ensure a connection
is stable for 30 seconds before exiting.

## How to build
``docker build -t <your tag> .``

## How to run
Determine the IP address you want to target to validate reachability. Edit the exgw_basic2_job.yaml
file to include your image tag as well as the target IP as a script argument.

### Create the external gateway namespace
``kubectl create -f gw_namespace2.yaml``

### Create the stable connection job
```kubectl create -f exgw_basic2_job.yaml```

### Verifying success

The script will attempt 3 times to:
 - send arp request/receive response 
 - Complete 30 successful pings over 30
 - If these steps above fail, the script will wait 5 seconds and iterate the next loop

Sample output:

```
--- 9.9.9.9 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.107/0.107/0.107/0.000 ms
connection not yet stable to:  9.9.9.9
connection is stable over 30 seconds, after  2  tries

```

The script works by sending an ARP request first. This allows the br-ext ovn-kube bridge to
forward an ARP request to the external gateway. This ARP trigger makes the external gateway
send back a response which allows br-ext to build a flow to allow traffic from the pod (i.e. the pings).
Once the ARP is complete, pinging over 30 seconds (the maximum flow resync window) verifies the learned
flow is not being removed and that the connection is stable.
