# Development scripts

This directory contains scripts that are useful for development and testing of the project.

To use, set up a Python virtual environment:

```sh
python3 -m venv .venv
source .venv/bin/activate
```

Then, from the repository root, install dependencies:

```sh
pip install -r script/requirements.txt
```

Afterward, invoke scripts directly:

```sh
./script/claude.py
```

Note that some scripts may require additional setup or configuration. For example, `claude.py` requires an `ANTHROPIC_API_KEY` environment variable to be set.
