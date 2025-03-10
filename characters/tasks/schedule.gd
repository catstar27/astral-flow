extends Resource
class_name Schedule
## Schedule of tasks

@export var tasks: Array[Task] ## Array of tasks in this schedule
@export var loop_schedule: bool = false ## Whether to loop this schedule on completion
@export var use_timed_schedule: bool = false ## Whether to use in game time to run tasks
var user: Character ## User of this schedule
var schedule_executed: bool = false ## Whether this schedule has executed
var task_index: int = 0 ## Index of current task
signal pause ## Emitted when this is paused
signal unpause ## Emitted when this is unpaused

func _init()->void:
	pause.connect(pause_execution)
	unpause.connect(unpause_execution)

## Pauses the current task
func pause_execution()->void:
	tasks[task_index].paused = true

## Unpauses the current task
func unpause_execution()->void:
	tasks[task_index].paused = false

## Duplicates this schedule and all its tasks
func duplicate_schedule()->Schedule:
	var new_schedule: Schedule = Schedule.new()
	new_schedule.loop_schedule = loop_schedule
	new_schedule.use_timed_schedule = use_timed_schedule
	for task in tasks:
		new_schedule.tasks.append(task.duplicate_task())
	return new_schedule

## Initializes the schedule by setting the user of all tasks and copying the tasks
func init_schedule()->void:
	for index in range(0, tasks.size()):
		tasks[index].user = user

## Processes the schedule, running the proper task
func process_schedule()->void:
	if tasks.size() == 0 || user.in_combat || !user.active:
		return
	if !loop_schedule && schedule_executed:
		return
	if !use_timed_schedule:
		user.schedule_processing = true
		if !tasks[task_index].task_completed.is_connected(task_done):
			tasks[task_index].task_completed.connect(task_done)
		tasks[task_index].call_deferred("execute_task")

## Called when the current task has been executed to determine the next action to take
func task_done()->void:
	tasks[task_index].task_completed.disconnect(task_done)
	user.schedule_processing = false
	task_index = (task_index+1)%tasks.size()
	if (task_index == 0 && !loop_schedule) || !user.active:
		if task_index == 0:
			schedule_executed = true
			if user.schedules[user.schedule_index] == self:
				user.current_schedule_executed = true
		return
	process_schedule()
