#!/bin/bash

# ... (les autres fonctions assume_role et undo_assume restent inchangées) ...

nuke_account() {
  ACCOUNT_ID=$1
  assume_role $ACCOUNT_ID

  # Create the aws-nuke config file
  cat > nuke-config.yml << EOL
---
regions:
- global
- us-east-1

account-blocklist:
- 999999999999 # Remplacez cette valeur par l'ID de votre compte principal AWS Organizations

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
