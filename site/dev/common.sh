#!/usr/bin/env bash
#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -e

REMOTE="iceberg_docs"

create_or_update_docs_remote () {
  # check if remote exists before adding it
  git config "remote.${REMOTE}.url" >/dev/null || 
    git remote add "${REMOTE}" https://github.com/apache/iceberg.git

  git fetch "${REMOTE}"
}

pull_remote () {
  local BRANCH="$1"
  assert_not_empty "${BRANCH}"

  git pull "${REMOTE}" "${BRANCH}" 
}

push_remote () {
  local BRANCH="$1"
  assert_not_empty "${BRANCH}"

  git push "${REMOTE}" "${BRANCH}" 
}

install_deps () {
  pip -q install -r requirements.txt --upgrade
}

assert_not_empty () {
  if [ -z "$1" ]
    then
      echo "No argument supplied"
      exit 1
  fi 
}

get_latest_version () {
  basename $(ls -d docs/docs/*/ | sort -V | tail -1)
}

create_nightly () {
  rm -f docs/docs/nightly/
  ln -s ../nightly docs/docs/nightly
}

create_latest () {
  local ICEBERG_VERSION="$1"
  assert_not_empty "${ICEBERG_VERSION}"

  rm -rf docs/docs/latest/
  mkdir docs/docs/latest/

  ln -s "../${ICEBERG_VERSION}/docs" docs/docs/latest/docs
  cp "docs/docs/${ICEBERG_VERSION}/mkdocs.yml" docs/docs/latest/

  cd docs/docs/
  update_version "latest"
  cd -
}

update_version () {
  local ICEBERG_VERSION="$1"
  assert_not_empty "${ICEBERG_VERSION}"

  sed -i '' -E "s/(^site\_name:[[:space:]]+docs\/).*$/\1${ICEBERG_VERSION}/" ${ICEBERG_VERSION}/mkdocs.yml
  sed -i '' -E "s/(^[[:space:]]*-[[:space:]]+Javadoc:.*\/javadoc\/).*$/\1${ICEBERG_VERSION}/" ${ICEBERG_VERSION}/mkdocs.yml

  #sed -i '' -E "s/    \- latest: '\!include docs\/docs\/latest\/mkdocs\.yml'/a    \- ${ICEBERG_VERSION}: '\!include docs\/docs\/${ICEBERG_VERSION}\/mkdocs\.yml/" ../../mkdocs.yml
}
# https://squidfunk.github.io/mkdocs-material/setup/setting-up-site-search/#search-exclusion
search_exclude_versioned_docs () {
  local ICEBERG_VERSION="$1"
  assert_not_empty "${ICEBERG_VERSION}"

  cd "${ICEBERG_VERSION}/docs/"
  
  python3 -c "import os
for f in filter(lambda x: x.endswith('.md'), os.listdir()): lines = open(f).readlines(); open(f, 'w').writelines(lines[:2] + ['search:\n', '  exclude: true\n'] + lines[2:]);"
  
  cd -
}

pull_versioned_docs () {
  create_or_update_docs_remote
  git worktree add docs/docs "${REMOTE}/docs"
  git worktree add docs/javadoc "${REMOTE}/javadoc"
  
  create_latest $(get_latest_version)
  create_nightly
}

clean () {
  set +e # avoid exit if any step in clean fails

  rm -rf docs/docs/latest  &> /dev/null
  rm -f docs/docs/nightly  &> /dev/null

  git worktree remove docs/docs &> /dev/null
  git worktree remove docs/javadoc &> /dev/null

  rm -rf site/ &> /dev/null

  set -e
}
