extends RefCounted

## Custom render sample
## 1. Open the demo scene, select a Scatter node
## 2. Select this script as 'Custom Render Script'
## 3. Select Render Mode 'Custom'
## 
## Note that if you do 3. before 2. youll see a error indicating a script is required.


## scatter:    The scatter node; note using this introduces higher chance if incompatibility
##             of your script with future versions of ProtonScatter
##
## transforms: The transforms result from the modifier stack
##
## config:     The custom render resource set on the node, cast this to what you expect (if any)
##
func protonscatter_custom_render(scatter: ProtonScatter, transforms: Array[Transform3D], config: Resource) -> void:
	print("Using sample protonscatter_custom_render")
	
	# Just use one of the standard ones; replace this with your custom render-instancing code
	scatter._update_multimeshes()
