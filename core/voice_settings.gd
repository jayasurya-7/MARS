extends HBoxContainer
func _ready()->void:
	add_theme_constant_override("separation",10)
	var enabled=CheckBox.new()
	enabled.text="Voice guidance"
	enabled.button_pressed=Voice.enabled
	enabled.toggled.connect(Voice.set_enabled)
	add_child(enabled)
	var language=OptionButton.new()
	language.add_item("English")
	language.add_item("Tamil")
	language.selected=1 if Voice.language=="ta" else 0
	language.tooltip_text="Spoken guidance only. Screen text stays unchanged."
	language.item_selected.connect(func(index): Voice.set_language("ta" if index==1 else "en"))
	add_child(language)
	var preview=Button.new()
	preview.text="Listen"
	preview.disabled=not Voice.enabled
	enabled.toggled.connect(func(value): preview.disabled=not value)
	preview.pressed.connect(func():
		Voice.stop_speech()
		Voice.speak("preview"))
	add_child(preview)
