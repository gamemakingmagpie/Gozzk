extends Control
class_name Chat
@onready var NicknameLabel:Label = $HBoxContainer/Nickname
@onready var MessageLabel:Label = $HBoxContainer/Message

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func ReceiveMessage(Nickname,Message):
	NicknameLabel.text = Nickname
	MessageLabel.text = Message
	pass
