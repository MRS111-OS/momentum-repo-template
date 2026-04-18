# Docker Guide for ROS Humble Development

## Overview

Use Docker to create a consistent ROS Humble development environment:
- ✅ Same environment locally and in CI
- ✅ No "works on my machine" problems
- ✅ Easy team onboarding
- ✅ Isolated from your system

---

## Prerequisites

- Docker installed: `docker --version`
- Docker Compose installed: `docker-compose --version`

**Install Docker:**
```bash
# Ubuntu/Debian
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group (no sudo needed)
sudo usermod -aG docker $USER
```

---

## Quick Start: Development

### 1. **Build the Docker Image**

```bash
cd /path/to/momentum-repo
docker-compose build
```

This runs the `Dockerfile` which:
- Starts with `ros:humble` base image
- Installs ROS 2 dependencies
- Copies your repository inside
- Creates a workspace
- Builds your ROS packages

### 2. **Run the Development Container**

```bash
docker-compose up -d
```

Or with interactive shell:
```bash
docker-compose run --rm ros-humble-dev
```

### 3. **Enter the Container**

```bash
docker exec -it momentum-ros-humble bash
```

Now inside the container:
```bash
# Source ROS setup
source /opt/ros/humble/setup.bash
source /home/ros/ws/install/setup.bash

# Build packages
colcon build

# Run tests
colcon test

# Run specific test
colcon test --packages-select my_package

# Launch node
ros2 run my_package my_node
```

### 4. **Stop Container**

```bash
docker-compose down
```

---

## Full Testing Workflow: CI/CD

### 1. **Build Testing Image**

```bash
docker build -f Dockerfile.testing -t momentum-test:latest .
```

### 2. **Run All Tests with Reports**

```bash
docker run --rm \
  -v $(pwd)/test-results:/test-results \
  momentum-test:latest
```

This automatically:
- ✅ Builds packages with `colcon build`
- ✅ Runs ROS tests with `colcon test`
- ✅ Runs Python unit tests with `pytest`
- ✅ Generates coverage reports
- ✅ Runs code quality checks
- ✅ Generates all reports in `test-results/`

### 3. **View Test Reports**

```bash
# Check what was generated
ls -la test-results/

# View test summary
cat test-results/test-results.txt

# View Python test output
cat test-results/pytest.log

# View coverage report
cat test-results/coverage.xml
```

---

## File Structure

```
momentum-repo/
├── Dockerfile               # Development environment
├── Dockerfile.testing       # Testing-only environment
├── docker-compose.yml       # Local development setup
├── src/
│   ├── package_1/
│   └── package_2/
├── tests/
│   ├── test_unit.py
│   └── test_integration.py
└── requirements.txt
```

---

## Docker Build Process Explained

### Dockerfile (Development)

```dockerfile
FROM ros:humble
```
→ Start with official ROS Humble image (Ubuntu 22.04 + ROS2 pre-installed)

```dockerfile
RUN apt-get update && apt-get install -y \
    python3-colcon-common-extensions \
    python3-pytest \
    ...
```
→ Install ROS build tools and testing libraries

```dockerfile
COPY . src/repository
```
→ Copy your entire repo into the container

```dockerfile
RUN colcon build
```
→ Build your ROS packages using colcon

```dockerfile
CMD ["colcon", "test", "..."]
```
→ When container starts, automatically run tests

### Dockerfile.testing (CI)

Same as above, but:
- Uses more aggressive parallel building
- Captures test output to files
- Generates XML coverage reports
- Runs multiple test tools (`pytest`, `ament_flake8`)
- Exits with proper error codes for CI/CD

---

## Common Commands

### Development (Iterative)

```bash
# Start container
docker-compose up -d

# Enter container
docker exec -it momentum-ros-humble bash

# Build packages
colcon build

# Run tests
colcon test

# Edit files on host, changes appear in container
# (because of volume mounts)
```

### Testing (One-off)

```bash
# Run full test suite
docker run --rm -v $(pwd)/test-results:/test-results momentum-test:latest

# Run specific package test
docker run --rm \
  -e PACKAGE=my_package \
  momentum-test:latest

# Keep container for debugging
docker run -it -v $(pwd)/test-results:/test-results momentum-test:latest /bin/bash
```

### Debugging

```bash
# See container logs
docker logs momentum-ros-humble

# Check image size
docker images | grep momentum

# Inspect what's inside
docker run -it momentum-test:latest bash

# See what files got built
docker run --rm momentum-test:latest ls -la /home/ros/ws/install/
```

---

## Architecture Diagram

```
Host Machine                    Docker Container
─────────────────────────────────────────────────
Your Source Code       ←→  /home/ros/ws/src/repository
                            (volume mount)
                       
pytest.ini             ─→   Mounted for testing
requirements.txt       ─→   Mounted + pip install
                       
                            ROS 2 Humble
                            Colcon build tool
                            Your ROS packages
                            Test runner
                            
                            /test-results/
                            ├── pytest.log
                            ├── coverage.xml
                            ├── colcon-test.log
                            └── test-results.txt
                       ←─   Volume mount back to host
```

---

## Integration with GitHub Actions (CI)

In `.github/workflows/ci.yml`:

```yaml
- name: Run Docker Tests
  run: |
    docker build -f Dockerfile.testing -t momentum-test .
    docker run --rm \
      -v $(pwd)/test-results:/test-results \
      momentum-test

- name: Upload Test Results
  uses: actions/upload-artifact@v3
  with:
    name: test-results
    path: test-results/
```

---

## Troubleshooting

### Issue: "docker: command not found"
```bash
sudo apt-get install docker.io docker-compose
sudo usermod -aG docker $USER
# Log out and log back in
```

### Issue: "Permission denied"
```bash
# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker  # Apply immediately
```

### Issue: "Cannot find package"
```bash
# Update rosdep database
docker run --rm momentum-test rosdep update

# Check package.xml dependencies
cat src/my_package/package.xml
```

### Issue: "Build takes too long"
```bash
# Use parallel workers
colcon build --parallel-workers 8

# Or in Dockerfile:
RUN colcon build --parallel-workers 4
```

### Issue: "Tests pass locally but fail in Docker"
Common causes:
- Different Ubuntu version (use `ros:humble` to match)
- Missing system dependencies (add to `apt-get install` in Dockerfile)
- Python version difference (Humble uses Python 3.10)
- Missing environment variables

---

## Performance Tips

### Build Caching
```bash
# Docker caches layers - reuse them
docker build -f Dockerfile .  # Slow first time
docker build -f Dockerfile .  # Fast second time (cached)

# Force rebuild
docker build --no-cache -f Dockerfile .
```

### Volume Mounts (Live Editing)
```bash
# Changes on host appear in container instantly
docker-compose up -d
# Edit files, they're immediately available in container
```

### Resource Limits
```bash
# Limit CPU and memory
docker run --cpus="2" --memory="4g" momentum-test:latest
```

---

## Next Steps

1. **Build locally first:**
   ```bash
   docker-compose build
   docker-compose up -d
   docker exec -it momentum-ros-humble bash
   ```

2. **Test the build:**
   ```bash
   docker run --rm -v $(pwd)/test-results:/test-results momentum-test:latest
   ```

3. **Integrate with GitHub:**
   - Add Docker job to `.github/workflows/ci.yml`
   - Upload test results as artifacts
   - Fail CI if tests don't pass

4. **Use in team:**
   - Every developer uses same Docker image
   - No environment mismatch issues
   - Consistent test results everywhere
