# GitHub Actions Workflows

This directory contains CI/CD workflows for the Convooy project.

## Workflows

### Backend Tests (`backend-tests.yml`)

Automatically runs the backend test suite when changes are made to the backend code.

**Triggers:**
- Pull requests that modify files in `backend/`
- Pushes to `main` branch that modify files in `backend/`

**What it does:**
1. Sets up Node.js 22
2. Starts a PostgreSQL test database
3. Installs dependencies
4. Generates Prisma client
5. Pushes database schema
6. Runs all tests with coverage
7. Uploads coverage reports to Codecov (optional)
8. Comments PR with coverage report (optional)

**Environment:**
- **OS**: Ubuntu Latest
- **Node**: 22.x
- **Database**: PostgreSQL 15 (Alpine)
- **Test Database**: `convooy_test`

**Required Secrets (Optional):**
- `CODECOV_TOKEN` - For uploading coverage reports to Codecov

**Duration:** ~2-3 minutes

### Features

✅ **Path Filtering**: Only runs when backend files change  
✅ **PostgreSQL Service**: Automatic test database setup  
✅ **Coverage Reports**: Generates and uploads test coverage  
✅ **PR Comments**: Automatically comments coverage on PRs  
✅ **Fast**: Uses Yarn cache for quick installs  

## Local Testing

To test the workflow locally, you can use [act](https://github.com/nektos/act):

```bash
# Install act
brew install act

# Run the backend tests workflow
act pull_request -W .github/workflows/backend-tests.yml
```

## Adding New Workflows

When adding new workflows:

1. Create a new `.yml` file in this directory
2. Follow the naming convention: `{component}-{action}.yml`
3. Add appropriate triggers (push, pull_request, etc.)
4. Use path filters to only run when relevant files change
5. Document the workflow in this README

## Troubleshooting

### Tests fail in CI but pass locally

- Check that the database connection string is correct
- Ensure all environment variables are set
- Verify Node.js version matches (22.x)

### Slow test runs

- Check if Yarn cache is being used
- Consider splitting tests into multiple jobs
- Review database startup time

### Coverage upload fails

- Verify `CODECOV_TOKEN` is set in repository secrets
- Check Codecov service status
- Ensure `lcov.info` file is being generated

## Status Badges

Add this badge to your README to show test status:

```markdown
[![Backend Tests](https://github.com/YOUR_ORG/convooy/actions/workflows/backend-tests.yml/badge.svg)](https://github.com/YOUR_ORG/convooy/actions/workflows/backend-tests.yml)
```

