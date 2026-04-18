# CI Configuration: Ubuntu 22.04 + ROS Version Parameter

## ✅ Changes Made

### 1. **Ubuntu Version Pinned to 22.04**
All CI jobs now run on `ubuntu-22.04` instead of `ubuntu-latest`:
```yaml
runs-on: ubuntu-22.04
```

**Benefits:**
- ✅ Consistent with ROS 2 Humble (uses Ubuntu 22.04)
- ✅ No surprises from Ubuntu upgrades breaking CI
- ✅ Matches your local development environment

### 2. **ROS Version Parametrized**
Now you can test with different ROS 2 versions:
```yaml
env:
  ROS_DISTRO: humble  # Options: humble, iron, jazzy
  UBUNTU_VERSION: "22.04"
```

**Supported distros:**
- `humble` (Ubuntu 22.04) - **default**
- `iron` (Ubuntu 22.04)
- `jazzy` (Ubuntu 24.04) - *future ready*

### 3. **Docker Images Updated**
Both Dockerfiles now accept `ROS_DISTRO` parameter:

**Dockerfile:**
```dockerfile
ARG ROS_DISTRO=humble
FROM ros:${ROS_DISTRO}
```

**Dockerfile.testing:**
```dockerfile
ARG ROS_DISTRO=humble
FROM ros:${ROS_DISTRO}
```

**docker-compose.yml:**
```yaml
ros-dev:
  build:
    args:
      ROS_DISTRO: ${ROS_DISTRO:-humble}
```

### 4. **CI Triggers (Unchanged - Already Correct)**
```yaml
on:
  push:
    branches: [ main ]          # Only on push to main
  pull_request:
    branches: [ dev, main ]     # On all PRs to dev and main
```

**How it works:**
- ❌ Push to dev → **NO CI** (use PRs instead)
- ✅ PR to dev → **CI runs**
- ✅ PR to main → **CI runs**
- ✅ Push to main → **CI runs** (after PR merge)

---

## 🔧 How to Use

### Default: Test with Humble (current setup)

No changes needed - CI automatically uses humble:

```bash
# Push your code
git push origin feat/my-feature

# GitHub Actions automatically:
# 1. Tests on Ubuntu 22.04
# 2. Uses ROS Humble
# 3. Builds and tests
```

### Advanced: Change ROS Version for Testing

**Option A: Change global CI default**

Edit `.github/workflows/ci.yml`:
```yaml
env:
  ROS_DISTRO: iron  # Change to iron or jazzy
```

**Option B: Test locally with different ROS version**

```bash
# Build with Iron
docker build -f Dockerfile.testing \
  --build-arg ROS_DISTRO=iron \
  -t momentum-test:iron .

# Run tests
docker run --rm \
  -v $(pwd)/test-results:/test-results \
  momentum-test:iron
```

**Option C: Use docker-compose with environment variable**

```bash
# Test with Iron locally
ROS_DISTRO=iron docker-compose up -d
docker exec -it momentum-ros-iron bash

# Inside container
colcon build
colcon test
```

---

## 📋 CI Workflow (What Happens When You Push)

```
Developer pushes to PR (or main)
         ↓
GitHub detects event: Is it a PR to dev/main, or push to main?
         ↓
YES → CI Pipeline Starts
         ↓
┌──────────────────────────────────────────────────┐
│ Runner: ubuntu-22.04 (not ubuntu-latest)         │
├──────────────────────────────────────────────────┤
│                                                  │
│ JOB 1: Python Tests (3 versions)                 │
│  └─ Python 3.9, 3.10, 3.11                      │
│     pytest, coverage on ubuntu-22.04             │
│                                                  │
│ JOB 2: Linting                                   │
│  └─ black, flake8, isort on ubuntu-22.04         │
│                                                  │
│ JOB 3: ROS Tests                                 │
│  ├─ Build Docker image: ros:${ROS_DISTRO}       │
│  │  (currently: ros:humble)                      │
│  ├─ Run: colcon build                            │
│  ├─ Run: colcon test                             │
│  ├─ Run: pytest (Python tests)                   │
│  └─ Generate reports                             │
│                                                  │
│ Runner: ubuntu-22.04                             │
└──────────────────────────────────────────────────┘
         ↓
    All pass? ✓
    └─ Green checkmark on PR → Can merge
    └─ Push to main
    └─ CD pipeline auto-deploys
```

---

## 🎯 Test Triggers

| Event | Branch | Trigger | Reason |
|-------|--------|---------|--------|
| Push | main | ✅ YES | Release code |
| Push | dev | ❌ NO | Use PRs for review |
| PR | main ← * | ✅ YES | Before merging to prod |
| PR | dev ← * | ✅ YES | Before merging to dev |

---

## 💾 Files Modified

### `.github/workflows/ci.yml`
- Added environment variables for `ROS_DISTRO` and `UBUNTU_VERSION`
- Changed all `runs-on: ubuntu-latest` → `runs-on: ubuntu-22.04`
- Renamed `ros-humble-tests` → `ros-tests` (more generic)
- Updated Docker build to use `--build-arg ROS_DISTRO=${{ env.ROS_DISTRO }}`
- Updated artifacts naming to include ROS distro

### `Dockerfile`
- Added `ARG ROS_DISTRO=humble` at top
- Changed `FROM ros:humble` → `FROM ros:${ROS_DISTRO}`
- Changed all `ros-humble-*` packages → `ros-${ROS_DISTRO}-*`
- Added build arg instructions in comments

### `Dockerfile.testing`
- Added `ARG ROS_DISTRO=humble` at top
- Changed `FROM ros:humble` → `FROM ros:${ROS_DISTRO}`
- Changed all `ros-humble-*` packages → `ros-${ROS_DISTRO}-*`

### `docker-compose.yml`
- Renamed service: `ros-humble-dev` → `ros-dev`
- Added `build.args` to pass `ROS_DISTRO`
- Container name respects `ROS_DISTRO`: `momentum-ros-${ROS_DISTRO:-humble}`
- Added `ROS_DISTRO` environment variable

---

## 🚀 Quick Start Examples

### Example 1: Humble (Default)
```bash
# CI automatically uses humble
git push origin feat/...
# → Tests run on Ubuntu 22.04 with ROS Humble
```

### Example 2: Test Locally Before Pushing
```bash
# Verify tests pass locally first
docker build -f Dockerfile.testing -t momentum-test:humble .
docker run --rm -v $(pwd)/test-results:/test-results momentum-test:humble

# Check results
cat test-results/test-results.txt

# All good? Push
git push origin feat/my-feature
```

### Example 3: Future: Switch to Iron
```bash
# When you want to test with Iron
# Edit .github/workflows/ci.yml:

env:
  ROS_DISTRO: iron
  
# Now all CI runs use Iron + Ubuntu 22.04
# Commit and push
git push origin feat/...
```

### Example 4: Local Development with Iron
```bash
# Try Iron locally
ROS_DISTRO=iron docker-compose up -d
docker exec -it momentum-ros-iron bash

cd /home/ros/ws
colcon build
colcon test
```

---

## ⚠️ Important Notes

### Ubuntu Version Matters
- `Ubuntu 22.04` = Humble, Iron
- `Ubuntu 24.04` = Jazzy (future)
- If switching to Jazzy, may need to update runner

### ROS Distro Must Exist
```bash
# Valid
ROS_DISTRO=humble  ✅
ROS_DISTRO=iron    ✅
ROS_DISTRO=jazzy   ✅

# Invalid (will fail)
ROS_DISTRO=foxy    ❌ (too old, use older Ubuntu)
ROS_DISTRO=rolling ❌ (development only)
```

### CI Timing
- Python tests: 3-5 min (fast)
- Lint: 1-2 min (fast)
- Docker tests: 10-20 min (slower because builds image)
- **Total: 15-25 minutes**

---

## 🔍 Debugging CI Failures

### Check CI Status

On your PR, look at job statuses:
```
✓ python-tests
✓ lint
✗ ros-tests           ← Click to see why it failed
```

### Common Failures

**1. Docker Build Failed**
```
ERROR: Package 'X' requires ROS Y packages

Solution:
- Check package.xml dependencies
- Ensure all packages use ros-${ROS_DISTRO}-* format
- Some packages might not exist for your ROS version
```

**2. Tests Fail on Distro**
```
ERROR: Cannot import ros_distro_humble

Solution:
- Test locally first: ROS_DISTRO=iron docker-compose up -d
- Fix compatibility issues before pushing
```

**3. Ubuntu 22.04 Not Available** (rare)
```
ERROR: ubuntu-22.04 runner not available

Solution:
- GitHub might have maintenance
- Wait or file issue with GitHub
- Can temporarily use ubuntu-latest
```

---

## 📚 Related Documentation

- [docs/CI_EXPLANATION.md](CI_EXPLANATION.md) - Detailed CI breakdown
- [docs/DOCKER_GUIDE.md](DOCKER_GUIDE.md) - Docker local testing
- [docs/WORKFLOW.md](WORKFLOW.md) - Development workflow
- [.github/workflows/ci.yml](../.github/workflows/ci.yml) - Full pipeline code

---

## ✅ Summary: What You Get

```
✅ Tests run on consistent OS: Ubuntu 22.04
✅ ROS version easily configurable: humble, iron, jazzy
✅ CI triggers correctly: no tests on push to dev
✅ Docker image builds support all ROS versions
✅ Local dev matches CI environment
✅ Test reports uploaded for debugging
✅ Fast feedback: 15-25 min per PR
```

**Ready to push?** Your next PR will automatically use this setup! 🚀
