@tool
extends RandomNumberGenerator

# Allow jumping to a position in the sequence of the current seed
# Note this this is a rare case of where I used AI to help out.
# Prompt involved giving it the C++ implementation backend of 
# gdscript RandomNumberGenerator.

const MULT: int = 6364136223846793005
const INC_DEFAULT: int = 1442695040888963407

func jump(position: int) -> void:
	var temp: RandomNumberGenerator = RandomNumberGenerator.new()
	temp.seed = seed
	state = _get_jumped_state(temp.state, position)

func _get_jumped_state(current_state: int, delta: int) -> int:
	var cur_mult: int = MULT
	var cur_plus: int = (INC_DEFAULT << 1) | 1
	var acc_mult: int = 1
	var acc_plus: int = 0
	
	# Unsigned 64-bit Delta handling
	var delta_u: int = delta
	while delta_u != 0:
		if delta_u & 1:
			acc_mult = _mul64(acc_mult, cur_mult)
			acc_plus = _mul64(acc_plus, cur_mult) + cur_plus
		cur_plus = _mul64(cur_mult, cur_plus) + cur_plus
		cur_mult = _mul64(cur_mult, cur_mult)
		# Logical shift right
		delta_u = (delta_u >> 1) & 0x7FFFFFFFFFFFFFFF
	
	return _mul64(acc_mult, current_state) + acc_plus

func _mul64(a: int, b: int) -> int:
	var a_lo: int = a & 0xffffffff
	var a_hi: int = (a >> 32) & 0xffffffff
	var b_lo: int = b & 0xffffffff
	var b_hi: int = (b >> 32) & 0xffffffff
	var lo: int = a_lo * b_lo
	var hi: int = (a_hi * b_lo + a_lo * b_hi + (lo >> 32))
	return (lo & 0xffffffff) | (hi << 32)

## Calculates the state of a PCG32 RNG after 'delta' steps.
## current_s: The starting 64-bit state (from rng.state)
## delta: The number of steps to jump forward
func _calculate_jump(current_s: int, delta: int) -> int:
	# PCG Constants
	var cur_mult: int = 6364136223846793005
	var cur_plus: int = 1442695040888963407 # (INC_DEFAULT << 1) | 1
	
	# Result constants
	var acc_mult: int = 1
	var acc_plus: int = 0
	
	# Handle delta as unsigned 64-bit
	var delta_u: int = delta
	
	while delta_u > 0:
		# If the current bit of delta is set, apply the current transformation
		if delta_u & 1:
			acc_mult = _mul64(acc_mult, cur_mult)
			acc_plus = _u64_add(_mul64(acc_plus, cur_mult), cur_plus)
		
		# Square the transformation (double the jump distance)
		cur_plus = _u64_add(_mul64(cur_mult, cur_plus), cur_plus)
		cur_mult = _mul64(cur_mult, cur_mult)
		
		# Logical shift right to process the next bit of delta
		delta_u = (delta_u >> 1) & 0x7FFFFFFFFFFFFFFF
		
	# Final state = (original_state * acc_mult) + acc_plus
	return _u64_add(_mul64(acc_mult, current_s), acc_plus)

# --- Helper logic to keep math in the 64-bit integer lane ---
func _u64_add(a: int, b: int) -> int:
	return a + b
	
