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

The script will attempt 3 times to send arp request/receive response, and have 30 successful pings over 30
seconds. The job should complete and you should see some type of logging from the pod indicating the 
connection became stable:

```
--- 9.9.9.9 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.107/0.107/0.107/0.000 ms
connection not yet stable to:  9.9.9.9
connection is stable over 30 seconds, after  2  tries

```
