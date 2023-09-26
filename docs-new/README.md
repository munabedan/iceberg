<!--
 - Licensed to the Apache Software Foundation (ASF) under one or more
 - contributor license agreements.  See the NOTICE file distributed with
 - this work for additional information regarding copyright ownership.
 - The ASF licenses this file to You under the Apache License, Version 2.0
 - (the "License"); you may not use this file except in compliance with
 - the License.  You may obtain a copy of the License at
 -
 -   http://www.apache.org/licenses/LICENSE-2.0
 -
 - Unless required by applicable law or agreed to in writing, software
 - distributed under the License is distributed on an "AS IS" BASIS,
 - WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 - See the License for the specific language governing permissions and
 - limitations under the License.
 -->

# Iceberg site and documentation

This holds the static files that define and build the documentation site for Apache Iceberg.

## Requirements 

* Python >=3.9
* pip


## Usage

The directory structure is intended to mimic the tree hierarchy of the website. This will enable contributors to find the documentation they need to update easier. The static and documentation will reside in the same location. 

All static pages are all the `./docs/.*md` files and the docs are the `.docs/docs/<version>/docs/*.md` files. Notice the location of the `mkdocs.yml`. Looking at this though, you may ask where the older versions and javadocs are.

```
.
├── docs
│   ├── assets
│   ├── docs
│   │   └── latest
│   │       ├── docs
│   │       │   ├── assets
│   │       │   ├── api.md
│   │       │   ├── ...
│   │       │   └── table-migration.md
│   │       └── **mkdocs.yml(docs)** 
│   ├── about.md
│   ├── ...
│   └── view-spec.md
├── README.md
├── **mkdocs.yml(static)**
├── requirements.txt
└── variables.yml
```

All of the documentation versions are saved in special `docs-<version>` branches that only contain the root of the docs version. There is also a `javadoc` tag that contains all prior versions of the javadocs in a single tag. These are generated and loaded only at build time using the [git-worktree](https://git-scm.com/docs/git-worktree) docs.

```
.
└── docs
    ├── docs
    │   ├── latest
    │   ├── 1.3.1
    │   ├── 1.3.0
    │   └── ...
    └── javadoc
        ├── latest
        ├── 1.3.1
        ├── 1.3.0
        └── ...
```

### Install

1. (Optional) Set up venv
```
python -m venv mkdocs_env
source mkdocs_env/bin/activate
```

1. Install required Python libraries
```
pip install -r requirements.txt
```

#### Adding additional versioned documentation

To build locally with additional docs versions, add them to your working tree.
For now, I'm just adding a single version, and the javadocs directory.

```
git worktree add site/docs/1.3.1 docs-1.3.1
git worktree add site/javadoc javadoc
```

## Build

Run the build command in the root directory, and optionally add `--clean` to force MkDocs to clear previously generated pages.

```
mkdocs build [--clean]
```

## Run

Start MkDocs server locally to verify the site looks good.

```
mkdocs serve
```

### Release process

Deploying a version of the docs is a two step process:
 1. Cut a new release from the `latest` documentation which creates a new branch `docs-<version>`.

    ```
    .github/bin/deploy_docs.sh -v 1.4.0
    ```

    See [deploy_docs.sh](.github/bin/deploy_docs.sh) for more details.

 1. Make sure to add the new version to the list of versions to pull into git worktree.
 1. Follow the steps in [the build process](#build).
 1. Push the generated site to `gh-pages`.

## Validate Links

### How links work in this project

Wherever the `docs_dir` points to for a given MkDocs project, becomes the root of that project and [all links are relative to it](https://www.mkdocs.org/user-guide/writing-your-docs/#internal-links). In the Iceberg docs, the top level root is in the `./site` directory and `./site/docs/<version>` is the root for each versioned doc project. 

```
.
├── site
│   ├── docs
│   │  ├── latest
│   │  │   └── mkdocs.yml(docs_dir='.')
│   │  └── 1.3.1
│   │      └── mkdocs.yml(docs_dir='.')
│   └─ javadoc
│      ├── latest
│      └── 1.3.1
└── mkdocs.yml(docs_dir='site')
```

When `mkdocs-monorepo-plugin` compiles, it must first build the versioned documentation sites before aggregating the top-level site with the generated. Due to the delayed aggregation of subdocs of `mkdocs-monorepo-plugin` there may be warnings that display for the versioned docs that compile without being able to reference documentation it expects outside of the immediate poject due to being off by one or more directories. In other words, if the relative linking required doesn't mirror the directory layout on disk, these errors will occur. The only place this occurs now is with the nav link to javadoc. For more information, refer to: <https://github.com/backstage/mkdocs-monorepo-plugin#usage>

To ensure the links work, you may use linkchecker to traverse the links on the livesite when you're running locally. This may eventually be used as part of the build unless a more suitable static solution is found.

The main issue with using static analysis tools like [mkdocs-linkcheck](https://pypi.org/project/mkdocs-linkcheck) is that they verify links within a single project and do not yet have the ability to analyse a stitched monorepo that we are building with this site.

A step that hasn't been tested yet is considering to use the [offline plugin](https://squidfunk.github.io/mkdocs-material/setup/building-for-offline-usage/) to build a local offline version and test that the internal offline generated site links all work with mkdocs-linkcheck. This would be much faster and less error prone for internal doc links than depending on a running live site. linkchecker will still be a useful tool to run daily on the site to automate any live linking issues. 

```
pip install linkchecker

./linkchecker http://localhost:8000 -r1 -Fcsv/link_warnings.csv

cat ./link_warnings.csv
```

## Things to consider

 - Do not use static links from within the documentation to the public Iceberg site (i.e. `[branching](https://iceberg.apache.org/docs/latest/branching)`). If you are running in a local environment and made changes to the page you're linking to, your changes mysteriously won't take effect and you'll be scratching your head unless you happen to notice the url bar change.
 - Only use relative links. If you want to reference the root (the directory where the main mkdocs.yml is located `site` in our case) use "spec.md" vs "/spec.md". Also, static sites should only reference the `docs/*` (see next point), but docs can reference the static content normally (e.g. `branching.md` page which is a versioned page linking to `spec.md` which is a static page).
 - Avoid statically linking a specific version of the documentation ('latest', '1.3.1', etc...) unless it is absolutely relevant to the context being provided. This should almost never be the case unless referencing legacy functionality.
 - When internally linking markdown files to other markdown files, [always use the `.md` suffix](https://github.com/mkdocs/mkdocs/issues/2456#issuecomment-881877986). That will indicate to mkdocs exactly how to treat that link depending on the mode the link is compiled with, e.g. if it becomes a <filename>/index.html or <filename>.html. Using the `.md` extension will work with either mode. 
