# Managing the GCP organization

This Terraform module manages organization and folder security.

# Executing a Terraform run

## High level

This module is executed via a local user.
The reasoning for this is simple:

- This module controls the highest level of security in a GCP organization
- It ensures basic compliance with internal security and data policies
- When anything goes wrong, direct control is the best way to immediately resolve the issues
- Modifications to these security mechanisms need a manual step to elevate (`sudo`) permissions

## Steps to execute a terraform run

1. Ensure you have an authenticated `gcloud` environment
2. Ensure you have the correct `terraform` [version](./versions.tf) installed
3. Add your Google user to the `gcp.break.glass@domain.tld` group via <https://admin.google.com>
4. Wait for a few minutes (usually takes about 1 minute) for the membership changes to apply
5. `terraform apply`
6. Verify that the `terraform apply` run executed successfully
7. Verify that the GCP organization is in the desired state
8. Remove your Google user from the `gcp.break.glass@domain.tld` group via <https://admin.google.com>
9. Wait for a few minutes (usually takes about 1 minute) for the membership changes to apply
10. Verify that your super admin permissions are revoked:
    - The `Edit` button on the Organization Policies > Policy Details page should be grayed-out
    - The following 2 links do not yet properly work with IAM Deny policies (replace USER@domain.tld with your
      email):
      - [Policy troubleshooter](https://console.cloud.google.com/iam-admin/troubleshooter;principal=USER@domain.tld;resources=%2F%2Fcloudresourcemanager.googleapis.com%2Forganizations%2FORGANIZATION_ID;permissions=resourcemanager.projects.updateLiens/result?organizationId=ORGANIZATION_ID)
      - [Policy Analyzer](https://console.cloud.google.com/iam-admin/troubleshooter;principal=USER@domain.tld;resources=%2F%2Fcloudresourcemanager.googleapis.com%2Forganizations%2FORGANIZATION_ID,%2F%2Fcloudresourcemanager.googleapis.com%2Forganizations%2FORGANIZATION_ID,%2F%2Fcloudresourcemanager.googleapis.com%2Forganizations%2FORGANIZATION_ID;permissions=resourcemanager.projects.updateLiens,orgpolicy.policy.set,iam.denypolicies.update/result?organizationId=ORGANIZATION_ID)

# How does it _really_ work?

## Assumptions

This module works because of the following assumptions:

- There is a proper process to gain access to the `gcp.break.glass@domain.tld` group.
- The `gcp.break.glass@domain.tld` group will never have any permanent members.
- The `gcp.break.glass@domain.tld` group will never ever be deleted.

## Basic building blocks

This module relies on the following GCP concepts:

- Organization Policies
  - Limit the allowed values on several API calls, including (but not limited to):
    - GCP regions
    - IAM principals
    - External ip addresses
  - Reject adding any IAM principals on the GCP organization node
- Project Liens
  - Prevent deletion of projects
- IAM Deny Policies (unless the principal is a member of the `gcp.break.glass@domain.tld` group)
  - Deny certain permissions, including (but not limited to):
    - Modifying Organization Policies
    - Modifying Project Liens
    - Modifying IAM Deny Policies

# How to recover when access is lost

## Some access to the Cloud Identity domain remains

1. Don't panic
2. Recover access to any Super Admin account on the Cloud Identity account on <https://admin.google.com>
   1. May need to reset password, user backup codes, or re-provision the user via IT
3. Ensure the `gcp.break.glass@domain.tld` group exists
4. Follow standard procedure as described above to repair the organization

## No access to the Cloud Identity domain

1. Don't panic
2. Contact the Customer Engineer or Account Manager for ORGANIZATION at Google
3. Verify your identity and recover an admin account
4. Ensure the `gcp.break.glass@domain.tld` group exists
5. Follow standard procedure as described above to repair the organization

## The `gcp.break.glass@domain.tld` group no longer has access

1. Don't panic
2. Contact the Customer Engineer or Account Manager for ORGANIZATION at Google
3. Reset the following on the organization node:
   1. Organization Policies
   2. IAM Deny Policies
4. Follow standard procedure as described above to repair the organization
