if [[ "$RELEASE_TYPE" == "major" || "$RELEASE_TYPE" == "minor" || "$RELEASE_TYPE" == "patch" ]]; 
then
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
    
    # Create a pull request from the new branch to the main branch
    PR_TITLE="Sync changes from ${INPUT_SOURCE_REPO} for release ${RELEASE_TAG}"
    PR_BODY="This pull request syncs changes from ${INPUT_SOURCE_REPO} for release ${RELEASE_TAG}."
    TARGET_REPO_NAME=${INPUT_TARGET_REPO#https://github.com/}

    echo $INPUT_GIT_TARGET_TOKEN | gh auth login --with-token
    gh pr create --title "Sync changes from $NEW_BRANCH_NAME" --body "This pull request syncs changes from $NEW_BRANCH_NAME" --base main --head $NEW_BRANCH_NAME --repo $INPUT_TARGET_REPO

    echo "Pull request created successfully."
else
    echo "No sync operation due to beta"
fi
