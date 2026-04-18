# Quick Reference: Customize Your Status Badges

## TL;DR - 2 Minute Setup

### 1. Get Your GitHub Info
- Go to: https://github.com/YOUR-USERNAME/YOUR-REPO-NAME
- Note your **username** and **repo name**

Example:
```
URL: https://github.com/awesome-robotics/momentum-repo
Username: awesome-robotics
Repo: momentum-repo
```

### 2. Replace in README.md

Find and replace **in README.md only**:

```bash
# Linux/Mac
sed -i 's|YOUR_GITHUB_USERNAME/REPO_NAME|awesome-robotics/momentum-repo|g' README.md

# Or manually:
# Find: YOUR_GITHUB_USERNAME/REPO_NAME
# Replace with: awesome-robotics/momentum-repo
```

### 3. Verify Changes
```bash
# Check it worked
grep "github.com" README.md

# Should show your repo, not placeholder:
# https://github.com/awesome-robotics/momentum-repo/...
```

### 4. Commit and Push
```bash
git add README.md
git commit -m "docs: add CI status badges"
git push origin feat/badges
```

### 5. View on GitHub
1. Go to your repo on GitHub
2. Open README
3. See live badges! 🎉

---

## Before & After

### BEFORE (Placeholder)
```markdown
[![CI - Python](https://github.com/YOUR_GITHUB_USERNAME/REPO_NAME/actions/workflows/ci.yml/badge.svg)](https://github.com/YOUR_GITHUB_USERNAME/REPO_NAME/actions/workflows/ci.yml)
```

### AFTER (Your Repo)
```markdown
[![CI - Python](https://github.com/awesome-robotics/momentum-repo/actions/workflows/ci.yml/badge.svg)](https://github.com/awesome-robotics/momentum-repo/actions/workflows/ci.yml)
```

---

## What Each Badge Shows

| Badge | Shows | Status |
|-------|-------|--------|
| CI - Python | Python 3.11 tests | ✅ Passing / ❌ Failing |
| CI - Linting | Code quality (black, flake8) | ✅ Clean / ❌ Issues |
| CI - ROS | ROS Humble compatibility | ✅ Works / ❌ Broken |

---

## Expected Results

### ✅ After Setup (Green - All Good)
```
✅ CI - Python   [Passing]
✅ CI - Linting  [Passing]
✅ CI - ROS      [Passing]

Status Table:
Python: 3.11
ROS 2: Humble (Ubuntu 22.04)
Tests: pytest + coverage
Code Quality: black, flake8, isort
```

### ⏳ During First CI Run (Gray - Running)
Badges might show gray for 2-3 minutes while CI runs.

### ❌ If Tests Fail (Red - Issue)
Badges turn red:
```
✅ CI - Python   [Passing]
❌ CI - Linting  [Failing] ← Click for details
✅ CI - ROS      [Passing]
```

---

## One-Liner Commands

### Replace Locally
```bash
# All in one:
sed -i "s|YOUR_GITHUB_USERNAME/REPO_NAME|$(git remote get-url origin | sed 's|.*://.*[:/]||; s|\.git||')|g" README.md
```

### Verify It Worked
```bash
grep -c "YOUR_GITHUB" README.md
# Should output: 0 (no placeholders left)

grep -c "github.com" README.md
# Should output: 3 (three badges)
```

### Show Badge URLs
```bash
grep "github.com" README.md | head -3
```

---

## Troubleshooting Quick Fixes

### Badge Shows Unknown/Gray
→ CI hasn't run yet. Wait 2-3 min after first push.

### Badge URL is broken
→ You didn't replace placeholders correctly.
```bash
# Check current content
cat README.md | grep "YOUR_GITHUB"

# If still shows placeholder, update it:
sed -i 's|YOUR_GITHUB_USERNAME/REPO_NAME|your-user/your-repo|g' README.md
```

### Badges not visible in preview
→ You're editing on GitHub web interface.
→ Clone locally, edit, push, then view on GitHub.

---

## Done! ✅

After these steps:
- Your README shows live CI status
- Team sees "Tests passing ✓"
- Badges link to full CI history
- Status updates automatically

**Next?** Push your code and watch badges turn green! 🚀
