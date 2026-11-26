extends Node

signal button(index: int)

const PORT := 24653
const TIMEOUT := 1.1
var link := PacketPeerUDP.new()
var axis := Vector2.ZERO
var connected := false
var silence := 0.0
var pressed := PackedInt32Array([0, 0, 0, 0])
var listening := false

func _ready() -> void:
	listening = link.bind(PORT, "127.0.0.1") == OK

func _process(dt: float) -> void:
	if not listening:
		return
	silence += dt
	if connected and silence > TIMEOUT:
		connected = false
		axis = Vector2.ZERO
		pressed.fill(0)
	for i in range(mini(32, link.get_available_packet_count())):
		var packet := link.get_packet()
		if packet.size() > 64:
			continue
		var values := decode(packet.get_string_from_utf8())
		if values.is_empty():
			continue
		connected = true
		silence = 0.0
		axis = Vector2(calibrate(values[0]), calibrate(values[1]))
		if axis.length() > 1.0:
			axis = axis.normalized()
		for j in range(4):
			if values[j + 2] == 1 and pressed[j] == 0:
				button.emit(j)
			pressed[j] = values[j + 2]
		link.set_dest_address(link.get_packet_ip(), link.get_packet_port())
		link.put_packet("OK".to_utf8_buffer())

static func calibrate(value: int) -> float:
	var unit := (float(value) - 2048.0) / 2048.0
	if absf(unit) < 0.20:
		return 0.0
	return signf(unit) * clampf((absf(unit) - 0.20) / 0.72, 0.0, 1.0)

static func decode(message: String) -> PackedInt32Array:
	var parts := message.strip_edges().split(",")
	if parts.size() != 7 or parts[0] != "SV1":
		return PackedInt32Array()
	var values := PackedInt32Array()
	for i in range(1, parts.size()):
		if not parts[i].is_valid_int():
			return PackedInt32Array()
		var value := parts[i].to_int()
		var ceiling := 4095 if i <= 2 else 1
		if value < 0 or value > ceiling:
			return PackedInt32Array()
		values.append(value)
	return values
