extends Label

func _ready() -> void:
    var stream := AnthropicClient.stream([
        {"role": "user", "content": "You are an AI assistant in a space game inspired by Escape Velocity. Write a first greeting to the player."}
    ])

    stream.contents_updated.connect(self._on_contents_updated)
    stream.finished.connect(self._on_finished)
    stream.error.connect(self._on_error)

func _on_contents_updated(stream: AnthropicStream) -> void:
    self._update_text_from_message(stream.get_message())

func _on_finished(stream: AnthropicStream) -> void:
    self._update_text_from_message(stream.get_message())

func _update_text_from_message(message: Dictionary) -> void:
    var content: Array[Dictionary] = message["content"]
    var message_text := ""

    for block in content:
        if block["type"] == "text":
            message_text += block["value"]
    
    self.text = message_text

func _on_error(_stream: AnthropicStream, type: String, message: String) -> void:
    self.text += "Error: %s: %s\n" % [type, message]
