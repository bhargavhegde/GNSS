#!/bin/bash
set -e

# NOTE: Update these IP variables to match your actual hardware before running
OUSTER_IP="192.168.1.10"
GNSS_IP="169.254.56.64"

source /opt/ros/humble/setup.bash

echo "Starting Ouster ROS Driver..."
# Ouster ROS 2 driver component
ros2 launch ouster_ros driver.launch.py sensor_hostname:=$OUSTER_IP &

echo "Starting NMEA NavSat Driver for GNSS..."
# Provide the GNSS Fix via NMEA over TCP
ros2 run nmea_navsat_driver nmea_tcp_driver --ros-args -p ip:=$GNSS_IP -p port:=55555 &

echo "Waiting for drivers to initialize..."
sleep 5

# Get the current date and time for the bag folder name
TIMESTAMP=$(date +"%Y_%m_%d_%H_%M_%S")
BAG_NAME="synced_dataset_$TIMESTAMP"

echo "================================="
echo "Starting rosbag record..."
echo "Saving to: /root/workspace/data/$BAG_NAME"
echo "Press Ctrl+C to stop recording."
echo "================================="

cd /root/workspace/data
ros2 bag record -o $BAG_NAME \
    /ouster/points \
    /ouster/imu \
    /fix \
    /vel \
    /time_reference

wait
