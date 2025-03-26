extends Sprite2D
class_name MoveArrow
## Sprite that makes an arrow point between points

const directions = {
	Vector2.RIGHT: 0,
	Vector2.DOWN: 1,
	Vector2.LEFT: 2,
	Vector2.UP: 3
}

const linked_frames = {
	Vector2.RIGHT: [10,11],
	Vector2.DOWN: [9,11],
	Vector2.LEFT: [8,9],
	Vector2.UP: [8,10]
}

## Makes the arrow point from start_pos to end_pos
func draw_between(start_pos: Vector2, end_pos: Vector2)->void:
	var dir_entry: Vector2 = (position-start_pos).normalized()
	var dir_exit: Vector2 = (position-end_pos).normalized()
	if abs(dir_entry) == abs(dir_exit):
		if abs(dir_entry) == Vector2.RIGHT:
			frame = 12
		else:
			frame = 13
		return
	for i in range(0,2):
		for j in range(0,2):
			if linked_frames[dir_entry][i] == linked_frames[dir_exit][j]:
				frame = linked_frames[dir_entry][i]
				return

## Makes an arrowhead
func draw_head(start_pos: Vector2, end_pos: Vector2)->void:
	var dir: Vector2 = (end_pos-start_pos).normalized()
	frame = 4+directions[dir]

## Makes the tail of the arrow
func draw_tail(start_pos: Vector2, end_pos: Vector2)->void:
	var dir: Vector2 = (end_pos-start_pos).normalized()
	frame = directions[dir]

## Sets the text on the label
func set_label(text: String)->void:
	$Label.text = text
