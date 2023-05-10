---
regions:
  - "us-east-1"
account-blocklist:
  - "999999999999" # Remplacez par votre compte principal pour éviter de le supprimer accidentellement


show_nukeable_resources() {
  ACCOUNT_ID=$1
  assume_team $ACCOUNT_ID
  aws-nuke --config nuke-config.yml --dry-run
  undo_assume
}
