extends Sprite2D

@export var speed = 200.0
@export var pulse_speed = 2.0
@export var max_glow = 2.0

var time = 0.0

func _process(delta):
    # 1. Handle Movement
    var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    position += direction * speed * delta
    
    # 2. Handle the "Shader Pulse" (Bloom Effect)
    time += delta * pulse_speed
    var pulse_value = (sin(time) + 1.0) / 2.0 # Ranges 0.0 to 1.0
    
    # We update the shader uniform 'width' to make the outline grow and shrink
    # And we update 'outline_color' with a "Raw Value" > 1.0 to trigger Bloom/Glow
    if material:
        material.set_shader_parameter("width", 1.0 + (pulse_value * 2.0))
        var glow_color = Color(0.2, 0.8, 1.0, 1.0) * (1.0 + (pulse_value * max_glow))
        material.set_shader_parameter("outline_color", glow_color)
