extends Resource
class_name Ability
## An ability which can be used by a Character
##
## Can perform tasks such as dealing damage or inflicting statuses

#region Variables and Signals
## Targeting options
enum target_type_options {
	user, ## This can be used only on the user
	allies, ## This can be used only on allies or tiles
	allies_or_user, ## This can be used on the user or allies or tiles
	enemies, ## This can be used only on enemies or tiles
	others, ## This can be used on anything other than the user
	all, ## This can be used on anything
	none ## This can be used only on tiles
	}
## Activation options
enum activation_type_options {
	melee, ## This ability is triggered through a melee attack
	projectile, ## This ability is triggered through a projectile
	summon ## This ability simply triggers at the destination
}
## Damage type options
enum damage_type_options {
	blunt, ## Physical damage relying on blunt force
	electric, ## Magical damage using electric charge
	none ## No damage is done
	}
## Conditions for Status application
enum status_effect_conditions {
	on_hit, ## Status applied when ability hits a target
	on_use ## Status applied when ability is used on target
}
## Skill options
enum skill_used_options {intelligence, agility, strength, endurance, resolve, charisma, passion}
var user: Character = null ## Character using the ability
@export var display_name: String = "NameHere" ## Name of the ability shown in the GUI
@export_multiline var description: String = "Description Here" ## Description of the ability
@export var icon: Texture2D ## Icon to show for this ability
@export var sound: AudioStreamWAV ## Sound that plays when the ability activates
@export_group("Costs")
@export var ap_cost: int = 0 ## Amount of AP used by the ability
@export var mp_cost: int = 0 ## Amount of MP used by the ability
@export_group("Targeting")
@export var ability_range: int = 1 ## Number of tiles away from the user this can target
@export var target_type: target_type_options = target_type_options.all ## The type of target this can be used on
@export var activation_type: activation_type_options = activation_type_options.melee ## The activation method
@export var animation_override: StringName = "" ## Overrides the generic animation
@export var projectile_scene: PackedScene = null ## Scene of projectile to use if this is projectile-based
@export_group("Effects")
@export var base_damage: int = 0 ## Unmodified damage of the ability
@export var ignore_defense: bool = false ## Whether damage from this ignores defense
@export var damage_type: damage_type_options = damage_type_options.blunt ## The type of damage this deals, for resistances
@export var skill_used: skill_used_options = skill_used_options.strength ## The user skill this checks, for accuracy and damage modifier
@export var statuses: Dictionary[Status, status_effect_conditions] ## List of statuses paired with the conditions for them to be applied
signal activated ## Sent when the ability is activated
#endregion

#region Setup
func setup() -> void:
	description += "\nAP Cost: "+str(ap_cost)+"\nMP Cost: "+str(mp_cost)+"\nRange: "
	if target_type == target_type_options.user:
		description += "Self"
	elif ability_range == 1:
		description += "Melee"
	else:
		description += str(ability_range)+" Tiles"

## Special version of duplicate for abilities
func duplicate_ability(subresources: bool = false)->Ability:
	var copy1: Ability = super.duplicate(subresources)
	copy1.setup()
	var status_dict: Dictionary[Status, status_effect_conditions]
	for status_to_copy in statuses.keys():
		status_dict[status_to_copy.duplicate(true)] = statuses[status_to_copy]
	return copy1
#endregion

#region Range and Targeting
## Returns a list of destinations that this can target
func get_valid_destinations()->Array[Vector2]:
	if target_type == target_type_options.user:
		return [user.position]
	var destinations: Array[Vector2] = []
	var scale_factor: int = NavMaster.tile_size
	for x in range(user.position.x-ability_range*scale_factor, user.position.x+ability_range*scale_factor+1, scale_factor):
		for y in range(user.position.y-ability_range*scale_factor, user.position.y+ability_range*scale_factor+1, scale_factor):
			var pos: Vector2 = Vector2(x,y)
			var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(user.global_position, pos, 2)
			if user.get_world_2d().direct_space_state.intersect_ray(query) == {}:
				if pos != user.position:
					if is_tile_valid(pos):
						destinations.append(pos)
	return destinations

## Returns true if the tile is a valid target
func is_tile_valid(destination: Vector2)->bool:
	var x_dist: float = abs(user.global_position.x-destination.x)
	var y_dist: float = abs(user.global_position.y-destination.y)
	var range_factor: float = (x_dist+y_dist)/NavMaster.tile_size
	if !is_target_valid(get_target(destination)):
		return false
	return range_factor<=ability_range

## Checks if a given target is a valid target for this ability
func is_target_valid(target: Node2D)->bool:
	if target is Interactive:
		return true
	elif target is Character:
		match target_type:
			target_type_options.user:
				if target == user:
					return true
			target_type_options.allies:
				if target not in user.enemies:
					return true
			target_type_options.allies_or_user:
				if target not in user.enemies || target == user:
					return true
			target_type_options.enemies:
				if target in user.enemies:
					return true
			target_type_options.others:
				if target != user:
					return true
			target_type_options.all:
				return true
			target_type_options.none:
				return false
	else:
		return true
	return false

## Gets the object at the given location
func get_target(destination: Vector2)->Node2D:
	return NavMaster.get_obj_at_pos(destination)

## Returns a color corresponding to the type of target this can affect
func get_targeting_color()->Color:
	match target_type:
		target_type_options.user:
			return Settings.gameplay.support_indicator_tint
		target_type_options.allies:
			return Settings.gameplay.support_indicator_tint
		target_type_options.allies_or_user:
			return Settings.gameplay.support_indicator_tint
		target_type_options.enemies:
			return Settings.gameplay.attack_indicator_tint
	return Settings.gameplay.attack_indicator_tint
#endregion

#region Effects
## Deals damage to a target if accuracy is good enough
func deal_damage(target: Node2D)->void:
	if target != null:
		@warning_ignore("integer_division")
		var total_damage: int = base_damage+(user.star_stats[skill_used_options.keys()[skill_used]]/2)
		@warning_ignore("integer_division")
		total_damage += (user.star_stat_mods[skill_used_options.keys()[skill_used]]/2)
		if target is Character:
			var accuracy: int = randi_range(1, 20) + user.star_stats[skill_used_options.keys()[skill_used]]
			accuracy += user.star_stat_mods[skill_used_options.keys()[skill_used]]
			if accuracy >= (target.base_stats.avoidance+target.stat_mods.avoidance):
				target.call_deferred("damage", user, total_damage, damage_type, ignore_defense)
				for status in statuses:
					if statuses[status] == status_effect_conditions.on_hit:
						inflict_status(target, status)
			else:
				var text_ind_pos: Vector2 = target.text_indicator_shift+target.global_position
				EventBus.broadcast("MAKE_TEXT_INDICATOR", ["Miss!", text_ind_pos])
		elif target.has_method("damage"):
			target.call_deferred("damage", user, total_damage, damage_type)

## Inflicts a status on a target
func inflict_status(target: Node2D, status: Status)->void:
	if status == null:
		return
	if target != null && target.has_method("add_status"):
		target.call_deferred("add_status", status, user)
#endregion

#region Activation
## Used by base ability class to call side functions related to activation
func activate(destination: Vector2)->void:
	match activation_type:
		activation_type_options.projectile:
			await activation_projectile(destination)
		activation_type_options.melee:
			await activation_melee(destination)
		activation_type_options.summon:
			await activation_summon(destination)
	play_sound()
	for status in statuses:
		if statuses[status] == status_effect_conditions.on_use:
			inflict_status(get_target(destination), status)
	if base_damage != 0:
		deal_damage(get_target(destination))
	activated.emit()

## Activates with casting or shooting animations and summons projectile
func activation_projectile(destination: Vector2)->void:
	if projectile_scene == null:
		printerr("Missing projectile scene for projectile-based ability "+str(self))
		return
	var projectile: Projectile = projectile_scene.instantiate()
	projectile.ability = self
	user.add_child(projectile)
	if animation_override != "" && user.anim_player.has_animation(animation_override):
		user.anim_player.play(animation_override)
		while user.anim_player.is_playing():
			await user.anim_player.animation_finished
	await projectile.shoot(destination)

## Activates with melee animations (WIP)
func activation_melee(_destination: Vector2)->void:
	if animation_override != "" && user.anim_player.has_animation(animation_override):
		user.anim_player.play(animation_override)
	else:
		user.anim_player.play("Character/melee")
	while user.anim_player.is_playing():
		await user.anim_player.animation_finished

## Activates with casting animations (WIP)
func activation_summon(_destination: Vector2)->void:
	if animation_override != "" && user.anim_player.has_animation(animation_override):
		user.anim_player.play(animation_override)
	else:
		user.anim_player.play("Character/melee")
	while user.anim_player.is_playing():
		await user.anim_player.animation_finished

## Plays the ability's activation sound
func play_sound()->void:
	if sound != null:
		EventBus.broadcast("PLAY_SOUND", [sound, "positional", user.global_position])
	else:
		printerr("Empty Sound for Ability: "+display_name)
#endregion

#region Status Functions

#endregion
