#!/bin/bash

# the high level structure of this script needs to be kept in sync
# with the deploy.yml workflow. we don't call it directly because we want
# to have parallel builds for each service in the workflow.

# Required environment variables:
# PROJECT_ID: GCP project ID
# IMAGE_TAG: Tag for the image (usually git SHA)

set -e

# print usage function
function print_usage() {
    echo "Usage: $0 <LLM_MODEL> <CREDENTIALS_FILE>"
    echo "LLM_MODEL: The LLM model to use"
    echo "CREDENTIALS_FILE: The path to the credentials file"
}

# if arg is passed, use it as the LLM_MODEL
# otherwise log out fallback value
if [ -n "$1" ]; then
    LLM_MODEL=$1
else
    print_usage
    LLM_MODEL="llama3.2:1b"
    echo "LLM_MODEL is not set, using fallback value: $LLM_MODEL"
fi

if [ -n "$2" ]; then
    CREDENTIALS_FILE=$2
else
    print_usage
    exit 1
fi

# Configuration
REGION="us-central1"
SERVICES=(
    "api:Dockerfile:src/api:"
    "probability-model:Dockerfile:src/probability_model:"
    "llm:Dockerfile:src/llm:"
    "ollama:ollama.Dockerfile:src/llm:--build-arg LLM_MODEL=${LLM_MODEL}"
)

# Setup GCP authentication
echo "Setting up GCP authentication..."
gcloud auth configure-docker

# Build and push all services sequentially
for service in "${SERVICES[@]}"; do
    IFS=: read -r SERVICE_NAME DOCKERFILE SERVICE_PATH BUILD_ARGS <<< "$service"
    
    echo -e "\n=== Building $SERVICE_NAME ===\n"
    export SERVICE_NAME DOCKERFILE SERVICE_PATH BUILD_ARGS
    if ! ./docker-build-and-push.sh; then
        echo "Failed to build $SERVICE_NAME"
        exit 1
    fi
done

./ansible-deploy.sh "$LLM_MODEL" "$CREDENTIALS_FILE"