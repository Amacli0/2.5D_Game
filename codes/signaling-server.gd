extends Node

var server = WebSocketMultiplayerPeer.new()
const SIGNALING_PORT = 9080
var host_id: int = 0

func _ready():
	
	server.peer_connected.connect(_client_baglandi)
	server.peer_disconnected.connect(_client_koptu)
	
	var error = server.create_server(SIGNALING_PORT)
	if error == OK:
		print("Sunucu kuruldu bekleniliyor")
	else:
		print("Sunucu kurulamadi ", error)
		
func _process(delta: float) -> void:
	server.poll()
	
	while server.get_available_packet_count() > 0:
		var gonderen_id = server.get_packet_peer()
		var packet = server.get_packet()
		var message = JSON.parse_string(packet.get_string_from_utf8())
		
		if message:
			mesaji_yonlendir(gonderen_id ,message)

func _client_baglandi(id):
	if host_id == 0:
		host_id = id
		print("Dedicated Server tespit edildi, Sinyal Host ID'si: ", host_id)
		
	print("Signaling sunucusuna yeni bir soket bağlandı: ", id)
	var welcome_msg = {"type": "welcome", "id": id}
	server.get_peer(id).put_packet(JSON.stringify(welcome_msg).to_utf8_buffer())


func _client_koptu(id):
	print("Signaling sunucusundan bir soket koptu: ", id)

func mesaji_yonlendir(gonderen_id: int, data: Dictionary):
	# data yapısı: {"target": hedef_peer_id, "type": "offer/answer/candidate", "payload": ...}
	var target_id = data.get("target", 0)
	data["sender"] = 1 if gonderen_id == host_id else gonderen_id
	
	var alici_soket_id = 0
	
	if target_id == 1:
		alici_soket_id = host_id
	else:
		alici_soket_id = target_id
	if alici_soket_id != 0 and server.has_peer(alici_soket_id):
		print("Mesaj iletiliyor -> Alıcı Soket: ", alici_soket_id, " Tip: ", data.get("type"))
		server.get_peer(alici_soket_id).put_packet(JSON.stringify(data).to_utf8_buffer())
