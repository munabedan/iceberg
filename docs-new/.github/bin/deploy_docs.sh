#!/bin/bash

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -v|--version) ICEBERG_VERSION="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

GIT_BRANCH="docs-${ICEBERG_VERSION}"

# change to branch
git checkout -b $GIT_BRANCH

cd ..

#remove all all files and directories except the docs/ folder
find . -type f -exec rm -f {} +
find . ! -name 'docs-new' -type d -exec rm -rf {} +

# move the nightly docs to the root and change from 'nightly'
mv docs-new/docs/docs/nightly/* .

#delete dirs
rm -r ./docs-new

# update versions in mkdocs.yml
sed -i '' -E "s/(^site\_name:[[:space:]]+docs\/).*$/\1${ICEBERG_VERSION}/" "./mkdocs.yml" 
sed -i '' -E "s/(^[[:space:]]*-[[:space:]]+Javadoc:.*\/javadoc\/)nightly/\1${ICEBERG_VERSION}/" "./mkdocs.yml"

# add exclude search for older documentation
python3 -c "import os
for f in filter(lambda x: x.endswith('.md'), os.listdir('.')): lines = open(f).readlines(); open(f, 'w').writelines(lines[:2] + ['search:\n', '  exclude: true\n'] + lines[2:]);"

git add .

git commit -m "Deploy ${GIT_BRANCH} branch"

git push origin $GIT_BRANCH

git checkout master
