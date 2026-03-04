#!/usr/bin/env bash
#
# Deploy Secure Tunneling Component to Greengrass Nucleus Lite
#
# This script creates/updates the Greengrass component and deploys it to devices
#

set -e

# Configuration
COMPONENT_NAME="com.bartrack.SecureTunneling"
COMPONENT_VERSION="${1:-1.0.25}"
AWS_REGION="us-east-1"
AWS_ACCOUNT="374401410677"
AWS_PROFILE="${AWS_PROFILE:-bt-dev}"
THING_NAME="${2:-bcm-02c000816015bfa8}"  # Orange Pi Zero device

echo "========================================="
echo "Deploying Secure Tunneling to Greengrass"
echo "========================================="
echo ""
echo "Component: $COMPONENT_NAME"
echo "Version: $COMPONENT_VERSION"
echo "Region: $AWS_REGION"
echo "Profile: $AWS_PROFILE"
echo "Target Device: $THING_NAME"
echo ""

# Use the v1.0.25 recipe file
RECIPE_FILE="recipe-nucleus-lite-v1.0.25.yaml"
echo "Using recipe file: $RECIPE_FILE"

# Create the component
echo ""
echo "Creating/updating Greengrass component..."
aws greengrassv2 create-component-version \
  --inline-recipe fileb://$RECIPE_FILE \
  --region $AWS_REGION \
  --profile $AWS_PROFILE

echo ""
echo "Component created successfully!"

# Get the thing's core device name (for Nucleus Lite, thing name = core device name)
CORE_DEVICE_NAME="$THING_NAME"

echo ""
echo "Creating deployment for device: $CORE_DEVICE_NAME"

# Create deployment JSON
cat > /tmp/deployment-$THING_NAME.json << EOF
{
  "targetArn": "arn:aws:iot:$AWS_REGION:362106343162:thing/$CORE_DEVICE_NAME",
  "deploymentName": "SecureTunneling-$THING_NAME-$(date +%Y%m%d-%H%M%S)",
  "components": {
    "$COMPONENT_NAME": {
      "componentVersion": "$COMPONENT_VERSION",
      "configurationUpdate": {
        "merge": "{\"dockerImage\":\"362106343162.dkr.ecr.us-east-2.amazonaws.com/secure-tunneling:$COMPONENT_VERSION\",\"containerName\":\"secure-tunneling\"}"
      }
    }
  },
  "deploymentPolicies": {
    "failureHandlingPolicy": "ROLLBACK",
    "componentUpdatePolicy": {
      "timeoutInSeconds": 300,
      "action": "NOTIFY_COMPONENTS"
    },
    "configurationValidationPolicy": {
      "timeoutInSeconds": 60
    }
  }
}
EOF

# Deploy to device
echo ""
echo "Deploying component to device..."
DEPLOYMENT_ID=$(aws greengrassv2 create-deployment \
  --cli-input-json file:///tmp/deployment-$THING_NAME.json \
  --region $AWS_REGION \
  --profile $AWS_PROFILE \
  --query 'deploymentId' \
  --output text)

echo ""
echo "========================================="
echo "Deployment Created!"
echo "========================================="
echo ""
echo "Deployment ID: $DEPLOYMENT_ID"
echo "Component: $COMPONENT_NAME v$COMPONENT_VERSION"
echo "Device: $CORE_DEVICE_NAME"
echo ""
echo "Check deployment status:"
echo "  aws greengrassv2 get-deployment \\"
echo "    --deployment-id $DEPLOYMENT_ID \\"
echo "    --region $AWS_REGION \\"
echo "    --profile $AWS_PROFILE"
echo ""
echo "Monitor component on device:"
echo "  ssh bartrack@orangepizero"
echo "  sudo docker ps"
echo "  sudo docker logs secure-tunneling"
echo ""

# Clean up
rm /tmp/deployment-$THING_NAME.json
