# GNSS + LiDAR Time Synchronization Deployment

This repository contains the deployment scripts and Docker environment necessary to properly time-synchronize a laptop and an Ouster OS1 LiDAR using a GNSS receiver, and record a synchronized ROS 2 bag.

## Overview
Because the moving vehicle and this stationary setup are geographically separated, they cannot share a local PTP/NTP network.
The solution is to sync both systems to **Global GPS Time**:
1. The GNSS receiver reads GPS time from satellites.
2. The laptop (`gpsd` + `chrony`) reads this time over Ethernet to sync its internal system clock.
3. The Ouster OS1 LiDAR syncs its internal clock to the laptop's via a PTP Server (`ptp4l`).
4. The ROS 2 container launches drivers, and the generated `/ouster/points` and `/fix` topics will share the identical global timeframe as the moving vehicle.

## Step 1: Host Time Synchronization
This step configures the laptop to bridge the GPS time to the LiDAR.

1. Navigate to the `deployment` directory.
2. Run the automated configuration script:
   ```bash
   ./setup_sync.sh
   ```
   *(This will install chrony/gpsd, link them to the GNSS at `169.254.56.64:55555`, and restart the services).*
3. Verify `chrony` shows `NMEA` as a time source using `chronyc sources -v`.
4. Start the PTP Grandmaster Server on the Ethernet port connected to the LiDAR (e.g., `eth1`):
   ```bash
   sudo ptp4l -i <LIDAR_INTERFACE> -m -H
   ```
5. Tell the Ouster to listen to the PTP server:
   ```bash
   curl -i -X PUT http://192.168.1.10/api/v1/time/timestamp_mode -d '"TIME_FROM_PTP_1588"'
   ```

## Step 2: ROS 2 Data Recording
Once time is synchronized, launch the containerized ROS environment to begin recording.

1. Ensure the `OUSTER_IP` and `GNSS_IP` inside `start_recording.sh` match your hardware.
2. Build and launch the container:
   ```bash
   docker compose up --build
   ```
3. The container will automatically launch the Ouster and NMEA NavSat drivers, initialize for 5 seconds, and begin recording a rosbag.
4. Press `Ctrl+C` to cleanly stop recording. The synced rosbag will be saved to the `deployment/data/` folder on the host laptop.
