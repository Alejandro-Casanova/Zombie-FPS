extends RigidBody3D

const MUZZLE_VELOCITY = 30
const CLEANUP_TIMEUP = 30
const BOUNCE_DUMP = 100
const g = Vector3.DOWN * 20

var velocity = Vector3.ZERO

var stale = false # If true, no more damae is inflicted or collition sound is played

# Called when the node enters the scene tree for the first time.
func _ready():
	$Timer.set_wait_time(CLEANUP_TIMEUP)

func _physics_process(delta):
	if transform.origin.is_equal_approx(transform.origin + velocity.normalized()):
		look_at(transform.origin + velocity.normalized(), Vector3.UP)
	
	var collision = move_and_collide(velocity * delta)
	if collision: 
		velocity = velocity.bounce(collision.get_normal()) / BOUNCE_DUMP
		
		if stale: return
		
		$AudioStreamPlayer3D.play()
		if collision.get_collider().has_method("hit"):
			collision.get_collider().hit(1)
		stale = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_timer_timeout():
	queue_free()
