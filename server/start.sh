#!/bin/bash

# MulaMail Server Startup Script
# This script helps you start the server with proper configuration

set -e

echo "🚀 MulaMail 2 Server Startup"
echo "=============================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if MongoDB is running
check_mongodb() {
    if ! nc -z localhost 27017 2>/dev/null; then
        return 1
    fi
    return 0
}

# Check prerequisites
echo "📋 Checking prerequisites..."

if ! command_exists go; then
    echo -e "${RED}❌ Go is not installed${NC}"
    echo "Please install Go 1.22 or later: https://golang.org/dl/"
    exit 1
fi
echo -e "${GREEN}✓${NC} Go found: $(go version)"

if ! command_exists docker; then
    echo -e "${YELLOW}⚠${NC} Docker not found (optional, but recommended for MongoDB)"
fi

# Check MongoDB
echo ""
echo "🔍 Checking MongoDB..."
if check_mongodb; then
    echo -e "${GREEN}✓${NC} MongoDB is running on localhost:27017"
else
    echo -e "${YELLOW}⚠${NC} MongoDB is not running"
    echo ""
    echo "Would you like to start MongoDB using Docker? (y/n)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        if command_exists docker; then
            echo "Starting MongoDB..."
            docker run -d \
                --name mulamail-mongo \
                -p 27017:27017 \
                -v mulamail-data:/data/db \
                mongo:latest 2>/dev/null || docker start mulamail-mongo

            echo "Waiting for MongoDB to start..."
            sleep 3

            if check_mongodb; then
                echo -e "${GREEN}✓${NC} MongoDB started successfully"
            else
                echo -e "${RED}❌ Failed to start MongoDB${NC}"
                exit 1
            fi
        else
            echo -e "${RED}❌ Docker is not installed${NC}"
            echo "Please install Docker or start MongoDB manually"
            exit 1
        fi
    else
        echo "Please start MongoDB manually and run this script again"
        exit 1
    fi
fi

# Check/Set environment variables
echo ""
echo "🔧 Configuring environment variables..."

# Port
if [ -z "$PORT" ]; then
    export PORT="8080"
    echo "Using default PORT: $PORT"
fi

# MongoDB URI
if [ -z "$MONGO_URI" ]; then
    export MONGO_URI="mongodb://localhost:27017"
    echo "Using default MONGO_URI: $MONGO_URI"
fi

# MongoDB Database
if [ -z "$MONGO_DB" ]; then
    export MONGO_DB="mulamail"
    echo "Using default MONGO_DB: $MONGO_DB"
fi

# Solana RPC
if [ -z "$SOLANA_RPC" ]; then
    export SOLANA_RPC="https://api.devnet.solana.com"
    echo -e "${YELLOW}Using devnet:${NC} $SOLANA_RPC"
    echo "For production, set: export SOLANA_RPC=https://api.mainnet-beta.solana.com"
fi

# Encryption Key (CRITICAL)
if [ -z "$ENCRYPTION_KEY" ]; then
    echo ""
    echo -e "${YELLOW}⚠️  WARNING: No ENCRYPTION_KEY set!${NC}"
    echo ""
    echo "Would you like to generate a new encryption key? (y/n)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        export ENCRYPTION_KEY=$(openssl rand -hex 32)
        echo -e "${GREEN}✓${NC} Generated new encryption key"
        echo ""
        echo "IMPORTANT: Save this encryption key for future use:"
        echo "export ENCRYPTION_KEY=\"$ENCRYPTION_KEY\""
        echo ""
        echo "Add it to your .bashrc or .zshrc to persist it"
        echo ""
        echo "Press Enter to continue..."
        read -r
    else
        echo "Using insecure default key (DO NOT USE IN PRODUCTION)"
        export ENCRYPTION_KEY="0000000000000000000000000000000000000000000000000000000000000000"
    fi
else
    echo -e "${GREEN}✓${NC} ENCRYPTION_KEY is set"
fi

# AWS (optional)
if [ -z "$AWS_REGION" ]; then
    export AWS_REGION="us-east-1"
fi
if [ -z "$S3_BUCKET" ]; then
    export S3_BUCKET="mulamail-vault"
fi

echo ""
echo "📦 Current Configuration:"
echo "------------------------"
echo "PORT:           $PORT"
echo "MONGO_URI:      $MONGO_URI"
echo "MONGO_DB:       $MONGO_DB"
echo "SOLANA_RPC:     $SOLANA_RPC"
echo "AWS_REGION:     $AWS_REGION"
echo "S3_BUCKET:      $S3_BUCKET"
echo "ENCRYPTION_KEY: ${ENCRYPTION_KEY:0:16}... (hidden)"
echo ""

# Install dependencies
echo "📥 Installing Go dependencies..."
go mod download

# Build or run
echo ""
echo "How would you like to start the server?"
echo "1) Run directly (go run)"
echo "2) Build and run binary"
echo "3) Run tests first, then start"
echo ""
read -p "Choose option [1-3]: " option

case $option in
    1)
        echo ""
        echo "🚀 Starting server..."
        echo ""
        go run main.go
        ;;
    2)
        echo ""
        echo "🔨 Building server..."
        go build -o mulamail-server main.go
        echo -e "${GREEN}✓${NC} Build complete: ./mulamail-server"
        echo ""
        echo "🚀 Starting server..."
        echo ""
        ./mulamail-server
        ;;
    3)
        echo ""
        echo "🧪 Running tests..."
        echo ""
        make test-unit || go test ./vault ./config ./blockchain ./api

        if [ $? -eq 0 ]; then
            echo ""
            echo -e "${GREEN}✓${NC} All tests passed!"
            echo ""
            echo "🚀 Starting server..."
            echo ""
            go run main.go
        else
            echo ""
            echo -e "${RED}❌ Tests failed${NC}"
            echo "Fix the tests before starting the server"
            exit 1
        fi
        ;;
    *)
        echo "Invalid option. Running directly..."
        go run main.go
        ;;
esac
