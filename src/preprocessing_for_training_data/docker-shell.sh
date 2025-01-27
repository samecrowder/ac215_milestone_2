#!/bin/bash

# exit immediately if a command exits with a non-zero status
set -e

export IMAGE_NAME=${IMAGE_NAME:-"preprocessing-for-training-data"}
export BASE_DIR=$(pwd)
export SECRETS_DIR=${SECRETS_DIR:-"$BASE_DIR/../../../secrets"}
export GCP_PROJECT=${GCP_PROJECT:-"tennis-match-predictor"}
export GCP_ZONE=${GCP_ZONE:-"us-central1-a"}
export GCS_BUCKET_NAME=${GCS_BUCKET_NAME:-"msmballstars-data"}
export DATA_FOLDER=${DATA_FOLDER:-"version3"}
export DATA_FILE=${DATA_FILE:-"combined_atp_matches.csv"}
export LOOKBACK=${LOOKBACK:-10}
export GOOGLE_APPLICATION_CREDENTIALS=${GOOGLE_APPLICATION_CREDENTIALS:-"/secrets/data-service-account.json"}

# Check to see if path to secrets is correct
if [ ! -f "$SECRETS_DIR/data-service-account.json" ]; then
    echo "data-service-account.json not found at the path you have provided."
    exit 1
fi

# Build the image based on the Dockerfile
docker build -t $IMAGE_NAME -f Dockerfile .

echo "Host GOOGLE_APPLICATION_CREDENTIALS: $GOOGLE_APPLICATION_CREDENTIALS"

# Run the container
docker run --rm -it \
--mount type=bind,source="$BASE_DIR",target=/app \
--mount type=bind,source="$SECRETS_DIR",target=/secrets \
-e GOOGLE_APPLICATION_CREDENTIALS=$GOOGLE_APPLICATION_CREDENTIALS \
-e GCP_PROJECT="$GCP_PROJECT" \
-e GCP_ZONE=$GCP_ZONE \
-e GCS_BUCKET_NAME=$GCS_BUCKET_NAME \
-e DATA_FOLDER=$DATA_FOLDER \
-e DATA_FILE=$DATA_FILE \
-e LOOKBACK=$LOOKBACK \
-e DEV=1 $IMAGE_NAME
