# Momentum Robotics Repository

This repository follows a structured development workflow.

## CI Checks

[![Python Tests](https://img.shields.io/github/actions/workflow/status/MRS111-OS/momentum-repo-template/ci.yml?branch=dev&label=Python%20Tests&logo=python&logoColor=white)](https://github.com/MRS111-OS/momentum-repo-template/actions/workflows/ci.yml)
[![Linting](https://img.shields.io/github/actions/workflow/status/MRS111-OS/momentum-repo-template/ci.yml?branch=dev&label=Linting&logo=githubactions&logoColor=white)](https://github.com/MRS111-OS/momentum-repo-template/actions/workflows/ci.yml)
[![ROS 2 Humble Build/Test](https://img.shields.io/github/actions/workflow/status/MRS111-OS/momentum-repo-template/ci.yml?branch=dev&label=ROS%202%20Humble&logo=ros&logoColor=white)](https://github.com/MRS111-OS/momentum-repo-template/actions/workflows/ci.yml)
[![ROS 2 Jazzy Build/Test](https://img.shields.io/github/actions/workflow/status/MRS111-OS/momentum-repo-template/ci.yml?branch=dev&label=ROS%202%20Jazzy&logo=ros&logoColor=white)](https://github.com/MRS111-OS/momentum-repo-template/actions/workflows/ci.yml)

| Status | Details |
|--------|---------|
| **Python** | 3.11 |
| **ROS 2** | Humble (Ubuntu 22.04) + Jazzy (Ubuntu 24.04) |
| **Tests** | pytest + coverage |
| **Code Quality** | black, flake8, isort |

## Branch Strategy
- `dev` → Active development
- `main` → Production-ready code (PR only)

## Workflow
1. Create/checkout `dev`
2. Push changes to `dev`
3. Create Pull Request: `dev → main`
4. Get approval
5. Merge to `main`

## Rules
- Do NOT push directly to `main`
- All changes must go through PR
- Ensure code is tested before merging

## Structure
- `/src` → Source code
- `/tests` → Test cases
- `/docs` → Documentation