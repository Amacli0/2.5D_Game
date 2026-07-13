extends Node3D

var rct_peer := WebRTCMultiplayerPeer.new()
var signal_socket := WebSocketPeer.new()

const SIGNAL_ADDRESS = "ws://127.0.0.1:9080"
var my_id := 0
var is_server := false

# Format: { peer_id: WebRTCPeerConnection }
var peer_connections := {}

func setup_network(as_server: bool):
	is_server = as_server

	# 1. Godot Multiplayer WebRTC altyapısını başlat
	if is_server:
		rct_peer.create_server()
		multiplayer.multiplayer_peer = rct_peer

	# 3. Sinyal sunucusuna bağlan
	var error = signal_socket.connect_to_url(SIGNAL_ADDRESS)
	if error == OK:
		print("Postacıya (Signaling) bağlanılıyor...")
	else:
		print("Postacıya bağlanılamadı: ", error)
		
		
func _process(delta: float) -> void:
	signal_socket.poll()
	var state = signal_socket.get_ready_state()
	
	if state == WebSocketPeer.STATE_OPEN:
		while signal_socket.get_available_packet_count() > 0:
			var packet = signal_socket.get_packet()
			var message = JSON.parse_string(packet.get_string_from_utf8())
			if message:
				signal_mesaji_isle(message)		
func signal_mesaji_isle(data: Dictionary):
	var type = data.get("type", "")
	var sender = data.get("sender", "")
	print("Postacıdan mesaj geldi! Tipi: ", type, " Gönderen: ", sender)
	
	_signaling_mesajini_isle(data)
	
	
# -------------------------------------------------------------------
# MEKTUP İŞLEME MERKEZİ (Offer / Answer / Candidate)
# -------------------------------------------------------------------
func _signaling_mesajini_isle(data: Dictionary):
	var type = data.get("type", "")
	var sender = data.get("sender", 0)
	
	if type == "welcome":
		var assigned_id = data.get("id", 0)
		print("Signaling ID'miz alındı: ", my_id)
		
		# Eğer biz OYUNCUYSAK, hemen Sunucuya (ID: 1) TEKLİF (Offer) atıyoruz!
		if not is_server:
			my_id = assigned_id
			rct_peer.create_client(my_id)
			multiplayer.multiplayer_peer = rct_peer
			_teklif_olustur_ve_gonder(1)

	elif type == "offer":
		# SUNUCU TARAFINDAYIZ: Oyuncudan TEKLİF geldi!
		# Şimdi buna CEVAP (Answer) vereceğiz.
		_teklifi_kabul_et_ve_cevapla(sender, data.get("sdp", ""))
		print("SUNUCUYA OFFER ULAŞTI! Cevap hazırlanıyor...")
	elif type == "answer":
		# OYUNCU TARAFINDAYIZ: Sunucudan CEVAP geldi!
		_cevabi_isle(sender, data.get("sdp", ""))

	elif type == "candidate":
		# Küçük adres pusulası (ICE Candidate) geldi.
		_adres_pusulasini_isle(sender, data)

# -------------------------------------------------------------------
# WEBRTC BAĞLANTI (TELSİZ) KURMA FONKSİYONLARI
# -------------------------------------------------------------------

# 1. AHMET (Client): Teklif (Offer) Oluşturur
func _teklif_olustur_ve_gonder(target_id: int):
	var connection = _yeni_baglanti_olustur(target_id)
	connection.create_offer()
# 2. MEHMET (Server): Teklifi Alır ve Cevap (Answer) Üretir
func _teklifi_kabul_et_ve_cevapla(sender_id: int, sdp: String):
	var connection = _yeni_baglanti_olustur(sender_id)
	connection.set_remote_description("offer", sdp)

# 3. AHMET (Client): Sunucudan Gelen Cevabı (Answer) Telsize Tanıtır
func _cevabi_isle(sender_id: int, sdp: String):
	if peer_connections.has(sender_id):
		peer_connections[sender_id].set_remote_description("answer", sdp)

# 4. Adres Pusulalarını (ICE Candidates) İşleme
func _adres_pusulasini_isle(sender_id: int, data: Dictionary):
	if peer_connections.has(sender_id):
		peer_connections[sender_id].add_ice_candidate(
			data.get("media", ""),
			data.get("index", 0),
			data.get("name", "")
		)

# -------------------------------------------------------------------
# TELSİZ CİHAZI YARDIMCI FONKSİYONU
# -------------------------------------------------------------------
func _yeni_baglanti_olustur(target_id: int) -> WebRTCPeerConnection:
	var connection := WebRTCPeerConnection.new()
	
	# Google'ın ücretsiz adres bulucu (STUN) sunucusu
	connection.initialize({
		"iceServers": [{ "urls": ["stun:stun.l.google.com:19302"] }]
	})
	
	# Sinyalleri (Kulakları) Bağlıyoruz:
	
	# A) "Telsiz frekansı hazır olduğunda mektup at" sinyali
	connection.session_description_created.connect(
		func(type, sdp):
			connection.set_local_description(type, sdp)
			_postaciya_mektup_at({"target": target_id, "type": type, "sdp": sdp})
	)
	
	# B) "Yeni bir adres pusulası bulduğumda mektup at" sinyali
	connection.ice_candidate_created.connect(
		func(media, index, name):
			_postaciya_mektup_at({
				"target": target_id,
				"type": "candidate",
				"media": media,
				"index": index,
				"name": name
			})
	)
	
	# Bu telsiz bağlantısını Godot'nun Multiplayer sistemine ekliyoruz!
	rct_peer.add_peer(connection, target_id)
	peer_connections[target_id] = connection
	
	return connection

func _postaciya_mektup_at(data: Dictionary):
	signal_socket.put_packet(JSON.stringify(data).to_utf8_buffer())
