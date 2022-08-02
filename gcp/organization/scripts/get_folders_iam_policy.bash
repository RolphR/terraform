#!/usr/bin/env bash

gcloud resource-manager folders list \
  --organization ORGANIZATION_ID \
  --billing-project=BILLING_PROJECT_ID \
  --format=json > folders.json

#cat folders.json| jq -crM '.[]|(.name|split("/")|.[1])+"={\ndisplay_name=\""+.displayName+"\"\n}"'

echo "folders = {"
folders=$(cat folders.json| jq -crM '.[]|(.name|split("/")|.[1])'|sort -n)
for folder_id in $folders
do
  display_name=$(cat folders.json | jq -crM ".[]|select(.name == \"folders/${folder_id}\")|.displayName")
  echo "${folder_id} = {"
  echo "display_name = \"${display_name}\""
  echo "overlay_permissions = {"
  gcloud resource-manager folders get-iam-policy $folder_id \
    --billing-project=BILLING_PROJECT_ID \
    --format=json | \
    jq -crM '.bindings|.[]|"\""+.role+"\":[\n"+(.members|map("\""+.+"\",")|join("\n"))+"]"'
  echo "}"
  echo "}"
done

echo "}"
