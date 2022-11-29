extends Control

# BUTTONS
onready var selectFilesBtn = $BtnHBox/SelectFilesBtn
onready var selectWatermarkBtn = $BtnHBox/SelectWatermarkBtn
onready var startBtn = $BtnHBox/StartBtn
# FILE DIALOG
onready var fileDialog = $FileDialog
onready var selectingLabel = $SelectingLabel
# PROGRESS POPUP
onready var progressPopup = $ProgressPopup
onready var popupOkBtn = $ProgressPopup/PopupOkBtn
onready var progressBar = $ProgressPopup/ProgressBar
onready var progressFileLabel = $ProgressPopup/ProgressFileLabel
onready var progressQuantityLabel = $ProgressPopup/ProgressQuantityLabel
# INFO LABELS
onready var openedNLabel = $InfoControl/OpenedNLabel
onready var openedWatermarkLabel = $InfoControl/OpenedWatermarkLabel
onready var openDirBtn = $InfoControl/OpenDirBtn


var appDirectory : String = ""
var imagePathsArray : Array = []
var watermarkPath : String = ""
var thread : Thread = null
var shoudKillThread : bool = false

func _ready():
	ConnectSignals()
	appDirectory = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS) + "/WatermarkMaker"
	var dir = Directory.new()
	if dir.open(appDirectory) != OK:
		dir.make_dir(appDirectory)


func DisableButtons() -> void:
	selectFilesBtn.disabled = true
	selectWatermarkBtn.disabled = true
	startBtn.disabled = true


func EnableButtons() -> void:
	selectFilesBtn.disabled = false
	selectWatermarkBtn.disabled = false
	startBtn.disabled = false


func ConnectSignals() -> void:
	selectFilesBtn.connect("pressed", self, "on_select_files_pressed")
	selectWatermarkBtn.connect("pressed", self, "on_select_watermark_pressed")
	startBtn.connect("pressed", self, "on_start_pressed")
	fileDialog.connect("fileDoubleClickOpened", self, "on_file_double_click_opened")
	fileDialog.connect("filesOpenBtnOpened", self, "on_files_open_btn_pressed")
	fileDialog.connect("cancelPressed", self, "on_file_dialog_cancel_pressed")
	popupOkBtn.connect("pressed", self, "on_progress_popup_ok_pressed")
	openDirBtn.connect("pressed", self, "on_open_dir_pressed")


func on_open_dir_pressed() -> void:
	OS.shell_open(appDirectory)


func on_progress_popup_ok_pressed() -> void:
	progressPopup.visible = false


func on_file_dialog_cancel_pressed() -> void:
	fileDialog.visible = false
	selectingLabel.text = ""
	EnableButtons()


func on_files_open_btn_pressed(value : Array) -> void:
	if fileDialog.GetSelectMode() == 0:
		# WATERMARK
		watermarkPath = value[0]
		openedWatermarkLabel.text = watermarkPath
	else:
		# IMAGES
		imagePathsArray = value
		openedNLabel.text = str(imagePathsArray.size())
	
	fileDialog.visible = false
	selectingLabel.text = ""
	EnableButtons()





func on_file_double_click_opened(value) -> void:
#	print("doubleclick")
	if fileDialog.GetSelectMode() == 0:
		# WATERMARK
		watermarkPath = value
		openedWatermarkLabel.text = watermarkPath
	else:
		# IMAGES
		imagePathsArray.resize(1)
		imagePathsArray[0] = value
		openedNLabel.text = str(imagePathsArray.size())
	
	fileDialog.visible = false
	selectingLabel.text = ""
	EnableButtons()


func on_select_files_pressed() -> void:
	fileDialog.visible = true
	fileDialog.SetSelectMode(1)
	selectingLabel.text = "Selecting: Files"
	DisableButtons()


func on_select_watermark_pressed() -> void:
	fileDialog.visible = true
	fileDialog.SetSelectMode(0)
	selectingLabel.text = "Selecting: Watermark"
	DisableButtons()


func on_start_pressed() -> void:
	popupOkBtn.disabled = true
	fileDialog.visible = false
	DisableButtons()
	progressPopup.popup()
	
	if thread == null:
		thread = Thread.new()
	elif thread.is_active():
		thread.wait_to_finish()
		thread = Thread.new()
	
	thread.start(self, "_thread_function")


func _thread_function() -> void:
	var image = Image.new()
	var watermarkImage = Image.new()
	var imageSize : Vector2
	var watermarkSize : Vector2
	var n : int = imagePathsArray.size()
	var nameArray : Array = []
	var fileName : String = ""
	
	progressBar.max_value = n
	progressBar.value = 0
	
	watermarkImage.load(watermarkPath)
	watermarkSize = watermarkImage.get_size()
	watermarkImage.convert(Image.FORMAT_RGBA8)
	
	for i in range(0, n, 1):
		if shoudKillThread:
			return
		nameArray = imagePathsArray[i].split("/")
		fileName = nameArray[nameArray.size() - 1]
		progressQuantityLabel.text = str(i) + "/" + str(n)
		progressFileLabel.text = fileName
		image.load(imagePathsArray[i])
		imageSize = image.get_size()
		image.convert(Image.FORMAT_RGBA8)
		image.blend_rect(
			watermarkImage, 
			Rect2(0, 0, watermarkSize.x, watermarkSize.y),
			Vector2(
				imageSize.x - watermarkSize.x - (0.01 * imageSize.x), 
				imageSize.y - watermarkSize.y - (0.01 * imageSize.y)
			)
		)
		image.save_png(appDirectory + "/" + fileName + ".png")
		progressBar.value += 1
	
	progressQuantityLabel.text = str(n) + "/" + str(n)
	popupOkBtn.disabled = false
	EnableButtons()


func _exit_tree():
	shoudKillThread = true
	if thread != null:
		if thread.is_active():
			thread.wait_to_finish()




