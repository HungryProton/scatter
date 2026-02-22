@tool
extends Node

const JumpableRNG = preload("../src/common/random.gd")
const ProtonScatterParallel = preload("../src/common/parallel.gd")


func _ready() -> void:
	_sequence_compare_int()
	_sequence_compare_float()
	_sequence_jump_compare_int()
	_sequence_jump_compare_float()
	_parallel_sequence()
	
	
func _sequence_compare_int() -> void:
	var rng_a: RandomNumberGenerator = RandomNumberGenerator.new()
	var rng_b: JumpableRNG = JumpableRNG.new()
	
	for seed: int in 10:
		rng_a.seed = seed
		rng_b.seed = seed
		
		for sequence: int in 100:
			var a: int = rng_a.randi()
			var b: int = rng_b.randi()

			assert(a==b)

	print("RNG integer sequence compare PASS")

func _sequence_compare_float() -> void:
	var rng_a: RandomNumberGenerator = RandomNumberGenerator.new()
	var rng_b: JumpableRNG = JumpableRNG.new()
	
	for seed: int in 10:
		rng_a.seed = seed
		rng_b.seed = seed
		
		for sequence: int in 10:
			var a: float = rng_a.randf()
			var b: float = rng_b.randf()

			assert(a==b)

	print("RNG float sequence compare PASS")

func _sequence_jump_compare_int() -> void:
	var rng_a: RandomNumberGenerator = RandomNumberGenerator.new()
	var rng_b: JumpableRNG = JumpableRNG.new()

	rng_a.seed = 1234
	rng_b.seed = 1234

	var set_a: Array[int] = []
	var set_b: Array[int] = []

	for i: int in 1000:
		set_a.append(rng_a.randi())

	var start_state: int = rng_b.state
	for i: int in 1000:
		if i % 50 == 0:
			rng_b.jump(987654)  # Jump away
			rng_b.randi()
			rng_b.jump(i)		# Jump back

		set_b.append(rng_b.randi())

	for i: int in 1000:
		var a: int = set_a[i]
		var b: int = set_b[i]
		
		if b != a:
			print("difference at step: %s, a=%s, b=%s" % [i, a, b])

		assert(b == a)

	print("RNG int sequence JUMPING compare PASS")
	
	
func _sequence_jump_compare_float() -> void:
	var rng_a: RandomNumberGenerator = RandomNumberGenerator.new()
	var rng_b: JumpableRNG = JumpableRNG.new()

	rng_a.seed = 1234
	rng_b.seed = 1234

	var set_a: Array[float] = []
	var set_b: Array[float] = []

	for i: int in 1000:
		set_a.append(rng_a.randf())

	var start_state: int = rng_b.state
	for i: int in 1000:
		if i % 50 == 0:
			rng_b.jump(987654)  # Jump away
			rng_b.randi()
			rng_b.jump(i * 2)		# Jump back

		set_b.append(rng_b.randf())

	for i: int in 1000:
		var a: float = set_a[i]
		var b: float = set_b[i]
		
		if b != a:
			print("difference at step: %s, a=%s, b=%s" % [i, a, b])

		assert(b == a)

	print("RNG float sequence JUMPING compare PASS")
	

var _parallel_result: Array[float] = []
	
func _parallel_sequence() -> void:

	const SEED: int = 123
	const AMOUNT: int = 50000

	_parallel_result.resize(AMOUNT)

	var classic_rng: RandomNumberGenerator = RandomNumberGenerator.new()
	classic_rng.seed = SEED


	var parallel: ProtonScatterParallel = ProtonScatterParallel.new()

	parallel.set_rng_seed(SEED, 2) 
	parallel.prepare("random_test", AMOUNT, 500, _parallel_random)
	
	parallel._tasks.shuffle()
	
	parallel.execute_all()
	
	for i: int in AMOUNT:
		assert(classic_rng.randf() == _parallel_result[i])
	
	print("Parallel execution jobs RNG sequence JUMPING compare PASS")


func _parallel_random(task: Dictionary) -> void:
	var from: int = task['from'] 		
	var to: int = task['to'] 
	var rng: JumpableRNG = task['rng']
	
	for i: int in range(from, to):
		_parallel_result[i] = rng.randf()
	
	
