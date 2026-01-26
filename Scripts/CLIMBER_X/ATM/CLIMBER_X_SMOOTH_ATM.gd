class_name SMOOTHER
extends Node

func smooth2(GridData : Array, TriData : Array[Array], niter : int) -> Array:
	var ReturnArray : Array = GridData
	for n in range(0,niter):
		var StorageArray : Array = []
		for i in range(0,GridData):
			var ValidInts : Array[int] = []
			for tri in TriData:
				if (tri.find(i) != -1):
					if(ValidInts.find(tri[0]) == -1):
						ValidInts.append(tri[0])
					if(ValidInts.find(tri[1]) == -1):
						ValidInts.append(tri[1])
					if(ValidInts.find(tri[2]) == -1):
						ValidInts.append(tri[2])
			if(ValidInts.find(i) != -1):
				ValidInts.remove_at(ValidInts.find(i))
			var PointTotal : float = 0
			for point in ValidInts:
				PointTotal += ReturnArray[point]
			PointTotal /= ValidInts.size()
			StorageArray.append((ReturnArray[i]+PointTotal)/2)
		ReturnArray = StorageArray
	return ReturnArray

func zona(GridData : Array, latlong : Array, Cost : Array, bounds : Array[float]) -> float:
	var value : float = 0.0
	var weight : int = 0
	for point in range(0,GridData.size()):
		if(latlong[point].x >= bounds[0] and latlong[point].x <= bounds[1]):
			value += GridData[point] * Cost[point]
			weight += Cost[point]
	return value/weight

#Leaving out Zofil()
