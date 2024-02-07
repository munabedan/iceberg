from common import clean, install_deps, pull_versioned_docs
import sys
import subprocess

def serve():
    # Clean, install_deps, and pull_versioned_docs from common.py
    clean()
    install_deps()
    pull_versioned_docs()

    # Run mkdocs serve
    subprocess.run(["mkdocs", "serve", "--dirty", "--watch"])

def main():
    # Accessing arguments passed to the script
    arguments = sys.argv[1:]

    # Check if 'serve' argument is passed
    if "serve" in arguments:
        serve()
    else:
        print("Invalid command. Available command: 'serve'.")

if __name__ == "__main__":
    main()
