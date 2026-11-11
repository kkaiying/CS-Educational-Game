extends HBoxContainer

@export var setting_name := "Setting"
@export var values: Array[float] = []
@export var default_index := 0

func _ready():
	$NameLabel.text = setting_name
	$Slider.min_value = 0
	$Slider.max_value = values.size() - 1
	$Slider.step = 1
	$Slider.value = default_index
	$Slider.value_changed.connect(func(_v): update_label())
	update_label()
	
# setting's actual value, e.g. 0.95
func get_value() -> float:
	return values[int($Slider.value)]

func update_label() -> void:
	$ValueLabel.text = str(get_value())
