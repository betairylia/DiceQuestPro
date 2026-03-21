class_name BindGroupAwait
extends RefCounted

var _all_complete: bool
signal _signal_all_complete

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
	
	_all_complete = false
	
	for ix in range(len(tasks)):
		var task: AwaitWrapper = tasks[ix]
		task._done.connect(_on_signal_complete(ix), CONNECT_ONE_SHOT)
		task.Run()
	
	if not _all_complete:
		await _signal_all_complete
	return _results
	
func _until_all_complete():
	while(_all_complete == false):
		pass

func _on_signal_complete(id: int) -> Callable:
	var foo = func foo(result) -> void:
		_counter -= 1
		_results[id] = result
		if _counter == 0:
			_all_complete = true
			_signal_all_complete.emit()
	return foo
