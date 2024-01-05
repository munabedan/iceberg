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

source dev/common.sh
set -e

assert_not_empty "${ICEBERG_VERSION}"
clean

git checkout docs
pull_remote docs

cp ../docs/ docs/"${ICEBERG_VERSION}"

cd ../

update_version "${ICEBERG_VERSION}"
search_exclude_versioned_docs "${ICEBERG_VERSION}"

git add "${ICEBERG_VERSION}" 
git commit -m "Deploy ${ICEBERG_VERSION} to docs branch"
push_remote docs

git checkout -
cd site/
