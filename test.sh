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
    echo "Account ID: $ACCOUNT_ID; Actual expense: $ACTUAL_SPENT USD" 
    undo_assume 
}


while read ACCOUNT_ID; do
  get_budget "$ACCOUNT_ID"
done < accounts.txt



