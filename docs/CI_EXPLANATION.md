# CI/CD Pipeline Explanation

## Overview of `.github/workflows/ci.yml`

This pipeline runs automated checks for pull requests to `dev` and `main`, plus direct pushes to `main`.

Current trigger behavior:
- Push to `main` -> CI runs
- Push to `dev` -> CI does not run
- Pull request to `dev` -> CI runs
- Pull request to `main` -> CI runs

---

## Visual Flow

```
Developer opens/updates PR to dev/main
         ↓
GitHub Actions starts CI
         ↓
┌─────────────────────────────────────────────┐
│ JOB 1: python-tests                         │
│ - Ubuntu 22.04                              │
│ - Python 3.11                               │
│ - pytest + coverage.xml                     │
└─────────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────────┐
│ JOB 2: lint                                 │
│ - Ubuntu 22.04                              │
│ - flake8, black --check, isort --check-only │
└─────────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────────┐
│ JOB 3: ros-tests (matrix)                   │
│ - Ubuntu 22.04 runner                        │
│ - ROS_DISTRO=humble                          │
│ - ROS_DISTRO=jazzy                           │
│ - Build Dockerfile.testing image             │
│ - Run colcon test + pytest + reports         │
└─────────────────────────────────────────────┘
         ↓
All checks pass? Merge allowed
Any check fails? Fix + push to re-run
```

---

## Job Details

### 1) `python-tests`

What it does:
- Sets up Python 3.11
- Installs dependencies from `requirements.txt`
- Runs:

```bash
pytest tests/ -v --cov=src --cov-report=xml
```

Outputs:
- `coverage.xml` uploaded to Codecov

### 2) `lint`

What it does:
- Runs static checks:

```bash
flake8 src/ tests/ --count --select=E9,F63,F7,F82 --show-source --statistics
black --check src/ tests/
isort --check-only src/ tests/
```

Purpose:
- Catch syntax/runtime-signature issues early
- Enforce formatting and import order consistency

### 3) `ros-tests` (matrix: `humble`, `jazzy`)

What it does for each distro:
1. Build Docker image from `Dockerfile.testing`
2. Run one-shot container with mounted `test-results/`
3. Inside container:
- source ROS setup
- source workspace setup
- run `colcon test`
- run `pytest` if test files are found
- run `ament_flake8` (report-only)
4. Upload artifacts:
- `ros-test-results-humble`
- `ros-test-results-jazzy`

---

## Workspace Layout Used by Docker Tests

Inside container (`Dockerfile.testing`):
- Workspace root: `/home/ros/momentum_ws`
- Repository path: `/home/ros/momentum_ws/src/repository`
- Build artifacts: `/home/ros/momentum_ws/build`
- Install artifacts: `/home/ros/momentum_ws/install`
- Colcon logs: `/home/ros/momentum_ws/log`
- Exported CI reports: `/test-results`

On GitHub runner host:
- `./test-results` is bind-mounted to `/test-results` in container

---

## How to Reproduce CI Locally

### Python + lint jobs

```bash
pip install -r requirements.txt
pip install pytest pytest-cov flake8 black isort
pytest tests/ -v --cov=src --cov-report=xml
flake8 src/ tests/ --count --select=E9,F63,F7,F82 --show-source --statistics
black --check src/ tests/
isort --check-only src/ tests/
```

### ROS Docker job (single distro)

```bash
docker build -f Dockerfile.testing --build-arg ROS_DISTRO=humble -t momentum-test:humble .
mkdir -p test-results
docker run --rm \
  -v $(pwd)/test-results:/test-results \
  -e ROS_DISTRO=humble \
  -e ROS_TEST_MODE=colcon-test \
  momentum-test:humble
```

---

## Failure Triage

If `python-tests` fails:
- Re-run failed test locally with `pytest -v`

If `lint` fails:
- Run black/isort formatters locally, re-run flake8

If `ros-tests` fails:
- Download artifacts from the failed distro
- Check `colcon-test.log`, `pytest.log`, and `test-results.txt`
- Reproduce with `Dockerfile.testing` locally using same distro
