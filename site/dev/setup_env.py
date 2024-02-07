from common import clean, install_deps, pull_versioned_docs

# Source the common.sh script (assuming it sets some environment variables or defines functions)
# No direct equivalent in Python, assuming the required environment setup is done in common.py

# Commands to execute
commands = [
    clean,
    install_deps,
    pull_versioned_docs
]

for cmd in commands:
    cmd()
