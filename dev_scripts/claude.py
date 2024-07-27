#!.venv/bin/python

from typing import Iterable
from anthropic import Anthropic
from anthropic.types import Message, MessageParam
from dotenv import load_dotenv
from pathlib import Path
from rich.console import Console

load_dotenv()

client = Anthropic()
console = Console()

CONTEXT_PATHS = [
    'actors/**/*.gd',
    'galaxy/**/*.gd',
    'galaxy/main_galaxy.tres',
    'galaxy/star_system/star_systems/*.tres',
    'mechanics/**/*.gd',
    'mechanics/**/*.tres',
    'planet/**/*.gd',
    'screens/landing/**/*.gd',
    'ships/**/*.gd',
    'ships/**/*.tscn',
    'utils/**/*.gd',
]

SYSTEM_PROMPT = """\
Aid with designing the game Merc, an Escape Velocity-like game created with Godot 4. You should help with designing the game's mechanics, crafting story and game content, as well as programming behaviors into the game itself.

When designing new star systems and planets, keep the following in mind:
- There can only be one trading market for a whole star system. All planets within the system share the same trading market (meaning the same list of commodities and prices).
- Planetary descriptions should be interesting and captivating, but limit them to approximately five or so paragraphs."""

def load_context_from_file(path: Path) -> str:
    contents = path.read_text()
    return f"""\
<file path="{path}">
{contents}
</file>"""

def load_context_from_path(path_glob: str) -> str:
    return "\n".join([load_context_from_file(file) for file in Path('.').glob(path_glob)])

def load_project_context() -> str:
    return "\n".join([load_context_from_path(path) for path in CONTEXT_PATHS])

def sample(messages: Iterable[MessageParam], append_to_system_prompt: str | None = None) -> Message:
    system_prompt = SYSTEM_PROMPT
    if append_to_system_prompt is not None:
        system_prompt += f"\n\n{append_to_system_prompt}"

    with client.messages.stream(model="claude-3-5-sonnet-20240620", max_tokens=4096, system=system_prompt, messages=messages) as stream:
        for text in stream.text_stream:
            console.print(text, end='', style="dodger_blue2")
        console.print()

        return stream.get_final_message()

def main() -> None:
    project_context = load_project_context()

    messages = []
    while True:
        try:
            prompt = console.input('> ')
        except KeyboardInterrupt:
            return
        except EOFError:
            return

        console.print()

        user_message: MessageParam = {"role": "user", "content": prompt}

        try:
            with console.status("Sampling…"):
                assistant_message = sample(messages + [user_message], append_to_system_prompt=f"Use these files from the project to help with your response:\n{project_context}")

            messages += [user_message, assistant_message]
            console.print()
        except KeyboardInterrupt:
            console.print("\n\n[interrupted, discarding last turn]", style="bright_black")

if __name__ == '__main__':
    main()
