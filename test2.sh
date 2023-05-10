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


add_account_alias() {
  ACCOUNT_ID=$1
  ACCOUNT_ALIAS=$2

  # Vérifie si l'alias respecte les exigences
  if [[ ! $ACCOUNT_ALIAS =~ ^[a-z0-9][a-z0-9-]*[a-z0-9]$ ]]; then
    echo "L'alias de compte ${ACCOUNT_ALIAS} ne respecte pas les exigences. Il doit contenir uniquement des chiffres, des lettres minuscules et des traits d'union, et ne peut pas commencer ou se terminer par un trait d'union."
    return
  fi

  assume_team $ACCOUNT_ID
  aws iam create-account-alias --account-alias "$ACCOUNT_ALIAS"
  undo_assume
}


while read ACCOUNT_ID; do
  ACCOUNT_ALIAS="alias-for-account-$ACCOUNT_ID" # Remplacez par un format d'alias de votre choix
  add_account_alias "$ACCOUNT_ID" "$ACCOUNT_ALIAS"
done < accounts.txt

