#!/bin/bash

# Convooy Backend Setup Script
echo "🚀 Setting up Convooy Backend..."

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js 22+ first."
    exit 1
fi

# Check Node.js version
NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 22 ]; then
    echo "❌ Node.js version 22+ is required. Current version: $(node -v)"
    exit 1
fi

echo "✅ Node.js $(node -v) detected"

# Install dependencies
echo "📦 Installing dependencies..."
npm install

# Copy environment file if it doesn't exist
if [ ! -f .env ]; then
    echo "📝 Creating .env file from template..."
    cp env.example .env
    echo "⚠️  Please edit .env file with your database credentials"
else
    echo "✅ .env file already exists"
fi

# Check if Docker is available
if command -v docker &> /dev/null; then
    echo "🐳 Docker detected"
    
    # Ask if user wants to start PostgreSQL with Docker
    read -p "Do you want to start PostgreSQL with Docker? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🚀 Starting PostgreSQL container..."
        docker-compose up postgres -d
        
        # Wait for PostgreSQL to be ready
        echo "⏳ Waiting for PostgreSQL to be ready..."
        sleep 5
        
        # Generate Prisma client and push schema
        echo "🗄️  Setting up database..."
        npm run db:generate
        npm run db:push
        
        echo "✅ Database setup complete!"
    fi
else
    echo "⚠️  Docker not found. Please ensure PostgreSQL is running manually."
fi

echo ""
echo "🎉 Setup complete!"
echo ""
echo "Next steps:"
echo "1. Edit .env file with your configuration"
echo "2. Run 'npm run dev' to start the development server"
echo "3. Visit http://localhost:3001/api/health to verify the API is running"
echo ""
echo "Available commands:"
echo "  npm run dev      - Start development server"
echo "  npm run build    - Build for production"
echo "  npm run db:studio - Open Prisma Studio"
echo "  npm run lint     - Run linter"
echo ""
