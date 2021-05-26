# stableConnection

Verifies with kubernetes connection is stable with a job. Uses arping and ping to ensure a connection
is stable for 30 seconds before exiting.

## How to build
``docker build -t <your tag> .``

## How to run
Determine the IP address you want to target to validate reachability. Edit the exgw_basic2_job.yaml
file to include your image tag as well as the target IP as a script argument. Also, specify the mode
to the script of either "ping" or "http" to determine how to test reachability to target.

### Create the external gateway namespace
``kubectl create -f gw_namespace2.yaml``

### Create the stable connection job
```kubectl create -f exgw_basic2_job.yaml```

### Verifying success

#### Ping mode
The script in ping mode will attempt up to 10 times to:
 - send arp request/receive response 
 - Complete 30 successful pings over 30
 - If these steps above fail, the script will wait 15 seconds and iterate the next loop

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

#### HTTP mode
The script in http mode will attempt up to 10 times to:
- send a request to the target every second for 30 seconds consecutively
- If these steps above fail, the script will wait 15 seconds and iterate the next loop

```
successful get, attempt 25
successful get, attempt 26
successful get, attempt 27
successful get, attempt 28
successful get, attempt 29
connection is stable over 30 seconds, after  5  tries

```

The script works by sending HTTP GET requests which will trigger an initial ARP and then attempt to get a
URL for 30 seconds. This allows initial building of the learn flow. If the learn flow is removed over the
30 second period, the script backs off for 15 seconds and tries again for another 30 seconds. This may take
several iterations if the learned flow was removed and is slower than ping mode because the pod will not
force a new ARP using HTTP mode.
