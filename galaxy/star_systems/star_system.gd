extends Resource
class_name StarSystem

## Describes the non-visual characteristics of a single star system.
##
## Visual characteristics, pre-existing nodes, etc., should all be saved into a scene that matches the [method scene_path].

## The human-readable name of this star system.
@export var name: StringName

## All hyperspace connections that this system has to other systems.
@export var connections: Array[StringName] = []

## The position of this star system within the galaxy.
@export var position: Vector3

## A weak reference to the [Galaxy] that this system is part of.
##
## This is populated when the galaxy is initialized.
var galaxy: WeakRef

## The resource path to this star system's scene.
func scene_path() -> String:
    return "res://galaxy/star_systems/scenes/%s.tscn" % self.name.to_snake_case()
