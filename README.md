# Momentum Robotics Repository

**Developed by:** Deepak Yadav, Momentum Robotics (MRS111-OS)

This repository provides a structured template for ROS 2 robotics applications with automated CI/CD testing, Docker development environments, and multi-distro support.

---

## 📊 CI Checks

[![Python Tests](https://img.shields.io/github/actions/workflow/status/MRS111-OS/momentum-repo-template/ci.yml?branch=dev&label=Python%20Tests&logo=python&logoColor=white)](https://github.com/MRS111-OS/momentum-repo-template/actions/workflows/ci.yml)
[![Linting](https://img.shields.io/github/actions/workflow/status/MRS111-OS/momentum-repo-template/ci.yml?branch=dev&label=Linting&logo=githubactions&logoColor=white)](https://github.com/MRS111-OS/momentum-repo-template/actions/workflows/ci.yml)
[![ROS 2 Humble Build/Test](https://img.shields.io/github/actions/workflow/status/MRS111-OS/momentum-repo-template/ci.yml?branch=dev&label=ROS%202%20Humble&logo=ros&logoColor=white)](https://github.com/MRS111-OS/momentum-repo-template/actions/workflows/ci.yml)
[![ROS 2 Jazzy Build/Test](https://img.shields.io/github/actions/workflow/status/MRS111-OS/momentum-repo-template/ci.yml?branch=dev&label=ROS%202%20Jazzy&logo=ros&logoColor=white)](https://github.com/MRS111-OS/momentum-repo-template/actions/workflows/ci.yml)

| Component | Details |
|-----------|---------|
| **Python** | 3.11 |
| **ROS 2** | Humble (Ubuntu 22.04), Jazzy (Ubuntu 24.04) |
| **Testing** | pytest + coverage |
| **Code Quality** | black, flake8, isort |

---

## 🚀 Quick Start

### Prerequisites
- Docker & Docker Compose
- Git
- GitHub account (for PR workflow)

### Clone & Setup
```bash
git clone https://github.com/MRS111-OS/momentum-repo-template.git
cd momentum-repo-template
docker-compose up -d
docker exec -it momentum-ros-humble bash
colcon build && colcon test
```

---

## 📁 Repository Structure

```
momentum-repo-template/
├── src/                  # ROS 2 packages and Python modules
├── tests/                # Unit and integration tests
├── docs/                 # Documentation (development guides, CI explanation)
├── .github/workflows/    # GitHub Actions CI/CD pipeline
├── Dockerfile            # Development environment
├── Dockerfile.testing    # CI testing environment
├── docker-compose.yml    # Docker Compose for local dev
├── requirements.txt      # Python dependencies
├── README.md            # This file
├── LICENSE              # MIT License
├── CONTRIBUTING.md      # Contributing guidelines
└── .gitignore          # Git configuration
```

---

## 🔄 Git Workflow

### Branching Strategy
- `dev` → Active development branch
- `main` → Production-ready code (PR only)

### Making Changes
1. **Create a feature branch from `dev`:**
   ```bash
   git checkout -b feat/my-feature dev
   ```

2. **Commit with clear messages:**
   ```bash
   git commit -m "feat: add new robot sensor driver"
   ```

3. **Push and create Pull Request:**
   ```bash
   git push origin feat/my-feature
   ```

4. **Merge only after:**
   - ✅ All CI checks pass
   - ✅ At least 1 approval
   - ✅ All review comments resolved

### Commit Message Format
- `feat:` New feature
- `fix:` Bug fix
- `refactor:` Code restructure
- `docs:` Documentation updates
- `chore:` Build/tooling changes

---

## ✅ Rules & Policies

| Rule | Detail |
|------|--------|
| **No Direct Push to Main** | All changes via PR only |
| **Branch Protection** | PRs require approval + passed CI |
| **Code Quality** | black, flake8, isort must pass |
| **Test Coverage** | All new code must have tests |
| **Documentation** | Changes to public APIs require doc updates |

---

## 🐳 Docker Development

### Start Development Environment
```bash
docker-compose up -d
docker exec -it momentum-ros-humble bash
```

### Build & Test
```bash
cd /home/ros/momentum_ws
colcon build
colcon test
```

Workspace path map (inside container):
- Repository source: `/home/ros/momentum_ws/src/repository`
- Build artifacts: `/home/ros/momentum_ws/build`
- Install artifacts: `/home/ros/momentum_ws/install`
- Colcon logs: `/home/ros/momentum_ws/log`

---

## 📚 Documentation

- [**WORKFLOW.md**](docs/WORKFLOW.md) - Complete development workflow
- [**DOCKER_GUIDE.md**](docs/DOCKER_GUIDE.md) - Docker setup & usage
- [**LOCAL_TESTING_AND_CI.md**](docs/LOCAL_TESTING_AND_CI.md) - Testing & CI integration
- [**CI_EXPLANATION.md**](docs/CI_EXPLANATION.md) - CI pipeline details
- [**CONTRIBUTING.md**](CONTRIBUTING.md) - Contribution guidelines

---

## 📝 License

This project is licensed under the **MIT License** - see [LICENSE](LICENSE) file for details.

**Copyright © 2026 Deepak Yadav, Momentum Robotics (MRS111-OS)**

---

## 👤 Author

- **Name:** Deepak Yadav  
- **Organization:** Momentum Robotics (MRS111-OS)  
- **Repository:** [https://github.com/MRS111-OS/momentum-repo-template](https://github.com/MRS111-OS/momentum-repo-template)