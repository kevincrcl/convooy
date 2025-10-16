#!/bin/bash

# Setup test database for Convooy backend tests
# This script creates a test database and pushes the Prisma schema

set -e

echo "🔧 Setting up test database..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
  echo "❌ Docker is not running. Please start Docker first."
  exit 1
fi

# Start database services if not already running
echo "📦 Starting database services..."
docker compose up -d postgres

# Wait for PostgreSQL to be ready
echo "⏳ Waiting for PostgreSQL to be ready..."
sleep 3

# Check if test database exists, create if not
echo "🗄️  Creating test database if it doesn't exist..."
docker exec convooy-postgres psql -U convooy_user -d postgres -tc "SELECT 1 FROM pg_database WHERE datname = 'convooy_test'" | grep -q 1 || \
  docker exec convooy-postgres psql -U convooy_user -d postgres -c "CREATE DATABASE convooy_test;"

# Push Prisma schema to test database
echo "📊 Pushing Prisma schema to test database..."
DATABASE_URL="postgresql://convooy_user:convooy_password@localhost:5432/convooy_test" yarn db:push

echo "✅ Test database setup complete!"
echo ""
echo "You can now run tests with: yarn test"

