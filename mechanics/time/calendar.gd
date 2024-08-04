extends SaveableResource
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

## The maximum random variance in cycles to add or subtract when time passes.
const TIME_PASSING_RANDOMNESS = 0.1

## The in-game cycle in GST, [i]without[/i] accounting for how many ticks have passed in the game engine.
var _base_cycle: float:
    set(value):
        if value == _base_cycle:
            return

        _base_cycle = value
        self.emit_changed()

## The millisecond tick when the calendar started timekeeping.
var _calendar_start_ticks_msec: int

func _init() -> void:
    self._calendar_start_ticks_msec = Time.get_ticks_msec()
    self._base_cycle = 214000 + randf_range(0, 999) # ~4830 CE

## Advances the in-game clock by approximately the given number of [param days] (converted to GST).
func pass_approximate_days(days: float) -> void:
    var cycles_to_pass := days * 24 * randf_range(1 - TIME_PASSING_RANDOMNESS, 1 + TIME_PASSING_RANDOMNESS)
    self._base_cycle += cycles_to_pass

## Returns the current in-game cycle in GST, including accounting for actual (wall-clock) time that has passed in the game engine.
func get_current_cycle() -> float:
    var msec_passed := Time.get_ticks_msec() - self._calendar_start_ticks_msec
    var rotations := msec_passed / PULSAR_ROTATION_PERIOD_MSEC
    var cycle_offset := rotations / ROTATIONS_PER_CYCLE
    return self._base_cycle + cycle_offset

## Formats the current GST timestamp as a string, suitable for presentation.
func get_gst() -> String:
    var current_cycle := self.get_current_cycle()

    var kilocycles := int(current_cycle / 1000)
    var cycles := int(current_cycle) % 1000
    var millicycles := int((current_cycle - floorf(current_cycle)) * 1000)

    return "%03d.%03d.%03d GST" % [kilocycles, cycles, millicycles]

func save_to_dict() -> Dictionary:
    var result := {}
    result["cycle"] = self.get_current_cycle()
    return result

func load_from_dict(dict: Dictionary) -> void:
    self._calendar_start_ticks_msec = Time.get_ticks_msec()
    self._base_cycle = dict["cycle"]
