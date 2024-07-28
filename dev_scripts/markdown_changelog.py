#!.venv/bin/python

import os
import subprocess
from dotenv import load_dotenv
from github import Auth, Github
from github.WorkflowRun import WorkflowRun

load_dotenv()

GITHUB_TOKEN = os.environ["GITHUB_TOKEN"]

auth = Auth.Token(GITHUB_TOKEN)
client = Github(auth=auth, per_page=1)

def main():
    last_successful_run: WorkflowRun = client.get_repo("jspahrsummers/Merc").get_workflow("main.yml").get_runs(status="success")[0]
    from_commit = last_successful_run.head_sha
    head_commit = subprocess.check_output(["git","rev-parse","HEAD"]).decode().strip()

    commit_log = subprocess.check_output(["git", "log", "--first-parent", "--reverse", r"--pretty=tformat:* [%s](<https://github.com/jspahrsummers/Merc/commit/%H>)", f"{from_commit}..{head_commit}"]).decode().strip()
    print(f"[Changes](<https://github.com/jspahrsummers/Merc/compare/{from_commit}...{head_commit}>):\n{commit_log}")

if __name__ == "__main__":
    main()
