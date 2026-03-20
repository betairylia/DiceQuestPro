class_name BindGroupAwait
extends RefCounted

signal _all_complete

var _counter: int = 0
var _results: Array = []

# tasks: Array[Callable]
static func all(tasks: Array) -> Array:
	var sg = BindGroupAwait.new()
	return await sg._register_all(tasks.map(
		func (task): return AwaitWrapper.new(task)
	))

# tasks: Array[AwaitWrapper]
func _register_all(tasks: Array) -> Array:
	_counter = tasks.size()
	_results.resize(len(tasks))
	
	if _counter == 0:
		return []
	
	for ix in range(len(tasks)):
		var task: AwaitWrapper = tasks[ix]
		task._done.connect(_on_signal_complete(ix), CONNECT_ONE_SHOT)
		task.Run()
	
	await _all_complete
	return _results
	
func _on_signal_complete(id: int) -> Callable:
	var foo = func foo(result) -> void:
		_counter -= 1
		_results[id] = result
		if _counter == 0:
			_all_complete.emit()
	return foo
