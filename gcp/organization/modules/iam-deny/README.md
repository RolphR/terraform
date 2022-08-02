# What is protected?

IAM deny policies prevent certain permissions from being allowed,
and thus prevents the execution of certain API calls

# Why?

Ideally all permission grants should follow the least-privilege principle.
However, certain implementation restrictions and requirements prevent an
ideal iam policy implementation.
For example:

- Network XPN admin and Organization Policy Administrator can only be granted
  on the organization node level;
- In order to easily interact with Google Support, the requester ideally needs
  Owner or Editor permissions.

# Documentation

- [GCP Documentation](https://cloud.google.com/iam/docs/deny-overview)
- [GCP API Documentation](https://cloud.google.com/iam/docs/reference/rest/v2beta/policies)
- [Supported permissions](https://cloud.google.com/iam/docs/deny-permissions-support)
- [Terraform
  documentation](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/iam_deny_policy)
