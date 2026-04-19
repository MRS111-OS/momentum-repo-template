# Local Testing & CI/CD Integration Guide

## Complete Picture: How Everything Works Together

```
┌─────────────────────────────────────────────────────────────────────┐
│                   YOUR DEVELOPMENT WORKFLOW                         │
└─────────────────────────────────────────────────────────────────────┘

STEP 1: LOCAL DEVELOPMENT (Your Machine)
```
```
┌─────────────────────────────────────────────────┐
│ Option A: Pure Python Package                   │
├─────────────────────────────────────────────────┤
│ $ pip install -r requirements.txt               │
│ $ pytest tests/ -v --cov=src                    │
│ $ black src/                                    │
│ $ flake8 src/                                   │
│ (takes 1-3 minutes)                             │
└─────────────────────────────────────────────────┘
```

```
┌─────────────────────────────────────────────────┐
│ Option B: ROS Package (Docker)                  │
├─────────────────────────────────────────────────┤
│ $ docker-compose up -d                          │
│ $ docker exec -it momentum-ros-humble bash      │
│ $ cd /home/ros/momentum_ws                      │
│ $ colcon build                                  │
│ $ colcon test                                   │
│ (takes 5-15 minutes first time, cached later)   │
└─────────────────────────────────────────────────┘

STEP 2: PUSH TO GITHUB
```
```
$ git push origin feat/my-feature
```

```
STEP 3: GITHUB ACTIONS CI RUNS AUTOMATICALLY
```
```
┌──────────────────────────────────────────────────────────────┐
│                    GitHub Actions Workflow                   │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  JOB 1: Python Tests (1 runner)             (2-5 min)       │
│  └─ Python 3.11: pytest + coverage                          │
│                                                              │
│  JOB 2: Linting (1 runner)                 (1-2 min)        │
│  ├─ flake8 src/                                             │
│  ├─ black --check src/                                      │
│  └─ isort --check-only src/                                 │
│                                                              │
│  JOB 3: ROS Docker Tests (matrix)          (10-20 min)      │
│  ├─ ROS Humble: build image + run full test container       │
│  ├─ ROS Jazzy:  build image + run full test container       │
│  ├─ colcon build + colcon test                              │
│  ├─ pytest + coverage.xml                                   │
│  ├─ ament_flake8 (report only)                              │
│  └─ Upload artifacts: ros-test-results-<distro>             │
│                                                              │
│  ALL JOBS PASS? ✓ Green checkmark on PR                    │
│  ANY JOB FAIL?  ✗ Red X on PR (must fix)                   │
└──────────────────────────────────────────────────────────────┘

STEP 4: REVIEW & MERGE
```
```
All checks pass ✓
├─ Code reviewer approves
└─ Merge to dev

Later: Create Release PR
├─ PR: dev → main
└─ Deploy to robots (CD pipeline)
```

---

## File Quick Reference

| File | Purpose | Used For |
|------|---------|----------|
| [requirements.txt](../requirements.txt) | Python deps | pip install |
| [.github/workflows/ci.yml](../.github/workflows/ci.yml) | CI pipeline | Runs tests on GitHub |
| [Dockerfile](../Dockerfile) | Dev environment | `docker build` + local dev |
| [Dockerfile.testing](../Dockerfile.testing) | Test environment | CI test runs |
| [docker-compose.yml](../docker-compose.yml) | Dev convenience | `docker-compose up` |
| [docs/CI_EXPLANATION.md](CI_EXPLANATION.md) | CI usage | Understand CI.yml |
| [docs/DOCKER_GUIDE.md](DOCKER_GUIDE.md) | Docker usage | Build/test locally |
| [tests/](../tests/) | Unit tests | pytest runs here |
| [src/](../src/) | Source code | Linting checks this |

---

## Scenario Walkthrough: "I'm adding a sensor driver"

### Step 1: Local Development (5-10 min)

```bash
# Start local ROS environment
docker-compose up -d
docker exec -it momentum-ros-humble bash

# Inside container
cd /home/ros/momentum_ws
colcon build
colcon test

# See if tests pass: ✓
# See if code builds: ✓
```

### Step 2: Code Review Check

```bash
# Exit Docker, check Python code quality on host
docker exec -it momentum-ros-humble bash -c "\
  source ~/.bashrc && \
  ament_flake8 /home/ros/momentum_ws/src/repository/src/my_sensor_driver.py && \
  ament_black --check /home/ros/momentum_ws/src/repository"

# All pass: ✓
```

### Step 3: Push to GitHub

```bash
git add .
git commit -m "feat: add thermal sensor driver"
git push origin feat/thermal-sensor
```

### Step 4: GitHub Actions Runs (Automatic)

**Your PR shows:**
```
 ✓ python-tests (Python 3.11 passed)
 ✓ lint (black, flake8, isort passed)
 ✓ ros-tests / humble and ros-tests / jazzy passed
```

Timeline:
- 0-2 min: Setup
- 2-5 min: Python tests
- 5-7 min: Lint
- 7-20 min: Docker ROS tests
- **20-25 min total**

### Step 5: Get Approval

Reviewer clicks "Approve" because:
- ✅ Tests passed automatically
- ✅ Code is clean (black/flake8/isort)
- ✅ Logic looks correct (after manual review)
- ✅ Sensor driver works on Ubuntu Humble (Docker verified)

### Step 6: Merge

You click "Merge Pull Request"
- Code goes to `dev`
- Other developers pull the latest with your sensor driver

### Step 7: Release

Once a day/week:
```bash
# Create release PR
git checkout -b release/v1.3.0
git push origin release/v1.3.0
# Create PR: release → main on GitHub
# Get approval
# Merge
# Tag: git tag v1.3.0
# CD pipeline deploys to robots
```

---

## The Three Testing Layers

### Layer 1: Your Machine (Python only)

**When:** During coding
**Command:** 
```bash
pytest tests/ -v
black src/
```
**Time:** 1-2 minutes
**Output:** Pass/Fail
**Cost:** Free (local)

### Layer 2: Your Machine (Full ROS)

**When:** Before pushing
**Command:**
```bash
docker-compose up -d
docker exec -it momentum-ros-humble bash
cd /home/ros/momentum_ws
colcon build && colcon test
```
**Time:** 5-15 minutes (first time), 2-5 min (cached)
**Output:** Build logs, test results
**Cost:** Free (Docker on your machine)

### Layer 3: GitHub Actions (All Tests)

**When:** Every push/PR
**Runs:** Automatically
**Tests:** 
- Python 3.11
- Code quality (black, flake8, isort)
- ROS Humble and Jazzy full Docker build + tests
**Time:** 20-30 minutes total
**Output:** Green ✓ or Red ✗ on PR
**Cost:** Free (GitHub included)

---

## What Gets Tested

```
Your Push to feat/my-feature
         ↓
GitHub Actions Triggered
         ↓
┌─────────────────────────────────────┐
│ Python Tests (3.11)                 │
├─────────────────────────────────────┤
│ pytest tests/ -v --cov=src          │
│ • Unit tests                        │
│ • Coverage %                        │
│ • Integration tests                 │
└─────────────────────────────────────┘
         ↓
┌─────────────────────────────────────┐
│ Code Quality                        │
├─────────────────────────────────────┤
│ • flake8: catch errors              │
│ • black: formatting                 │
│ • isort: imports organized          │
└─────────────────────────────────────┘
         ↓
┌─────────────────────────────────────┐
│ ROS Matrix Build & Test             │
├─────────────────────────────────────┤
│ • Ubuntu 22.04 + ROS Humble/Jazzy   │
│ • colcon build                      │
│ • colcon test                       │
│ • ament_flake8 (ROS style)          │
│ • Coverage report                   │
│ • Test logs                         │
└─────────────────────────────────────┘
         ↓
    Results on PR:      All ✓? Merge!
                        Any ✗? Fix + retry
```

---

## Real-World Pipeline Time

```
9:00 - Push code: git push origin feat/...
       GitHub Actions starts automatically
       └─ You don't have to do anything

9:02 - Python tests running (3.11)
9:05 - Lint checks running
9:07 - Docker image building
9:12 - ROS compilation
9:20 - ROS tests running
9:25 - All complete

9:25 - PR shows: ✓ All checks passed
       Green checkmark = safe to merge
       
9:30 - Code reviewer approves
9:35 - You click "Merge"
       Code is now in dev branch
```

---

## If Something Fails

### Python Test Fails

```
CI Output:
  FAILED tests/test_gps.py::test_calibration
  AssertionError: expected 2.5, got 3.1

What to do:
1. Pull dev: git pull origin dev
2. Check locally: pytest tests/test_gps.py::test_calibration -v
3. Debug why it fails
4. Fix the code or test
5. Verify locally: pytest tests/ -v
6. Push fix: git push origin feat/...
7. CI re-runs automatically
```

### Black Formatting Fails

```
CI Output:
  would reformat src/sensors.py

What to do:
1. Run black locally: black src/sensors.py
2. Commit: git add . && git commit -m "style: format with black"
3. Push: git push origin feat/...
4. CI re-runs, should pass
```

### Docker Build Fails

```
CI Output:
  ERROR: Package 'my_package' not found in rosdep

What to do:
1. Check package.xml dependencies
2. Add missing dependency
3. Test locally first: docker build -f Dockerfile.testing .
4. Push fix
5. CI re-runs
```

---

## Performance: Making CI Faster

### For Python Tests
```yaml
# Current: Tests run on Python 3.11 only
# Option 1: Add matrix if you want broader compatibility checks
python-version: ['3.10', '3.11']

# Option 2: Parallelize tests (if you have many)
pytest -n auto tests/
```

### For Docker Tests
```yaml
# Current: Builds full image every time (10-20 min)
# Option 1: Use Docker layer caching
docker build --cache-from momentum-test:latest .

# Option 2: Only test changed packages
colcon test --packages-select my_package
```

### For Code Quality
```yaml
# Run in parallel, not sequentially
flake8 src/ & black --check src/ & isort --check-only src/
wait
```

---

## Debugging: Understanding CI Logs

### Check CI Status

On your PR:
```
✓ python-tests / Python 3.11
✓ lint
✗ ros-tests / humble  ← Click this to see error
✗ ros-tests / jazzy   ← Or this one
```

### Download Artifacts

After CI runs (even if it fails):
```
Artifacts
├─ ros-test-results-humble
└─ ros-test-results-jazzy
   ├─ pytest.log
   ├─ colcon-test.log
   ├─ coverage.xml
   └─ test-results.txt
```

Click to download and inspect.

### Re-run CI (Without Pushing)

On PR:
1. Click "..." (More options)
2. "Re-run failed jobs"
3. CI runs again with same code

---

## Team Setup: First Day

### Developer joins team

**Step 1: Clone repo**
```bash
git clone <repo>
cd momentum-repo
```

**Step 2: Quick start**
```bash
# Option A: Python only
pip install -r requirements.txt
pytest tests/ -v

# Option B: Full ROS
docker-compose up -d
docker exec -it momentum-ros-humble bash
cd /home/ros/momentum_ws
```

**Step 3: Read docs**
- [WORKFLOW.md](WORKFLOW.md) - How we work
- [CI_EXPLANATION.md](CI_EXPLANATION.md) - How CI works
- [DOCKER_GUIDE.md](DOCKER_GUIDE.md) - Using Docker

**Step 4: Create feature branch**
```bash
git checkout -b feat/my-first-feature
```

**Step 5: Make changes & test**
```bash
docker-compose up -d
docker exec -it momentum-ros-humble bash
cd /home/ros/momentum_ws
colcon build && colcon test
```

**Step 6: Push & PR**
```bash
git push origin feat/...
# Create PR on GitHub
# CI runs automatically
# Wait for approval
# Merge
```

---

## Checklist: Before Pushing

- [ ] Tests pass locally: `pytest tests/ -v`
- [ ] Docker tests pass: `docker run --rm -v $(pwd)/test-results:/test-results momentum-test`
- [ ] Code is formatted: `black src/`
- [ ] No import issues: `isort src/`
- [ ] No obvious errors: `flake8 src/`
- [ ] Commit message is clear: `git log --oneline -1`
- [ ] Pushing to feature branch (not main): `git branch`

---

## Links & Next Steps

**For Developers:**
- [WORKFLOW.md](WORKFLOW.md) - Daily workflow
- [CI_EXPLANATION.md](CI_EXPLANATION.md) - Understanding CI
- [DOCKER_GUIDE.md](DOCKER_GUIDE.md) - Using Docker locally

**For DevOps/Leads:**
- Review [.github/workflows/ci.yml](../.github/workflows/ci.yml)
- Review [Dockerfile](../Dockerfile) and [Dockerfile.testing](../Dockerfile.testing)
- Integrate with your deployment system

**Running Locally:**
```bash
# Python only
pytest tests/ -v --cov=src

# Full ROS
docker-compose up -d
docker exec -it momentum-ros-humble bash
cd /home/ros/momentum_ws
colcon build && colcon test
```

---

## Behind the Scenes: Option B (Docker ROS)

When you run local Option B, this is the exact order:

1. `docker-compose up -d`
  - Builds image from `Dockerfile` with `ROS_DISTRO` (default `humble`).
  - Starts container `momentum-ros-${ROS_DISTRO}`.
  - Mounts your repo to `/home/ros/momentum_ws/src/repository`.
  - Reuses named volumes for `/home/ros/momentum_ws/build`, `/home/ros/momentum_ws/install`, and `/home/ros/momentum_ws/log`.

2. `docker exec -it momentum-ros-humble bash`
  - Opens an interactive shell in the running container.

3. `cd /home/ros/momentum_ws && colcon build`
  - Builds packages discovered under `src/`.
  - Writes incremental artifacts to `build/` and `install/`.

4. `colcon test`
  - Runs package tests and stores logs/results under workspace log/build paths.
  - You can inspect summary with `colcon test-result --verbose`.

CI uses `Dockerfile.testing` (not `Dockerfile`) and runs the same pattern in one-shot containers per distro (`humble`, `jazzy`) with reports exported to `test-results/`.
