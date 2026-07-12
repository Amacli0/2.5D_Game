extends Node3D

const PORT = 12345
const DEFAULT_IP = "127.0.0.1" # Test için kendi bilgisayarın (localhost)

func _ready():
	multiplayer.peer_connected.connect(_oyuncu_katildi)
	multiplayer.peer_disconnected.connect(_oyuncu_ayrildi)

func host_ol():
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT)
	multiplayer.multiplayer_peer = peer
	print("Sunucu kuruldu, oyuncular bekleniyor...")
	oyuncu_dogur(1)
	
func katil_ol(ip = DEFAULT_IP):
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(ip, PORT)
	multiplayer.multiplayer_peer = peer
	print("Sunucuya bağlanılıyor...")

func _oyuncu_katildi(id):
	print("Yeni bir oyuncu katıldı! ID: ", id)
	if multiplayer.is_server():
		oyuncu_dogur(id)

func _oyuncu_ayrildi(id):
	print("Oyuncu ayrıldı! ID: ", id)
	var ayrilan_oyuncu = $Players.get_node_or_null(str(id))
	if multiplayer.is_server():
		if ayrilan_oyuncu:
			ayrilan_oyuncu.queue_free()
		
func oyuncu_dogur(id):
	var yeni_karakter = load("res://scenes/karakter.tscn").instantiate()
	yeni_karakter.name = str(id)
	$Players.add_child(yeni_karakter)
