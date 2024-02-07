import subprocess

def run_command(command):
    try:
        subprocess.run(command, check=True)
    except subprocess.CalledProcessError as e:
        print(f"Command '{e.cmd}' failed with return code {e.returncode}")
        exit(1)  # Exit the script upon encountering an error

# Example usage:
run_command(["./dev/setup_env.sh"])
run_command(["mkdocs", "build"])
