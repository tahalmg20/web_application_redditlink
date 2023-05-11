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




empty_s3_bucket() {
  BUCKET=$1
  aws s3api list-object-versions --bucket "$BUCKET" --query 'Versions[].{Key:Key,VersionId:VersionId}' --output text | while read -r KEY VERSION_ID; do
    echo "Deleting $KEY with version $VERSION_ID"
    aws s3api delete-object --bucket "$BUCKET" --key "$KEY" --version-id "$VERSION_ID"
  done
}


 
        "AWS::S3::Bucket")
          empty_s3_bucket "$RESOURCE_ID"
          aws s3api delete-bucket --region "$REGION" --bucket "$RESOURCE_ID"
          ;;
          
          
          
# Function to empty an S3 bucket
empty_s3_bucket() {
  BUCKET=$1

  # Delete objects and their versions
  aws s3api list-object-versions --bucket "$BUCKET" --output json | jq -r '.Versions + .DeleteMarkers | .[] | .Key + " " + .VersionId' | while read -r KEY VERSION_ID; do
    echo "Deleting $KEY with version $VERSION_ID"
    aws s3api delete-object --bucket "$BUCKET" --key "$KEY" --version-id "$VERSION_ID"
  done
}




# Function to empty an S3 bucket
empty_s3_bucket() {
  BUCKET=$1

  # Function to format object keys and versions for batch delete
  format_delete_objects_input() {
    jq -r '(.Versions + .DeleteMarkers) | to_entries | map({Key: .value.Key, VersionId: .value.VersionId})'
  }

  # Delete objects and versions in batches
  while true; do
    DELETE_OBJECTS_JSON=$(aws s3api list-object-versions --bucket "$BUCKET" --output json | format_delete_objects_input)
    OBJECT_COUNT=$(echo "$DELETE_OBJECTS_JSON" | jq length)

    if [ "$OBJECT_COUNT" -eq 0 ]; then
      break
    fi

    echo "Deleting $OBJECT_COUNT objects and their versions"
    aws s3api delete-objects --bucket "$BUCKET" --delete "{\"Objects\": $DELETE_OBJECTS_JSON}"
  done
}





#!/bin/bash

# ... (Les autres fonctions et configurations du script)

# Fichier de sortie
output_file="nuke_results.txt"

# Supprimer le fichier de sortie s'il existe déjà
if [ -f "$output_file" ]; then
  rm "$output_file"
fi

while read ACCOUNT_ID; do
  assume_team "$ACCOUNT_ID"
  nuke_output=$(aws-nuke --config aws-nuke-config.yaml --force --no-dry-run 2>&1)
  undo_assume
  
  # Vérifier si "No resource to delete" est présent dans la sortie d'aws-nuke
  if echo "$nuke_output" | grep -q "No resource to delete"; then
    echo "$ACCOUNT_ID: No resource to delete" >> "$output_file"
  else
    echo "$ACCOUNT_ID: Resources deleted" >> "$output_file"
  fi
done < accounts.txt




create_temp_alias() {
  ACCOUNT_ID=$1
  assume_team $ACCOUNT_ID
  TEMP_ALIAS="temp-alias-$ACCOUNT_ID"
  aws iam create-account-alias --account-alias "$TEMP_ALIAS"
  undo_assume
}

#Remove the temporary account alias
remove_temp_alias() {
  ACCOUNT_ID=$1
  assume_team $ACCOUNT_ID
  TEMP_ALIAS="temp-alias-$ACCOUNT_ID"
  aws iam delete-account-alias --account-alias "$TEMP_ALIAS"
  undo_assume
}





# Function to empty a prefix in an S3 bucket
empty_s3_prefix() {
  BUCKET=$1
  PREFIX=$2
  BATCH_SIZE=1000

  # Function to format object keys and versions for batch delete
  format_delete_objects_input() {
    jq -r '(.Versions + .DeleteMarkers) | to_entries | map({Key: .value.Key, VersionId: .value.VersionId})'
  }

  # Delete objects and versions in batches
  while true; do
    DELETE_OBJECTS_JSON=$(aws s3api list-object-versions --bucket "$BUCKET" --prefix "$PREFIX" --output json | format_delete_objects_input)
    OBJECT_COUNT=$(echo "$DELETE_OBJECTS_JSON" | jq length)

    if [ "$OBJECT_COUNT" -eq 0 ]; then
      break
    fi

    for ((i = 0; i < OBJECT_COUNT; i += BATCH_SIZE)); do
      DELETE_BATCH_JSON=$(echo "$DELETE_OBJECTS_JSON" | jq ".[$i:$((i + BATCH_SIZE))]")

      echo "Deleting objects and their versions with prefix $PREFIX (Batch: $((i / BATCH_SIZE + 1)))"
      aws s3api delete-objects --bucket "$BUCKET" --delete "{\"Objects\": $DELETE_BATCH_JSON}"
    done
  done
}



# Create a random string of length N
random_string() {
  LENGTH=$1
  cat /dev/urandom | tr -dc 'a-z' | fold -w "$LENGTH" | head -n 1
}

# Create a temporary account alias
create_temp_alias() {
  ACCOUNT_ID=$1
  assume_team $ACCOUNT_ID
  TEMP_ALIAS="tempalias-$(random_string 10)"
  echo "Generated alias: $TEMP_ALIAS"
  aws iam create-account-alias --account-alias "$TEMP_ALIAS"
  undo_assume
  echo "$TEMP_ALIAS"
}




#!/bin/bash

# ... (Les autres fonctions et configurations du script)

# Fichier de sortie
output_file="nuke_results.txt"

# Supprimer le fichier de sortie s'il existe déjà
if [ -f "$output_file" ]; then
  rm "$output_file"
fi

while read ACCOUNT_ID; do
  assume_team "$ACCOUNT_ID"
  nuke_output=$(aws-nuke --config aws-nuke-config.yaml --force --no-dry-run 2>&1)
  undo_assume
  
  # Vérifier si "No resource to delete" est présent dans la sortie d'aws-nuke
  if echo "$nuke_output" | grep -q "No resource to delete"; then
    echo "$ACCOUNT_ID: No resource to delete" >> "$output_file"
  else
    echo "$ACCOUNT_ID: Resources deleted" >> "$output_file"
  fi
done < accounts.txt




nuke_resources() {
  ACCOUNT_ID=$1
  assume_team $ACCOUNT_ID
  nuke_output=$(aws-nuke --config aws-nuke-config.yaml --force --no-dry-run 2>&1)
  undo_assume

  if echo "$nuke_output" | grep -q "No resource to delete"; then
    echo "No resource to delete"
  else
    echo "Resources deleted"
  fi
}



echo "$ACCOUNT_ID: $nuke_result" >> "$output_file"





list_remaining_resources() {
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
  echo "ID >>>>>>>>> : $ACCOUNT_ID "
  echo "Region: $REGION"
  echo "Remaining resources:"

  for RESOURCE_TYPE in "${RESOURCE_TYPES[@]}"; do
    echo "Resource type: $RESOURCE_TYPE"
    aws configservice list-discovered-resources --region "$REGION" --resource-type "$RESOURCE_TYPE" --query 'resourceIdentifiers[*].resourceId' --output table
  done

  undo_assume
}

