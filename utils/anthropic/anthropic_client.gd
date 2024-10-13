extends Node

var api_key: String

const MODEL = "claude-3-5-sonnet-20240620"
const API_VERSION = "2023-06-01"
const BETA = "prompt-caching-2024-07-31"

const DEFAULT_MAX_TOKENS = 8192

func stream(messages: Array[Dictionary], system: Array[Dictionary] = [], max_tokens: int = DEFAULT_MAX_TOKENS, stop_sequences: PackedStringArray = PackedStringArray()) -> AnthropicStream:
    var headers := PackedStringArray([
        "x-api-key: %s" % self.api_key,
        "anthropic-beta: %s" % BETA,
        "anthropic-version: %s" % API_VERSION,
        "content-type: application/json"
    ])

    var request := {
        "model": MODEL,
        "messages": messages,
        "max_tokens": max_tokens,
        "stream": true,
        "temperature": 1.0,
    }

    if stop_sequences:
        request["stop_sequences"] = stop_sequences
    if system:
        request["system"] = system

    var event_source := HTTPEventSource.new()
    var error := event_source.connect_to_url("https://api.anthropic.com/v1/messages", headers, HTTPClient.METHOD_POST, JSON.stringify(request, "", false))
    if error != Error.OK:
        push_error("Could not stream response: %s" % error)
        return
    
    var anthropic_stream := AnthropicStream.new()
    anthropic_stream.event_source = event_source
    self.add_child(anthropic_stream)

    return anthropic_stream
