#!/usr/bin/env bash
#
# Build Containerized Secure Tunneling for ARMv7 and Push to ECR
#
# This script builds the secure tunneling container for ARM architecture
# and pushes it to AWS ECR for deployment to Orange Pi Zero devices.
#

set -e

# Configuration
AWS_PROFILE="bt-dev"
AWS_ACCOUNT="374401410677"
ECR_REGISTRY="${AWS_ACCOUNT}.dkr.ecr.us-east-1.amazonaws.com"
ECR_REPO="secure-tunneling"
AWS_REGION="us-east-1"
VERSION="${1:-1.0.25}"
PLATFORM="linux/arm/v7"

echo "========================================="
echo "Building Secure Tunneling Container"
echo "========================================="
echo ""
echo "Platform: $PLATFORM"
echo "Version: $VERSION"
echo "ECR Registry: $ECR_REGISTRY"
echo "ECR Repository: $ECR_REPO"
echo ""

# Check if Docker is running
if ! docker info &> /dev/null; then
  echo "ERROR: Docker is not running"
  echo "Please start Docker Desktop"
  exit 1
fi

# Login to ECR
echo "Logging in to ECR..."
aws ecr get-login-password --region $AWS_REGION --profile $AWS_PROFILE | docker login --username AWS --password-stdin $ECR_REGISTRY

# Create ECR repository if it doesn't exist
echo "Ensuring ECR repository exists..."
aws ecr describe-repositories --repository-names $ECR_REPO --region $AWS_REGION --profile $AWS_PROFILE &>/dev/null || \
  aws ecr create-repository --repository-name $ECR_REPO --region $AWS_REGION --profile $AWS_PROFILE

# Build the Docker image for ARMv7
echo ""
echo "Building Docker image for $PLATFORM..."
cd src
docker buildx build \
  --platform $PLATFORM \
  --tag $ECR_REGISTRY/$ECR_REPO:$VERSION \
  --tag $ECR_REGISTRY/$ECR_REPO:latest \
  --load \
  .

cd ..

# Verify the image
echo ""
echo "Verifying image..."
docker images | grep $ECR_REPO

# Push to ECR
echo ""
echo "Pushing to ECR..."
docker push $ECR_REGISTRY/$ECR_REPO:$VERSION
docker push $ECR_REGISTRY/$ECR_REPO:latest

echo ""
echo "========================================="
echo "Build and Push Complete!"
echo "========================================="
echo ""
echo "Image: $ECR_REGISTRY/$ECR_REPO:$VERSION"
echo "Latest: $ECR_REGISTRY/$ECR_REPO:latest"
echo ""
echo "Next steps:"
echo "  1. Update Greengrass recipe to use this ECR image"
echo "  2. Deploy component to Orange Pi Zero devices"
echo ""
