extends CharacterBody3D

func die():
	$AnimationTree.active = false
	$AnimationPlayer.play("Death")


func _on_animation_player_animation_finished(anim_name):
	if anim_name == "Death":
		queue_free()
