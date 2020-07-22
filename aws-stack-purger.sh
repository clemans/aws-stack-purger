#!/usr/bin/env bash

function getStackNames() {
  read -p "Delete CF Stack ...  [a]ngular, ap[i], [c]loudFormation, [e]cs, [s]am-[m]ulti-lambda, [w]eb, Everythin[g] (Default: [g]):  " prompter
  if [[ -z ${prompter} ]]; then
    prompter=G
  fi
  case $prompter in
    a | A) echo "angular";;
    c | C) echo "cloudformation";;
    e | E) echo "ecs";;
    i | I) echo "api";;
    m | M) echo "sam-multi-lambda";;
    s | S) echo "sam";;
    g | G) echo "angular api cloudformation ecs sam sam-multi-lambda web";;
    *) echo -e "your selection is Invalid. Please try again."; getStackNames;;
  esac
}

function getFeatureNumber() {
    read -n 5 -p "Input the feature number you wish to purge (example: 3038 for 'feature-3038'): " fNum
    echo $fNum
}


function ExecuteScript { args: integer featureNumber , string stackNames } {

    function getAngularBuckets() {
        stackName=dev-iad-test-angular-feature-devops-
        buckets=$(aws s3api list-buckets --query "Buckets[].Name" | sed 's: ::g' | sed -e 's|["\""]||g' | sed -e 's|[","]||g' | grep -i "${stackName}${featureNumber:0:3}")
        echo $buckets
    }

    function deleteS3BucketObjects() {
      case $stack in
        "angular")
              buckets=$(getAngularBuckets);;
         "web")
              buckets=$stackName;;
        *)
              buckets='';;
      esac
      for bucket in $buckets; do
        aws s3 rm s3://$bucket/ --recursive
      done
    }

    function deleteS3Bucket() {
      case $stack in
        "angular")
                  buckets=$(getAngularBuckets);;
        "web")
                  buckets=$stackName;;
        *)
                  buckets="";;
      esac
      for bucket in $buckets; do
        aws s3api delete-bucket --bucket $bucket --output text
      done
    }

    function deleteCFStack { args: string stackName } {
      aws cloudformation delete-stack --stack-name $stackName
    }

  #Execution of CloudFormation Stack & S3 Bucket Deletion
  for stack in ${stackNames[*]}; do
    stackName="dev-iad-test-$stack-feature-devops-$featureNumber";
    deleteS3BucketObjects
    deleteS3Bucket
    deleteCFStack
  done
}

#Execution
featureNumber=$(getFeatureNumber)
stackNames=$(getStackNames)
ExecuteScript 2>/dev/null
