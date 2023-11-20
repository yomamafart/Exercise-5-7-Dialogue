# Exercise 5.7-Dialogue

Exercise for MSCH-C220

This exercise is an opportunity for you to experiment with an open source Godot Dialogue add-on called Dialogue Manager. Dialogue Manager is [still in very active development](https://github.com/nathanhoad/godot_dialogue_manager)—its Godot 4 release is currently at 2.29.0. It is still a little tricky to use around the edges, but it is a powerful system for creating and introducing dialogue systems into your games.

Fork this repository. When that process has completed, make sure that the top of the repository reads [your username]/Exercise-5-7-Dialogue. *Edit the LICENSE and replace BL-MSCH-C220 with your full name.* Commit your changes.

Clone the repository to a Local Path on your computer.

Open Godot. Import the project.godot file and open the "Dialogue" project.

Dialgoue Manager is released as a Godot add-on. I have already downloaded the plug-in and included it in the res://addon folder in this repository. You now need to enable the plug-in: this can be done in Project->Project Settings->Plugins and checking the "Dialogue Manager" Enable box.

Back in your main window, you should now see an additional workspace tab labeled Dialogue. This is where we will do most of the work for this exercise.

The Game scene consists of a cyborg and a zombie standing on a platform suspended over a beach. We are going to allow them to have a conversation. Open the Dialogic workspace.

Dialogic uses a few main categories for assembling dialogue trees. Dialogues will take place between characters, so we will first write what they will be saying.

In the Dialogue tab, create a new dialogue. Save it as `res://Dialogue/Dialogue.dialogue`. Replace the default text with the following:
```
~ main

Player: [[Hi|Hello|Howdy]], what is your name?
Zombie: Growl
- Are you a nice zombie?
	Zombie: Growl
- Are you going to eat my brains?
	Zombie: Growl
- End the conversation => END
Player: I guess I have to shoot you, now.
set Global.shoot()

=> END
```

We then need to set up a dialogue balloon for use with this dialogue. In the Project->Tools menu, select "Create copy of dialogue example balloon". Save it in the res://Dialogue/ folder.

Open res://Dialogue/balloon.tscn. Under the Dialogue node, add a HBoxContainer node. Make the VBoxContainer node a child of the HBoxContainer. Add a TextureRect node as the first child under HBoxContainer and rename it as Portrait. Right-click on the Portrait node and select `%Access As Unique Name`. Drag res://Assets/Player_Portrait.png into the Texture field of the Portrait node and select Expand Mode = Fit Width. Select the VBoxContainer node and in the Inspector, check Control->Container Sizing->Expand = on.

Edit res://balloon.gd, and replace its contents with the following:
```
extends CanvasLayer


@onready var balloon: Panel = %Balloon
@onready var character_portrait: TextureRect = %Portrait
@onready var character_label: RichTextLabel = %CharacterLabel
@onready var dialogue_label: DialogueLabel = %DialogueLabel
@onready var responses_menu: DialogueResponsesMenu = %ResponsesMenu
@export var portraits = [
	{ "name": "Player", "portrait": load("res://Assets/Player_Portrait.png") }
	,{ "name": "Zombie", "portrait": load("res://Assets/Zombie_Portrait.png") }
]

## The dialogue resource
var resource: DialogueResource

## Temporary game states
var temporary_game_states: Array = []

## See if we are waiting for the player
var is_waiting_for_input: bool = false

## See if we are running a long mutation and should hide the balloon
var will_hide_balloon: bool = false

## The current line
var dialogue_line: DialogueLine:
	set(next_dialogue_line):
		is_waiting_for_input = false

		# The dialogue has finished so close the balloon
		if not next_dialogue_line:
			queue_free()
			return

		dialogue_line = next_dialogue_line

		character_label.visible = not dialogue_line.character.is_empty()
		character_label.text = tr(dialogue_line.character, "dialogue")
		var found_p = false
		for p in portraits:
			if dialogue_line.character == p["name"]:
				character_portrait.texture = p["portrait"]
				found_p = true
		if not found_p:
			character_portrait.hide()

		dialogue_label.hide()
		dialogue_label.dialogue_line = dialogue_line

		responses_menu.hide()
		responses_menu.set_responses(dialogue_line.responses)

		# Show our balloon
		balloon.show()
		will_hide_balloon = false

		dialogue_label.show()
		if not dialogue_line.text.is_empty():
			dialogue_label.type_out()
			await dialogue_label.finished_typing

		# Wait for input
		if dialogue_line.responses.size() > 0:
			balloon.focus_mode = Control.FOCUS_NONE
			responses_menu.show()
		elif dialogue_line.time != "":
			var time = dialogue_line.text.length() * 0.02 if dialogue_line.time == "auto" else dialogue_line.time.to_float()
			await get_tree().create_timer(time).timeout
			next(dialogue_line.next_id)
		else:
			is_waiting_for_input = true
			balloon.focus_mode = Control.FOCUS_ALL
			balloon.grab_focus()
	get:
		return dialogue_line

func _ready() -> void:
	balloon.hide()
	Engine.get_singleton("DialogueManager").mutated.connect(_on_mutated)

func _unhandled_input(_event: InputEvent) -> void:
	# Only the balloon is allowed to handle input while it's showing
	get_viewport().set_input_as_handled()

## Start some dialogue
func start(dialogue_resource: DialogueResource, title: String, extra_game_states: Array = []) -> void:
	temporary_game_states =  [self] + extra_game_states
	is_waiting_for_input = false
	resource = dialogue_resource
	self.dialogue_line = await resource.get_next_dialogue_line(title, temporary_game_states)

## Go to the next line
func next(next_id: String) -> void:
	self.dialogue_line = await resource.get_next_dialogue_line(next_id, temporary_game_states)

### Signals

func _on_mutated(_mutation: Dictionary) -> void:
	is_waiting_for_input = false
	will_hide_balloon = true
	get_tree().create_timer(0.1).timeout.connect(func():
		if will_hide_balloon:
			will_hide_balloon = false
			balloon.hide()
	)

func _on_balloon_gui_input(event: InputEvent) -> void:
	# If the user clicks on the balloon while it's typing then skip typing
	if dialogue_label.is_typing and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		get_viewport().set_input_as_handled()
		dialogue_label.skip_typing()
		return

	if not is_waiting_for_input: return
	if dialogue_line.responses.size() > 0: return
	
	# When there are no response options the balloon itself is the clickable thing
	get_viewport().set_input_as_handled()

	if event is InputEventMouseButton and event.is_pressed() and event.button_index == 1:
		next(dialogue_line.next_id)
	elif event.is_action_pressed("ui_accept") and get_viewport().gui_get_focus_owner() == balloon:
		next(dialogue_line.next_id)

func _on_responses_menu_response_selected(response: DialogueResponse) -> void:
	next(response.next_id)
```

If, in the dialogue, the speaker is labeled "Player", you should see the player's portrait. If you indicate "Zombie", you should see the zombie portrait. Otherwise, the portrait will be hidden.

Add a script to the Player node in `res://Player/Player.tscn` (`res://Player/Player.gd`):
```
extends CharacterBody3D

const Balloon = preload("res://Dialogue/balloon.tscn")
var played = false


func _unhandled_input(event):
	if event.is_action_pressed("dialogue") and not played:
		var balloon = Balloon.instantiate()
		get_tree().current_scene.add_child(balloon)
		balloon.start(load("res://Dialogue/Dialogue.dialogue"), "main")
		played = true
``` 

Finally, open res://Global.gd and create a new `shoot()` function. It should cause the player's shoot animation to play, and then cause the Zombie to play the Death animation.

As you can see, Dialogue Manager is quite powerful, and we are barely scratching the surface. It can handle branching conversations, updating variables, multiple themes and player portraits, etc. The documentation is still quite rudimentary, but it linked from the README.md at [https://github.com/nathanhoad/godot_dialogue_manager](https://github.com/nathanhoad/godot_dialogue_manager). The creator, Nathan Hoad, has also created several fairly good YouTube tutorials exploring the plugin.

Save the scene and run your project. You should see the dialogue appear on the screen. You can advance from one text even to the next using the Space bar.

Quit Godot. In GitHub desktop, add a summary message, commit your changes and push them back to GitHub. If you return to and refresh your GitHub repository page, you should now see your updated files with the time when they were changed.

Now edit the README.md file. When you have finished editing, commit your changes, and then turn in the URL of the main repository page (https://github.com/[username]/Exercise-5-7-Dialogue) on Canvas.

The final state of the file should be as follows (replacing the "Created by" information with your name):
```
# Exercise 5.7—Dialogue

Exercise for MSCH-C220

An exploration of dialogue systems in Godot using Dialogue Manager.

## Implementation

 - Built using Godot 4.1.1
 - [Dialogue Manager 2.29.0](https://github.com/nathanhoad/godot_dialogue_manager) created by Nathan Hoad.

## References

None

## Future Development

None

## Created by 

Jason Francis
```