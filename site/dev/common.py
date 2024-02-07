import subprocess
import os
import shutil
import platform


REMOTE = "iceberg_docs"


def create_or_update_docs_remote():
    print(" --> create or update docs remote")

    remote_url_check = subprocess.run(["git", "config", f"remote.{REMOTE}.url"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)

    if remote_url_check.returncode != 0:
        subprocess.run(["git", "remote", "add", REMOTE, "https://github.com/apache/iceberg.git"], check=True)

    subprocess.run(["git", "fetch", REMOTE], check=True)

# Example usage:
#create_or_update_docs_remote()



def pull_remote(branch):
    print(" --> pull remote")

    assert branch, "Branch name must not be empty"

    # Perform a pull from the specified branch of the remote repository
    subprocess.run(["git", "pull", REMOTE, branch], check=True)

# Example usage:
#pull_remote("your_branch_name")



def push_remote(branch):
    print(" --> push remote")

    assert branch, "Branch name must not be empty"


    # Push changes to the specified branch of the remote repository
    subprocess.run(["git", "push", REMOTE, branch], check=True)

# Example usage:
#push_remote("your_branch_name")



def install_deps():
    print(" --> install deps")

    # Use pip to install or upgrade dependencies from the 'requirements.txt' file quietly
    subprocess.run(["pip", "install", "-q", "-r", "requirements.txt", "--upgrade"], check=True)

# Example usage:
#install_deps()



def get_latest_version():
    print(" --> get latest version")

    # Find the latest numeric folder within 'docs/docs/' structure
    latest = max((d for d in os.listdir("docs/docs") if d.isdigit()), default=None)

    return latest

# Example usage:
#latest_version = get_latest_version()
#print(f"Latest version is: {latest_version}")



def create_nightly():
    print(" --> create nightly")

    nightly_path = "docs/docs/nightly/"
    existing_link = os.path.islink(nightly_path)

    # Remove any existing 'nightly' symbolic link to prevent conflicts
    if existing_link:
        os.unlink(nightly_path)

    # Create a symbolic link pointing to the 'nightly' documentation
    os.symlink("../nightly", nightly_path)

# Example usage:
#create_nightly()


def create_latest(ICEBERG_VERSION):
    print(" --> create latest")

    assert ICEBERG_VERSION, "ICEBERG_VERSION must not be empty"

    print(ICEBERG_VERSION)

    latest_docs_path = "docs/docs/latest/"
    ICEBERG_version_path = f"docs/docs/{ICEBERG_VERSION}"

    # Remove any existing 'latest' directory and recreate it
    if os.path.exists(latest_docs_path):
        shutil.rmtree(latest_docs_path)
    os.makedirs(latest_docs_path)

    # Create symbolic links and copy configuration files for the 'latest' documentation
    os.symlink(f"../{ICEBERG_VERSION}/docs", os.path.join(latest_docs_path, "docs"))
    shutil.copy(os.path.join(ICEBERG_version_path, "mkdocs.yml"), latest_docs_path)

    # Update version information within the 'latest' documentation
    update_version("latest")

# Example usage:
#create_latest("your_ICEBERG_VERSION")
    


def update_version(ICEBERG_VERSION):
    print(" --> update version")

    assert ICEBERG_VERSION, "ICEBERG_VERSION must not be empty"

    mkdocs_path = f"docs/docs/{ICEBERG_VERSION}/mkdocs.yml"

    # Ensure ICEBERG_VERSION is not empty
    if platform.system() == "Darwin":
        with open(mkdocs_path, 'r') as file:
            lines = file.readlines()
            updated_lines = [
                line.replace(
                    r"(^site\_name:[[:space:]]+docs\/).*?$",
                    rf"\1{ICEBERG_VERSION}"
                ) if "site_name" in line else
                line.replace(
                    r"(^[[:space:]]*-[[:space:]]+Javadoc:.*\/javadoc\/).*?$",
                    rf"\1{ICEBERG_VERSION}"
                ) if "Javadoc" in line else line
                for line in lines
            ]
        with open(mkdocs_path, 'w') as file:
            file.writelines(updated_lines)
    elif platform.system() == "Linux":
        with open(mkdocs_path, 'r') as file:
            lines = file.readlines()
            updated_lines = [
                line.replace(
                    r"(^site_name:[[:space:]]+docs\/)[^[:space:]]+",
                    rf"\1{ICEBERG_VERSION}"
                ) if "site_name" in line else
                line.replace(
                    r"(^[[:space:]]*-[[:space:]]+Javadoc:.*\/javadoc\/).*?$",
                    rf"\1{ICEBERG_VERSION}"
                ) if "Javadoc" in line else line
                for line in lines
            ]
        with open(mkdocs_path, 'w') as file:
            file.writelines(updated_lines)

# Example usage:
#update_version("your_ICEBERG_VERSION")


def search_exclude_versioned_docs(ICEBERG_VERSION):
    print(" --> search exclude version docs")

    assert ICEBERG_VERSION, "ICEBERG_VERSION must not be empty"

    docs_path = f"{ICEBERG_VERSION}/docs/"

    # Ensure ICEBERG_VERSION is not empty
    if os.path.exists(docs_path):
        os.chdir(docs_path)

        # Modify .md files to exclude versioned documentation from search indexing
        for file in filter(lambda x: x.endswith('.md'), os.listdir()):
            with open(file, 'r') as f:
                lines = f.readlines()
                updated_lines = lines[:2] + ['search:\n', '  exclude: true\n'] + lines[2:]
            with open(file, 'w') as f:
                f.writelines(updated_lines)

        os.chdir("..")  # Move back to the previous directory

# Example usage:
#search_exclude_versioned_docs("your_ICEBERG_VERSION")


def pull_versioned_docs():
    print(" --> pull versioned docs")

    # Ensure the remote repository for documentation exists and is up-to-date
    create_or_update_docs_remote()

    # Add local worktrees for documentation and javadoc from the remote repository
    subprocess.run(["git", "worktree", "add", "docs/docs", f"{REMOTE}/docs"], check=True)
    subprocess.run(["git", "worktree", "add", "docs/javadoc", f"{REMOTE}/javadoc"], check=True)
  
    # Retrieve the latest version of documentation for processing
    latest_version = get_latest_version()

    # Output the latest version for debugging purposes
    print(f"Latest version is: {latest_version}")

    # Create the 'latest' version of documentation
    create_latest(latest_version)

# Example usage:
#pull_versioned_docs()
    

def clean():
    print(" --> clean")

    # Remove 'latest' directory and related Git worktrees
    shutil.rmtree("docs/docs/latest", ignore_errors=True)
    subprocess.run(["git", "worktree", "remove", "docs/docs"], stderr=subprocess.DEVNULL)
    subprocess.run(["git", "worktree", "remove", "docs/javadoc"], stderr=subprocess.DEVNULL)

    # Remove any additional temporary artifacts (e.g., 'site/' directory)
    shutil.rmtree("site", ignore_errors=True)

# Example usage:
#clean()    