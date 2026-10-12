# Agy with Agent Github Token
# https://github.com/settings/personal-access-tokens
# Contents & Pull Requests- Read & Write
# Edit ~/.local/bin/agy

mkdir -p ~/.local/bin
cat << 'EOF' > ~/.local/bin/agy
#!/usr/bin/env bash

# 1. Provide scoped GitHub token to gh and standard tooling
export GH_TOKEN="github_pat_xxx"
export GITHUB_TOKEN="github_pat_xxx"

# 2. Tell Git inside agy to translate SSH URLs to authenticated HTTPS URLs
export GIT_CONFIG_COUNT=1
export GIT_CONFIG_KEY_0="url.https://x-access-token:${GH_TOKEN}@github.com/.insteadOf"
export GIT_CONFIG_VALUE_0="git@github.com:"

export GIT_AUTHOR_NAME="YourName (Agent)"
export GIT_AUTHOR_EMAIL="your_email+agent@example.com"

# 3. Hand off to actual agy binary
exec /usr/bin/agy "$@"
EOF
chmod +x ~/.local/bin/agy
