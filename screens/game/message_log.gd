extends Label
class_name MessageLog

@export_range(1.0, 10.0, 0.5, "suffix:s") var message_lifetime: float = 5.0

## Messages currently being displayed in the log.
##
## Each entry is a dictionary with the following keys:
##      - "text": The message text.
##      - "created_at": The msec ticks at which the message was created, used to automatically expire it.
var _messages: Array[Dictionary] = []

## Push the given message text onto the log.
func add_message(message_text: String) -> void:
    self._messages.push_back({
        "text": message_text,
        "created_at": Time.get_ticks_msec()
    })
    self._update_text()

func _update_text() -> void:
    var new_text := ""
    for message in self._messages:
        new_text += message["text"] + "\n"
    
    self.text = new_text

func _process(_delta: float) -> void:
    var now := Time.get_ticks_msec()
    var messages_to_remove := 0
    for i in range(self._messages.size()):
        var message := self._messages[i]
        var created_at: int = message["created_at"]
        if now - created_at < int(self.message_lifetime * 1000):
            break
        
        messages_to_remove += 1
    
    if messages_to_remove == 0:
        return
    
    self._messages = self._messages.slice(messages_to_remove)
    self._update_text()
