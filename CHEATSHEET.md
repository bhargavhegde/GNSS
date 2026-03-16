# Diagnostics Cheatsheet

If you need to verify that everything is working—or if the GNSS isn't locking or the LiDAR isn't syncing—use these commands to debug the time synchronization bridge.

## 1. Checking the GNSS Data Stream
Use these commands to make sure the GNSS receiver is actually broadcasting data over the network to `gpsd`.

*   **View raw NMEA stream directly from GNSS:**
    ```bash
    nc -zv -w 2 169.254.56.64 55555
    ```
    *(Should say `succeeded!`. If it times out, the GNSS is not connected properly to the Ethernet port).*

*   **View parsed GPS packets from `gpsd`:**
    ```bash
    gpsmon -a -n
    ```
    *(Watch the screen to ensure it is actively receiving coordinates and timestamps. Press `Ctrl+C` to exit).*

## 2. Checking the Laptop's Time Sync (Chrony)
Use these commands to verify that `chrony` has successfully grabbed the time from `gpsd` and forced the laptop's clock to match it.

*   **Check Chrony Sources (Is it reading NMEA?):**
    ```bash
    chronyc sources -v
    ```
    *(Look for the `NMEA` row. The `Reach` column should be greater than `0`. The `State` column should ideally be `*` or `+`, meaning it is actively being used).*

*   **Check Chrony Tracking (Is the laptop synced?):**
    ```bash
    chronyc tracking
    ```
    *(Look at `System time`. This tells you how far off your laptop's clock currently is from true GPS Time. You want this offset to be as small as possible—ideally under 0.005 seconds).*

## 3. Checking the Ouster LiDAR Time Sync
Use these commands to verify that the LiDAR has successfully connected to the laptop's PTP server (`ptp4l`) and matched its clock.

*   *(Assuming Ouster IP is `192.168.1.10`. Make sure `ptp4l` is actively running in another terminal).*

*   **Verify the LiDAR is listening to PTP:**
    ```bash
    curl http://192.168.1.10/api/v1/time/timestamp_mode
    ```
    *(Should return `"TIME_FROM_PTP_1588"`).*

*   **Verify the LiDAR's PTP Lock Status:**
    ```bash
    curl http://192.168.1.10/api/v1/time/ptp/1588/status
    ```
    *(Look for `"master_offset"`. This value is in nanoseconds. Once this number drops and stabilizes, the LiDAR is perfectly synced to the laptop).*

*   **Verify the LiDAR's Sync Status (Overall):**
    ```bash
    curl http://192.168.1.10/api/v1/time/sync/timestamp_status
    ```
    *(Should return `"SYNC"`).*
