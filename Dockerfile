# usage: docker build --build-arg ROS2_VERSION=<version> -t mocap_ws .
ARG ROS2_VERSION=jazzy
ARG ROS_DOMAIN_ID=0

# starting image
FROM ros:${ROS2_VERSION}

# need to re-declare ARG for local scope (docker is weird)
ARG ROS2_VERSION

# install required packages
RUN apt-get update && apt-get install -y \
    ros-${ROS2_VERSION}-nav-msgs \
    python3-pip

# let pip break system packages
ENV PIP_BREAK_SYSTEM_PACKAGES=1

# set ros domain id
ARG ROS_DOMAIN_ID
ENV ROS_DOMAIN_ID=${ROS_DOMAIN_ID}

# copy source
WORKDIR /ros2_ws
COPY src /ros2_ws/src

# copy mocap params
COPY mocap_optitrack_driver_params.yaml /ros2_ws/src/mocap4ros2_optitrack/mocap_optitrack_driver/config/mocap_optitrack_driver_params.yaml

# docker image for all packages vs only for robot
ARG ROBOT_BUILD

# rosdeps
RUN . /opt/ros/${ROS2_VERSION}/setup.sh && \
    rosdep update && \
    rosdep install --from-paths src --ignore-src -r -y

# build packages
RUN . /opt/ros/${ROS2_VERSION}/setup.sh && \
    colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release

# disable FAST DDS optimizations that prevent node discovery, may need to also set on host machine if using
ENV FASTDDS_BUILTIN_TRANSPORTS=UDPv4

# entrypoint
COPY entrypoint.sh /ros2_ws/entrypoint.sh
RUN chmod +x /ros2_ws/entrypoint.sh
ENTRYPOINT ["/ros2_ws/entrypoint.sh"]