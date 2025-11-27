extends Node

var screen_margin: float = 20.0
var debug_mode: bool = true


func get_screen_bounds() -> Rect2:
	var viewport := get_viewport()
	if not viewport:
		if debug_mode:
			print("ScreenBoundsManager: Viewport não encontrado!")
		return Rect2()

	var camera := viewport.get_camera_2d()
	var viewport_size := viewport.get_visible_rect().size

	if camera:
		var camera_pos := camera.get_screen_center_position()
		var zoom := camera.zoom

		var half_size := (viewport_size / zoom) / 2.0

		var bounds := Rect2(
			camera_pos - half_size + Vector2(screen_margin, screen_margin),
			viewport_size / zoom - Vector2(screen_margin * 2.0, screen_margin * 2.0)
		)

		return bounds

	# SEM CÂMERA
	var bounds := Rect2(
		Vector2(screen_margin, screen_margin),
		viewport_size - Vector2(screen_margin * 2.0, screen_margin * 2.0)
	)

	return bounds


func clamp_position(pos: Vector2) -> Vector2:
	var bounds := get_screen_bounds()
	return pos.clamp(bounds.position, bounds.end)


func is_inside_screen(pos: Vector2) -> bool:
	return get_screen_bounds().has_point(pos)


func get_screen_size() -> Vector2:
	return get_screen_bounds().size


func set_margin(value: float):
	screen_margin = value


func set_debug_mode(active: bool):
	debug_mode = active


# Recalcula os limites somente depois da cena realmente carregar.
func update_bounds_after_scene_change():
	await get_tree().process_frame

	var camera := get_viewport().get_camera_2d()

	# Apenas recalcula os bounds ao chamar
	get_screen_bounds()
