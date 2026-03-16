# Extrinsic Calibration: GNSS Antenna to Ouster LiDAR

This document explains exactly how to physically measure and apply the spatial offset (Extrinsic Calibration) between your GNSS antenna and your Ouster LiDAR.

Since both sensors cannot occupy the exact same physical space on your vehicle/tripod, you must tell your software exactly how far apart they are. If you skip this, your LiDAR point clouds will be plotted in the wrong location on the map.

---

## 1. Understanding the Coordinate Frame (Where is X, Y, and Z?)

ROS uses the **Right-Hand Rule** coordinate system. When standing behind your stationary setup (or sitting in the driver's seat of the vehicle) looking forward:

*   **X-Axis (Red):** Points straight **FORWARD** (the direction of travel or the front of the setup).
*   **Y-Axis (Green):** Points straight to the **LEFT**.
*   **Z-Axis (Blue):** Points straight **UP** towards the sky.

### The Origin Point
For this calculation, we treat the **GNSS Antenna as the origin `(0, 0, 0)`**.
You are measuring the position of the **LiDAR** *relative* to the GNSS antenna.

---

## 2. Where to Measure From and To

You need to measure between the true "centers" of both devices using a tape measure. All measurements must be recorded in **Meters**.

**Point A (The Origin): GNSS Antenna Phase Center**
*   This is not the bottom of the antenna or the mounting thread. It is typically the exact geometric center of the dome/disk of the antenna itself.

**Point B (The Target): Ouster OS1 Optical Center**
*   This is the exact center of the cylindrical sensor body (halfway up the cylinder, directly in the middle).

---

## 3. Taking the Measurements

Grab your tape measure and find the distances from **Point A (GNSS)** to **Point B (LiDAR)** along the specific axes:

1.  **Measuring X (Forward/Backward Displacement):**
    *   How far forward or backward is the LiDAR from the GNSS antenna?
    *   *If the LiDAR is mounted **in front of** the GNSS: X is a **Positive** number.*
    *   *If the LiDAR is mounted **behind** the GNSS: X is a **Negative** number.*
    *   *Example: LiDAR is 30 centimeters in front of the antenna. `X = 0.3`.*

2.  **Measuring Y (Left/Right Displacement):**
    *   How far to the left or right is the LiDAR from the GNSS antenna?
    *   *If the LiDAR is mounted to the **left of** the GNSS: Y is a **Positive** number.*
    *   *If the LiDAR is mounted to the **right of** the GNSS: Y is a **Negative** number.*
    *   *Example: LiDAR is mounted perfectly centered horizontally with the antenna. `Y = 0.0`.*

3.  **Measuring Z (Up/Down Displacement):**
    *   How far up or down is the LiDAR from the GNSS antenna?
    *   *If the LiDAR is mounted **above** the GNSS: Z is a **Positive** number.*
    *   *If the LiDAR is mounted **below** the GNSS (very common): Z is a **Negative** number.*
    *   *Example: The GNSS antenna is on a pole 50 centimeters directly above the LiDAR. `Z = -0.5`.*

---

## 4. Applying the Calibration to the Code

Once you have your three numbers in meters (e.g., `X = 0.3`, `Y = 0.0`, `Z = -0.5`), you need to apply them to your ROS system so the data is saved correctly in the rosbag.

### Updating the `docker-compose.yml`

The easiest way to apply this automatically every time you hit record is to add a `tf2_ros` static transform publisher to your Docker compose launch sequence.

1. Open your `docker-compose.yml` file.
2. Under the `services:` section, add a new service block that runs the publisher:
   *(Note the order of the numbers: `X Y Z Yaw Pitch Roll`)*

```yaml
  calibration_publisher:
    image: osrf/ros:humble-desktop
    network_mode: "host"
    command: >
      bash -c "source /opt/ros/humble/setup.bash &&
      ros2 run tf2_ros static_transform_publisher 0.3 0.0 -0.5 0.0 0.0 0.0 gnss_link ouster_sensor"
```
*(Make sure to change `0.3`, `0.0`, and `-0.5` to your actual tape measure readings!)*

### What this command does:
It broadcasts a constant message to the ROS network saying: *"The `ouster_sensor` frame is exactly 0.3m front, 0.0m left, and -0.5m down from the `gnss_link` frame, with zero rotation differences (Yaw, Pitch, Roll = 0)."*

Because you are recording the `/tf_static` topic in your `start_recording.sh` script, this calibration data is permanently embedded into your rosbag, meaning any mapping software reading the bag later knows exactly how to align the data!
