# GitHub Status Badges Guide

## Overview

Status badges are small images displayed on your README that show:
- ✅ Test status (passing/failing)
- 🐍 Python version compatibility (3.11)
- 🤖 ROS 2 version compatibility (Humble)
- 📦 Code quality checks

---

## Setting Up Badges

### Step 1: Customize the Badge URLs

Your README currently has placeholder badges:

```markdown
[![CI - Python](https://github.com/YOUR_GITHUB_USERNAME/REPO_NAME/actions/workflows/ci.yml/badge.svg)](...)
```

**Replace:**
- `YOUR_GITHUB_USERNAME` → Your actual GitHub username
- `REPO_NAME` → Your repository name

**Example:**
If your repo is `https://github.com/awesome-robotics/momentum-repo`:
- Username: `awesome-robotics`
- Repo: `momentum-repo`

**Updated badge:**
```markdown
[![CI - Python](https://github.com/awesome-robotics/momentum-repo/actions/workflows/ci.yml/badge.svg)](https://github.com/awesome-robotics/momentum-repo/actions/workflows/ci.yml)
```

### Step 2: Edit README.md

Replace all three instances of `YOUR_GITHUB_USERNAME/REPO_NAME`:

```bash
# Find and replace (using sed or manually)
sed -i 's|YOUR_GITHUB_USERNAME/REPO_NAME|awesome-robotics/momentum-repo|g' README.md
```

Or manually edit [README.md](../README.md) and replace with your details.

### Step 3: Commit and Push

```bash
git add README.md
git commit -m "docs: add CI status badges"
git push origin feat/add-badges
```

### Step 4: Create PR and See Badges Live

Once you push to GitHub and view the README on the web, the badges will show:

```
✅ CI - Python   [Passing]
✅ CI - Linting  [Passing]
✅ CI - ROS      [Passing]
```

Click any badge to see full CI history.

---

## Badge Types Explained

### 1. **CI - Python** Badge
```markdown
[![CI - Python](https://github.com/USERNAME/REPO/actions/workflows/ci.yml/badge.svg)](...)
```
- Shows: Python 3.11 tests status
- Color: Green (passing), Red (failing)
- Updates: Every push or PR

### 2. **CI - Linting** Badge
```markdown
[![CI - Linting](https://github.com/USERNAME/REPO/actions/workflows/ci.yml/badge.svg)](...)
```
- Shows: Code quality (black, flake8, isort)
- Color: Green (all checks pass), Red (style issues)
- Updates: Every push or PR

### 3. **CI - ROS** Badge
```markdown
[![CI - ROS](https://github.com/USERNAME/REPO/actions/workflows/ci.yml/badge.svg)](...)
```
- Shows: ROS Humble compatibility
- Color: Green (builds + tests pass), Red (build failed)
- Updates: Every push or PR

---

## Current Status Table

The README includes a compatibility table:

```markdown
| Status | Details |
|--------|---------|
| **Python** | 3.11 |
| **ROS 2** | Humble (Ubuntu 22.04) |
| **Tests** | pytest + coverage |
| **Code Quality** | black, flake8, isort |
```

This shows at-a-glance what your project supports.

---

## What the Badges Tell Developers

### ✅ All Green
```
✅ CI - Python   [Passing]
✅ CI - Linting  [Passing]
✅ CI - ROS      [Passing]
```
**Meaning:** "This code is ready to use. Tests pass, style is clean, ROS Humble compatible."

### ❌ Any Red
```
✅ CI - Python   [Passing]
❌ CI - Linting  [Failing]
✅ CI - ROS      [Passing]
```
**Meaning:** "Code style needs fixing before using this version. See GitHub Actions for details."

### 🔄 Gray (In Progress)
```
⏳ CI - Python   [Running]
⏳ CI - Linting  [Running]
⏳ CI - ROS      [Queued]
```
**Meaning:** "Tests are currently running. Check back in a few minutes."

---

## Advanced Options

### Branch-Specific Badges

Show status for specific branches:

```markdown
# Main branch status (production-ready)
[![Main CI](https://github.com/USERNAME/REPO/actions/workflows/ci.yml/badge.svg?branch=main)](...)

# Dev branch status (active development)
[![Dev CI](https://github.com/USERNAME/REPO/actions/workflows/ci.yml/badge.svg?branch=dev)](...)
```

### Event-Specific Badges

Show status for specific events:

```markdown
# On push events only
[![On Push](https://github.com/USERNAME/REPO/actions/workflows/ci.yml/badge.svg?event=push)](...)

# On pull requests only
[![On PR](https://github.com/USERNAME/REPO/actions/workflows/ci.yml/badge.svg?event=pull_request)](...)
```

### Badge with Custom Label

```markdown
[![Tests Passing](https://github.com/USERNAME/REPO/actions/workflows/ci.yml/badge.svg)](...)
[![ROS Humble Compatible](https://github.com/USERNAME/REPO/actions/workflows/ci.yml/badge.svg)](...)
```

---

## Real-World Examples

### Example 1: Simple Status
```markdown
# Momentum Robotics

[![Build Status](https://github.com/robotics-team/momentum/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/robotics-team/momentum/actions)

This is a ROS 2 Humble robotics project.
```

### Example 2: Full Status Board
```markdown
# Momentum Robotics - Status

| Test | Status |
|------|--------|
| Python 3.11 | [![CI](https://github.com/team/momentum/actions/workflows/ci.yml/badge.svg)](..)|
| ROS Humble | [![CI](https://github.com/team/momentum/actions/workflows/ci.yml/badge.svg)](..)|
| Linting | [![CI](https://github.com/team/momentum/actions/workflows/ci.yml/badge.svg)](..)|
| Coverage | 85% |
```

### Example 3: Multiple Workflows
```markdown
# Project Status

[![Unit Tests](https://github.com/user/repo/actions/workflows/ci.yml/badge.svg)](...)
[![Integration Tests](https://github.com/user/repo/actions/workflows/ci.yml/badge.svg)](...)
[![Deployment](https://github.com/user/repo/actions/workflows/deploy.yml/badge.svg)](...)
```

---

## Troubleshooting

### Badge Shows "Unknown"
- Workflow hasn't run yet
- **Fix:** Trigger a CI run (push to main or create PR)
- Wait 2-3 minutes for badge to update

### Badge URL Shows 404
- Workflow file doesn't exist or has different name
- Check workflow file exists: `.github/workflows/ci.yml`
- Verify path in badge is correct

### Badge Not Clickable
- Make sure href link is correct format
- Should point to: `https://github.com/USERNAME/REPO/actions/workflows/ci.yml`

---

## Step-by-Step: Your Repo

### Quick Setup

1. **Edit README.md:**
   ```bash
   # Replace placeholders with your info
   sed -i 's|YOUR_GITHUB_USERNAME/REPO_NAME|YOUR_USER/YOUR_REPO|g' README.md
   ```

2. **Verify changes:**
   ```bash
   cat README.md | grep "github.com"
   # Should show your URLs, not placeholder
   ```

3. **Commit and push:**
   ```bash
   git add README.md
   git commit -m "docs: customize CI status badges"
   git push origin feat/badges
   ```

4. **Create PR on GitHub:**
   - Go to your repo on GitHub
   - Click "Pull requests"
   - Click "New pull request"
   - Select `feat/badges` → `main`
   - Create PR
   - View README preview with live badges

---

## After First CI Run

Once CI runs successfully (first time on your repo):
- Badges update automatically ✅
- Shows "Passing" in green
- Click badge to see full CI history
- New team members see: "This code is tested and validated"

---

## Links & References

- [GitHub Actions Badges](https://docs.github.com/en/actions/monitoring-and-troubleshooting-workflows/adding-a-workflow-status-badge)
- [Your CI Workflow](../README.md) - Status badges location
- [.github/workflows/ci.yml](../.github/workflows/ci.yml) - Workflow definition

---

## Summary

```
Before Setup:
❓ README shows "YOUR_GITHUB_USERNAME" placeholder

After Setup:
✅ README shows live CI status badges
✅ Developers instantly see if code passes tests
✅ Badges link to full CI history
✅ Shows ROS Humble + Python 3.11 compatibility
```

**Next step:** Replace placeholders in [README.md](../README.md) with your GitHub username and repo name! 🚀
