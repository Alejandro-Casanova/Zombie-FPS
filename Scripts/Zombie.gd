extends CharacterBody3D

const SPEED = 0.4
const JUMP_VELOCITY = 4.5
const ROTATION_FORCE = 4
const CLEANUP_TIMEOUT = 45 # Seconds to remove dead body from the game

const BLOW_SOUND = preload("res://Assets/Sound Effects/blow.wav")
const ZOMBIE_DEATH_SOUND = preload("res://Assets/Sound Effects/zombie_death.wav")

enum ZOMBIE_STATE {
  IDLE,
  WALKING,
  ATTACKING,
  DEAD
}

# Get the gravity from the project settings to be synced with RigidBody nodes.
# var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var desired_direction = Vector3(0, 0, 0)
var zombie_state = ZOMBIE_STATE.IDLE
var zombie_health = 5

func halt_zombie():
	desired_direction = Vector3(0, 0, 0)
	velocity = Vector3(0,0,0)
	
func _ready():
	$zombie_animated_model/AnimationPlayer.play('Idle')

func _physics_process(delta):
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	
	match zombie_state:
		ZOMBIE_STATE.IDLE:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)
		ZOMBIE_STATE.WALKING:
			if desired_direction.length() > 0:
				var desired_rotation = atan2(desired_direction.x, desired_direction.z)
				rotation.y = lerp_angle(rotation.y, desired_rotation, delta * ROTATION_FORCE)
				velocity = desired_direction * SPEED
		ZOMBIE_STATE.ATTACKING:
			pass
		ZOMBIE_STATE.DEAD:
			pass 

	# Manage Collitions
	var collision = move_and_collide(velocity * delta)
	if(collision): 
		if(collision.get_collider().name != "Floor"): # Ignore floor collitions
			var n = collision.get_normal().normalized() # Collision surface normal
			desired_direction = desired_direction - 2 * desired_direction.dot(n) * n # Reflect direction
		
		
func _on_timer_timeout():
	# Update zombie state every time the timer runs out (periodically)
	match zombie_state:
		ZOMBIE_STATE.IDLE:
			if randf() > 0.4:
				desired_direction = Vector3(randf_range(-1,1), 0, randf_range(-1,1)).normalized()
				$zombie_animated_model/AnimationPlayer.play('Walk')
				zombie_state = ZOMBIE_STATE.WALKING
		ZOMBIE_STATE.WALKING:
			if randf() > 0.8:
				halt_zombie()
				$zombie_animated_model/AnimationPlayer.play('Idle')
				zombie_state = ZOMBIE_STATE.IDLE
		ZOMBIE_STATE.ATTACKING:
			pass
		ZOMBIE_STATE.DEAD:
			queue_free()

func hit(damage):
	if zombie_state != ZOMBIE_STATE.DEAD:
		#$BlowSound.play()
		zombie_health -= damage
		if zombie_health <= 0: # Health run out
			zombie_state = ZOMBIE_STATE.DEAD # Update state
			
			halt_zombie()
			$CollisionShape3D.disabled = true # Disable hit box
			$zombie_animated_model/AnimationPlayer.play('Death1')
			$Timer.start(CLEANUP_TIMEOUT) # Start longer timer for resource cleanup
			$DeathSound.play()
