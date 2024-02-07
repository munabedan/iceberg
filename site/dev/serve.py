import subprocess

def run_command(command):
    try:
        subprocess.run(command, check=True, shell=True)
    except subprocess.CalledProcessError as e:
        print(f"Command '{e.cmd}' failed with return code {e.returncode}")
        exit(1)  # Exit the script upon encountering an error

# Run setup_env.py (assuming it sets up the required environment)
run_command(["python3", "./dev/setup_env.py"])

# Run mkdocs serve with options
run_command(["mkdocs", "serve", "--dirty", "--watch", "."])
