extends Label
class_name MessageLog

## Default lifetime (in seconds) for a short-lived message.
const SHORT_MESSAGE_LIFETIME = 5.0

## Default lifetime (in seconds) for a long-lived message.
const LONG_MESSAGE_LIFETIME = 30.0

## Audio to play when a new message is added.
@export var new_message_audio: AudioStreamPlayer

## Messages currently being displayed in the log.
var _messages := PackedStringArray()

## Push the given message text onto the log, with the given lifetime in seconds.
func add_message(message_text: String, lifetime: float = SHORT_MESSAGE_LIFETIME, play_sound: bool = true) -> void:
    assert(lifetime > 0, "Message should have a positive lifetime")

    self._messages.append(message_text)
    self._update_text()

    if play_sound:
        self.new_message_audio.play()
    
    await self.get_tree().create_timer(lifetime).timeout

    var index := self._messages.rfind(message_text)
    if index == -1:
        return

    self._messages.remove_at(index)
    self._update_text()

func clear() -> void:
    self._messages.clear()
    self._update_text()

func _update_text() -> void:
    self.text = "\n".join(self._messages)
