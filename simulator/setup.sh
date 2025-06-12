#!/bin/bash

# X Server : simulate graphic card in memory for the browser.
# The html pages are unpredictable in headless mode
echo "Starting Xvfb server."
mkdir -p /tmp/logs/
touch /tmp/logs/xfvfb.log
Xvfb :0 -screen 0 1296x736x16 -ac > /tmp/logs/xfvfb.log 2>&1 &

# VNC server : Connects to the X server and send the GUI on port 5900.
if [[ " $@ " =~ "--send-gui-to-vnc" ]] then
    echo "Starting x11vnc with GUI access. Connect with a VNC client to localhost:5900"
    # Start x11vnc with GUI access
    mkdir -p /tmp/logs/
    touch /tmp/logs/x11vnc.log
    x11vnc -forever -create -display :0 -rfbport 5900 -nopw > /tmp/logs/x11vnc.log 2>&1 &
fi

# Add my_solution (i.e. the docker-gateway, so that we can reach 
# the host (which has exposed ports to my_solution own docker network))
# entry to /etc/hosts

# Extract the hexadecimal gateway for the default route (Destination == 00000000)
GATEWAY_HEX=$(awk '$2 == "00000000" { print $3 }' /proc/net/route)

# Convert the reversed hexadecimal gateway to a human-readable IP address
GATEWAY_IP=$(printf "%d.%d.%d.%d\n" \
    $((0x${GATEWAY_HEX:6:2})) \
    $((0x${GATEWAY_HEX:4:2})) \
    $((0x${GATEWAY_HEX:2:2})) \
    $((0x${GATEWAY_HEX:0:2})))

# Append the gateway IP to /etc/hosts with our custom domain
echo "Adding my-solution.com to /etc/hosts with IP $GATEWAY_IP"
echo "$GATEWAY_IP my-solution.com" >> /etc/hosts

# Check if the script received the --use-host-as-dns option
if [[ " $@ " =~ " --use-host-as-dns " ]]; then
    # Set host as DNS so that we can run the network adblocker (PiHole) on the host.
    echo "Using host as DNS server. Setting nameserver to $GATEWAY_IP"
    echo "nameserver $GATEWAY_IP" > /etc/resolv.conf
fi