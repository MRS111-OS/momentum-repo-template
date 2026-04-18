# Momentum Robotics Workflow Guide

**For: ROS Development Teams | Small Teams (2-5 people) | Continuous Release Cycle**

This document explains how to use the Momentum workflow for your ROS robotics projects.

---

## 🎯 Core Workflow Overview

```
┌─────────────────────────────────────────────────────┐
│ Always Working on DEV                               │
├─────────────────────────────────────────────────────┤
│ 1. Pull latest from dev                             │
│ 2. Create feature branch                            │
│ 3. Code → Commit → Push to feature branch           │
│ 4. Create PR: feature → dev                         │
│ 5. Automated tests run (CI)                         │
│ 6. Team review & approve                            │
│ 7. Merge to dev                                     │
├─────────────────────────────────────────────────────┤
│ MAIN = Stable Releases Only                         │
│ 1. When ready: PR dev → main                        │
│ 2. Tag release version (v1.2.3)                     │
│ 3. One or two approvals required                    │
│ 4. Deploy to robots                                 │
└─────────────────────────────────────────────────────┘
```

### Key Principles
- **DEV branch** = Daily development, continuous integration
- **MAIN branch** = Release-ready code, never push directly
- **Pull Requests** = Every change goes through review
- **Automated Tests** = CI catches bugs before humans do

---

## 📋 Branch Strategy

### Branch Types

| Branch | Purpose | Created From | Merges To | Lifetime |
|--------|---------|--------------|-----------|----------|
| `main` | Production releases | Tagged releases | — | Forever |
| `dev` | Active development | Initial repo | `main` | Forever |
| `feat/name` | New features | `dev` | `dev` via PR | Days/weeks |
| `fix/name` | Bug fixes | `dev` | `dev` via PR | Days |
| `hotfix/name` | Urgent production fixes | `main` | `main` + `dev` | Hours/days |

### Naming Convention
```
feat/sensor-calibration
fix/gps-drift-issue
refactor/navigation-stack
docs/setup-guide
```

---

## 🔄 Step-by-Step Workflow

### 1. **Setup (First Time)**

```bash
# Clone the repository
git clone https://github.com/your-org/momentum-repo.git
cd momentum-repo

# Ensure you're on dev
git checkout dev
git pull origin dev

# Create your feature branch
git checkout -b feat/your-feature-name
```

### 2. **Development & Commits**

```bash
# Make changes to source code
nano src/sensors/gps_driver.py

# Write tests for your changes
nano tests/test_gps.py

# Run tests locally before committing
pytest tests/ -v

# Format code consistently
black src/ tests/
isort src/ tests/

# Check for style issues
flake8 src/

# Commit with clear message
git add .
git commit -m "feat: add GPS offset calibration"
```

**Commit Message Format:**
- `feat:` new feature
- `fix:` bug fix
- `refactor:` code improvement
- `docs:` documentation changes

### 3. **Push & Create Pull Request**

```bash
# Push your feature branch
git push origin feat/your-feature-name

# Go to GitHub and create Pull Request
# - Base: dev
# - Compare: feat/your-feature-name
# - Title: Clear, descriptive
# - Description: What? Why? How tested?
```

**PR Description Template:**
```markdown
## Summary
Add GPS offset calibration for outdoor navigation

## Changes
- Fixed GPS drift calculation in gps_driver.py
- Added offset correction algorithm
- Added 5 new test cases

## Testing
- [x] Tested on TurtleBot locally
- [x] Tested with 3+ environments
- [x] Edge cases covered (GPS loss, multipath)

## Type of Change
- [x] New feature
- [ ] Bug fix
- [ ] Breaking change
```

### 4. **Automated Tests Run**

The CI pipeline automatically runs:
- ✅ **Unit Tests** (`pytest`) - Verifies functionality
- ✅ **Code Formatting** (`black`) - Consistent style
- ✅ **Import Sorting** (`isort`) - Clean imports
- ✅ **Linting** (`flake8`) - Style compliance

**If tests fail:**
1. Check CI output for errors
2. Fix issues locally
3. Commit and push again
4. CI re-runs automatically

### 5. **Team Review**

A team member reviews your PR:
- Checks logic and correctness
- Verifies tests are adequate
- May request changes
- Tests are passing

**If changes requested:**
```bash
# Make requested changes
git add .
git commit -m "fix: address review comments"
git push origin feat/your-feature-name
# No new PR needed - updates existing one
```

### 6. **Approval & Merge**

Once approved:
1. All tests pass ✓
2. All comments resolved ✓
3. At least 1 approval ✓
4. Merge to `dev` button appears

Someone (usually the PR author) clicks "Merge Pull Request"

### 7. **Branch Cleanup** (Optional)

```bash
# Delete your local branch
git branch -d feat/your-feature-name

# Delete remote branch
git push origin --delete feat/your-feature-name
```

---

## 🚀 Release Process

When you have multiple features ready for production:

### Weekly Release (Example: Monday morning)

```bash
# Make sure dev is up to date
git checkout dev
git pull origin dev

# Create release PR
git checkout -b release/v1.2.0
# No code changes, just version bumps if needed

# Push and create PR: release → main
git push origin release/v1.2.0

# On GitHub:
# - Create PR: release/v1.2.0 → main
# - Get 2 approvals minimum
# - Merge when ready
```

### Tag & Deploy

```bash
# Switch to main (after PR merge)
git checkout main
git pull origin main

# Create release tag
git tag -a v1.2.0 -m "Release version 1.2.0"
git push origin v1.2.0

# Deployment system picks up the tag
# (Your CI/CD deploys to robots)
```

---

## 📊 Real-World ROS Example

### Scenario: Sensor Driver Development

**Developer Alice** - I'm fixing GPS drift:
```bash
git checkout -b fix/gps-drift-issue

# src/sensors/gps_driver.py - Add offset correction
# tests/test_gps.py - Add test cases

# Test locally on TurtleBot
pytest tests/test_gps.py -v  # All pass ✓

git add .
git commit -m "fix: correct GPS drift using Kalman filter"
git push origin fix/gps-drift-issue

# Create PR on GitHub, explains:
# - What: Fixed GPS drift that caused 2m error
# - Why: Kalman filter now corrects systematic offset
# - How tested: 30-min field test, 5 locations
```

**Developer Bob** - Meanwhile, working independently:
```bash
git checkout -b feat/compass-fusion

# src/sensors/compass_fusion.py - New algorithm
# tests/test_compass.py - Test coverage

# Bob's work doesn't conflict with Alice's - different files
```

**Review & Merge:**
- Bob reviews Alice's PR: "Looks good, adds inline doc?"
- Alice adds doc comment, pushes again
- Bob approves
- CI passes ✓
- Alice merges to `dev`

**Daily Release:**
- Both PRs merged to `dev`
- Manager creates PR: dev → main
- Tests run again on full codebase
- Approved and merged
- Tag: v0.5.0
- Robots updated via CD pipeline

---

## ⚠️ Critical Rules

❌ **NEVER DO THIS:**
```bash
git push origin main          # Direct push to main
git commit directly on dev    # Always use feature branch
```

✅ **ALWAYS DO THIS:**
```bash
git checkout -b feat/name     # Create feature branch
git push origin feat/name     # Push to feature branch
# Then create PR on GitHub    # Never direct merge
```

**Why?**
- Prevents accidental broken code on main
- Ensures every change is reviewed
- Keeps main deployable at all times
- Easy to revert if needed

---

## 🛡️ Workflow Benefits for ROS Teams

| Challenge | Solution |
|-----------|----------|
| **Robot crashes from bad code** | All code reviewed + tested before main |
| **Merge conflicts between team members** | Each person isolated on feature branch |
| **"Works on my machine" bugs** | CI runs identical tests for everyone |
| **Hard to track what changed** | Clear commit history + PR descriptions |
| **Team working on same code** | Multiple people collaborate without blocking |
| **Need to revert urgent mistake** | Easy PR revert, release new version |

---

## 🔧 Troubleshooting

### "My branch is behind dev"

```bash
git checkout your-branch
git fetch origin
git rebase origin/dev

# If conflicts occur, resolve them, then:
git add .
git rebase --continue
git push origin your-branch --force
```

### "I made a mistake before pushing"

```bash
# Undo last commit (keeps changes)
git reset --soft HEAD~1

# Undo last commit (discards changes)
git reset --hard HEAD~1
```

### "Merge conflict on PR"

Your PR shows "conflicting files". Resolve locally:
```bash
git fetch origin
git merge origin/dev  # Brings in latest changes

# Manually fix conflicting sections in your editor
git add .
git commit -m "resolve: merge conflicts from dev"
git push origin your-branch
```

---

## 📅 Daily Rhythm Example

```
9:00 AM  → Pull latest dev, create feature branch, start coding
10:00 AM → Commit first version of changes
11:30 AM → Push to GitHub, create PR
11:45 AM → CI runs automatically (2-3 min)
12:00 PM → Team member reviews during standup
12:30 PM → Request changes or approve
1:00 PM  → Fix + push updates if needed
2:00 PM  → Approved & merged to dev ✓
3:00 PM  → Daily release: dev → main
3:30 PM  → Tag v0.X.0, robots auto-update
```

---

## ❓ Common Team Questions

### Q1: What if I'm still working but need to check something on dev?

```bash
# Option 1: Stash changes
git stash
git checkout dev
git pull

# Make your check, then return
git checkout your-branch
git stash pop

# Option 2: Create temporary commit
git add .
git commit -m "WIP: temporary save"
# Fix up your commit later
```

### Q2: Emergency hotfix needed while I'm in middle of feature?

```bash
# On your feature branch, commit what you have
git add .
git commit -m "WIP: feature in progress"

# Create hotfix (from main)
git checkout main
git pull
git checkout -b hotfix/critical-issue

# Make fix, test, push, create PR → main
# Then return to your feature
git checkout feat/your-feature
```

### Q3: How do I handle ROS package version numbers?

- Update `package.xml` version in the PR
- Same format: `<version>1.2.3</version>`
- Matches git tag: `v1.2.3`
- Example PR: "feat: add GPS calibration (v1.2.3)"

### Q4: Can I work on multiple features at once?

Yes, but keep them on separate branches:
```bash
git checkout -b feat/feature-1
# Work on feature 1
git add . && git commit -m "feat: ..."

# Switch to different feature
git checkout -b feat/feature-2
# Work on feature 2
```

Each PR is independent and can be reviewed/merged separately.

### Q5: What if my PR is blocked by someone else's changes?

Your PR shows "branch has conflicts". Simply:
```bash
git fetch origin
git rebase origin/dev
# Fix any conflicts in your editor
git add .
git rebase --continue
git push origin your-branch --force
```

---

## 📚 Related Documents

- [README.md](../README.md) - Project overview & branch strategy
- [CONTRIBUTING.md](../CONTRIBUTING.md) - Detailed contribution guidelines
- [CI/CD Pipeline](./.github/workflows/ci.yml) - Automated tests & checks

---

## 🤝 Questions?

Reach out to the team via:
- Slack #dev-channel
- GitHub Issues for bugs/features
- Team standup for process questions

**Keep it simple:** Branch → Code → Test → PR → Review → Merge → Release
