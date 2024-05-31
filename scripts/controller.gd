extends Resource

## Controls players and ai
class_name Controller

## Locomotion settings for the owning actor, do not set action animations
## as action animations should be set in the primary weapon
@export
var IDLE_LENGTH: float
@export
var WALK_LENGTH: float

## The tree that controls all animations
var animation_tree: AnimationTree

## Refernce to get all the animations
var animation_player: AnimationPlayer

## Who owns this controller
var owner: CharacterBody2D

@export
var direction_facing: Enums.DIRECTION_FACING

var playing_action_animation : bool = false

## Determines if we can handle calling the action of the target
func can_handle_action(target: Node) -> bool:
	# Return if there's nothing there
	if not is_instance_valid(target):
		return false
	
	if target.is_queued_for_deletion():
		return false
		
	if playing_action_animation:
		return false
		
	# Check the groups to make sure all of my equipment is in the actionable item
	for group in target.get_groups():
		if group.begins_with("_"):
			continue
		if group not in owner.equipment_manager.equipment[Enums.ITEM_TYPE.PRIMARY].can_action_with:
			return false
	return true
	
## Calls the action of a target if it can
func _handle_action(target: Node) -> void:
	# Check if we can do an action
	if not can_handle_action(target):
		return
	
	# Play that animation
	playing_action_animation = true
	__set_animation("Swing", 0, false, true)
	await owner.get_tree().create_timer(owner.equipment_manager.equipment[Enums.ITEM_TYPE.PRIMARY].attack_speed).timeout
	# Call that targets action
	target.action(owner.equipment_manager.equipment[Enums.ITEM_TYPE.PRIMARY])
	
	if owner.equipment_manager.equipment[Enums.ITEM_TYPE.PRIMARY].knock_back_strength != 0:
		target.apply_force(
			owner.global_position.direction_to(target.global_position),
			owner.equipment_manager.equipment[Enums.ITEM_TYPE.PRIMARY].knock_back_strength,
			.1,
			false
		)
	
	playing_action_animation = false

## Calls the interact of a target if it can
func handle_interact(target: Node) -> void:
	if can_handle_interact(target):
		target.interact(owner)

## Determines if we can handle interacting with the target
func can_handle_interact(target: Node) -> bool:
	if not is_instance_valid(target):
		return false
	
	if "Interact" not in target.get_groups():
		return false
	
	return true

## Updates the velocity of the owner
func _maneuver(v: Vector2, f: Vector2 = Vector2()) -> void:
	# Add velocity and play animations
	if v.normalized().round().x == 1: # Player walking Right
		direction_facing = Enums.DIRECTION_FACING.RIGHT
	if v.normalized().round().x == -1: # Player Walking left
		direction_facing = Enums.DIRECTION_FACING.LEFT
	if v.normalized().round().y == 1: # Player Walk Toward player
		direction_facing = Enums.DIRECTION_FACING.FRONT
	if v.normalized().round().y == -1: # Player Walk away from player
		direction_facing = Enums.DIRECTION_FACING.BACK
	if v == Vector2.ZERO: # Default to idle
		__set_animation("Idle", IDLE_LENGTH)
	else:
		__set_animation("Walk", WALK_LENGTH)
	
	owner.velocity = v + f


## Goes through all logic to set an animation
##
## If the is_one_shot is set to true, method will wait for desired time length and then return true
func __set_animation(state_machine_name: String, desired_length : float, is_locomotion: bool = true, is_one_shot: bool = false) -> void:

	# Set the animation variable accordingly. Also update the time
	if is_locomotion:
		animation_tree.set("parameters/Locomotion-Transitions/transition_request", state_machine_name)
	else:
		animation_tree.set("parameters/Action-Transitions/transition_request", state_machine_name)
	
	if playing_action_animation:
		__set_time_scale_node(state_machine_name, owner.equipment_manager.equipment[Enums.ITEM_TYPE.PRIMARY].attack_speed)
	else:
		__set_time_scale_node(state_machine_name, desired_length)
	
	if is_one_shot:
		# Start the animation
		animation_tree.get("parameters/%s/playback" % state_machine_name).start("Start")
		animation_tree.set("parameters/One-Shot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		
	
func __set_time_scale_node(state_machine_name: String, desired_time: float) -> void:
	var node_from_direction : String
	if direction_facing == Enums.DIRECTION_FACING.BACK:
		node_from_direction = "%s-Away"
	if direction_facing == Enums.DIRECTION_FACING.FRONT:
		node_from_direction = "%s-Toward"
	if direction_facing == Enums.DIRECTION_FACING.RIGHT:
		node_from_direction = "%s-Right"
	if direction_facing == Enums.DIRECTION_FACING.LEFT:
		node_from_direction = "%s-Left"
		
	node_from_direction = node_from_direction % state_machine_name
	
	var anim = animation_player.get_animation(node_from_direction)
	#if owner.get_groups().has("Player"):
		#print_debug((desired_time / anim.length))
	if is_instance_valid(anim):
		animation_tree.set("parameters/TimeScale/scale", ( (desired_time / anim.length)) )
