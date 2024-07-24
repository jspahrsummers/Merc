extends Resource
class_name Calendar

## The in-game clock and calendar for the Merc universe.
##
## This timekeeping system, Galactic Standard Time, is meant to represent something universal to all denizens, regardless of star system or planet. It's based on the rotational period of a fictional pulsar, approximately calibrated to Earth time. GST's base unit is a "cycle," with SI prefixes used to denote larger or smaller units.
##
## Approximate conversions to Earth time:
## [ul]
## 1 millicycle (mc) = 0.001 c ≈ 3.592 seconds
## 1 cycle (c) ≈ 59 minutes 52 seconds
## 1 kilocycle (kc) = 1000 c ≈ 41.59 days
## 1 megacycle (Mc) = 1000 kc ≈ 113.95 years
## [/ul]
##
## See [url]https://github.com/jspahrsummers/Merc/wiki/Time[/url] for more details.

## The rotation period of the pulsar used as the reference point for GST.
const PULSAR_ROTATION_PERIOD_MSEC = 1.337

## How many rotations of the pulsar correspond to 1 cycle.
const ROTATIONS_PER_CYCLE = 2686610

## The year (CE) that GST timekeeping began.
const TIMEKEEPING_STARTING_YEAR = 2050

## When [method increment_kilocycle] is called, the current cycle ([member get_current_cycle]) is reset, then offset by a random amount up to this bound.
##
## This is used to give players more interesting timestamps, instead of the cycle always starting at 0.
const MAX_RANDOM_CYCLE_OFFSET = 900

## The current (integral) kilocycle in game.
@export var current_kilocycle: int = 214 # ~4830 CE

## The millisecond tick when the current kilocycle started, used to calculate the current (sub-kilocycle) cycle.
var _current_kilocycle_start_ticks_msec: int

## The random offset to add to the current cycle, to make timestamps more interesting.
##
## See [constant MAX_RANDOM_CYCLE_OFFSET]
var _current_cycle_offset: float

func _init() -> void:
    self._reset_cycle()

func _reset_cycle() -> void:
    self._current_kilocycle_start_ticks_msec = Time.get_ticks_msec()
    self._current_cycle_offset = randf_range(0, MAX_RANDOM_CYCLE_OFFSET)

## Move forward the kilocycle counter by the given [param delta].
##
## Also resets the current cycle count [i]within[/i] the kilocycle.
func increment_kilocycle(delta: int=1) -> void:
    self.current_kilocycle += delta
    self._reset_cycle()

## Returns the number of cycles that have passed [i]within[/i] the current kilocycle.
func get_current_cycle() -> float:
    var msec_passed := Time.get_ticks_msec() - self._current_kilocycle_start_ticks_msec
    var rotations := msec_passed / PULSAR_ROTATION_PERIOD_MSEC
    var cycles := rotations / ROTATIONS_PER_CYCLE
    return cycles + self._current_cycle_offset

## Formats the current GST timestamp as a string, suitable for presentation.
func get_gst() -> String:
    return "%d.%04.4f GST" % [self.current_kilocycle, self.get_current_cycle()]
