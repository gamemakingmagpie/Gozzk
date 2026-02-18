extends Control

@onready var ChatContainer = $ChatContainer
# Called when the node enters the scene tree for the first time.
func _ready():

		
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_chat_received(Nickname,Msg,IsSubscriber,RoleCode,emojis:Dictionary):
	var NewChat:Chat = load('res://chat.tscn').instantiate()
	ChatContainer.add_child(NewChat)
	NewChat.ReceiveMessage(Nickname,Msg)
	


func _on_chat_receiver_channel_connected(Name: Variant, Thumbnail: Variant) -> void:
	%Label.text = Name
	%TextureRect.texture = Thumbnail
	
	pass # Replace with function body.


func _on_chat_receiver_channel_not_live() -> void:
	print("Channel Not Live. or check channel id?")
	pass # Replace with function body.


func _on_chat_receiver_channel_not_exist() -> void:
	print("Channel Doesn't exist, Check channel id?")
	pass # Replace with function body.
