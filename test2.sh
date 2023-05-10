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

















# Delete remaining resources in an account using AWS Config
delete_remaining_resources() {
  ACCOUNT_ID=$1
  REGION="us-east-1"
  RESOURCE_TYPES=(
    "AWS::EC2::Instance"
    "AWS::Lambda::Function"
    "AWS::S3::Bucket"
    "AWS::EC2::SecurityGroup"
    "AWS::Logs::LogGroup"
    "AWS::CloudTrail::Trail"
    "AWS::SSM::ManagedInstanceInventory"
  )
  assume_team $ACCOUNT_ID

  echo "Region: $REGION"
  echo "Deleting resources:"

  for RESOURCE_TYPE in "${RESOURCE_TYPES[@]}"; do
    echo "Resource type: $RESOURCE_TYPE"
    RESOURCE_IDS=$(aws configservice list-discovered-resources --region "$REGION" --resource-type "$RESOURCE_TYPE" --query 'resourceIdentifiers[*].resourceId' --output text)

    for RESOURCE_ID in $RESOURCE_IDS; do
      echo "Deleting $RESOURCE_ID"
      case $RESOURCE_TYPE in
        "AWS::EC2::Instance")
          aws ec2 terminate-instances --region "$REGION" --instance-ids "$RESOURCE_ID"
          ;;
        "AWS::Lambda::Function")
          aws lambda delete-function --region "$REGION" --function-name "$RESOURCE_ID"
          ;;
        "AWS::S3::Bucket")
          aws s3api delete-bucket --region "$REGION" --bucket "$RESOURCE_ID"
          ;;
        "AWS::EC2::SecurityGroup")
          aws ec2 delete-security-group --region "$REGION" --group-id "$RESOURCE_ID"
          ;;
        "AWS::Logs::LogGroup")
          aws logs delete-log-group --region "$REGION" --log-group-name "$RESOURCE_ID"
          ;;
        "AWS::CloudTrail::Trail")
          aws cloudtrail delete-trail --region "$REGION" --name "$RESOURCE_ID"
          ;;
        "AWS::SSM::ManagedInstanceInventory")
          aws ssm deregister-managed-instance --region "$REGION" --instance-id "$RESOURCE_ID"
          ;;
        *)
          echo "Unknown resource type: $RESOURCE_TYPE"
          ;;
      esac
    done
  done

  undo_assume
}


