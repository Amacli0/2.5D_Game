extends Node3D

var rct_peer := WebRTCMultiplayerPeer.new()
var signal_socket := WebSocketPeer.new()

const SIGNAL_ADDRESS = "ws://127.0.0.1:9080"
var my_id := 0
var is_server := false

var peer_connections := {}

func setup_network(as_server: bool):
	is_server = as_server

	if is_server:
		my_id = 1
		rct_peer.create_server()
		multiplayer.multiplayer_peer = rct_peer

	var error = signal_socket.connect_to_url(SIGNAL_ADDRESS)
	if error == OK:
		print("Signaling sunucusuna bağlanılıyor... (Is Server: ", is_server, ")")
	else:
		print("Signaling sunucusuna bağlanılamadı: ", error)

func _process(_delta: float) -> void:
	signal_socket.poll()
	var state = signal_socket.get_ready_state()
	
	if state == WebSocketPeer.STATE_OPEN:
		while signal_socket.get_available_packet_count() > 0:
			var packet = signal_socket.get_packet()
			
			# was_string_packet() paketi aldıktan SONRA kontrol edilir
			if signal_socket.was_string_packet():
				var text_data = packet.get_string_from_utf8()
				var json = JSON.new()
				if json.parse(text_data) == OK:
					var message = json.get_data()
					if message is Dictionary:
						_signaling_mesajini_isle(message)

func _signaling_mesajini_isle(data: Dictionary):
	var type = data.get("type", "")
	var sender = int(data.get("sender", 0))

	if type == "welcome":
		var assigned_id = int(data.get("id", 0))
		print("Signaling ID alındı: ", assigned_id)
		
		if not is_server:
			my_id = assigned_id
			rct_peer.create_client(my_id)
			multiplayer.multiplayer_peer = rct_peer
			print("Client WebRTC başlatıldı (ID: ", my_id, "). Host'a (1) offer gönderiliyor...")
			_teklif_olustur_ve_gonder(1)

	elif type == "offer":
		print("SUNUCUYA OFFER ULAŞTI! Gönderen Peer ID: ", sender)
		_teklifi_kabul_et_ve_cevapla(sender, data.get("sdp", ""))

	elif type == "answer":
		print("CLIENT'A ANSWER ULAŞTI! Gönderen: ", sender)
		_cevabi_isle(sender, data.get("sdp", ""))

	elif type == "candidate":
		_adres_pusulasini_isle(sender, data)

func _teklif_olustur_ve_gonder(target_id: int):
	var connection = _yeni_baglanti_olustur(target_id)
	connection.create_offer()

func _teklifi_kabul_et_ve_cevapla(sender_id: int, sdp: String):
	var connection = _yeni_baglanti_olustur(sender_id)
	connection.set_remote_description("offer", sdp)

func _cevabi_isle(sender_id: int, sdp: String):
	if peer_connections.has(sender_id):
		peer_connections[sender_id].set_remote_description("answer", sdp)

func _adres_pusulasini_isle(sender_id: int, data: Dictionary):
	if peer_connections.has(sender_id):
		peer_connections[sender_id].add_ice_candidate(
			data.get("media", ""),
			int(data.get("index", 0)),
			data.get("candidate_name", "") # Fix: 'name' uyarısını engellemek için parametre adı güncellendi
		)

func _yeni_baglanti_olustur(target_id: int) -> WebRTCPeerConnection:
	if peer_connections.has(target_id):
		return peer_connections[target_id]

	var connection := WebRTCPeerConnection.new()
	connection.initialize({
		"iceServers": [{ "urls": ["stun:stun.l.google.com:19302"] }]
	})

	connection.session_description_created.connect(
		func(type, sdp):
			connection.set_local_description(type, sdp)
			_postaciya_mektup_at({"target": target_id, "type": type, "sdp": sdp})
	)

	connection.ice_candidate_created.connect(
		func(media, index, candidate_name):
			_postaciya_mektup_at({
				"target": target_id,
				"type": "candidate",
				"media": media,
				"index": index,
				"candidate_name": candidate_name
			})
	)

	rct_peer.add_peer(connection, target_id)
	peer_connections[target_id] = connection
	return connection

func _postaciya_mektup_at(data: Dictionary):
	signal_socket.send_text(JSON.stringify(data))
