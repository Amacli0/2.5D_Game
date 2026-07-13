extends Node

var server = WebSocketMultiplayerPeer.new()
const SIGNALING_PORT = 9080

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
	print("Signaling sunucusuna yeni bir soket bağlandı: ", id)
	var welcome_msg = {"type": "welcome", "id": id}
	server.get_peer(id).put_packet(JSON.stringify(welcome_msg).to_utf8_buffer())


func _client_koptu(id):
	print("Signaling sunucusundan bir soket koptu: ", id)

func mesaji_yonlendir(gonderen_id: int, data: Dictionary):
	# data yapısı: {"target": hedef_peer_id, "type": "offer/answer/candidate", "payload": ...}
	var target_id = data.get("target", 0)
	data["sender"] = gonderen_id
	if target_id != 0:
		server.get_peer(target_id).put_packet(JSON.stringify(data).to_utf8_buffer())
