#!/bin/bash

#Assume role (ACCOUNT_ID as parameter)
assume_team () {
    OUT=$(aws sts assume-role --role-arn arn:aws:iam::034322259089:role/MyOrgaAccountProvRole --role-session-name AWSCLI);
    export AWS_ACCESS_KEY_ID=$(echo $OUT | jq -r '.Credentials''.AccessKeyId');
    export AWS_SECRET_ACCESS_KEY=$(echo $OUT | jq -r '.Credentials''.SecretAccessKey');
    export AWS_SESSION_TOKEN=$(echo $OUT | jq -r '.Credentials''.SessionToken');
   
    OUT=$(aws sts assume-role --role-arn arn:aws:iam::"$1":role/OrganizationAccountTestProvRole --role-session-name AWSCLI);
    export AWS_ACCESS_KEY_ID=$(echo $OUT | jq -r '.Credentials''.AccessKeyId');
    export AWS_SECRET_ACCESS_KEY=$(echo $OUT | jq -r '.Credentials''.SecretAccessKey');
    export AWS_SESSION_TOKEN=$(echo $OUT | jq -r '.Credentials''.SessionToken');
}

#Undo assume role (unset the AWS environment variables)
undo_assume(){
    unset AWS_ACCESS_KEY_ID;
    unset AWS_SECRET_ACCESS_KEY;
    unset AWS_SESSION_TOKEN;
}

#Get budget of account X
get_budget(){
    ACCOUNT_ID=$1
    assume_team $ACCOUNT_ID
    ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text);
    ACTUAL_SPENT=$(aws budgets describe-budget --account-id "$ACCOUNT_ID" --budget-name "wavegame budget" --query 'Budget.CalculatedSpend.ActualSpend.Amount' --output text);
    echo "$ACCOUNT_ID,$ACTUAL_SPENT" 
    undo_assume 
}


# List remaining resources in an account using AWS Config
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

  echo "Region: $REGION"
  echo "Remaining resources:"

  for RESOURCE_TYPE in "${RESOURCE_TYPES[@]}"; do
    echo "Resource type: $RESOURCE_TYPE"
    aws configservice list-discovered-resources --region "$REGION" --resource-type "$RESOURCE_TYPE" --query 'resourceIdentifiers[*].resourceId' --output table
  done

  undo_assume
}


# Create a CSV file and write the header
CSV_FILE="aws_budgets.csv"
echo "Account ID,Actual Spent" > $CSV_FILE

# Read the account IDs and write the budgets to the CSV file
while read ACCOUNT_ID; do
  get_budget "$ACCOUNT_ID" >> $CSV_FILE
done < accounts.txt

