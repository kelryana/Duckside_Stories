extends CanvasLayer

@onready var rec_dot = $REC/HBoxContainer/RecDot

func _on_timer_timeout():
	rec_dot.visible = not rec_dot.visible
