extends SceneTree
# The device / laptop name sent to the server can be changed in Uploads & services.
var failures = 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var dash = root.get_node("NeuroDash")
	var services = root.get_node("Services")
	var settings = services.settings
	var saved: Dictionary = {}
	if settings.has_section("neurodash"):
		for key in settings.get_section_keys("neurodash"): saved[key] = settings.get_value("neurodash", key)
	for key in ["device_id", "client_id"]: settings.erase_section_key("neurodash", key)
	services.agent_available = false
	check(dash.effective_device() == "MARS" and dash.config().device == "MARS", "Default device name is MARS")
	services.agent_available = true
	services.agent_identity = {"device": "NOARK", "client": "Severus"}
	check(dash.effective_device() == "NOARK" and dash.effective_client() == "Severus", "Automatic: the agent's names are followed")
	check(dash.identity_warning() == "", "No warning while following the agent")
	dash.set_value("device_id", "PLUTO")
	check(dash.effective_device() == "PLUTO" and dash.config().device == "PLUTO", "A typed device name wins over the agent")
	check(dash.identity_warning().contains("NOARK"), "A name that differs from the agent's gets a warning")
	dash.set_value("client_id", "ward-3")
	check(dash.config().client == "ward-3", "The laptop name can be changed too")
	dash.set_value("device_id", "")
	dash.set_value("client_id", "")
	check(dash.effective_device() == "NOARK" and not settings.has_section_key("neurodash", "device_id"), "Clearing the field goes back to automatic")
	# The patient list follows the chosen device name.
	services.agent_available = false
	dash.set_value("device_id", "NOARK")
	check(dash.effective_device() == "NOARK", "Device name is used for the patient list filter")
	# Server address: host or host:port, validated, saved, and testable.
	var parsed = dash.parse_address(" 192.168.0.104:5000 ")
	check(parsed.ok and parsed.host == "192.168.0.104" and parsed.port == 5000, "host:port is parsed")
	check(dash.parse_address("server.local").port == dash.DEFAULT_PORT, "A bare host uses the default port")
	check(not dash.parse_address("bad host").ok and not dash.parse_address("10.0.0.1:99999").ok and not dash.parse_address("").ok and not dash.parse_address("10.0.0.1:x").ok, "Invalid addresses are refused")
	check(dash.set_server("10.1.2.3:6000") and dash.server_address() == "10.1.2.3:6000", "A typed server address is stored")
	check(not dash.set_server("bad host") and dash.server_address() == "10.1.2.3:6000", "An invalid address leaves the old one in place")
	var down = dash.ping_task({"ip": "127.0.0.1", "port": 9})
	check(not down.ok and down.message.contains("Cannot reach"), "A dead address reports that it cannot be reached")
	var listener = TCPServer.new()
	listener.listen(0, "127.0.0.1")
	var open = dash.ping_task({"ip": "127.0.0.1", "port": listener.get_local_port()})
	check(open.ok and open.message.contains("reachable"), "A listening address is reported reachable: " + open.message)
	listener.stop()
	# The tab shows the fields.
	var flow = load("res://core/workflows.gd").new()
	root.add_child(flow)
	await process_frame
	await process_frame
	await process_frame
	check(flow.names_status != null and flow.names_status.text.contains("NOARK"), "The settings tab shows what the server sees: " + flow.names_status.text)
	flow.queue_free()
	services.agent_identity = {}
	if settings.has_section("neurodash"): settings.erase_section("neurodash")
	for key in saved: settings.set_value("neurodash", key, saved[key])
	services.save()
	print("Device name: %d failures" % failures)
	quit(1 if failures else 0)
