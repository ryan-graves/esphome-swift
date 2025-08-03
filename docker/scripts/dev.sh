#!/bin/bash
# Development shell script for ESPHome Swift Docker environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🐳 ESPHome Swift - Docker Development Environment${NC}"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running. Please start Docker Desktop.${NC}"
    exit 1
fi

# Build the image if it doesn't exist or if --build is passed
if [[ "$1" == "--build" ]] || ! docker images | grep -q "esphome-swift.*embedded"; then
    echo -e "${YELLOW}📦 Building Docker image...${NC}"
    docker compose build swift-embedded
fi

# Run the development shell
echo -e "${GREEN}🚀 Starting development shell...${NC}"
echo -e "${YELLOW}Tips:${NC}"
echo "  - Your project is mounted at /workspace/esphome-swift"
echo "  - Swift Embedded is available with 'swift build'"
echo "  - Exit with 'exit' or Ctrl+D"
echo ""

docker compose run --rm swift-embedded /bin/bash