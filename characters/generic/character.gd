extends CharacterBody2D
class_name Character
## Class for characters that move and interact with the environment and other characters
##
## This base type represents anything not player-controlled

#region Stats
@export var star_stats: Dictionary[String, int] = { ## Stats on the stat star
	"intelligence": 10,
	"agility": 10,
	"strength": 10,
	"endurance": 10,
	"charisma": 10,
	"resolve": 10,
	"passion": 10
}
var star_stat_mods: Dictionary[String, int] = { ## Modifications to star stats
	"intelligence": 0,
	"agility": 0,
	"strength": 0,
	"endurance": 0,
	"charisma": 0,
	"resolve": 0,
	"passion": 0
}
var base_stats: Dictionary[String, int] = { ## Base stats calculated from star stats
	"max_ap": 0,
	"max_mp": 0,
	"max_hp": 0,
	"avoidance": 0,
	"crit_range": 1,
	"defense": 0,
	"dt": 10,
	"sequence": 0,
	"move_speed": 1
}
var stat_mods: Dictionary[String, int] = { ## Stat modifiers from statuses, etc.
	"max_ap": 0,
	"max_mp": 0,
	"max_hp": 0,
	"avoidance": 0,
	"crit_range": 0,
	"defense": 0,
	"dt": 0,
	"sequence": 0,
	"move_speed": 0
}
#endregion
#region Exports
enum ai_types { ## Options for enemy ai
	melee_aggressive, ## Aggressive melee attacker that tries to damage as much as possible
	melee_safe ## Safe melee attacker that tries to stay alive but still deal damage
}
@export var display_name: String = "Name Here" ## Name displayed in gui and logs
@export var portrait: Texture2D = preload("uid://b3jluv54rfg24") ## Character's portrait
@export var pronouns: String = "They/Them" ## Character's pronouns in gui and logs
@export var dialogues: Array[DialogicTimeline] ## Dialogues for the NPC to enter when interacted
@export var signal_dialogues: Dictionary[String, DialogicTimeline] ## Second set of dialogue for triggering through signals
@export var text_indicator_shift: Vector2 = Vector2.UP*32 ## Distance away from this to spawn text indicators
@export_group("Initial Stuff")
@export var starting_skills: Array[Skill] ## List of skills to start with
@export var starting_breakthroughs: Array[Breakthrough] ## List of breakthroughs
@export var export_abilities: Array[Ability] = [] ## Exported ability list for initial abilities
@export var starting_statuses: Array[Status] ## List of statuses to start with
@export var starting_items: Array[Item] ## List of items to start with
@export_group("Combat") ## Exports related to combat ai and what this considers an enemy
@export var ai_type: ai_types ## This enemy's ai type
@export var allies: Array[Character] = [] ## List of allies to bring into combat alongside this character
@export var enemies: Array[Character] = [] ## List of enemies to watch for
@export var hostile_to_player: bool = false ## Whether this character attacks the player on sight
@export_group("Schedule") ## Exports related to this character's schedule. Do not use for the player
@export var schedules: Array[Schedule] ## List of tasks for the character to carry out
@export_group("Activation") ## Exports related to character's active state
@export var active: bool = true ## Whether the character is active in the game map or disabled
#endregion
#region Vars
const range_indicator_scene: PackedScene = preload("res://misc/selection_cursor/range_indicator.tscn")
@onready var sprite: Sprite2D = %Sprite ## Sprite of this character
@onready var silhouette: Sprite2D = %Silhouette ## Silhouette of this character
@onready var anim_player: AnimationPlayer = %AnimationPlayer ## Animation Player for this character
@onready var state_machine: StateMachine = %StateMachine ## State Machine for this character
@onready var status_manager: StatusManager = %StatusManager ## Status Manager for this character
@onready var item_manager: ItemManager = %ItemManager ## Item Manager for this character
@onready var combat_trigger: Area2D = %CombatTrigger ## Area that tracks other characters for combat
@onready var collision: CollisionShape2D = %Collision ## Collision of the character
var skills: Array[Skill] ## Actual list of skills
var skill_ids: Array[String] ## List of ids for skills
var skill_effects: Array[SkillEffect] ## List of skill effects
var breakthroughs: Array[Breakthrough] ## Actual list of breakthroughs
var breakthrough_ids: Array[String] ## List of ids for breakthroughs
var abilities: Array[Ability] ## Actual list of abilities
var sequence: int ## Order of this character in the current combat and turn
var in_combat: bool = false ## Whether this character is in combat
var taking_turn: bool = false ## Whether this character is taking their turn
var range_indicators: Array[Sprite2D] = [] ## Range indicators for selected ability
var selected_ability: Ability = null ## Ability attempted to be used by the character
var skill_points: int ## Characters unused points for learning skills
var cur_ap: int ## Character's current action points
var cur_mp: int ## Character's current health points
var cur_hp: int ## Character's current magic points
var dialogue_index: int = 0 ## Current index of dialogue scene to play
var schedule_index: int = 0 ## Current index of the schedule being executed
var current_schedule_executed: bool = false ## Whether the current schedule has been finished at least once
var current_schedule_looping: bool = false ## Whether the current schedule is looping
var current_schedule_task_index: int = 0 ## Index of current schedule's current task
var schedule_processing: bool = false ## Whether the schedule is being executed currently
var is_selected: bool = false ## Whether this character is selected
var combat_target: Character = null ## The character this is attempting to attack
var watching: Dictionary[Node2D, RayCast2D] = {} ## Character/raycast pairs for characters in combat trigger
var speed_remainder: int = 0 ## Amount of unused free movement
var status_data: Dictionary[String, Variant] ## Save data for the status manager
var item_data: Dictionary[String, int] ## Save data holding item ids and amounts
var to_save: Array[StringName] = [ ## Variables to save
	"position",
	"star_stats",
	"base_stats",
	"skill_ids",
	"breakthrough_ids",
	"skill_points",
	"cur_hp",
	"cur_ap",
	"cur_mp",
	"active",
	"current_schedule_executed",
	"current_schedule_looping",
	"current_schedule_task_index",
	"schedule_index",
	"dialogue_index",
	"status_data",
	"item_data"
]
#endregion
#region Signals
signal move_order(pos: Vector2) ## Emitted when the character attempts to move
signal stop_move_order ## Emitted to halt character movement
signal interact_order(target: Node2D) ## Emitted when character tries interacting
signal ability_order(ability: Ability, destination: Vector2) ## Emitted when character tries using ability
signal pos_changed(character: Character) ## Emitted when the character's position changes
signal ended_turn(character: Character) ## Emitted when the character's turn ends
signal stats_changed ## Emitted when the character's stats change
signal abilities_changed ## Emitted when the character's abilities change
signal surrendered ## Emitted if the character surrenders in combat
signal surrendered_node(node: Character) ## Emitted if the character surrenders in combat; gives the node
signal surrendered_named(display_name: String) ## Emitted if the character surrenders in combat; gives the display name
signal defeated ## Emitted upon defeat; Sends nothing
signal defeated_node(node: Character) ## Emitted upon defeat; Sends the character defeated
signal defeated_at(pos: Vector2) ## Emitted upon defeat; Sends the character defeated position
signal defeated_named(display_name: String) ## Emitted upon defeat; Sends the character defeated name
signal damaged(source: Node) ## Emitted upon taking damage; Sends the damage source
signal revived ## Emitted if this character survives despite being lowered to 0 health or less
signal revived_named(display_name: String) ## Same as revived but sends the display name
signal rested ## Emitted when the character rests
signal combat_entered ## Emitted when the character enters combat
signal combat_exited ## Emitted when the character exits combat
signal ability_selected ## Emitted when the character selects an ability
signal ability_deselected ## Emitted when the character deselects their ability
signal saved(node: Character) ## Emitted when the character saves data
signal loaded(node: Character) ## Emitted when the character loads data
#endregion

#region Prep
func _ready() -> void:
	_setup()

## Called alongside _ready to setup the character
func _setup()->void:
	if !active:
		hide()
	EventBus.subscribe("GLOBAL_TIMER_TIMEOUT", self, "refresh")
	EventBus.subscribe("REST", self, "rest")
	status_manager.status_damage_ticked.connect(damage)
	status_manager.status_stat_mod_changed.connect(update_stat_mod)
	status_manager.status_action_occurred.connect(process_status_action)
	pos_changed.connect(status_manager.process_move)
	rested.connect(status_manager.process_rest)
	damaged.connect(status_manager.process_damage)
	damaged.connect(on_damaged)
	duplicate_export_abilities()
	calc_base_stats()
	cur_hp = base_stats.max_hp+stat_mods.max_hp
	cur_ap = base_stats.max_ap+stat_mods.max_ap
	cur_mp = base_stats.max_mp+stat_mods.max_mp
	silhouette.material = silhouette.material.duplicate()
	set_outline_color()
	EventBus.subscribe("GAMEPLAY_SETTINGS_CHANGED", self, "set_outline_color")
	init_schedule()
	init_statuses()
	init_skills()

## Duplicates the export abilities, copying them into the actual ability array
func duplicate_export_abilities()->void:
	for ability in export_abilities:
		var copy: Ability = ability.duplicate_ability()
		copy.user = self
		abilities.append(copy)

## Calculates base stats based on star stats
func calc_base_stats()->void:
	base_stats.max_hp = maxi(5+(star_stats.endurance-10)*2+(star_stats.strength-10), 5)
	base_stats.max_ap = maxi(2+(star_stats.agility-10)+(star_stats.resolve-10), 5)
	base_stats.max_mp = maxi(5+(star_stats.intelligence-10)+(star_stats.passion-10), 5)
	base_stats.avoidance = maxi(10+(star_stats.agility-10)*2+(star_stats.charisma-10), 0)
	base_stats.sequence = (star_stats.passion-10)+(star_stats.agility-10)

## Updates stat modifiers based on given args
func update_stat_mod(stat_mod_name: String, amount: int)->void:
	if stat_mod_name not in stat_mods:
		printerr("Attempted to change stat mod "+stat_mod_name+" not in stat_mods")
	else:
		stat_mods[stat_mod_name] += amount

## Refreshes the character; called either when a combat round starts or time ticks
func refresh()->void:
	cur_ap = base_stats.max_ap+stat_mods.max_ap
	stats_changed.emit()
	status_manager.tick_status()

## Rests the character, replenishing magic and health as well as action points
func rest()->void:
	cur_ap = base_stats.max_ap+stat_mods.max_ap
	cur_hp = base_stats.max_hp+stat_mods.max_hp
	cur_mp = base_stats.max_mp+stat_mods.max_mp
	rested.emit()
#endregion

#region Schedule
## Initializes the schedule by setting the user of all tasks and copying the tasks
func init_schedule()->void:
	var new_schedules: Array[Schedule]
	for schedule in schedules:
		var new_schedule: Schedule = schedule.duplicate_schedule()
		new_schedules.append(new_schedule)
		new_schedule.user = self
		new_schedule.init_schedule()
	schedules = new_schedules

## Starts executing the next schedule in the array
func next_schedule()->void:
	if schedule_index == schedules.size()-1:
		printerr("Attempted to change to nonexistent schedule in character "+display_name)
		return
	stop_looping()
	schedules[schedule_index].pause.emit()
	schedule_index += 1
	schedules[schedule_index].task_index = 0
	schedules[schedule_index].process_schedule()

## Stops the schedule from looping
func stop_looping()->void:
	schedules[schedule_index].loop_schedule = false

## Starts looping the schedule
func start_looping()->void:
	if !schedules[schedule_index].loop_schedule && schedules[schedule_index].schedule_executed && schedules.size() > 0:
		schedules[schedule_index].loop_schedule = true
		schedules[schedule_index].process_schedule()
#endregion

#region Orders
## Sets the position directly with no animation
func set_pos(pos: Vector2):
	EventBus.broadcast("POS_UNOCCUPIED", position)
	position = pos
	EventBus.broadcast("POS_OCCUPIED", position)

## Attempts to start moving the character
func move(pos: Vector2)->void:
	move_order.emit(pos)

## Attempts to stop the character from moving
func stop_movement()->void:
	stop_move_order.emit()

## Attempts to interact with a target
func interact(target: Node2D)->void:
	interact_order.emit(target)

## Attempts to activate an ability at a destination
func activate_ability(ability: Ability, destination: Vector2)->void:
	ability_order.emit(ability, destination)
#endregion

#region Combat
## Called when the character enters combat
func enter_combat()->void:
	in_combat = true
	speed_remainder = 0
	combat_entered.emit()

## Called when the character exits combat
func exit_combat()->void:
	in_combat = false
	combat_exited.emit()
	if schedules.size() > 0:
		schedules[schedule_index].process_schedule()

## Returns an array showing ap required for moving on a path of given length
func get_ap_for_path(path_length: int, use_ap: bool = true)->Array[Array]:
	if path_length < 1:
		printerr("Attempted to get ap for path of length zero on character "+display_name)
		return []
	var ap_arr: Array[Array] = [[]]
	ap_arr[0] = [cur_ap, speed_remainder]
	for index in range(1, path_length+1):
		if ap_arr[index-1][1] == 0:
			if in_combat && ap_arr[index-1][0] == 0:
				break
			ap_arr.append([ap_arr[index-1][0]-1, ap_arr[index-1][1]+base_stats.move_speed+stat_mods.move_speed-1])
		else:
			ap_arr.append([ap_arr[index-1][0], ap_arr[index-1][1]-1])
	if use_ap && in_combat:
		cur_ap = ap_arr.back()[0]
		speed_remainder = ap_arr.back()[1]
		stats_changed.emit()
	return ap_arr

## Rolls the character's current sequence, adding randomness to the turn order
func roll_sequence()->void:
	sequence = base_stats.sequence+stat_mods.sequence+randi_range(1,10)

## Attempts to surrender combat
func surrender()->void:
	if !in_combat:
		return
	hostile_to_player = false
	combat_target = null
	EventBus.broadcast("QUEST_EVENT", "defeat:"+display_name)
	surrendered.emit()
	surrendered_named.emit(display_name)
	surrendered_node.emit(self)
	if taking_turn:
		ended_turn.emit(self)

## Called upon defeat; also deactivates the character
func on_defeated()->void:
	status_manager.trigger_on_death()
	while status_manager.processing_conditionals:
		await status_manager.conditionals_processed
	if cur_hp > 0:
		EventBus.broadcast("MAKE_TEXT_INDICATOR", ["Revived!", text_indicator_shift+global_position, Color.ORANGE])
		anim_player.play("RESET")
		while anim_player.is_playing():
			await anim_player.animation_finished
		revived.emit()
		revived_named.emit(display_name)
		return
	EventBus.broadcast("PRINT_LOG","Defeated "+display_name)
	EventBus.broadcast("TILE_UNOCCUPIED", position)
	EventBus.broadcast("QUEST_EVENT", "defeat:"+display_name)
	if taking_turn:
		ended_turn.emit(self)
	defeated.emit()
	defeated_node.emit(self)
	defeated_at.emit(position)
	defeated_named.emit(display_name)
	deactivate()

## Damages the character for a given amount
func damage(source: Node, amount: int, _damage_type: Ability.damage_type_options, ignore_defense: bool = false)->void:
	var text_ind_pos: Vector2 = text_indicator_shift+global_position
	if amount >= base_stats.dt+stat_mods.dt || ignore_defense:
		cur_hp -= amount
		EventBus.broadcast("MAKE_TEXT_INDICATOR", [str(-amount), text_ind_pos])
	else:
		var damage_reduced: int = maxi(amount-base_stats.defense-stat_mods.defense, 0)
		cur_hp -= damage_reduced
		if damage_reduced > 0:
			EventBus.broadcast("MAKE_TEXT_INDICATOR", [str(-damage_reduced), text_ind_pos])
		else:
			EventBus.broadcast("MAKE_TEXT_INDICATOR", ["Blocked!", text_ind_pos])
	damaged.emit(source)
	stats_changed.emit()
	if cur_hp <= 0:
		anim_player.play("Character/defeat")

## Activates this character's ai, only if not controlled by player
func take_turn()->void:
	if self is not Player && combat_target != null:
		call_deferred(str(ai_types.keys()[ai_type]))
	elif self is not Player && combat_target == null:
		end_turn()

## Waits until the character is idle, then ends their turn
func end_turn()->void:
	while state_machine.current_state.state_id != "IDLE":
		await state_machine.state_changed
	remove_range_indicators()
	ended_turn.emit(self)

## Implementation of melee aggressive ai type that attacks with no self preservation
func melee_aggressive()->void:
	abilities.sort_custom(func(x,y): return x.base_damage>y.base_damage)
	if !abilities[0].is_tile_valid(combat_target.position):
		move(combat_target.position)
		await get_tree().create_timer(.01).timeout
		while state_machine.current_state.state_id != "IDLE":
			await state_machine.state_changed
	if abilities[0].is_tile_valid(combat_target.position):
		while cur_ap>=abilities[0].ap_cost:
			activate_ability(abilities[0], combat_target.position)
			while state_machine.current_state.state_id != "IDLE":
				await state_machine.state_changed
			if cur_hp <= 0:
				return
	end_turn()

## Implementation of melee safe ai type that attempts to stay alive and deal damage
func melee_safe()->void:
	end_turn()
#endregion

#region Inventory
## 
#endregion

#region Skills
## Initializes the skill list
func init_skills()->void:
	for skill in starting_skills:
		EventBus.broadcast("ADD_SKILL", [self, skill.id])
	for breakthrough in starting_breakthroughs:
		EventBus.broadcast("ADD_BREAKTHROUGH", [self, breakthrough.id])

## Adds the given skill to this character
func add_skill(skill: Skill)->void:
	if skill not in skills:
		skills.append(skill)
		if skill.id not in skill_ids:
			skill_ids.append(skill.id)
		for ability in skill.abilities:
			add_ability(ability)

## Adds the given breakthrough to this character
func add_breakthrough(breakthrough: Breakthrough)->void:
	if breakthrough not in breakthroughs:
		breakthroughs.append(breakthrough)
		if breakthrough.id not in breakthrough_ids:
			breakthrough_ids.append(breakthrough.id)
#endregion

#region Abilities
## Selects the given ability and places its indicators
func select_ability(ability: Ability)->void:
	while state_machine.current_state.state_id == "MOVE":
		await state_machine.state_changed
	selected_ability = ability
	place_range_indicators(ability)
	ability_selected.emit()

## Deselects the given ability and removes its indicators
func deselect_ability(will_reselect: bool = false)->void:
	selected_ability = null
	remove_range_indicators()
	if !will_reselect:
		ability_deselected.emit()

## Adds an ability
func add_ability(ability: Ability)->void:
	ability = ability.duplicate_ability(true)
	abilities.append(ability)
	ability.user = self
	abilities_changed.emit()

## Places indicators showing range for a given ability
func place_range_indicators(ability: Ability)->void:
	for location in ability.get_valid_destinations():
		var indicator: Sprite2D = range_indicator_scene.instantiate()
		indicator.modulate = ability.get_targeting_color()
		indicator.position = location-position
		add_child(indicator)
		range_indicators.append(indicator)

## Removes all indicators
func remove_range_indicators()->void:
	while range_indicators.size()>0:
		range_indicators.pop_front().queue_free()
#endregion

#region Status
## Initializes the status list with starting statuses
func init_statuses()->void:
	status_manager.remove_all_statuses()
	for status in starting_statuses:
		add_status(status, self, true)

## Adds the given status to this character
func add_status(status: Status, source: Node, quiet_add: bool = false)->void:
	status_manager.add_status(status, source)
	var info: Array = [status.display_name, text_indicator_shift+global_position, status.status_color]
	if !quiet_add:
		EventBus.broadcast("MAKE_TEXT_INDICATOR", info)

## Processes a status action, running the function with the given args
func process_status_action(action: Callable, args: Array)->void:
	deselect_ability()
	var prev_pos: Vector2 = position
	await action.call(args)
	if position != prev_pos:
		pos_changed.emit(self)
#endregion

#region Detection
func _process(_delta: float) -> void:
	if active:
		check_rays()

## Sets this character as hostile to the player
func set_player_enemy()->void:
	hostile_to_player = true

## Sets this character as non-hostile to the player
func set_player_neutral()->void:
	hostile_to_player = false

## Checks every ray this enemy is casting
func check_rays(_character: Character = null)->void:
	for character in watching:
		check_ray(character)

## Checks a ray corresponding to the character it is watching for
## Tries to start combat if the ray is colliding with its target
func check_ray(character: Character)->void:
	watching[character].target_position = character.position-position
	if watching[character].get_collider() == character:
		try_combat(character)

## Creates a new ray to track the character that entered the combat trigger
func _combat_trigger_entered(body: Node2D) -> void:
	if body is Character && body != self:
		var ray: RayCast2D = RayCast2D.new()
		ray.set_collision_mask_value(1, true)
		ray.set_collision_mask_value(2, true)
		add_child(ray)
		ray.target_position = body.position
		watching[body] = ray
		body.pos_changed.connect(check_ray)
		check_ray(body)

## Removes the ray corresponding to the tracked character
func _combat_trigger_exited(body: Node2D) -> void:
	if body is Character && body != self:
		body.pos_changed.disconnect(check_ray)
		remove_child.call_deferred(watching[body])
		watching[body].queue_free()
		watching.erase(body)

## Attempts to initiate combat with the given character
func try_combat(character: Character)->void:
	if !active:
		return
	if (!character.in_combat || !in_combat) && ((character is Player && hostile_to_player) || character in enemies):
		combat_target = character
		var participants: Array[Character] = [character, self]
		EventBus.broadcast("START_COMBAT", participants)
#endregion

#region Misc
## Called when interacted with
func _interacted(interactor: Character)->void:
	if interactor is Player:
		EventBus.broadcast("QUEST_EVENT", "interact_with:"+display_name)
		if dialogue_index < dialogues.size() && !hostile_to_player:
			EventBus.broadcast("ENTER_DIALOGUE", [dialogues[dialogue_index], true])

func activate_signal_dialogue(signal_name: String)->void:
	if signal_name in signal_dialogues.keys():
		EventBus.broadcast("ENTER_DIALOGUE", [signal_dialogues[signal_name], true])

## Increments the dialogue index
func next_dialogue()->void:
	dialogue_index += 1

## Sets the color of the character's outline
func set_outline_color()->void:
	var color: Color = Color(Settings.gameplay.selection_tint, 180.0/255.0)
	silhouette.material.set_shader_parameter("outline_color", color)

## Selects the character and adds the outline
func select()->void:
	silhouette.material.set_shader_parameter("width", 1)
	is_selected = true

## Deselects the character and removes the outline
func deselect()->void:
	silhouette.material.set_shader_parameter("width", 0)
	if has_method("deselect_ability"):
		call("deselect_ability")
	is_selected = false

## Activates the character, putting them into the game map at given position
func activate(pos: Vector2)->void:
	active = true
	collision.set_deferred("disabled", false)
	combat_trigger.set_deferred("disabled", false)
	position = pos
	EventBus.broadcast("TILE_OCCUPIED", [pos, self])
	show()
	if !schedule_processing && schedules.size() > 0:
		schedules[schedule_index].process_schedule()

## Deactivates the character
func deactivate()->void:
	active = false
	collision.set_deferred("disabled", true)
	combat_trigger.set_deferred("disabled", true)
	EventBus.broadcast("TILE_UNOCCUPIED", position)
	hide()

## Called when the character is damaged
func on_damaged(_source: Node)->void:
	return
#endregion

#region Saving and Loading
## Executes before making the save dict
func pre_save()->void:
	if schedules.size() > 0:
		current_schedule_executed = schedules[schedule_index].schedule_executed
		current_schedule_looping = schedules[schedule_index].loop_schedule
		current_schedule_task_index = schedules[schedule_index].task_index
	status_data = status_manager.get_save_data()

## Executes after making the save dict
func post_save()->void:
	saved.emit(self)

## Executes before loading data
func pre_load()->void:
	deselect()

## Executes after loading data
func post_load()->void:
	position = NavMaster.map.map_to_local(NavMaster.map.local_to_map(position))
	if schedules.size() > 0:
		schedules[schedule_index].schedule_executed = current_schedule_executed
		schedules[schedule_index].loop_schedule = current_schedule_looping
		schedules[schedule_index].task_index = current_schedule_task_index
	init_statuses()
	status_manager.load_save_data(status_data)
	for id in skill_ids:
		EventBus.broadcast("ADD_SKILL", [self, id])
	load_extra()
	state_machine.unpause()
	if active:
		activate(position)
	else:
		deactivate()
	loaded.emit(self)

## Contains extra protocol in child classes for after loading is complete
func load_extra()->void:
	return
#endregion
