#!/bin/bash
set -e

echo "=========================================="
echo " GNSS + Ouster LiDAR Time Sync Setup"
echo "=========================================="

echo "1. Installing chrony, ptp4l, and gpsd..."
sudo apt-get update
sudo apt-get install -y chrony linuxptp gpsd gpsd-clients python3-gps

# Connect gpsd to the Swift GNSS dynamically
# Make sure to ping or check if this IP is correct on your friend's laptop
GNSS_IP="169.254.56.64"
GNSS_PORT="55555"

echo "2. Setting up gpsd for GNSS IP: ${GNSS_IP}:${GNSS_PORT}..."
sudo systemctl stop gpsd.socket || true
sudo systemctl stop gpsd.service || true
sudo gpsd -N -n -S 2947 tcp://${GNSS_IP}:${GNSS_PORT} &

echo "3. Configuring chrony..."
if ! grep -q "refclock SHM 0 delay 0.2 refid NMEA" /etc/chrony/chrony.conf; then
    echo "refclock SHM 0 delay 0.2 refid NMEA" | sudo tee -a /etc/chrony/chrony.conf
fi

sudo systemctl restart chrony
sudo systemctl enable chrony
sleep 2

echo "4. Checking chrony sources (you should see NMEA):"
chronyc sources -v

echo ""
echo "=========================================="
echo "Host Setup Complete!"
echo "=========================================="
echo "Next steps to run manually:"
echo ""
echo "1. Find your LiDAR Ethernet interface (e.g. eth0) using 'ip a'"
echo "2. Run the PTP Grandmaster Server on that interface:"
echo "   sudo ptp4l -i <LIDAR_INTERFACE> -m -H"
echo ""
echo "3. Tell the Ouster to listen to PTP (Change IP to match your LiDAR):"
echo "   curl -i -X PUT http://192.168.1.10/api/v1/time/timestamp_mode -d '\"TIME_FROM_PTP_1588\"'"
echo ""
echo "4. Build and start the ROS 2 recording container:"
echo "   docker compose up --build"
echo "=========================================="
