#!/usr/bin/env bash

gcloud organizations get-iam-policy ORGANIZATION_ID \
  --billing-project=BILLING_PROJECT_ID \
  --format=json | \
  jq -crM '.bindings|.[]|"\""+.role+"\":[\n"+(.members|map("\""+.+"\",")|join("\n"))+"]"'
