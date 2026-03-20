class_name Arr

# Like Python's enumerate — maps over array with (index, element) instead of just element.
# Usage: Arr.emap(my_array, func(i, el): ...)
static func emap(arr: Array, fn: Callable) -> Array:
	var result = []
	for i in arr.size():
		result.append(fn.call(i, arr[i]))
	return result


# Deduplicate by reference — keeps first occurrence of each element.
# Usage: Arr.unique(my_array)
static func unique(arr: Array) -> Array:
	var seen: Array = []
	return arr.filter(func(el):
		if el in seen: return false
		seen.append(el)
		return true
	)
