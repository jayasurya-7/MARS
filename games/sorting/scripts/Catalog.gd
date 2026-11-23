class_name Catalog
extends RefCounted
## All item categories. Each game picks 4 of these at random for the bins.

const ALL: Array[Dictionary] = [
	{"id": "toy_car", "name": "Toy Cars", "color": Color(0.86, 0.55, 0.47)},
	{"id": "book", "name": "Books", "color": Color(0.5, 0.65, 0.84)},
	{"id": "clothes", "name": "Clothes", "color": Color(0.5, 0.74, 0.62)},
	{"id": "stuffed_animal", "name": "Stuffed Toys", "color": Color(0.87, 0.73, 0.48)},
	{"id": "fruit", "name": "Fruit", "color": Color(0.84, 0.58, 0.67)},
	{"id": "shoe", "name": "Shoes", "color": Color(0.64, 0.59, 0.82)},
	{"id": "cup", "name": "Cups", "color": Color(0.47, 0.72, 0.76)},
	{"id": "ball", "name": "Balls", "color": Color(0.67, 0.77, 0.5)},
]


static func pick(n: int) -> Array[Dictionary]:
	var all := ALL.duplicate()
	all.shuffle()
	var out: Array[Dictionary] = []
	for i in n:
		out.append(all[i])
	return out
