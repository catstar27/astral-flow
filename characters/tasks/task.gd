extends Resource
class_name Task
## Base class representing an npc task
##
## Does nothing on its own, use subtypes instead

enum scheduling_choice { ## Choices for type of scheduling
	ordered, ## This task is part of an ordered schedule
	timed ## This task is part of a timed schedule
}
@export_group("Timed Schedule") ## Exports related to timed schedules only
@export_range(0,23) var hour_start: int = 0 ## Hour at which this task starts
@export_range(0,23) var hour_end: int = 0 ## Hour at which this task ends
@export_range(0,59) var minute_start: int = 0 ## Minute at which this task starts
@export_range(0,59) var minute_end: int = 0 ## Minute at which this task ends
var user: Character ## The user of this task to be operated on
var executing: bool = false ## Whether the task is executing
var paused: bool = false ## Whether the task is paused
signal task_completed ## Emitted when the task is completed
signal pause ## Emitted when this is paused
signal unpause ## Emitted when this is unpaused

func _init() -> void:
	pause.connect(pause_execution)
	unpause.connect(unpause_execution)

## Pauses this task
func pause_execution()->void:
	paused = true

## Unpauses this task
func unpause_execution()->void:
	paused = false

## Returns true if this task is within its allotted time slot
func check_time(time: Array[int])->bool:
	if !executing:
		if time[1] == hour_start:
			if time[0] >= minute_start:
				return true
		elif time[1] > hour_start && time[1] < hour_end:
			return true
		elif time[1] == hour_end:
			if time[0] <= minute_end:
				return true
	return false

## Executes the task if the conditions are correct
func execute_task()->void:
	if user.in_combat || executing:
		return
	executing = true
	await task()
	task_completed.emit()
	executing = false

## Function that this task will execute
func task()->void:
	printerr("Attempted to use task of base type, use subtypes instead")
	await user.get_tree().create_timer(.1).timeout
