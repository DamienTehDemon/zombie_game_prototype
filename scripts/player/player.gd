extends CharacterBody2D
@export var player_movement_speed:float = 8000.0

@export var player_sprint_use_modifier:bool = false
@export var player_sprint_modifier:float = 2.0
@export var player_sprint_maximum:float = 100.0
@export var player_sprint_drain_rate:float = 2.0
@export var player_sprint_regen_rate:float = 1.0
var player_sprinting:bool = false
var player_current_sprint = 100.0

signal player_started_moving
signal player_stopped_moving
signal player_started_sprinting
signal player_stopped_sprinting
signal player_sprint_changed(maximum,current)

signal player_turned_flashlight_on
signal player_turned_flashlight_off


func _process(delta):
	look_at_mouse()
	movement_logic(delta)
	vision_logic()
	melee_logic()
	shoot_logic()
	weapon_switch_logic()

# Weapon Switch
func weapon_switch_logic():
	if(Input.is_action_just_pressed("next_weapon")):
		%WeaponSystem.next_weapon()
	if(Input.is_action_just_pressed("previous_weapon")):
		%WeaponSystem.previous_weapon()
	
	
# Combat Logic
func melee_logic():
	if(Input.is_action_just_pressed("melee")):
		%WeaponSystem.melee()
func shoot_logic():
	if(Input.is_action_just_pressed("shoot")):
		%WeaponSystem.shoot()

# Vision Cone Logic
func vision_logic():
	var zombies = %Vision.get_overlapping_bodies()
	for zombie in zombies:
		if(zombie is TileMap == false and is_line_of_sight_clear(zombie)):
			zombie.show()

func is_line_of_sight_clear(enemy):
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(enemy.global_position, global_position)
	query.exclude = [self]
	var result = space_state.intersect_ray(query)
	if(result.is_empty() or result.is_empty()==false and result["rid"]==enemy.get_rid()):
		return true
	return false

func _on_vision_body_shape_exited(_body_rid, body, _body_shape_index, _local_shape_index):
	if(body is TileMap == false):
		body.hide()
		

# Movement Logic
func movement_logic(delta):
	if(Input.is_action_pressed("sprint") and player_current_sprint>0):
		player_sprinting = true
	else:
		player_sprinting = false
		
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if(player_sprinting):
		velocity = direction * player_movement_speed * delta *1.5
		if(velocity.length()>0.0):
			player_current_sprint -= player_sprint_drain_rate * delta
			player_sprint_changed.emit(player_sprint_maximum,player_current_sprint)
	else:
		velocity = direction * player_movement_speed * delta
		player_current_sprint += player_sprint_regen_rate * delta
		player_sprint_changed.emit(player_sprint_maximum,player_current_sprint)
			
	move_and_slide()

	if(player_sprinting==true):
		if(velocity.length()>0):
			player_started_sprinting.emit()
		else:
			player_stopped_moving.emit()
	else:
		if(velocity.length()>0):
			player_started_moving.emit()
		else:
			player_stopped_moving.emit()
	
func look_at_mouse():
	look_at(get_global_mouse_position())
