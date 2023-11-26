extends CharacterBody3D

const Balloon = preload("res://Dialogue/balloon.tscn")
var played = false


func _unhandled_input(event):
	if event.is_action_pressed("dialogue") and not played:
		var balloon = Balloon.instantiate()
		get_tree().current_scene.add_child(balloon)
		balloon.start(load("res://Dialogue/Dialogue.dialogue"), "main")
		played = true
		

func shoot():
	$AnimationTree.active = false
	$AnimationPlayer.play("Shoot")
