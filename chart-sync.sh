version=$(curl -s https://raw.githubusercontent.com/devtron-labs/devtron/refs/heads/main/charts/devtron/Chart.yaml | grep "appVersion" | awk -F ': ' '{print $2}' )

if [[ "$version" == *"-rc"* ]]; then
  RELEASE_TYPE="beta"
else
  RELEASE_TYPE="stable"
fi

if [[ "$RELEASE_TYPE" != "beta" ]]; 
then
    echo $version
    echo "Starting PR creation..."
    # Clone the source repository
    git clone $INPUT_SOURCE_REPO
    cd ..

    # Clone the target repository
    git clone $INPUT_TARGET_REPO
    cd $INPUT_WORKING_DIR
    
    # Add a remote for the target repository
    git remote add target https://${INPUT_GIT_TARGET_USERNAME}:${INPUT_GIT_TARGET_TOKEN}@${INPUT_TARGET_REPO#https://}
    
    # Check out to the main branch and print remotes for verification
    git checkout main
    git remote -v
    
    # Set Git user email and name
    git config --global user.email ${INPUT_GIT_TARGET_USEREMAIL}
    git config --global user.name ${INPUT_GIT_TARGET_USERNAME}
    
    # Create a unique branch name using prefix and Git hash
    NEW_BRANCH_NAME="sync-$(date +"%Y-%m-%d-%H%M%S")-$(git rev-parse --short HEAD)"
    
    # Create and checkout a new branch
    git checkout -b $NEW_BRANCH_NAME
    
    # Copy contents from source directory to target directory
    rsync -av --exclude='.git' ../${INPUT_SOURCE_DIR} $INPUT_TARGET_DIR
    
    # Commit the changes and push them to the new branch
    git add .

    git commit -m "Syncing Repo from branch ${NEW_BRANCH_NAME}"
    git push target $NEW_BRANCH_NAME

    echo $NEW_BRANCH_NAME
    
    # Create a pull request from the new branch to the main branch
    PR_TITLE="Sync changes from ${INPUT_SOURCE_REPO} for release ${version}"
    echo $PR_TITLE
    PR_BODY="This pull request syncs changes from ${INPUT_SOURCE_REPO} for release ${version}."
    echo $PR_BODY
    TARGET_REPO_NAME=${INPUT_TARGET_REPO#https://github.com/}
    echo $INPUT_TARGET_REPO
    echo $INPUT_GIT_TARGET_TOKEN | gh auth login --with-token
    gh pr create --title "$PR_TITLE" --body "$PR_BODY" --base main --head $NEW_BRANCH_NAME --repo $INPUT_TARGET_REPO
    echo "Pull request created successfully."
else
    echo "No sync operation due to beta"
fi
