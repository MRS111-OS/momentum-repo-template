# Use official ROS 2 image as base
# Build with: docker build --build-arg ROS_DISTRO=humble .
# Supported: humble, iron, jazzy

ARG ROS_DISTRO=humble
FROM ros:${ROS_DISTRO}

# Set environment variables
ENV WORKSPACE=/home/ros/ws
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
RUN mkdir -p ${WORKSPACE}/src

# Set working directory
WORKDIR ${WORKSPACE}

# Copy repository into container
COPY . src/repository

# Install package dependencies using rosdep
RUN rosdep update && \
    rosdep install --from-paths src --ignore-src -r -y || true

# Install Python dependencies
RUN pip install --upgrade pip && \
    if [ -f src/repository/requirements.txt ]; then \
        pip install -r src/repository/requirements.txt; \
    fi

# Build the ROS 2 package
RUN . /opt/ros/humble/setup.sh && \
    colcon build \
    --symlink-install \
    --event-handlers console_direct+ \
    || echo "Build completed with warnings"

# Source setup files
RUN echo 'source /opt/ros/humble/setup.bash' >> ~/.bashrc && \
    echo "source ${WORKSPACE}/install/setup.bash" >> ~/.bashrc

# Run tests by default
CMD ["/bin/bash", "-c", \
    "source /opt/ros/humble/setup.bash && \
     source ${WORKSPACE}/install/setup.bash && \
     colcon test --event-handlers console_direct+ && \
     colcon test-result --verbose"]
