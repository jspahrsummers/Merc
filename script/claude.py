#!.venv/bin/python

import itertools
import sys
from collections.abc import Callable, Iterator
from contextlib import contextmanager
from copy import deepcopy
from pathlib import Path
from signal import SIGINT, signal
from typing import Iterable, cast

from anthropic import Anthropic
from anthropic.types.beta.prompt_caching import (
    PromptCachingBetaMessageParam,
    PromptCachingBetaTextBlockParam,
    PromptCachingBetaToolParam,
)
from anthropic.types.beta.prompt_caching.prompt_caching_beta_message import (
    PromptCachingBetaMessage,
)
from dotenv import load_dotenv
from prompt_toolkit import PromptSession
from prompt_toolkit.history import FileHistory
from rich.console import Console
from rich.prompt import Confirm
from rich.status import Status
from rich.syntax import Syntax
from rich.theme import Theme

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
    "actors/**/*",
    "addons/market_editor/**/*",
    "fx/**/*.gd",
    "galaxy/**/*.gd",
    "galaxy/map/galaxy_map_window.tscn",
    "galaxy/planet/**/*.tres",
    "galaxy/star_system/scenes/*.tscn",
    "galaxy/star_system/star_systems/*.tres",
    "mechanics/**/*.gd",
    "mechanics/**/*.tres",
    "screens/**/*.gd",
    "screens/**/*.tscn",
    "ships/**/*.gd",
    "utils/**/*.gd",
    "*.md",
    "project.godot",
]

AWARENESS_PATHS = [
    "ships/**/*.tscn",
    "stars/**/*.tscn",
]

SYSTEM_PROMPT = """\
Aid with designing the game Merc, an Escape Velocity-like game created with Godot 4. You should help with designing the game's mechanics, crafting story and game content, as well as programming behaviors into the game itself.

When designing new star systems and planets, keep the following in mind:
- There can only be one trading market for a whole star system. All planets within the system share the same trading market (meaning the same list of commodities and prices).
- Planetary descriptions should be interesting and captivating, but limit them to approximately five or so paragraphs.

You have a tool to replace the contents of a file, but wait to write code until specifically asked to do so."""

WRITE_FILE_TOOL = "write_file"


def load_context_from_file(path: Path) -> str:
    try:
        contents = path.read_text()
    except Exception:
        console.print(f"Error reading file: {path}", style="error")
        console.print_exception()
        return ""

    return f"""\
<file path="{path}">
{contents}
</file>"""


def load_context_from_paths(paths: Iterable[Path]) -> str:
    return "\n".join(load_context_from_file(path) for path in paths)


@contextmanager
def catch_interrupts(should_continue_fn: Callable[[], bool]):
    in_handler = False

    def handler(signum, frame):
        nonlocal in_handler
        if in_handler:
            raise KeyboardInterrupt

        in_handler = True
        should_continue = should_continue_fn()
        in_handler = False

        if not should_continue:
            raise KeyboardInterrupt

    prev = signal(SIGINT, handler)
    try:
        yield
    finally:
        signal(SIGINT, prev)


def sample(
    messages: list[PromptCachingBetaMessageParam],
    append_to_system_prompt: str | None = None,
) -> PromptCachingBetaMessage:
    system_prompt = SYSTEM_PROMPT
    if append_to_system_prompt is not None:
        system_prompt += append_to_system_prompt

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
                    "path": {
                        "type": "string",
                        "description": "The relative filesystem path to write to",
                    },
                    "content": {
                        "type": "string",
                        "description": "The full, new content for the file.",
                    },
                },
                "required": ["path", "content"],
            },
            "cache_control": {"type": "ephemeral"},
        }
    ]

    current_tool: str | None = None
    status: Status | None = None

    def check_continue() -> bool:
        if status:
            status.stop()

        result = Confirm.ask("\n\nInterrupted. Do you want to continue?", default=True)
        if result and status:
            status.start()

        return result

    with catch_interrupts(check_continue), client.beta.prompt_caching.messages.stream(
        model=MODEL,
        max_tokens=8192,
        system=[system_block],
        messages=messages,
        tools=tools,
        extra_headers={
            "anthropic-beta": "prompt-caching-2024-07-31,max-tokens-3-5-sonnet-2024-07-15"
        },
    ) as stream:
        try:
            for event in stream:
                match event.type:
                    case "text":
                        console.out(event.text, end="", style="assistant")

                    case "content_block_start":
                        if event.content_block.type == "tool_use":
                            console.print("\n")
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
                                lexer=Syntax.guess_lexer(path=path, code=code),
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


def glob_paths(globs: Iterable[str]) -> Iterator[Path]:
    paths = itertools.chain.from_iterable(
        Path(".").glob(path_glob) for path_glob in globs
    )

    return (path for path in paths if path.is_file() and not path.name.startswith("."))


def main() -> None:
    histfile = Path(__file__).with_name(".claude_history")
    session = PromptSession(history=FileHistory(str(histfile)))

    context_paths = set(glob_paths(CONTEXT_PATHS))
    awareness_paths_list = "\n".join(str(path) for path in glob_paths(AWARENESS_PATHS))

    context = load_context_from_paths(context_paths)
    messages: list[PromptCachingBetaMessageParam] = []

    def handle_command(command: str) -> None:
        nonlocal context_paths
        nonlocal context

        parts = command.split()
        match parts[0]:
            case "/paths":
                console.print(*context_paths, sep="\n", style="info")

            case "/bytes":
                sizes = {path: path.stat().st_size for path in context_paths}
                sorted_sizes = sorted(
                    sizes.items(), key=lambda item: item[1], reverse=True
                )
                for path, size in sorted_sizes:
                    console.print(f"{path} ({size} bytes)", style="info")

            case "/context":
                console.print(context, style="info")

            case "/add":
                for new_path in glob_paths(parts[1:]):
                    if new_path in context_paths:
                        continue

                    context_paths.add(new_path)
                    console.print(f"Added: {new_path}", style="info")

                context = load_context_from_paths(context_paths)

            case "/remove":
                for remove_path in glob_paths(parts[1:]):
                    if remove_path not in context_paths:
                        continue

                    context_paths.remove(remove_path)
                    console.print(f"Removed: {remove_path}", style="info")

                context = load_context_from_paths(context_paths)

            case "/clear":
                context_paths = []
                context = ""
                console.print("Context cleared.", style="info")

            case "/exit" | "/quit":
                sys.exit(0)

            case "/history":
                console.print(*messages, sep="\n", style="info")

            case _:
                console.print("Unrecognized command.", style="error")

    assistant_message: PromptCachingBetaMessage | None = None
    user_message: PromptCachingBetaMessageParam

    while True:
        if assistant_message and assistant_message.content[-1].type == "tool_use":
            # Fill in tool use result and keep sampling
            user_message = {
                "role": "user",
                "content": [
                    {
                        "type": "tool_result",
                        "tool_use_id": assistant_message.content[-1].id,
                        "cache_control": {"type": "ephemeral"},
                    }
                ],
            }
        else:
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

            user_message = {
                "role": "user",
                "content": [
                    {
                        "type": "text",
                        "text": prompt,
                        "cache_control": {"type": "ephemeral"},
                    }
                ],
            }

        try:
            assistant_message = sample(
                messages + [user_message],
                append_to_system_prompt=f"""

Use these files from the project to help with your response:
{context}

And here are some files whose existence you should be aware of, though you do not have access to their contents:
{awareness_paths_list}""",
            )

            # Only 4 cache breakpoints are allowed, so don't persist them in the message history
            del user_message["content"][-1]["cache_control"]  # type: ignore

            messages.append(user_message)
            messages.append(
                {"role": assistant_message.role, "content": assistant_message.content}
            )
            console.print()
        except KeyboardInterrupt:
            console.print("\n\nDiscarding last turn.\n", style="info")
        except Exception:
            console.print_exception()


if __name__ == "__main__":
    main()
