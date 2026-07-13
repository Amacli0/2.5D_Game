extends Node3D

const PORT = 12345
const DEFAULT_IP = "127.0.0.1" # Test için kendi bilgisayarın (localhost)

func _ready():
	multiplayer.peer_connected.connect(_oyuncu_katildi)
	multiplayer.peer_disconnected.connect(_oyuncu_ayrildi)
	if DisplayServer.get_name() == "headless":
		print("Dedicated Sunucu algılandı, otomatik başlatılıyor...")
		host_ol()
func host_ol():
	$WebrtcManager.setup_network(true)
	print("Sunucu kuruldu, oyuncular bekleniyor...")
	$CanvasLayer.hide()
	
func katil_ol(ip = DEFAULT_IP):
	$WebrtcManager.setup_network(false)
	$CanvasLayer.hide()
	
func _oyuncu_katildi(id):
	print("WebRTC üzerinden harika bir şekilde oyuncu katıldı! ID: ", id)
	if multiplayer.is_server():
		oyuncu_dogur(id)

func _oyuncu_ayrildi(id):
	print("Oyuncu koptu: ", id)
	if multiplayer.is_server():
		var ayrilan = $Players.get_node_or_null(str(id))
		if ayrilan:
			ayrilan.queue_free()
func oyuncu_dogur(id):
	var yeni_karakter = load("res://scenes/karakter.tscn").instantiate()
	yeni_karakter.name = str(id)
	$Players.add_child(yeni_karakter)
