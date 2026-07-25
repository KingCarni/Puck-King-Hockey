extends "res://scripts/adventure/adventure_screen.gd"

# Shop — placeholder storefront. Purchasing arrives with the item system.

const AdventureDataScript = preload("res://scripts/adventure/adventure_data.gd")

var _back_button: Button = null

func _screen_title() -> String:
	return "SHOP"

func _build_content(parent: Control) -> void:
	var center: CenterContainer = CenterContainer.new()
	parent.add_child(center)
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	center.add_child(vbox)

	for item: Dictionary in AdventureDataScript.shop_stock():
		var panel: PanelContainer = make_panel(COLOR_GOLD)
		panel.custom_minimum_size = Vector2(900.0, 0.0)
		vbox.add_child(panel)
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 24)
		panel.add_child(row)
		var text_box: VBoxContainer = VBoxContainer.new()
		text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(text_box)
		text_box.add_child(make_display_label(String(item.get("title", "")), 28, COLOR_BONE))
		text_box.add_child(make_accent_label(String(item.get("description", "")), 20, COLOR_STEEL))
		row.add_child(make_accent_label("%d G" % int(item.get("price", 0)), 28, COLOR_GOLD))

	var note: Label = make_accent_label("THE SHOPKEEPER IS STILL UNPACKING — PURCHASES COMING SOON", 24, COLOR_GOLD)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(note)

	_back_button = make_button("BACK", false, 84.0)
	_back_button.custom_minimum_size = Vector2(420.0, 84.0)
	_back_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_back_button.pressed.connect(func() -> void: _on_back())
	vbox.add_child(_back_button)

func _default_focus() -> Control:
	return _back_button
