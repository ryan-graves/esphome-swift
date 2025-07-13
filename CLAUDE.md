# ESPHome Swift - Development Guidelines

This file contains development guidelines, branching strategy, and other information to help contributors and maintainers work effectively with this repository.

## Branching Strategy

ESPHome Swift follows a **Git Flow inspired** branching strategy optimized for continuous integration and collaborative development.

### Branch Types

#### **Primary Branches**

1. **`main`** - Production Branch
   - Contains production-ready, stable code
   - Protected branch with required reviews
   - Only accepts merges from `develop` or `hotfix/` branches
   - Tagged for releases (`v1.0.0`, `v1.1.0`, etc.)
   - Deploys automatically trigger documentation updates

2. **`develop`** - Integration Branch
   - Integration branch for all new features
   - Contains latest development changes
   - Base branch for all `feature/` and `fix/` branches
   - Continuously tested via CI/CD
   - Merged to `main` for releases

#### **Supporting Branches**

3. **`feature/`** - Feature Development
   - For new features and enhancements
   - Branch from: `develop`
   - Merge back to: `develop`
   - Naming: `feature/description-of-feature`
   - Examples:
     - `feature/add-i2c-sensor-support`
     - `feature/implement-matter-protocol`
     - `feature/web-dashboard-improvements`

4. **`fix/`** - Bug Fixes
   - For non-critical bug fixes and improvements
   - Branch from: `develop`
   - Merge back to: `develop`
   - Naming: `fix/description-of-fix`
   - Examples:
     - `fix/dht-sensor-timeout-issue`
     - `fix/gpio-pin-validation-error`
     - `fix/memory-leak-in-wifi-module`

5. **`docs/`** - Documentation
   - For documentation updates and improvements
   - Branch from: `develop`
   - Merge back to: `develop`
   - Naming: `docs/description-of-changes`
   - Examples:
     - `docs/update-getting-started-guide`
     - `docs/add-component-examples`
     - `docs/fix-configuration-reference`

6. **`release/`** - Release Preparation
   - For preparing new releases
   - Branch from: `develop`
   - Merge to: `main` and `develop`
   - Naming: `release/vX.Y.Z`
   - Examples:
     - `release/v1.0.0`
     - `release/v1.2.0-beta.1`

7. **`hotfix/`** - Critical Fixes
   - For critical production fixes that can't wait for next release
   - Branch from: `main`
   - Merge to: `main` and `develop`
   - Naming: `hotfix/description-of-fix`
   - Examples:
     - `hotfix/critical-security-vulnerability`
     - `hotfix/build-system-failure`

### Branch Naming Conventions

**Format:** `type/descriptive-name-in-kebab-case`

**Guidelines:**
- Use lowercase letters and hyphens
- Be descriptive but concise
- Include issue number if applicable: `feature/123-add-spi-support`
- Avoid special characters, spaces, or underscores

**Examples:**
```
feature/add-bluetooth-mesh-support
fix/incorrect-pin-validation
docs/update-component-library
release/v1.1.0
hotfix/memory-overflow-in-parser
```

### Workflow

#### **Standard Feature Development**

1. **Start from develop:**
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/your-feature-name
   ```

2. **Develop and commit:**
   ```bash
   git add .
   git commit -m "feat: add new component support"
   git push origin feature/your-feature-name
   ```

3. **Create Pull Request:**
   - Target: `develop` branch
   - Include description, testing notes
   - Link related issues
   - Request appropriate reviewers

4. **After merge:**
   ```bash
   git checkout develop
   git pull origin develop
   git branch -d feature/your-feature-name
   ```

#### **Bug Fix Workflow**

1. **Start from develop:**
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b fix/bug-description
   ```

2. **Follow same process as features**
   - Target `develop` branch in PR
   - Include reproduction steps and fix details

#### **Release Workflow**

1. **Create release branch:**
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b release/v1.2.0
   ```

2. **Prepare release:**
   - Update version numbers
   - Update CHANGELOG.md
   - Final testing and bug fixes
   - Update documentation

3. **Merge to main:**
   ```bash
   # Create PR: release/v1.2.0 → main
   # After merge, tag the release
   git checkout main
   git pull origin main
   git tag -a v1.2.0 -m "Release version 1.2.0"
   git push origin v1.2.0
   ```

4. **Merge back to develop:**
   ```bash
   # Create PR: release/v1.2.0 → develop (or main → develop)
   ```

#### **Hotfix Workflow**

1. **Start from main:**
   ```bash
   git checkout main
   git pull origin main
   git checkout -b hotfix/critical-issue-description
   ```

2. **Fix and test thoroughly**

3. **Merge to main first:**
   ```bash
   # Create PR: hotfix/critical-issue → main
   # Tag immediately after merge
   git tag -a v1.2.1 -m "Hotfix version 1.2.1"
   git push origin v1.2.1
   ```

4. **Merge to develop:**
   ```bash
   # Create PR: hotfix/critical-issue → develop
   ```

### Pull Request Guidelines

#### **Required Information**
- **Title:** Clear, descriptive title following conventional commits
- **Description:** What changes were made and why
- **Testing:** How the changes were tested
- **Breaking Changes:** Any breaking changes and migration notes
- **Related Issues:** Link to GitHub issues

#### **Review Requirements**
- At least 1 approval for `feature/` and `fix/` branches
- At least 2 approvals for `release/` and `hotfix/` branches
- All CI checks must pass
- No merge conflicts

#### **Merge Strategy**
- **Feature/Fix branches:** Squash and merge (clean history)
- **Release branches:** Create merge commit (preserve release branch)
- **Hotfix branches:** Create merge commit (preserve critical fix history)

### Protected Branches

#### **`main` Branch Protection**
- Require pull request reviews (2 required)
- Dismiss stale PR approvals when new commits are pushed
- Require status checks to pass before merging
- Require branches to be up to date before merging
- Include administrators in restrictions
- Allow force pushes: **NO**
- Allow deletions: **NO**

#### **`develop` Branch Protection**
- Require pull request reviews (1 required)
- Require status checks to pass before merging
- Require branches to be up to date before merging
- Allow force pushes: **NO**
- Allow deletions: **NO**

### Commit Message Guidelines

Follow [Conventional Commits](https://www.conventionalcommits.org/) specification:

**Format:** `type(scope): description`

**Types:**
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `style:` Code style changes (formatting, missing semicolons, etc.)
- `refactor:` Code refactoring
- `test:` Adding or updating tests
- `chore:` Maintenance tasks
- `ci:` CI/CD changes

**Examples:**
```
feat(sensors): add BME280 temperature sensor support
fix(gpio): resolve pin validation for ESP32-C6
docs(readme): update installation instructions
style(core): fix SwiftLint violations in Configuration.swift
refactor(cli): simplify command argument parsing
test(components): add unit tests for DHT sensor factory
chore(deps): update Swift package dependencies
ci(actions): add cross-platform testing support
```

### Release Management

#### **Version Numbering**
Follow [Semantic Versioning](https://semver.org/): `MAJOR.MINOR.PATCH`

- **MAJOR:** Breaking changes, incompatible API changes
- **MINOR:** New features, backward-compatible additions
- **PATCH:** Bug fixes, backward-compatible fixes

#### **Release Process**
1. Create `release/vX.Y.Z` branch from `develop`
2. Update version numbers and changelog
3. Test thoroughly across all supported platforms
4. Create PR to `main` with detailed release notes
5. After merge, create GitHub release with tags
6. Merge release branch back to `develop`

#### **Pre-release Versions**
For beta/alpha releases: `v1.2.0-beta.1`, `v1.2.0-alpha.2`

### Branch Cleanup

#### **Automatic Cleanup**
- GitHub is configured to automatically delete head branches after PR merge
- Stale branches (>30 days inactive) will be reviewed monthly

#### **Manual Cleanup**
```bash
# Delete local branches that have been merged
git branch --merged develop | grep -v "\*\|develop\|main" | xargs -n 1 git branch -d

# Delete remote tracking branches that no longer exist
git remote prune origin
```

### Emergency Procedures

#### **Broken Main Branch**
1. Create hotfix branch from last known good commit
2. Fix the issue and thoroughly test
3. Create emergency PR with multiple reviewer approval
4. Consider reverting problematic commits if fix is complex

#### **Failed Release**
1. Stop release process immediately
2. Create hotfix if users are affected
3. Document what went wrong
4. Fix issues in develop branch
5. Start new release process

### Code Quality Standards

#### **Required Checks**
- All tests must pass (unit, integration)
- SwiftLint validation (macOS)
- SwiftFormat validation (cross-platform)
- Build succeeds on macOS and Linux
- Documentation builds successfully

#### **Performance Considerations**
- Memory usage profiling for embedded targets
- Build time optimization
- Package size considerations for CLI distribution

### Integration with GitHub

#### **Branch Protection Rules**
- Configured via GitHub repository settings
- Enforced for `main` and `develop` branches
- Includes status check requirements

#### **GitHub Actions Integration**
- CI runs on all PR branches
- Different workflow triggers for different branch types
- Automated release creation for version tags

#### **Issue Integration**
- Link PRs to issues using keywords: "Closes #123"
- Use issue templates for consistent reporting
- Label branches based on issue types

---

## Development Environment Setup

### **Required Tools**
- Swift 5.9+ (Swift 6.0+ recommended)
- SwiftLint (macOS only)
- SwiftFormat (cross-platform)
- ESP-IDF v5.3+ (for testing firmware generation)

### **Recommended IDE Setup**
- Xcode (macOS) with SwiftLint integration
- VS Code with Swift extensions
- Vim/Neovim with Swift LSP support

### **Pre-commit Hooks**
Consider setting up pre-commit hooks for:
- SwiftLint validation
- SwiftFormat auto-formatting
- Commit message validation
- Basic test execution

---

**Last Updated:** January 2025
**Maintainer:** @ryan-graves
**Review Schedule:** Quarterly or as needed for project evolution