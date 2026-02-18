extends Node

#ChannelID를 원하는 방송에 맞춰서 변형해 주세요. 방송인의 주소 제일 뒤에있는 문자열이 고유 Channel ID 입니다.
@export var ChannelID = ''

#성인전용을 걸어놨을 경우 ChatChannelID가 검색 안되는 문제가 있습니다. 커스텀으로 Chat Channel ID를 기입해서 우회할 수 있도록 할 예정입니다.
var ChatChannelID:String = ''
var AccessToken = null
var socket = WebSocketPeer.new()
var reconnect_time = 0.0
var firstTime = true

const REQTICK = 10.0

signal ChannelConnected(Name:String, Thumbnail:Texture2D)
signal ChannelNotLive
signal ChannelNotExist
signal ChatReceived(Nickname,Msg,IsSubscriber,RoleCode,emojis)
signal Donation(Amount,Msg)


func _ready():
	#이모티콘 처리용. 이모티콘을 다운받을 폴더를 만들어옵니다.
	if not DirAccess.dir_exists_absolute('user://emojis'):DirAccess.make_dir_absolute('user://emojis')		
	#Test용. ChannelID를 Chat Receiver에 넣어준 이후에 불러오세요.
	Start()
	#ConLoad.visible=false
	pass # Replace with function body.

## 채팅 리시버를 시작합니다. 이 시점 이전에 ChannelID가 지정되어 있어야 합니다.
func Start():
	#Channel ID를 통해서 Chat Channel ID를 찾습니다.
	var HTTPSREQ = 'https://api.chzzk.naver.com/polling/v2/channels/%s/live-status'%ChannelID
	var HTTP = HTTPRequest.new()
	add_child(HTTP)
	HTTP.request_completed.connect(_on_cid_request_completed)
	HTTP.request(HTTPSREQ)
	await HTTP.request_completed
	if ChatChannelID == '':
		return
	print("Connected to Chat Channel : %s"%ChatChannelID)
	#Channel 에 접근 할 수 있게 해주는 Token을 받습니다.
	var TokenURL = 'https://comm-api.game.naver.com/nng_main/v1/chats/access-token?channelId=%s&chatType=STREAMING'%ChatChannelID
	var TOKENHTTP = HTTPRequest.new()
	add_child(TOKENHTTP)
	TOKENHTTP.request_completed.connect(_on_token_request_completed)
	TOKENHTTP.request(TokenURL)
	await TOKENHTTP.request_completed
	print('TOKEN Earned')
	socket.connect_to_url('wss://kr-ss3.chat.naver.com/chat')
	var HTTPSREQ_INFO = 'https://api.chzzk.naver.com/service/v1/channels/%s'%ChannelID
	var HTTP_INFO = HTTPRequest.new()
	add_child(HTTP_INFO)
	HTTP_INFO.request_completed.connect(_on_info_request_completed)
	HTTP_INFO.request(HTTPSREQ_INFO)
	

##프로세스에서 웹소켓 연결을 통해 정보를 지속적으로 받아옵니다. 
func _process(delta):
	if socket == null:
		return
	socket.poll()
	var state = socket.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		if ChatChannelID == '':return
		if firstTime:
			var INPUT = '{"ver":"3","cmd":100,"svcid":"game","cid":"%s","bdy":{"uid":null,"devType":2001,"accTkn":"%s","auth":"READ","libVer":"4.9.3","osVer":"Windows/10","devName":"Google Chrome/131.0.0.0","locale":"ko","timezone":"Asia/Seoul"},"tid":1}'%[ChatChannelID,AccessToken]
			socket.send_text(INPUT)
			firstTime = false
		else:
			reconnect_time -= delta
			if reconnect_time<0:
				socket.send_text('{"ver": "3","cmd": 10000}')
				reconnect_time = REQTICK
			
		while socket.get_available_packet_count():
			var info = JSON.parse_string(socket.get_packet().get_string_from_utf8())
			var body = info['bdy']
			if body is Array:
				for eachBody in body:
					#도네이션 처리. 익명후원때문에 profile이 null로 들어오기도 합니다.					
					var Extras:Dictionary = JSON.parse_string(eachBody['extras'])
					if Extras.has('payAmount'):
						Donation.emit(Extras.payAmount,eachBody.msg)
					if eachBody.profile == null: return#	익명후원 처리(익명은 그냥 안읽을래)
					var Profile = JSON.parse_string(eachBody['profile'])
					var IsSubscriber = true if Profile['streamingProperty'].has('subscription') else false
					var emojis:Dictionary = Extras.emojis if Extras.has('emojis') else {}
					if Profile.has('nickname'):
						#이모티콘이 들어가 있으면 다운받아옵니다.
						SendMessage(Profile['nickname'],eachBody['msg'],IsSubscriber,Profile['userRoleCode'],emojis)
	elif state == WebSocketPeer.STATE_CLOSING:
		pass
	elif state == WebSocketPeer.STATE_CLOSED:
		var code = socket.get_close_code()
		var reason = socket.get_close_reason()
		#print("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
		#set_process(false) # Stop processing.

	pass

##메세지를 띄웁니다.
func SendMessage(Nickname,Msg,IsSubscriber,RoleCode,emojis):
	for eachEmoji in emojis:
		if not FileAccess.file_exists('user://emojis/%s.res'%eachEmoji):
			var newRequest:=HTTPRequest.new()
			add_child(newRequest)
			newRequest.request_completed.connect(free_request.bind(newRequest,Nickname,Msg,IsSubscriber,RoleCode,emojis,eachEmoji))
			newRequest.request(emojis[eachEmoji])
			return
	#모든 이모티콘이 받아진게 확인되면 나갑니다.
	#받는 Label은 RichTextLabel로 해주세요. [img={size}]로 크기를 조절할 수 있습니다.
	var newMsg = Msg
	newMsg = newMsg.replace('{:','[img=22]user://emojis/')
	newMsg = newMsg.replace(':}','.res[/img]')
	ChatReceived.emit(Nickname,newMsg,IsSubscriber,RoleCode,emojis)
	pass

##채팅창용. 이모지가 없으면 다운받고, 있다면 채팅을 띄웁니다.
func free_request(result, response_code, headers, body,HTTP,Nickname,Msg,IsSubscriber,RoleCode,emojis,emoji_name):
	#이모티콘을 다운받아 저장시킵니다.
	var newTexture:Texture2D
	if emojis[emoji_name].ends_with('gif'):
		newTexture = GifManager.animated_texture_from_buffer(body)
	elif emojis[emoji_name].ends_with('png'):
		var newImage = Image.new()
		newImage.load_png_from_buffer(body)
		newTexture = ImageTexture.create_from_image(newImage)
	elif emojis[emoji_name].ends_with('jpg'):
		var newImage = Image.new()
		newImage.load_jpg_from_buffer(body)
		newTexture = ImageTexture.create_from_image(newImage)
	elif emojis[emoji_name].ends_with('webp'):
		var newImage = Image.new()
		newImage.load_webp_from_buffer(body)
		newTexture = ImageTexture.create_from_image(newImage)
	else:
		print("Image Not Recognized!")
		return
	ResourceSaver.save(newTexture,'user://emojis/%s.res'%emoji_name)
	SendMessage(Nickname,Msg,IsSubscriber,RoleCode,emojis)
	HTTP.queue_free()
	pass



func _on_cid_request_completed(result, response_code, headers, body):
	if response_code==404:
		print("ERROR:404 BAD REQUEST | Check Channel ID")
		ChannelNotExist.emit()
		return
	if JSON.parse_string(body.get_string_from_utf8())['content']["status"] == "OPEN":
		ChatChannelID = JSON.parse_string(body.get_string_from_utf8())['content']["chatChannelId"]
	else:
		ChannelNotLive.emit()
	

func _on_token_request_completed(_result, _response_code, _headers, body):
	AccessToken = JSON.parse_string(body.get_string_from_utf8())['content']['accessToken']

func _on_info_request_completed(_result, _response_code, _headers, body):
	_request_image(JSON.parse_string(body.get_string_from_utf8())['content']['channelName'],JSON.parse_string(body.get_string_from_utf8())['content']['channelImageUrl'])
	pass

func _request_image(Name:String,ImageURL:String):
	var newRequest:=HTTPRequest.new()
	
	add_child(newRequest)
	newRequest.request_completed.connect(_image_received.bind(Name,ImageURL))
	newRequest.request(ImageURL)
	pass

func _image_received(_result, _response_code, _headers, body, Name:String,ImageURL:String):
	var newTexture:Texture2D
	if ImageURL.ends_with('gif'):
		newTexture = GifManager.animated_texture_from_buffer(body)
	elif ImageURL.ends_with('png'):
		var newImage = Image.new()
		newImage.load_png_from_buffer(body)
		newTexture = ImageTexture.create_from_image(newImage)
	elif ImageURL.ends_with('jpg'):
		var newImage = Image.new()
		newImage.load_jpg_from_buffer(body)
		newTexture = ImageTexture.create_from_image(newImage)
	elif ImageURL.ends_with('webp'):
		var newImage = Image.new()
		newImage.load_webp_from_buffer(body)
		newTexture = ImageTexture.create_from_image(newImage)
	else:
		print("Image Not Recognized!")
		return
	ChannelConnected.emit(Name,newTexture)
	pass
