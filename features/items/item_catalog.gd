class_name ItemCatalog
extends RefCounted

const DEFINITIONS: Dictionary = {
	&"crowbar": preload("res://data/items/crowbar.tres"),
	&"pistol": preload("res://data/items/pistol.tres"),
	&"shotgun": preload("res://data/items/shotgun.tres"),
	&"ammo_9mm": preload("res://data/items/ammo_9mm.tres"),
	&"shells": preload("res://data/items/shells.tres"),
	&"medkit": preload("res://data/items/medkit.tres"),
}


static func find(id: StringName) -> ItemDefinition:
	return DEFINITIONS.get(id) as ItemDefinition
