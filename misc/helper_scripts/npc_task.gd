extends Node
class_name NPCTask

enum scheduling_choice {ordered, timed}
enum type_choice {wait, guard, wander, patrol}
@export var user: Character
@export var type: type_choice
@export var scheduling: scheduling_choice
@export_range(0,10) var wait_time: float = 0.0
@export var guard_location: Vector2
@export var wander_max_distance: Vector2 = Vector2.ZERO
@export var patrol_points: Array[Vector2] = []
@export_group("Schedule")
@export_subgroup("Ordered")
@export var prev_task: NPCTask = null
@export_subgroup("Timed")
@export_range(0,23) var hour_start: int = 0
@export_range(0,23) var hour_end: int = 0
@export_range(0,59) var minute_start: int = 0
@export_range(0,59) var minute_end: int = 0
var executing: bool = false
signal task_completed

func _ready() -> void:
	if user == null:
		printerr("No User for Task")
		return
	if scheduling == scheduling_choice.ordered:
		if prev_task != null:
			prev_task.task_completed.connect(execute_task)
		else:
			execute_task()
	elif scheduling == scheduling_choice.timed:
		EventBus.subscribe("TIME_CHANGED", self, "check_time")

func check_time(time: Array[int])->void:
	if !executing:
		if time[1] == hour_start:
			if time[0] >= minute_start:
				execute_task()
		elif time[1] > hour_start && time[1] < hour_end:
			execute_task()
		elif time[1] == hour_end:
			if time[0] <= minute_end:
				execute_task()

func execute_task()->void:
	executing = true
	if type == type_choice.wait:
		await wait()
	elif type == type_choice.guard:
		await guard()
	elif type == type_choice.wander:
		await wander()
	elif type == type_choice.patrol:
		await patrol()
	task_completed.emit()
	executing = false

func wait()->void:
	await get_tree().create_timer(wait_time).timeout

func guard()->void:
	while user.position != guard_location:
		user.move_order.emit(guard_location)
		while user.state_machine.current_state.state_id != "IDLE":
			await user.state_machine.state_changed

func wander()->void:
	pass

func patrol()->void:
	pass
