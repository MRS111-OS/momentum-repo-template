# Momentum Robotics Repository

This repository follows a structured development workflow.

## ✅ Status & Compatibility

**CI badges are configured for this organization repository.**

[![CI - Python](https://github.com/MRS111-OS/momentum-repo-template/actions/workflows/ci.yml/badge.svg?branch=main&event=push)](https://github.com/MRS111-OS/momentum-repo-template/actions/workflows/ci.yml)
[![CI - Linting](https://github.com/MRS111-OS/momentum-repo-template/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/MRS111-OS/momentum-repo-template/actions/workflows/ci.yml)
[![CI - ROS](https://github.com/MRS111-OS/momentum-repo-template/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/MRS111-OS/momentum-repo-template/actions/workflows/ci.yml)

| Status | Details |
|--------|---------|
| **Python** | 3.11 |
| **ROS 2** | Humble (Ubuntu 22.04) |
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