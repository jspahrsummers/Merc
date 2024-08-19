#!.venv/bin/python

import itertools
import sys
from pathlib import Path
from typing import Iterable

from anthropic import Anthropic
from anthropic.types.beta.prompt_caching import (
    PromptCachingBetaMessageParam as MessageParam,
)
from anthropic.types.beta.prompt_caching import (
    PromptCachingBetaTextBlockParam,
    PromptCachingBetaToolParam,
)
from anthropic.types.beta.prompt_caching.prompt_caching_beta_message import PromptCachingBetaMessage
from anthropic.types.beta.prompt_caching.prompt_caching_beta_message_param import PromptCachingBetaMessageParam
from dotenv import load_dotenv
from prompt_toolkit import PromptSession
from prompt_toolkit.history import FileHistory
from rich.console import Console
from rich.prompt import Confirm
from rich.syntax import Syntax
from rich.status import Status
from rich.theme import Theme
from typing import cast

load_dotenv()

console_theme = Theme(
    {
        "info": "rgb(127,127,127)",
        "warning": "rgb(255,135,0)",
        "error": "rgb(215,0,0)",
        "assistant": "rgb(0,95,255)",
    }
)
console = Console(theme=console_theme, soft_wrap=True)

client = Anthropic()

MODEL = "claude-3-5-sonnet-20240620"

CONTEXT_PATHS = [
    "actors/**/*.gd",
    "addons/market_editor/**/*.gd",
    "galaxy/**/*.gd",
    "galaxy/star_system/star_systems/*.tres",
    "mechanics/**/*.gd",
    "mechanics/**/*.tres",
    "planet/**/*.gd",
    "planet/**/*.tres",
    "screens/**/*.gd",
    "ships/**/*.gd",
    "utils/**/*.gd",
    "*.md",
]

SYSTEM_PROMPT = """\
Aid with designing the game Merc, an Escape Velocity-like game created with Godot 4. You should help with designing the game's mechanics, crafting story and game content, as well as programming behaviors into the game itself.

When designing new star systems and planets, keep the following in mind:
- There can only be one trading market for a whole star system. All planets within the system share the same trading market (meaning the same list of commodities and prices).
- Planetary descriptions should be interesting and captivating, but limit them to approximately five or so paragraphs.

You have a tool to replace the contents of a file, but wait to write code until specifically asked to do so."""

WRITE_FILE_TOOL = "write_file"

def load_context_from_file(path: Path) -> str:
    contents = path.read_text()
    return f"""\
<file path="{path}">
{contents}
</file>"""

def load_context_from_paths(paths: Iterable[Path]) -> str:
    return "\n".join(load_context_from_file(path) for path in paths)

def sample(
    messages: list[MessageParam], append_to_system_prompt: str | None = None
) -> PromptCachingBetaMessage:
    system_prompt = SYSTEM_PROMPT
    if append_to_system_prompt is not None:
        system_prompt += f"\n\n{append_to_system_prompt}"

    system_block: PromptCachingBetaTextBlockParam = {
        "type": "text",
        "text": system_prompt,
        "cache_control": {"type": "ephemeral"},
    }

    tools: list[PromptCachingBetaToolParam] = [
        {
            "name": WRITE_FILE_TOOL,
            "description": "Replace the contents of a file.",
            "input_schema": {
                "type": "object",
                "properties": {
                    "path": {"type": "string", "description": "File path to write to"},
                    "content": {
                        "type": "string",
                        "description": "The full, new content for the file.",
                    },
                },
                "required": ["path", "content"],
            },
        }
    ]

    with client.beta.prompt_caching.messages.stream(
        model=MODEL,
        max_tokens=8192,
        system=[system_block],
        messages=messages,
        tools=tools,
        extra_headers={
            "anthropic-beta": "prompt-caching-2024-07-31,max-tokens-3-5-sonnet-2024-07-15"
        },
    ) as stream:
        assistant_turn = ""
        current_tool: str | None = None
        status: Status | None = None

        try:
            for event in stream:
                match event.type:
                    case "text":
                        console.out(event.text, end="", style="assistant")
                        assistant_turn += event.text

                    case "content_block_start":
                        if event.content_block.type == "tool_use":
                            current_tool = event.content_block.name
                            status = Status(f"{current_tool}…")
                            status.start()
                        else:
                            current_tool = None

                    case "content_block_stop":
                        if status:
                            status.stop()
                            status = None

                        if event.content_block.type == "tool_use":
                            assert event.content_block.name == current_tool

                            # Type of this is wrong in the SDK, for some reason
                            input = cast(dict, event.content_block.input)
                            path: str = input["path"]
                            code: str = input["content"]

                            syntax = Syntax(
                                code=code,
                                lexer=Syntax.guess_lexer(
                                    path=path, code=code
                                ),
                                theme="ansi_light",
                            )
                            console.print(syntax)

                            if Confirm.ask(f"\nWrite to file {path}?", default=False):
                                Path(path).write_text(code)

                        current_tool = None
        finally:
            if status:
                status.stop()

        console.out()

        message = stream.get_final_message()
        console.print(message.usage.to_json(indent=None), style="info")
        if message.stop_reason == "max_tokens":
            console.print("\nReached max tokens.\n", style="info")

        return message


def main() -> None:
    histfile = Path(__file__).with_name(".claude_history")
    session = PromptSession(history=FileHistory(str(histfile)))

    paths = list(
        itertools.chain.from_iterable(
            Path(".").glob(path_glob) for path_glob in CONTEXT_PATHS
        )
    )
    context = load_context_from_paths(paths)
    messages: list[MessageParam] = []

    def handle_command(command: str) -> None:
        nonlocal paths
        nonlocal context

        parts = command.split()
        match parts[0]:
            case "/paths":
                console.print(*paths, sep="\n", style="info")

            case "/bytes":
                sizes = {path: path.stat().st_size for path in paths}
                sorted_sizes = sorted(
                    sizes.items(), key=lambda item: item[1], reverse=True
                )
                for path, size in sorted_sizes:
                    console.print(f"{path} ({size} bytes)", style="info")

            case "/context":
                console.print(context, style="info")

            case "/add":
                path_glob = parts[1]
                for new_path in Path(".").glob(path_glob):
                    if new_path in paths:
                        continue

                    paths.append(new_path)
                    console.print(f"Added: {new_path}", style="info")

                context = load_context_from_paths(paths)

            case "/remove":
                path_glob = parts[1]
                for remove_path in Path(".").glob(path_glob):
                    if remove_path not in paths:
                        continue

                    paths.remove(remove_path)
                    console.print(f"Removed: {remove_path}", style="info")

                context = load_context_from_paths(paths)

            case "/clear":
                paths = []
                context = ""
                console.print("Context cleared.", style="info")

            case "/exit" | "/quit":
                sys.exit(0)

            case "/history":
                console.print(*messages, sep="\n", style="info")

            case _:
                console.print("Unrecognized command.", style="error")

    while True:
        try:
            prompt = session.prompt("\n> ")
        except KeyboardInterrupt:
            return
        except EOFError:
            return

        if not prompt.strip():
            continue

        if prompt.startswith("/"):
            try:
                handle_command(prompt)
            except Exception as err:
                console.print(f"Exception handling command: {err}", style="error")

            continue

        user_message: MessageParam = {"role": "user", "content": prompt}

        try:
            assistant_message = sample(
                messages + [user_message],
                append_to_system_prompt=f"Use these files from the project to help with your response:\n{context}",
            )

            messages.append(user_message)
            messages.append({"role": assistant_message.role, "content": assistant_message.content})
            console.print()
        except KeyboardInterrupt:
            console.print("\n\nInterrupted. Discarding last turn.\n", style="info")
            # TODO: Offer resumption


if __name__ == "__main__":
    main()
