#!/bin/bash

# Ensure test database is running and ready
# This script is called before running tests to make sure the database is available

set -e

# Skip Docker operations in CI environments (GitHub Actions, etc.)
if [ -n "$CI" ]; then
  echo "🔧 Running in CI environment - skipping Docker checks"
  exit 0
fi

# Function to check if PostgreSQL is running
check_postgres() {
  docker ps --filter "name=convooy-postgres" --filter "status=running" --format "{{.Names}}" | grep -q "convooy-postgres"
}

# Function to check if database is healthy
check_db_health() {
  docker exec convooy-postgres pg_isready -U convooy_user -d convooy_test > /dev/null 2>&1
}

# Function to check if test database exists
check_test_db_exists() {
  docker exec convooy-postgres psql -U convooy_user -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='convooy_test'" | grep -q 1
}

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
  echo "❌ Error: Docker is not running. Please start Docker first."
  exit 1
fi

# Check if PostgreSQL container is running
if ! check_postgres; then
  echo "📦 Starting PostgreSQL container..."
  docker compose up -d postgres
  
  # Wait for PostgreSQL to be ready
  echo "⏳ Waiting for PostgreSQL to be ready..."
  sleep 3
  
  # Wait until database is healthy
  attempts=0
  max_attempts=30
  until check_db_health || [ $attempts -eq $max_attempts ]; do
    attempts=$((attempts+1))
    sleep 1
  done
  
  if [ $attempts -eq $max_attempts ]; then
    echo "❌ Error: PostgreSQL failed to start within 30 seconds"
    exit 1
  fi
  
  echo "✅ PostgreSQL is running"
else
  # Just verify it's healthy
  if ! check_db_health; then
    echo "⏳ Waiting for PostgreSQL to be healthy..."
    sleep 2
  fi
fi

# Check if test database exists
if ! check_test_db_exists; then
  echo "🗄️  Creating test database..."
  docker exec convooy-postgres psql -U convooy_user -d postgres -c "CREATE DATABASE convooy_test;" > /dev/null 2>&1 || true
  
  # Push Prisma schema
  echo "📊 Pushing Prisma schema to test database..."
  DATABASE_URL="postgresql://convooy_user:convooy_password@localhost:5432/convooy_test" npx prisma db push --skip-generate > /dev/null 2>&1
  
  echo "✅ Test database created and initialized"
fi

# All checks passed
exit 0

