git clone $INPUT_SOURCE_REPO
cd ..
git clone $INPUT_TARGET_REPO
cd $INPUT_WORKING_DIR
git remote add target https://${INPUT_GIT_TARGET_USERNAME}:${INPUT_GIT_TARGET_TOKEN}@${INPUT_TARGET_REPO#https://}

git checkout main
git remote -v

git config --global user.email ${INPUT_GIT_TARGET_USEREMAIL}
git config --global user.name ${INPUT_GIT_TARGET_USERNAME}

cp -r ../${INPUT_SOURCE_DIR} $INPUT_TARGET_DIR
git add .
git commit -m "Synching Repo"

git push target main
