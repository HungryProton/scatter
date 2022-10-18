@tool
extends RefCounted


# Stores raw documentation data.

# The data is provided by any class that needs an entry in the documentation
# panel. This was initially designed for all the modifiers, but might be expanded
# to other parts of the addon as well.

# Formatting is handled by the main Documentation class.


class Warning:
	var text: String
	var importance: int

class Parameter:
	var name: String
	var cost: int
	var description: String
	var warning: Warning


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
	_paragraphs.push_back(_remove_line_breaks(text))


# Warning importance:
#	0: Default (Grey)
#	1: Mid (Yellow)
#	2: Critical (Red)
func add_warning(text: String, importance: int = 0) -> void:
	var w = Warning.new()
	w.text = _remove_line_breaks(text)
	w.importance = importance

	_warnings.push_back(w)


# Add documentation for a user exposed parameter.
# Cost:
# 	0: None
# 	1: Log
# 	2: Linear
# 	3: Exponential
func add_parameter(name: String, description: String, cost := 0, warning: String = "", warning_importance := -1) -> void:
	var p = Parameter.new()
	p.name = name
	p.cost = cost
	p.description = _remove_line_breaks(description)

	var w = Warning.new()
	w.text = _remove_line_breaks(warning)
	w.importance = warning_importance
	p.warning = w

	_parameters.push_back(p)


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


func _remove_line_breaks(text: String) -> String:
	# Remove tabs
	text = text.replace("\t", "")
	# Remove line breaks
	text = text.replace("\n", " ")
	# Remove occasional double space caused by the line above
	return text.replace("  ", " ")
