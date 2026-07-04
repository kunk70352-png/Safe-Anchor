## Anchor — Player-placed attraction point.
## Attracts nearby refugees within attraction_radius.
## Has a configurable lifetime; auto-destroys when time runs out.
class_name Anchor
extends Node2D

# ---- Signals ----
signal lifetime_expired(anchor: Anchor)

# ---- Exported Properties ----
@export var attraction_radius: float = 150.0:
	set(value):
		attraction_radius = value
		queue_redraw()
@export var lifetime: float = 15.0

# ---- Internal State ----
var _pulse_time: float = 0.0
var _remaining_lifetime: float = 0.0

# ---- Nodes ----
@onready var _timer: Timer = $LifetimeTimer


func _ready() -> void:
	add_to_group("attraction_sources")

	# Configure and start lifetime timer
	_timer.wait_time = lifetime
	_timer.one_shot = true
	_timer.timeout.connect(_on_lifetime_expired)
	_timer.start()
	_remaining_lifetime = lifetime


func _process(delta: float) -> void:
	_pulse_time += delta
	_remaining_lifetime = _timer.time_left
	queue_redraw()


func _on_lifetime_expired() -> void:
	lifetime_expired.emit(self)
	GameManager.remove_anchor()
	queue_free()


func _draw() -> void:
	# Pulse effect: radius oscillates slightly
	var pulse := 1.0 + sin(_pulse_time * 3.0) * 0.08
	var r := attraction_radius * pulse

	# Draw attraction radius (translucent blue, pulses)
	draw_circle(Vector2.ZERO, r, Color(0.0, 0.4, 1.0, 0.08))

	# Draw anchor cross (white with blue outline)
	var cross_size := 10.0 * pulse
	var blue := Color(0.2, 0.5, 1.0, 1.0)
	draw_line(Vector2(-cross_size, 0), Vector2(cross_size, 0), blue, 3.0)
	draw_line(Vector2(0, -cross_size), Vector2(0, cross_size), blue, 3.0)

	# Draw center dot
	draw_circle(Vector2.ZERO, 4.0, Color.WHITE)

	# Draw countdown ring (arc that shrinks as time runs out)
	if lifetime > 0:
		var fraction := _remaining_lifetime / lifetime
		var start_angle := -PI / 2.0
		var end_angle := start_angle + TAU * fraction
		draw_arc(Vector2.ZERO, 14.0, start_angle, end_angle, 32, Color.WHITE, 2.0)
