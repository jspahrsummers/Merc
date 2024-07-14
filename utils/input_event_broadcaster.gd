extends Node

## Broadcasts input events from arbitrary nodes to other nodes that may want to handle them.

signal input_event(receiver: Node, event: InputEvent)

func broadcast(receiver: Node, event: InputEvent) -> void:
    self.input_event.emit(receiver, event)
