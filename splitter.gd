# tool

# class_name

# extends
extends Control

## A brief description of your script.
##
## A more detailed description of the script.
##
## @tutorial:			http://the/tutorial1/url.com
## @tutorial(Tutorial2): http://the/tutorial2/url.com


# ----- signals

# ----- enums
enum LOCAL_STATUS {
	WAIT = 0,
	SPLIT_CICLE,
	SPLIT_WRITE_BRICK,
	MERGE_CICLE,
	MERGE_WRITE_FILE,
}

# ----- constants
const CHUNKSIZE = 550000
# MAX CHUNKSIZE IN A BRICK
const CHUNKSIZE_MULTI = 1000
const PREF = "test_"
const DEST_DIR = "/area_sviluppo/000_mapod4d/projects/c2/mapod4d_splitter_c2/file_splitted"
const FILE_DEST = "/area_sviluppo/000_mapod4d/projects/c2/mapod4d_splitter_c2/file_merged/test.exe"

# ----- exported variables

# ----- public variables


# ----- private variables
var _compressed = true
var _file_name = null
var _local_status = LOCAL_STATUS.WAIT
## split and merge var
var _from_data = null
var _current_brick = 0
var _current_brick_chunk = 0
var _brick_dest = null
var _brick_src = null
var _merge_file_dest = null

# ----- onready variables
@onready var chooser = $Chooser
@onready var _file_name_label = $MarginContainer/HBoxContainer/VBoxContainer2/Filename
@onready var _msgr = $MarginContainer/HBoxContainer/VBoxContainer2/Msgr
@onready var _split_button = $MarginContainer/HBoxContainer/VBoxContainer/Split
@onready var _brick_name = $MarginContainer/HBoxContainer/VBoxContainer2/HBoxContainer/BrickName
@onready var _merge_dest = $MarginContainer/HBoxContainer/VBoxContainer2/HBoxContainer2/MergeDest


# ----- optional built-in virtual _init method

# ----- built-in virtual _ready method

# Called when the node enters the scene tree for the first time.
func _ready():
	chooser.current_dir = "/area_sviluppo/000_mapod4d/projects/c2/mapod4d_splitter_c2/files"
	_msgr.text = ""
	_brick_name.clear()

# ----- remaining built-in virtual methods

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	match _local_status:
		LOCAL_STATUS.WAIT:
			pass 
		LOCAL_STATUS.SPLIT_CICLE:
			_split_cicle()
		LOCAL_STATUS.SPLIT_WRITE_BRICK:
			_split_write_brick()
		LOCAL_STATUS.MERGE_CICLE:
			_merge_cicle()
		LOCAL_STATUS.MERGE_WRITE_FILE:
			_merge_write_file()
	
# ----- public methods

# ----- private methods


func _on_choose_file_pressed():
	chooser.popup()


func _on_split_pressed():
	if _file_name != null:
		var brick_name = str(_brick_name.text).strip_edges().replace(' ','')
		_brick_name.text = brick_name
		var file_name = _file_name
		print(file_name)
		if len(brick_name) > 0:
			_from_data = FileAccess.open(file_name, FileAccess.READ)
			_current_brick = 0
			_current_brick_chunk = 0
			_split_button.disabled = true
			_msgr.text = ""
			_local_status = LOCAL_STATUS.SPLIT_CICLE
		else:
			_msgr.append_text("Enter brick name\n")


func _split_cicle():
	if _from_data.eof_reached() == false:
		var brick_name = _brick_name.text
		var file_name_dest_pre = DEST_DIR + "/" + brick_name + "_"
		var dest_file_name = file_name_dest_pre + str(_current_brick)
		if _compressed:
			_brick_dest = FileAccess.open_compressed(
					dest_file_name , 
					FileAccess.WRITE, FileAccess.COMPRESSION_DEFLATE)
		else:
			_brick_dest = FileAccess.open(dest_file_name , FileAccess.WRITE)
		_current_brick += 1
		_current_brick_chunk = 0
		_local_status = LOCAL_STATUS.SPLIT_WRITE_BRICK
	else:
		_from_data.close()
		_msgr.append_text("SPLIT ENDED\n")
		_local_status = LOCAL_STATUS.WAIT


func _split_write_brick():
	if _from_data.eof_reached() == false:
		if _current_brick_chunk >= CHUNKSIZE_MULTI:
			_brick_dest.close()
			_local_status = LOCAL_STATUS.SPLIT_CICLE
		else:
			var data_read = _from_data.get_buffer(CHUNKSIZE)
			var msg = str(_current_brick_chunk) + "-" + str(data_read.size())
			print(msg)
			_msgr.append_text(str(msg) + "\n")
			_brick_dest.store_buffer(data_read)
			_current_brick_chunk += 1
			_local_status = LOCAL_STATUS.SPLIT_WRITE_BRICK
	else:
		_brick_dest.close()
		_local_status = LOCAL_STATUS.SPLIT_CICLE


## split file file choosed
func _on_chooser_file_selected(path):
	#_file_name = chooser.current_dir + "/" + chooser.current_file
	_file_name = path
	_file_name_label.text = path
	_split_button.disabled = false


func _on_merge_pressed():
	#var count = 0
	#var data_read = null
	#var file_name_pre = DEST_DIR + "/" + PREF
	#var dest = FileAccess.open(FILE_DEST, FileAccess.WRITE)
	#
	#while true:
		#var name = file_name_pre + str(count)
		#print("START" + name)
		#if FileAccess.file_exists(name) == false:
			#dest.close()
			#break
		#var data = null
		#if _compressed:
			#data = FileAccess.open_compressed(
				#name, FileAccess.READ, FileAccess.COMPRESSION_DEFLATE)
		#else:
			#data = FileAccess.open(name, FileAccess.READ)
		#print(FileAccess.get_open_error())
		#_read_and_save(data, dest)
		#count += 1
	var brick_name = str(_brick_name.text).strip_edges().replace(' ','')
	_brick_name.text = brick_name
	var merge_dest = str(_merge_dest.text).strip_edges().replace(' ','')
	_merge_dest.text = merge_dest
	if len(brick_name) > 0:
		if len(merge_dest) > 0:
			var file_name_src_pre = DEST_DIR + "/" + brick_name + "_"
			var src_file_name = file_name_src_pre + str(_current_brick)
			var dest_name = DEST_DIR + "/" + merge_dest
			if FileAccess.file_exists(src_file_name):
				_merge_file_dest = FileAccess.open(dest_name, FileAccess.WRITE)
				_current_brick = 0
				_current_brick_chunk = 0
				_msgr.text = ""
				_local_status = LOCAL_STATUS.MERGE_CICLE
			else:
				_msgr.append_text("brick %s not found" % [src_file_name])
		else:
			_msgr.append_text("Enter merge dest name\n")
	else:
		_msgr.append_text("Enter brick name\n")


func _merge_cicle():
	var brick_name = str(_brick_name.text).strip_edges().replace(' ','')
	var file_name_src_pre = DEST_DIR + "/" + brick_name + "_"
	var src_file_name = file_name_src_pre + str(_current_brick)
	if FileAccess.file_exists(src_file_name):
		if _compressed:
			_brick_src = FileAccess.open_compressed(
					src_file_name, 
					FileAccess.READ, FileAccess.COMPRESSION_DEFLATE)
		else:
			_brick_src = FileAccess.open(src_file_name , FileAccess.READ)
		_local_status = LOCAL_STATUS.MERGE_WRITE_FILE
	else:
		_merge_file_dest.close()
		_msgr.append_text("MERGE ENDED\n")
		_local_status = LOCAL_STATUS.WAIT


func _merge_write_file():
	if _brick_src.eof_reached() == false:
		var data_read = _brick_src.get_buffer(CHUNKSIZE)
		var msg = str(_current_brick_chunk) + "-" + str(data_read.size())
		print(msg)
		_msgr.append_text(str(msg) + "\n")
		_merge_file_dest.store_buffer(data_read)
		_current_brick_chunk += 1
		_local_status = LOCAL_STATUS.MERGE_WRITE_FILE
	else:
		_brick_src.close()
		_current_brick += 1
		_local_status = LOCAL_STATUS.MERGE_CICLE


## OLD

##	var ctx = HashingContext.new()
##	ctx.start(HashingContext.HASH_SHA256)
		#_read_and_save(data, dest)
##		ctx.update(data_read)
		#dest.close()
		#count += 1
##	var result = ctx.finish()
##	print("END SPLIT " + result.hex_encode())
