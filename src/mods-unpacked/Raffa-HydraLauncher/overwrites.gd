extends Node

const MOD_ICON_PATH := "res://mods-unpacked/Raffa-HydraLauncher/overwrites/content/icons/"
const GAME_ICON_PATH := "res://content/icons/"

var icons := [
	"hydralauncher.png",
	"hydralauncherautotracker.png",
	"hydralauncherdamage1.png",
	"hydralauncherdamage2.png",
	"hydralaunchermaxprojectiles1.png",
	"hydralaunchermaxprojectiles2.png",
	"hydralauncherrecharge.png",
	"hydralaunchersalvosize.png",
	"hydralaunchertaserwarhead.png"
]

var iconTextures := []

func _init():
	for icon in icons:
		var overwrite = load(MOD_ICON_PATH+icon)
		iconTextures.append(overwrite)
		overwrite.take_over_path(GAME_ICON_PATH+icon)
