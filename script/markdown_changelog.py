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

def summary_from_commit_message(message: str) -> str:
    return message.splitlines()[0]

def main():
    repo = client.get_repo("jspahrsummers/Merc")

    last_successful_run: WorkflowRun = repo.get_workflow("main.yml").get_runs(status="success")[0]
    from_commit = last_successful_run.head_sha
    head_commit = subprocess.check_output(["git","rev-parse","HEAD"]).decode().strip()

    commit_log = "\n".join(f"* [{summary_from_commit_message(c.commit.message)}](<{c.commit.html_url}>)" for c in repo.compare(base=from_commit, head=head_commit).commits)
    print(f"[Changes](<https://github.com/jspahrsummers/Merc/compare/{from_commit}...{head_commit}>):\n{commit_log}")

if __name__ == "__main__":
    main()
