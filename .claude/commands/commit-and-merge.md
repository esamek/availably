# Commit and Merge Command

**Usage:** `/commit-and-merge [commit-message]`

## Description
Automates the complete git workflow: commit changes, push branch, create PR, check merge status, and auto-merge if no conflicts exist.

## Command Flow

### 1. Pre-flight Checks
```bash
# Check git status and show changes
git status
git diff --name-only
```

### 2. Commit Changes
```bash
# Stage all changes
git add .

# Create commit with provided or auto-generated message
git commit -m "commit-message

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

### 3. Push to Origin
```bash
# Push current branch with upstream tracking
git push -u origin $(git branch --show-current)
```

### 4. Create Pull Request
```bash
# Create PR with auto-generated title and body
gh pr create --title "commit-message" --body "## Summary
- [Auto-generated summary based on changes]

## Test Plan
- [x] Verify changes work as expected
- [x] Check for any breaking changes
- [x] Confirm tests pass (if applicable)

🤖 Generated with [Claude Code](https://claude.ai/code)"
```

### 5. Check Merge Status
```bash
# Check if PR is mergeable
gh pr view --json mergeable,mergeStateStatus
```

### 6. Auto-Merge (if possible)
```bash
# Merge with squash and delete branch if no conflicts
gh pr merge --squash --delete-branch

# Switch back to main and pull latest
git checkout main
git pull origin main
```

## Auto-Generated Commit Messages
When no commit message is provided, the command generates one based on:
- Modified files detected
- Type of changes (new features, fixes, docs, etc.)
- Branch name context

### Examples:
- `"Update CLAUDE.md with planning strategy"`
- `"Add new timeline component with drag selection"`
- `"Fix mobile responsive issues in navigation"`
- `"Refactor color system utilities"`

## Error Handling

### Merge Conflicts
If conflicts are detected:
```
❌ Merge conflicts detected in PR #X
   Manual resolution required before merging.
   
   Next steps:
   1. Resolve conflicts in GitHub UI or locally
   2. Re-run command to attempt merge
```

### Failed Checks
If CI/CD checks fail:
```
❌ PR checks failed - merge blocked
   
   Next steps:
   1. Review failed checks in GitHub
   2. Fix issues and push updates
   3. Re-run command when checks pass
```

### Missing Dependencies
If `gh` CLI is not available:
```
❌ GitHub CLI (gh) not found
   
   Install with: brew install gh
   Then authenticate: gh auth login
```

## Usage Examples

### With custom commit message:
```
/commit-and-merge "Add user authentication system"
```

### With auto-generated message:
```
/commit-and-merge
```

### Output on success:
```
✅ Commit created: abc123d
✅ Branch pushed: feature-branch
✅ PR created: #42
✅ Merge status: CLEAN
✅ PR merged and branch deleted
✅ Main branch updated
```

## Command Benefits
- **Speed**: Complete workflow in single command
- **Consistency**: Standardized commit messages and PR format
- **Safety**: Checks for conflicts before merging
- **Cleanup**: Automatic branch deletion after merge
- **Visibility**: Clear status reporting throughout process

## Integration Notes
This command integrates seamlessly with:
- Claude Code todo tracking
- Planning document workflow
- Git branching strategy
- GitHub PR templates
- Project CLAUDE.md guidelines