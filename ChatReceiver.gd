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

signal ChatReceived(Nickname,Msg)
signal Donation(Amount,Msg)
# Called when the node enters the scene tree for the first time.
func _ready():
	#Start()
	pass # Replace with function body.

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
	#Channel 에 접근 할 수 있게 해주는 Token을 받습니다.
	var TokenURL = 'https://comm-api.game.naver.com/nng_main/v1/chats/access-token?channelId=%s&chatType=STREAMING'%ChatChannelID
	var TOKENHTTP = HTTPRequest.new()
	add_child(TOKENHTTP)
	TOKENHTTP.request_completed.connect(_on_token_request_completed)
	TOKENHTTP.request(TokenURL)
	await TOKENHTTP.request_completed
	socket.connect_to_url('wss://kr-ss3.chat.naver.com/chat')

# Called every frame. 'delta' is the elapsed time since the previous frame.
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
					print(eachBody.msg)
					#도네이션 처리. 익명후원때문에 profile이 null로 들어오기도 합니다. 익명 처리 거르고 닉네임 받아오게 만들 수 도 있겠네요.
					var Extras:Dictionary = JSON.parse_string(eachBody['extras'])
					if Extras.has('payAmount'):
						Donation.emit(Extras.payAmount,eachBody.msg)
						prints(Extras.payAmount,eachBody.msg)
					if eachBody.profile == null:continue
					var Profile = JSON.parse_string(eachBody['profile'])
					if Profile.has('nickname'):
						#메세지에 이모티콘은 {:d_num:} 형식으로 들어옵니다. 활용하시려면 하세요.
						ChatReceived.emit(Profile['nickname'],eachBody['msg'])
	elif state == WebSocketPeer.STATE_CLOSING:
		pass
	elif state == WebSocketPeer.STATE_CLOSED:
		var code = socket.get_close_code()
		var reason = socket.get_close_reason()
		#print("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
		#set_process(false) # Stop processing.

	pass

func _on_cid_request_completed(result, response_code, headers, body):
	if response_code==404:
		print("ERROR:404 BAD REQUEST | Check Channel ID")
		ChatReceived.emit("에러","Channel ID를 확인해주세요")
		return
	ChatChannelID = JSON.parse_string(body.get_string_from_utf8())['content']["chatChannelId"]

func _on_token_request_completed(result, response_code, headers, body):
	AccessToken = JSON.parse_string(body.get_string_from_utf8())['content']['accessToken']
