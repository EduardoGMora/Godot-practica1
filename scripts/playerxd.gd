extends Area2D

signal hit

@export var speed = 400
@export var roll_speed_multiplier = 1.1
var screen_size
var is_rolling = false
var is_attacking = false
var last_velocity = Vector2(0, 1) 

func _ready() -> void:
	screen_size = get_viewport_rect().size
	hide()
	#$AnimatedSprite2D.animation_finished.connect(_on_animated_sprite_2d_animation_finished)

func _process(delta):
	var velocity = Vector2.ZERO # El vector de movimiento del jugador.
	
	# ==========================================================
	# A. LÓGICA DE ESTADOS Y MOVIMIENTO
	# ==========================================================
	
	if is_attacking:
		pass 
	
	elif is_rolling:
		velocity = last_velocity.normalized() * speed * roll_speed_multiplier
		
	else:
		# Lógica de input normal (cuando no ataca ni esquiva)
		
		# 1. Chequeo de Ataque
		if !is_attacking and Input.is_action_just_pressed("attack"):
			is_attacking = true
			$AnimatedSprite2D.play("attack")
			
			## ¡ACTIVAR EL HITBOX DE ATAQUE!
			#$AttackHitbox/CollisionShape2D.disabled = false 
		
		# 2. Chequeo de Esquiva
		elif Input.is_action_just_pressed("roll"):
			# Solo se permite esquivar si hay alguna dirección de movimiento
			if last_velocity.length() > 0:
				is_rolling = true
				$AnimatedSprite2D.play("roll")
		
		# 3. Input de Movimiento
		if Input.is_action_pressed("move_right"):
			velocity.x += 1
		if Input.is_action_pressed("move_left"):
			velocity.x -= 1
		if Input.is_action_pressed("move_down"):
			velocity.y += 1
		if Input.is_action_pressed("move_up"):
			velocity.y -= 1
			
		# 4. Actualizar last_velocity 
		if velocity.length() > 0:
			last_velocity = velocity.normalized()
			velocity = last_velocity * speed
		# Si el jugador no se mueve, velocity será ZERO.

	# ==========================================================
	# B. APLICAR MOVIMIENTO Y LÓGICA DE ANIMACIÓN
	# ==========================================================

	# Aplicar el movimiento: Se hace aquí para que funcione en los tres estados (Idle/Run, Attack, Roll)
	position += velocity * delta
	position = position.clamp(Vector2.ZERO, screen_size)
	
	# Lógica de animación: Solo se aplica si no está atacando o esquivando
	if not is_attacking and not is_rolling:
		if velocity.length() > 0:
			$AnimatedSprite2D.play("run")
		else:
			$AnimatedSprite2D.play("idle")

	# Lógica de Flip/Rotación (Asegúrate de que no interfiera con las animaciones de ataque/roll)
	if not is_attacking and not is_rolling:
		if velocity.x != 0:
			$AnimatedSprite2D.flip_v = false
			$Trail.rotation = 0
			if velocity.x < 0:
				$AnimatedSprite2D.flip_h = true
			else:
				$AnimatedSprite2D.flip_h = false

		elif velocity.y != 0:
			pass 

func _on_attack_hitbox_body_entered(body):
	# Asume que tus villanos tienen un script que implementa una función 'take_damage'
	if body.has_method("take_damage"):
		# Puedes pasar el daño, la fuerza del ataque, etc.
		body.take_damage(1) 
		
		# O, si quieres que simplemente mueran
		# body.queue_free()

func start(pos):
	position = pos
	show()
	$CollisionShape2D.disabled = false
	$AnimatedSprite2D.play("idle")
	set_process(true)

func _on_body_entered(body):
	hit.emit()
	hide()
	$CollisionShape2D.set_deferred(&"disabled", true)


func _on_animated_sprite_2d_animation_finished():
	var current_animation = $AnimatedSprite2D.animation
	
	if current_animation == "attack":
		is_attacking = false
		#$Mob/CollisionShape2D.disabled = true
		
	if current_animation == "roll":
		is_rolling = false
