extends Control

signal fileDoubleClickOpened
signal filesOpenBtnOpened
signal cancelPressed

const folderIcon = preload("res://img/folder.png")

onready var urlLineEdit = $URLHBox/UrlLineEdit
onready var urlBtn = $URLHBox/UrlBtn
onready var itemList = $ItemList
onready var backUrlBtn = $URLHBox/BackUrlBtn
onready var openBtn = $BtnHbox/OpenBtn
onready var cancelBtn = $BtnHbox/CancelBtn


var currentDir : String = ""


# Called when the node enters the scene tree for the first time.
func _ready():
	ConnectSignals()
	currentDir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	GetDirectoryContents(currentDir)
	urlLineEdit.text = currentDir
	SetSelectMode(1)


# Adds file names to "imageList" itemList
func GetDirectoryContents(path : String) -> void:
	itemList.clear()
	var dir = Directory.new()
	var temp : int = 0
	if dir.open(path) == OK:
		dir.list_dir_begin(true, true)
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				# FOLDER
				itemList.add_item(file_name)
				itemList.set_item_icon(temp, folderIcon)
			else:
				#FILE
				itemList.add_item(file_name)
			temp += 1
			file_name = dir.get_next()
#	else:
#		print("An error occurred when trying to access the path")


func SetSelectMode(value : int) -> void:
	itemList.unselect_all()
	if value == 0:
		itemList.select_mode = ItemList.SELECT_SINGLE
	else:
		itemList.select_mode = ItemList.SELECT_MULTI


func GetSelectMode() -> int:
	return itemList.select_mode


func ConnectSignals() -> void:
	urlBtn.connect("pressed", self, "on_url_pressed")
	backUrlBtn.connect("pressed", self, "on_back_pressed")
	urlLineEdit.connect("text_entered", self, "on_url_entered")
	itemList.connect("item_activated", self, "on_item_activated")
	openBtn.connect("pressed", self, "on_open_pressed")
	cancelBtn.connect("pressed", self, "on_cancel_pressed")


func on_open_pressed() -> void:
	var selectedItems : Array = itemList.get_selected_items()
	var temp : Array = []
	for i in range(0, selectedItems.size(), 1):
		temp.append(currentDir + "/" + itemList.get_item_text(selectedItems[i]))
	emit_signal("filesOpenBtnOpened", temp)

func on_cancel_pressed() -> void:
	#visible = false
	emit_signal("cancelPressed")


func on_item_activated(value : int) -> void:
	var dir = Directory.new()
	var path = currentDir + "/" + itemList.get_item_text(value)
	if dir.open(path) == OK:
		if dir.current_is_dir():
			currentDir = path
			urlLineEdit.text = currentDir
			GetDirectoryContents(currentDir)
			#print(currentDir)
	else:
		emit_signal("fileDoubleClickOpened", path)


func on_url_pressed() -> void:
	currentDir = urlLineEdit.text
	GetDirectoryContents(currentDir)


func on_back_pressed() -> void:
	var temp : Array = currentDir.split("/")
	temp.pop_back()
	
	currentDir = ""
	for i in range(0, temp.size(), 1):
		currentDir += temp[i] + "/"
	
	# If it's "C:/", don't remove last "/"
	if temp.size() != 1:
		currentDir.erase(currentDir.length()-1, 1)
	
	urlLineEdit.text = currentDir
	GetDirectoryContents(currentDir)



func on_url_entered(_value : String) -> void:
	currentDir = urlLineEdit.text
	GetDirectoryContents(currentDir)



