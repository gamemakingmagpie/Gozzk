extends Control

@onready var ChatContainer = $ChatContainer
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_chat_received(Nickname, Msg):
	var NewChat:Chat = load('res://chat.tscn').instantiate()
	ChatContainer.add_child(NewChat)
	NewChat.ReceiveMessage(Nickname,Msg)
	pass # Replace with function body.
