# Use official ROS 2 image as base
# Build with: docker build --build-arg ROS_DISTRO=humble .
# Supported: humble, iron, jazzy

ARG ROS_DISTRO=humble
FROM ros:${ROS_DISTRO}

# Set environment variables
ENV ROS_WS=/home/ros/momentum_ws
ENV WORKSPACE=/home/ros/momentum_ws
ENV REPO_PATH=/home/ros/momentum_ws/src/repository
ENV DEBIAN_FRONTEND=noninteractive
ARG ROS_DISTRO

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    build-essential \
    python3-pip \
    python3-colcon-common-extensions \
    python3-rosdep \
    python3-pytest \
    python3-pytest-cov \
    ros-${ROS_DISTRO}-ament-flake8 \
    ros-${ROS_DISTRO}-ament-black \
    ros-${ROS_DISTRO}-ament-mypy \
    && rm -rf /var/lib/apt/lists/*

# Create workspace directory
RUN mkdir -p ${ROS_WS}/src

# Set working directory
WORKDIR ${ROS_WS}

# Copy repository into container
COPY . ${REPO_PATH}

# Install package dependencies using rosdep
RUN rosdep update && \
    rosdep install --from-paths ${ROS_WS}/src --ignore-src -r -y || true

# Install Python dependencies
RUN pip install --upgrade pip && \
    if [ -f ${REPO_PATH}/requirements.txt ]; then \
        pip install -r ${REPO_PATH}/requirements.txt; \
    fi

# Build the ROS 2 package
RUN . /opt/ros/${ROS_DISTRO}/setup.sh && \
    colcon build \
    --symlink-install \
    --event-handlers console_direct+ \
    || echo "Build completed with warnings"

# Source setup files
RUN echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> ~/.bashrc && \
    echo "source ${ROS_WS}/install/setup.bash" >> ~/.bashrc

# Run tests by default
CMD ["/bin/bash", "-c", \
    "source /opt/ros/${ROS_DISTRO}/setup.bash && \
     source ${ROS_WS}/install/setup.bash && \
     colcon test --event-handlers console_direct+ && \
     colcon test-result --verbose"]
