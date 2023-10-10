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

# move to the iceberg root
cd $(git rev-parse --show-toplevel)

# remove all files and directories except the exceptions
find . \
 -not \( -path . \) \
 -not \( -path .. \) \
 -not \( -path ./.git -prune \) \
 -not \( -path ./.github -prune \) \
 -not \( -path ./docs-new  -prune \) \
 ! -name LICENSE \
 ! -name NOTICE \
 -exec rm -rf {} +

# move the nightly docs to the root and change from 'nightly'
mv docs-new ./tmp && \
mv ./tmp/docs/docs/nightly/* . && \
rm -r ./tmp

#delete top-level directories
rm -r ./docs-new

# update versions in mkdocs.yml
sed -i '' -E "s/(^site\_name:[[:space:]]+docs\/).*$/\1${ICEBERG_VERSION}/" "./mkdocs.yml" 
sed -i '' -E "s/(^[[:space:]]*-[[:space:]]+Javadoc:.*\/javadoc\/)nightly/\1${ICEBERG_VERSION}/" "./mkdocs.yml"

cd docs

# add exclude search for older documentation
python3 -c "import os
for f in filter(lambda x: x.endswith('.md'), os.listdir()): lines = open(f).readlines(); open(f, 'w').writelines(lines[:2] + ['search:\n', '  exclude: true\n'] + lines[2:]);"

cd ..

git add .

git commit -m "Deploy ${GIT_BRANCH} branch"

git push origin $GIT_BRANCH

git reset --hard origin/master

git checkout master
