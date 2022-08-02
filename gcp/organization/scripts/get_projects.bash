#!/usr/bin/env bash

gcloud projects list --billing-project=BILLING_PROJECT_ID --format=json > projects.json

# Filter the projects in the app-script folder (folders/SYSTEM_GSUITE_FOLDER_ID)
cat projects.json | jq -crM '.|=sort_by(.projectId)|.[]|select(.parent.id!="SYSTEM_GSUITE_FOLDER_ID")|.projectId+" = {\nname=\""+.name+"\"\n}"'
