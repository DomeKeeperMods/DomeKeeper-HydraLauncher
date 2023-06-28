extends Node

const MYMODNAME_MOD_DIR = "Raffa-HydraLauncher/"
const MYMODNAME_LOG = "Raffa-HydraLauncher"
const DOME_UPGRADE_NAME = "hydralauncher"

var dir = ""
var ext_dir = ""
var trans_dir = ""

func _init(modLoader = ModLoader):
	ModLoaderLog.info("Init", MYMODNAME_LOG)
	dir = ModLoaderMod.get_unpacked_dir() + MYMODNAME_MOD_DIR
	ext_dir = dir + "extensions/"
	trans_dir = dir + "translations/"
	
	# Add translations
	ModLoaderMod.add_translation(trans_dir + "hydralauncher_text.en.translation")
	
	# Add extensions
#	ModLoaderMod.install_script_extension(ext_dir + "main.gd")


func _ready():
	ModLoaderLog.info("Done", MYMODNAME_LOG)
	add_to_group("mod_init")

func modInit():
	var pathToModYaml : String = ModLoaderMod.get_unpacked_dir() + MYMODNAME_MOD_DIR + "yaml/"
	Data.parseUpgradesYaml(pathToModYaml + "upgrades.yaml")
	GameWorld.unlockElement(DOME_UPGRADE_NAME)
	# This signal can be used to test the mod
	#StageManager.connect("level_ready", self, "testMod")

func testMod():
	Level.stage.applyGadget(DOME_UPGRADE_NAME)
