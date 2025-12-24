extends CharacterBody3D

# ================== BEÁLLÍTÁSOK ==================

@export var max_health:int = 10
@export var current_health:int

@export var max_chase_distance := 50.0

@export var turn_speed := 6.0

@export var acceleration := 8.0
@export var deceleration := 10.0

@export var chase_strafe_strength := 0.6   # mennyire tér ki oldalra
@export var chase_strafe_change_time := 1.2

var current_speed := 0.0

var strafe_dir := 0.0
var strafe_timer := 0.0

@export var speed := 3.2
@export var chase_speed := 4.6
@export var gravity := 20.0

@export var detection_range := 14.0
@export var lose_range := 18.0
@export var follow_distance := 1.5

@export var wander_min_time := 2.0
@export var wander_max_time := 5.0

# ================== NODE REFERENCIÁK ==================

@export var ground_ray: RayCast3D
@export var front_ray: RayCast3D
@export var left_ray: RayCast3D
@export var right_ray: RayCast3D

# ================== ÁLLAPOTOK ==================

enum State {
	IDLE,
	WANDER,
	CHASE
}

var state: State = State.WANDER
var target: Node3D

# ================== WANDER ==================

var wander_dir: Vector3 = Vector3.ZERO
var wander_time := 0.0

# ================== READY ==================

func _ready():
	randomize()
	set_target(get_tree().get_first_node_in_group("player"))
	_reset_strafe()
	_pick_new_wander()
	
	current_health = max_health
	
	$Health3D/SubViewport/HPControl/HPBar.max_value = max_health
	$Health3D/SubViewport/HPControl/HPBar.value = current_health
	
func _get_damage(damage:int):
	current_health -= damage
	
	$Health3D/SubViewport/HPControl/HPBar.max_value = max_health
	$Health3D/SubViewport/HPControl/HPBar.value = current_health
	$Health3D/SubViewport/HPControl/Label.text = str(current_health) + " / " + str(max_health)
	#$Health3D/AnimationPlayer.play("in")
	
	if current_health <= 0:
		_die()

func _die():
	queue_free()

func _reset_strafe():
	strafe_timer = randf_range(0.6, chase_strafe_change_time)
	strafe_dir = randf_range(-1.0, 1.0)

func _update_speed(target_speed: float, delta: float):
	if current_speed < target_speed:
		current_speed = move_toward(current_speed, target_speed, acceleration * delta)
	else:
		current_speed = move_toward(current_speed, target_speed, deceleration * delta)

# ================== MAIN LOOP ==================
func _physics_process(delta):
	_apply_gravity(delta)

	match state:
		State.IDLE:
			_process_idle(delta)
		State.WANDER:
			_process_wander(delta)
		State.CHASE:
			_process_chase(delta)

	move_and_slide()

# ================== ÁLLAPOT LOGIKA ==================

func _process_idle(delta):
	velocity.x = 0
	velocity.z = 0

	_check_player_detection()

func _process_wander(delta):
	wander_time -= delta

	if wander_time <= 0:
		_pick_new_wander()

	if _is_path_blocked() or not ground_ray.is_colliding():
		_pick_new_wander(true)

	_update_speed(speed, delta)

	velocity.x = wander_dir.x * current_speed
	velocity.z = wander_dir.z * current_speed

	_smooth_look(wander_dir, delta)
	_check_player_detection()


func _process_chase(delta):
	if not target:
		state = State.WANDER
		return

	var to_target = target.global_position - global_position
	to_target.y = 0

	var distance = to_target.length()
	
	# --------- OPTIMALIZÁLT TÁVOLSÁG ELLENŐRZÉS ---------
	if distance > max_chase_distance:
		state = State.WANDER
		current_speed = 0.0
		return
	elif distance > lose_range:
		state = State.WANDER
		_update_speed(0, delta)
		return

	var dir = to_target.normalized()

	# --------- STRAFE LOGIKA ---------
	strafe_timer -= delta
	if strafe_timer <= 0:
		_reset_strafe()

	var right = Vector3(dir.z, 0, -dir.x)
	dir += right * strafe_dir * chase_strafe_strength
	dir = dir.normalized()

	# --------- AKADÁLYKERÜLÉS ---------
	if _is_path_blocked():
		dir = _avoid_direction(dir)

	# --------- SEBESSÉG ---------
	var target_speed = chase_speed
	if distance < follow_distance:
		target_speed = 0.0

	_update_speed(target_speed, delta)

	velocity.x = dir.x * current_speed
	velocity.z = dir.z * current_speed

	_smooth_look(dir, delta)

# ================== SEGÉD FUNKCIÓK ==================

func _apply_gravity(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0

func _pick_new_wander(force := false):
	wander_time = randf_range(wander_min_time, wander_max_time)

	var dir = Vector3(
		randf_range(-1.0, 1.0),
		0,
		randf_range(-1.0, 1.0)
	).normalized()

	wander_dir = dir

func _check_player_detection():
	if not target:
		return

	var dist = global_position.distance_to(target.global_position)
	if dist <= detection_range and dist <= max_chase_distance:
		state = State.CHASE

func _is_path_blocked() -> bool:
	return front_ray.is_colliding()

func _avoid_direction(current_dir: Vector3) -> Vector3:
	if not left_ray.is_colliding():
		return -transform.basis.x
	if not right_ray.is_colliding():
		return transform.basis.x
	return -current_dir

func _smooth_look(dir: Vector3, delta: float):
	if dir.length() < 0.01:
		return

	var target_yaw = atan2(dir.x, dir.z)
	var speed_mod = clamp(Vector3(velocity.x, 0, velocity.z).length() / chase_speed, 0.3, 1.0)
	rotation.y = lerp_angle(rotation.y, target_yaw, turn_speed * speed_mod * delta)

# ================== KÜLSŐ HÍVÁS ==================

func set_target(node: Node3D):
	target = node


func _on_hp_label_fade_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		$Health3D/AnimationPlayer.play("in")
		pass
		
func _on_hp_label_fade_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		$Health3D/AnimationPlayer.play("out")
