extends PanelContainer

class_name EquipmentSlot

## The item in this slot
@export
var quantity : int

@export 
var item : StaticBody2D

## The type of items this slot allows
@export 
var allowed_type : Enums.ITEM_TYPE

## The root of the inventory viewport
@export
var inventory_root : Control

var viewport: Control

var is_active_equipment_slot: bool = false

#@onready
#var viewport: Control = %InventoryViewportRootChild.get_parent()
# Called when the node enters the scene tree for the first time.
func _ready():
	update_icon()

func _input(event):
	if not _can_handle_input(event):
		return
	
	interact()

func _can_handle_input(event):
	# Check that we are the active slot
	if not is_active_equipment_slot:
		return false
		
	# Check if our item can be place
	if not is_instance_valid(item):
		return false
		
	if not item is HarvestNode:
		return false
		
	if not item.can_place:
		return 
	
	# Check we're actually in the viewport
	if not is_instance_valid(viewport):
		return false
	
	# Check that we pressed interact
	if not event is InputEventKey:
		return false
	
	if not event.keycode == 69:
		return false
	
	if not event.pressed:
		return false

	return true

func _get_drag_data(_at_position: Vector2):
	set_drag_preview(make_drag_preview())
	return self

func _can_drop_data(_at_position, data):
	if allowed_type == Enums.ITEM_TYPE.MAIN:
		return true
	
	if not data.item.has("type"):
		return false
		
	if allowed_type != data.item.type:
		return false
	return true
	
func _drop_data(_at_position : Vector2, data : Variant) -> void:
	# If the slot has something not allowed in our slot return
	if ( data.allowed_type != Enums.ITEM_TYPE.MAIN 
		and is_instance_valid(item)
		and item.type != data.allowed_type ):
		return
	
	# Update quantities
	var our_old_quantity = quantity
	quantity = data.quantity
	data.quantity = our_old_quantity
	
	# Update the items
	var our_old_item = item
	item = data.item
	data.item = our_old_item
	
	# Update icons
	update_icon()
	data.update_icon()
	
	
	# Signal that the item has been dropped in this slot
	if not (allowed_type == Enums.ITEM_TYPE.MAIN and data.allowed_type == Enums.ITEM_TYPE.MAIN):
		inventory_root.item_dropped.emit(allowed_type, self)

## Updates the icon for this slot
func update_icon():
	update_label()
	if !is_instance_valid(item):
		$Item.texture = null
		return
		
	$Item.texture = Global.generate_image_texture_from_scene(item)
	return	
	
func make_drag_preview():
	var t := TextureRect.new()
	t.texture = $Item.texture
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = size
	return t
func is_empty() -> bool:
	return quantity == 0

func update_label():
	( get_node("Count") as Label ).text = "" if quantity == 0 or quantity == 1 else str(quantity)

func interact() -> void:
	viewport.enter_build_mode.emit(item)

func _on_mouse_entered():
	is_active_equipment_slot = true
	
func _on_mouse_exited():
	is_active_equipment_slot = false
