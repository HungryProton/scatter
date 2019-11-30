# --
# DistributionUnique
# --
# Only useful for its get_int method. Returns a sequence of non repeating
# numbers in the given range. This is useful if you want non repeating
# --

tool

extends ScatterDistribution

class_name DistributionUnique

## --
## Exported variables
## --

## --
## Public variables
## --

## --
## Internal variables
## --

var _rand = RandomNumberGenerator.new()
var _numbers : Array = Array()
var _offset : int = 0

## --
## Getters and Setters
## --


## --
## Public methods
## --

func reset() -> void:
	_rand.set_seed(random_seed)
	_shuffle()
	_offset = -1

func get_int() -> int:
	_offset += 1
	return _numbers[_offset]

## --
## Protected methods
## --

## --
## Internal methods
## --

func _shuffle() -> void:
	_numbers = Array()
	_numbers.resize(range_1d.y)

	for i in range(range_1d.y):
		_numbers[i] = i
		var j = _rand.randi_range(0, i)
		if j != i:
			var ni = _numbers[i]
			var nj = _numbers[j]
			_numbers[i] = nj
			_numbers[j] = ni
