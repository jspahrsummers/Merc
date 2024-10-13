extends Node
class_name AnthropicStream

var event_source: HTTPEventSource:
    set(value):
        if value == event_source:
            return
        
        if event_source:
            event_source.event.disconnect(self._on_event)
            event_source.stop()
        event_source = value
        if event_source:
            event_source.event.connect(self._on_event)

var _message := {}
var _current_content_block := {}
var _current_content_index := -1
var _current_partial_input_json := ""

signal error(stream: AnthropicStream, type: String, message: String)
signal contents_updated(stream: AnthropicStream, message: Dictionary)
signal finished(stream: AnthropicStream, message: Dictionary)

func _process(_delta: float) -> void:
    self.event_source.poll()

func _stop() -> void:
    self.event_source.stop()
    self.get_parent().remove_child(self)

func _on_event(event: ServerSentEvent) -> void:
    var data: Dictionary = JSON.parse_string(event.data)
    if not data:
        push_warning("Could not parse SSE event \"%s\" data" % event.type)
        return

    match event.type:
        "ping":
            pass

        "error":
            self.error.emit(self, data["type"], data["message"])
            self._stop()
        
        "message_start":
            var message_start: Dictionary = data["message"]
            if self._message:
                push_error("Duplicate \"message_start\" event received (original ID: %s, new ID: %s)" % [self._message["id"], message_start["id"]])
            
            self._message = message_start
        
        "content_block_start":
            if not self._message:
                push_error("\"content_block_start\" event received before \"message_start\"")
                return

            if self._current_content_block:
                push_error("Duplicate \"content_block_start\" event received")
            
            self._current_content_block = data["content_block"]
            
            var contents: Array[Dictionary] = self._message.get_or_add("content", [])
            self._current_content_index = data["index"]
            if self._current_content_index != len(contents):
                push_error("Out-of-order \"content_block_start\" event received (expected index %d, got %d)" % [len(contents), self._current_content_index])
                return

            contents.append(self._current_content_block)
            self.contents_updated.emit(self, self._message)
        
        "content_block_delta":
            if not self._current_content_block:
                push_error("\"content_block_delta\" event received before \"content_block_start\"")
                return
            
            if data["index"] != self._current_content_index:
                push_error("Out-of-order \"content_block_delta\" event received (expected index %d, got %d)" % [self._current_content_index, data["index"]])
                return
            
            var delta: Dictionary = data["delta"]
            match delta["type"]:
                "text_delta":
                    var existing_text: String = self._current_content_block.get("text", "")
                    self._current_content_block["text"] = existing_text + delta["text"]
                    self.contents_updated.emit(self, self._message)
                
                "input_json_delta":
                    self._current_partial_input_json += delta["partial_json"]
        
        "content_block_stop":
            if not self._current_content_block:
                push_error("\"content_block_stop\" event received before \"content_block_start\"")
                return
            
            if data["index"] != self._current_content_index:
                push_error("Out-of-order \"content_block_stop\" event received (expected index %d, got %d)" % [self._current_content_index, data["index"]])
                return

            if self._current_partial_input_json:
                self._current_content_block["input"] = JSON.parse_string(self._current_partial_input_json)
                self._current_partial_input_json = ""
                self.contents_updated.emit(self, self._message)

            self._current_content_block = {}
        
        "message_delta":
            if not self._message:
                push_error("\"message_delta\" event received before \"message_start\"")
                return
            
            var message_delta: Dictionary = data["delta"]
            self._message.merge(message_delta, true)
        
        "message_stop":
            if self._message:
                self.finished.emit(self, self._message)
            else:
                push_error("\"message_stop\" event received before \"message_start\"")

            self._stop()
        
        _:
            push_warning("Unrecognized SSE event \"%s\"" % event.type)
