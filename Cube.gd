extends CharacterBody2D

const SPEED: float = 432.00
const JUMP_VELOCITY: float = 480.00 * 1.8
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity") * 3.3

@export var startPos: Node2D

# States
var gameStarted: bool = false
var inJump: bool = false
var notOnFloorSince: float = 0.0

# Nodes
@export var Events: Node
@onready var icon: Sprite2D = $"Icon"

var inAir: bool = false

var timeSinceLastJump: float = 0.0

var overlappingOrbs: Array[Node2D] = []

# Reset player
func resetp():
	velocity.x = SPEED
	velocity.y = 0
	position = startPos.position

	notOnFloorSince = 1.0
	inJump = false
	
# Reset map objects
func resetmo():
	get_tree().get_nodes_in_group("OrbUsed")
	remove_from_group("OrbUsed")

func verifyJumpRequirements():
	var spaceState = get_world_2d().direct_space_state

	var closeToFloorQuery = PhysicsRayQueryParameters2D.create(position + Vector2(0, 24), position + Vector2(0, 25))
	closeToFloorQuery.exclude = [self]

	var closeToFloor: bool = true if spaceState.intersect_ray(closeToFloorQuery) else false
	return !inJump and (is_on_floor() or notOnFloorSince < 0.2 or closeToFloor == true)

func _ready() -> void:
	# Defining Start Game Signal
	Events.startGame.connect(startGame)
	resetp() # Reseting Player
	resetmo() # Reseting Map Objects

# Start Game "Lambda"
func startGame() -> void:
		gameStarted = true

func _physics_process(delta: float) -> void:
	if not gameStarted:
		return

	# Add gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	
	# Handle Jump
	if Input.is_action_pressed("Jump") and verifyJumpRequirements():
		velocity.y = -JUMP_VELOCITY
		inJump = true;
	
	# Reseting In Jump State
	if (inJump and is_on_floor()):
		inJump = false
	
	# Handle Orbs
	for orb in overlappingOrbs:
		if orb.is_in_group("Yellow"):
			if Input.is_action_just_pressed("Jump") and not orb.is_in_group("OrbUsed"):
				orb.add_to_group("OrbUsed")
				velocity.y = -JUMP_VELOCITY
		elif orb.is_in_group("Orange"):
			if Input.is_action_just_pressed("Jump") and not orb.is_in_group("OrbUsed"):
				orb.add_to_group("OrbUsed")
				velocity.y = -JUMP_VELOCITY * 1.2

	# Handle Icon Rotation
	if !is_on_floor():
		icon.rotation_degrees += 250 * delta
		notOnFloorSince += delta

	elif is_on_floor():
		icon.rotation_degrees = lerp(icon.rotation_degrees, round(icon.rotation_degrees / 90) * 90, 0.2)
		notOnFloorSince = 0.0

	if Input.is_action_just_pressed("Debug"):
		resetp()
		resetmo()

	move_and_slide()

# Cube kill collision
func _on_block_collision_body_entered(body : Node2D) -> void:
	if body.is_in_group("Block"):
		resetp()
		resetmo()


func _on_instant_collision_body_entered(body : Node2D) -> void:
	# Instant Kill collision
	if body.is_in_group("Spike"):
		resetp()
		resetmo()

	# Orb collisions
	if body.is_in_group("Orb"):
		overlappingOrbs.append(body)

func _on_instant_collision_body_exited(body:Node2D) -> void:
	if body.is_in_group("Orb"):
		await get_tree().create_timer(0.1).timeout
		overlappingOrbs.erase(body)
