class_name AwaitWrapper
extends RefCounted

signal _done(result)

var target: Callable

func _init(_target: Callable):
	self.target = _target

func Run():
	var result = await self.target.call()
	_done.emit(result)
	return
