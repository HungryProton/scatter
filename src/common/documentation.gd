@tool
extends RefCounted

# This class provides a quick and easy way to document a Modifier and its
# parameters. It only holds the raw data, this is essentially a dictionnary
# with helper functions.


var _documentation: Dictionary


func _init():
	_documentation = {
		warnings = [],
		parameters = [],
		paragraphs = [],
	}

# Warning severity ranges from 0 to 2
func add_warning(text: String, severity := 0) -> void:
	_documentation.warnings.push_back({
		text = _remove_line_breaks(text),
		severity = severity,
	})


# Performance cost ranges from 0 to 3, 0 means no cost, 3 is a huge cost.
func add_parameter(parameter_name: String, text: String, cost := 0) -> void:
	_documentation.parameters.push_back({
		name = parameter_name,
		text = _remove_line_breaks(text),
		cost = cost,
	})


func add_paragraph(text: String, opts: Dictionary = {}) -> void:
	_documentation.paragraphs.push_back({
		text = _remove_line_breaks(text)
	})


func get_warnings() -> Array:
	return _documentation.warnings


func get_parameters() -> Array:
	return _documentation.parameters


func get_paragraphs() -> Array:
	return _documentation.paragraphs


func _remove_line_breaks(text: String) -> String:
	# Remove line breaks
	text = text.replace("\n", " ")
	# Remove occasional double space caused by the line above
	return text.replace("  ", " ")
