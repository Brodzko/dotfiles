#!/bin/bash
export GITLAB_PERSONAL_ACCESS_TOKEN=$(security find-generic-password -s "gitlab-mcp-token" -w)
export GITLAB_API_URL="https://gitlab.rossum.cloud/api/v4"
exec mcp-gitlab
