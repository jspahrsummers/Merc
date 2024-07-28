#!.venv/bin/python

import os
import subprocess
from typing import Iterator

from dotenv import load_dotenv
from github import Auth, Github
from github.Commit import Commit
from github.Repository import Repository
from github.WorkflowRun import WorkflowRun

load_dotenv()

GITHUB_TOKEN = os.environ["GITHUB_TOKEN"]

auth = Auth.Token(GITHUB_TOKEN)
client = Github(auth=auth, per_page=1)


def summary_from_commit_message(message: str) -> str:
    return message.splitlines()[0]


def iterate_commits_first_parent(
    repo: Repository, base: str, head: str
) -> Iterator[Commit]:
    hide_commits = set()

    # .reversed doesn't work from PyGithub for some reason
    all_commits = list(repo.compare(base=base, head=head).commits)

    for commit in reversed(all_commits):
        if commit.sha in hide_commits:
            for parent in commit.parents:
                hide_commits.add(parent.sha)

            continue

        yield commit
        for parent in commit.parents[1:]:
            hide_commits.add(parent.sha)


def main():
    repo = client.get_repo("jspahrsummers/Merc")

    last_successful_run: WorkflowRun = repo.get_workflow("main.yml").get_runs(
        status="success"
    )[0]
    from_commit = last_successful_run.head_sha
    head_commit = subprocess.check_output(["git", "rev-parse", "HEAD"]).decode().strip()

    commit_log = "\n".join(
        f"* [{summary_from_commit_message(c.commit.message)}](<{c.commit.html_url}>)"
        for c in iterate_commits_first_parent(repo, base=from_commit, head=head_commit)
    )
    print(
        f"[Changes](<https://github.com/jspahrsummers/Merc/compare/{from_commit}...{head_commit}>):\n{commit_log}"
    )


if __name__ == "__main__":
    main()
