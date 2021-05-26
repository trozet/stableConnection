import requests
import subprocess
import socket
import struct
import sys
import time


def get_default_gateway_linux():
    """Read the default gateway directly from /proc."""
    with open("/proc/net/route") as fh:
        for line in fh:
            fields = line.strip().split()
            if fields[1] != '00000000' or not int(fields[3], 16) & 2:
                # If not default route or not RTF_GATEWAY, skip it
                continue

            return socket.inet_ntoa(struct.pack("<L", int(fields[2], 16)))


def check_connection_stable(target_ip):
    # find .3 IP, should be default gw
    gw = get_default_gateway_linux()

    # setup arp request to build learn flow
    ar = subprocess.call(['arping', '-f', '-c', '5', gw])
    if ar == 0:
        for attempt in range(1, 30):
            res = subprocess.call(['ping', '-c', '1', target_ip])
            if res != 0:
                print("connection not yet stable to: ", target_ip)
                return False
            time.sleep(1)
    else:
        print("unable to arp for gateway:", gw)
        return False

    return True


def check_connection_stable_http(target_ip):
    for attempt in range(1, 30):
        try:
            r = requests.get("http://"+target_ip, timeout=1)
            if r.status_code != 200:
                print("connection not yet stable to: ", target_ip)
                return False
        except Exception:
            print("connection not yet stable to: ", target_ip)
            return False

        print("successful get, attempt", attempt)
        time.sleep(1)

    return True


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("script requires two arguments: IP to test connectivity to, and mode (ping, http)")
        exit(1)

    target = sys.argv[1]
    mode = sys.argv[2]
    for connAttempt in range(1, 10):
        if mode == "ping":
            if check_connection_stable(target):
                print("connection is stable over 30 seconds, after ", connAttempt, " tries")
                exit(0)
        elif mode == "http":
            if check_connection_stable_http(target):
                print("connection is stable over 30 seconds, after ", connAttempt, " tries")
                exit(0)
        else:
            print("invalid mode detected", mode, "use either 'ping' or 'http'")
            exit(1)
        print("connection not yet stable, attempt:", connAttempt)
        time.sleep(15)

    exit(1)
