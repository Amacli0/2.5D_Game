extends SceneTree

var server = WebSocketMultiplayerPeer.new()
const SIGNALING_PORT = 9080
var host_socket_id: int = 0
var socket_to_peer := {}
var peer_to_socket := {}

func _init():
	server.peer_connected.connect(_client_baglandi)
	server.peer_disconnected.connect(_client_koptu)
	
	var error = server.create_server(SIGNALING_PORT)
	if error == OK:
		print("Signaling Sunucu başlatıldı. Port: ", SIGNALING_PORT)
	else:
		print("Signaling Sunucusu başlatılamadı! Hata: ", error)

func _process(_delta: float) -> bool:
	server.poll()
	while server.get_available_packet_count() > 0:
		var gonderen_socket_id = server.get_packet_peer()
		var peer = server.get_peer(gonderen_socket_id)
		var packet = server.get_packet()
		
		if peer.was_string_packet():
			var text_data = packet.get_string_from_utf8()
			var json = JSON.new()
			if json.parse(text_data) == OK:
				var message = json.get_data()
				if message is Dictionary:
					mesaji_yonlendir(gonderen_socket_id, message)
	return false

func _client_baglandi(socket_id: int):
	if host_socket_id == 0:
		host_socket_id = socket_id
		socket_to_peer[socket_id] = 1
		peer_to_socket[1] = socket_id
		print("Dedicated Server tespit edildi (Socket ID: ", socket_id, ") -> Assigned Peer ID: 1")
		var welcome_msg = {"type": "welcome", "id": 1}
		server.get_peer(socket_id).send_text(JSON.stringify(welcome_msg))
	else:
		var peer_id = socket_id
		socket_to_peer[socket_id] = peer_id
		peer_to_socket[peer_id] = socket_id
		print("Yeni Client bağlandı (Socket ID: ", socket_id, ") -> Peer ID: ", peer_id)
		var welcome_msg = {"type": "welcome", "id": peer_id}
		server.get_peer(socket_id).send_text(JSON.stringify(welcome_msg))

func _client_koptu(socket_id: int):
	print("Soket koptu: ", socket_id)
	if socket_id == host_socket_id:
		host_socket_id = 0
	var peer_id = socket_to_peer.get(socket_id, 0)
	socket_to_peer.erase(socket_id)
	peer_to_socket.erase(peer_id)

func mesaji_yonlendir(gonderen_socket_id: int, data: Dictionary):
	var target_peer_id = int(data.get("target", 0))
	var gonderen_peer_id = socket_to_peer.get(gonderen_socket_id, 0)
	
	data["sender"] = gonderen_peer_id
	
	var alici_socket_id = peer_to_socket.get(target_peer_id, 0)
	
	if alici_socket_id != 0 and socket_to_peer.has(alici_socket_id):
		print("Mesaj yönlendiriliyor: Peer ", gonderen_peer_id, " -> Peer ", target_peer_id, " [Tip: ", data.get("type"), "]")
		server.get_peer(alici_socket_id).send_text(JSON.stringify(data))
