@tool
extends RefCounted


# Stores raw documentation data.

# The data is provided by any class that needs an entry in the documentation
# panel. This was initially designed for all the modifiers, but might be expanded
# to other parts of the addon as well.

# Formatting is handled by the main Documentation class.

const Util := preload("../common/util.gd")


class Warning:
	var text: String
	var importance: int

class Parameter:
	var name: String
	var cost: int
	var type: String
	var description: String
	var warnings: Array[Warning] = []

	func set_name(text: String) -> Parameter:
		name = Util.remove_line_breaks(text)
		return self

	func set_description(text: String) -> Parameter:
		description = Util.remove_line_breaks(text)
		return self

	func set_cost(val: int) -> Parameter:
		cost = val
		return self

	func set_type(val: String) -> Parameter:
		type = Util.remove_line_breaks(val)
		return self

	func add_warning(warning: String, warning_importance := -1) -> Parameter:
		var w = Warning.new()
		w.text = Util.remove_line_breaks(warning)
		w.importance = warning_importance
		warnings.push_back(w)
		return self


var _category: String
var _page_title: String
var _paragraphs: Array[String] = []
var _warnings: Array[Warning] = []
var _parameters: Array[Parameter] = []


func set_category(text: String) -> void:
	_category = text


func set_title(text: String) -> void:
	_page_title = text


func add_paragraph(text: String) -> void:
	_paragraphs.push_back(Util.remove_line_breaks(text))


# Warning importance:
#	0: Default (Grey)
#	1: Mid (Yellow)
#	2: Critical (Red)
func add_warning(text: String, importance: int = 0) -> void:
	var w = Warning.new()
	w.text = Util.remove_line_breaks(text)
	w.importance = importance

	_warnings.push_back(w)


# Add documentation for a user exposed parameter.
# Cost:
# 	0: None
# 	1: Log
# 	2: Linear
# 	3: Exponential
func add_parameter(name := "") -> Parameter:
	var p = Parameter.new()
	p.name = name
	p.cost = 0
	_parameters.push_back(p)
	return p


func get_title() -> String:
	return _page_title


func get_category() -> String:
	return _category


func get_paragraphs() -> Array[String]:
	return _paragraphs


func get_warnings() -> Array[Warning]:
	return _warnings


func get_parameters() -> Array[Parameter]:
	return _parameters
