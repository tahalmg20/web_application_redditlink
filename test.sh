#!/bin/bash

# ... (les autres fonctions assume_role et undo_assume restent inchangées) ...

nuke_account() {
  ACCOUNT_ID=$1
  assume_role $ACCOUNT_ID

  # Create the aws-nuke config file
  cat > nuke-config.yml << EOL
---
regions:
- us-east-1

account-blacklist:
  - 999999999999 # Replace with your AWS Organizations master account ID

accounts:
  $ACCOUNT_ID:
    filters:
      .*:
        - .*
EOL

  # Execute aws-nuke with the config file and check if it succeeds
  if aws-nuke -c nuke-config.yml --no-dry-run; then
    echo "Successfully nuked account: $ACCOUNT_ID"
  else
    echo "Failed to nuke account: $ACCOUNT_ID"
  fi

  undo_assume
}
