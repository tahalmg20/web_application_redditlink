#!/bin/bash

# ... (les autres fonctions assume_role et undo_assume restent inchangées) ...

nuke_account() {
  ACCOUNT_ID=$1
  assume_role $ACCOUNT_ID

  # Create the aws-nuke config file
  echo "---
regions:
  - us-east-1

account-blocklist:
  - 999999999999

accounts:
  $ACCOUNT_ID:
    filters:
      .*:
        - .*" > nuke-config.yml

  # Execute aws-nuke with the config file and check if it succeeds
  if aws-nuke -c nuke-config.yml --no-dry-run; then
    echo "Successfully nuked account: $ACCOUNT_ID"
  else
    echo "Failed to nuke account: $ACCOUNT_ID"
  fi

  undo_assume
}
