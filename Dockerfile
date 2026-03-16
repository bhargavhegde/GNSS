FROM osrf/ros:humble-desktop

# Install Ouster ROS drivers and NMEA navsat driver
RUN apt-get update && apt-get install -y \
    ros-humble-ouster-ros \
    ros-humble-nmea-navsat-driver \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /root/workspace
COPY start_recording.sh .
RUN chmod +x start_recording.sh

CMD ["./start_recording.sh"]
