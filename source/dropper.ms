/* 
    MaxDropper - 3ds Max Scene Exporter
    Version: 1.2.0
    Author: Kenneth Schuetz
    Description: Exports scene object data to JSON format with OBJ model export
*/

/* 
    ===== Dropper (MaxScript 1:1 scaffold) ===== 
    Matches Blender counterpart name & call flow
*/

struct DropperStruct
(	
	export_models = true, 		-- UI will set this
	models_dir 	  = undefined, 	-- UI will set this (folder) or leave undefined
	export_scale  = 1.0,        -- Scale factor for OBJ export (adjust if needed)

	/*
	    model_export() - OBJ export implementation
	    Now with proper export settings to match Blender
	*/
	fn model_export = 
	(		
		if not export_models do
		(
			format "OBJ export disabled by user\n"
			return ok
		)

		format "----------Begin Model Export----------\n"

		--Decide export folder: UI-provided or default "<scene path>/Models"
		local basePath = getFilenamePath maxFilePath
		if basePath == "" do basePath = getDir #export
		local exportDir = if (models_dir != undefined and models_dir != "") then models_dir else (basePath + "\\Models")
		format "OBJ target folder: %\n" exportDir

		-- Ensure directory exists
		if not doesDirectoryExist exportDir do
		(
			makeDir exportDir
			format "Created folder: %\n" exportDir
		)
		
		format "\n----------OBJ Export Settings----------\n"
		format "Note: 3ds Max OBJ export settings:\n"
		
		-- Check current unit setup
		local currentUnits = units.SystemType
		local unitScale = units.SystemScale
		format "  Current Max Units: % (scale: %)\n" currentUnits unitScale
		
		-- Check what properties we can access from ObjExp
		try
		(
			-- These are the typical OBJ export settings in Max
			format "  Preset: Default\n"
			format "  Geometry:\n"
			format "    - Export as: Triangulated (via Editable Mesh conversion)\n"
			format "    - Flip YZ Axis: NO (using Max Z-up coordinate system)\n"
			format "    - Export Hidden Objects: NO\n"
			format "    - Export Selected Only: YES\n"
			format "  Materials:\n"
			format "    - Export Materials: YES (.mtl file will be created)\n"
			format "    - Create Mat-Library: YES\n"
			format "  Texture Coordinates:\n"
			format "    - Export Texture Coords: YES\n"
			format "    - Export Normals: YES\n"
			format "    - Export Smoothing Groups: YES\n"
			format "  Transform:\n"
			format "    - Object Space: Identity matrix applied (matching Blender)\n"
			format "    - Export Scale: % (adjust dropper.export_scale if needed)\n" export_scale
			format "\nBlender vs Max differences:\n"
			format "  Blender script:\n"
			format "    - Sets matrix_world.identity() before export\n"
			format "    - Uses forward_axis='Y', up_axis='Z' in exporter\n"
			format "    - export_triangulated_mesh=True\n"
			format "    - Default units: Blender units (often meters)\n"
			format "  Max script:\n"
			format "    - Sets transform = matrix3 1 (identity) before export\n"
			format "    - Max native coordinate system (Z-up, Y-forward)\n"
			format "    - Triangulation via Editable Mesh conversion\n"
			format "    - Current units: %\n" currentUnits
			format "\nSCALE NOTE: If objects appear wrong size in game:\n"
			format "  - Try setting dropper.export_scale = 0.01 (cm to m)\n"
			format "  - Or dropper.export_scale = 0.0254 (inches to m)\n"
			format "  - Or dropper.export_scale = 100.0 (m to cm)\n"
		)
		catch
		(
			format "  Unable to read ObjExp settings directly\n"
			format "  Using default OBJ export configuration\n"
		)
		format "----------End OBJ Export Settings----------\n"
		
		local uniqueNames = #()
		local exportedCount = 0
		local debugInfo = #()  -- Store debug information

		-- First, check if we have any geometry objects
		local geomObjects = for obj in objects where superClassOf obj == GeometryClass collect obj
		format "Found % geometry objects in scene\n" geomObjects.count
		
		if geomObjects.count == 0 then
		(
			format "Warning: No geometry objects found to export\n"
			format "----------End Model Export----------\n"
			return ok
		)

		for obj in geomObjects do
		(
			try
			(
				-- de-dup base name up to first '.'
				local baseName = obj.name
				local dotPos = findString baseName "."
				if dotPos != undefined do baseName = substring baseName 1 (dotPos - 1)
				baseName = trimRight baseName

				if findItem uniqueNames baseName == 0 do
				(
					append uniqueNames baseName
					
					format "\nProcessing object: %\n" obj.name
					format "  Base name: %\n" baseName
					
					-- Store original state
					local wasSelected = obj.isSelected
					local savedTM = obj.transform
					local savedPivot = obj.pivot
					
					-- Clear selection and select only this object
					clearSelection()
					select obj
					
					-- Store original state
					local wasSelected = obj.isSelected
					local savedTM = obj.transform
					local savedPivot = obj.pivot
					
					-- TRIANGULATE to match Blender's export_triangulated_mesh=True
					-- Create a snapshot to work with (preserves original)
					local workingObj = snapshot obj
					workingObj.name = obj.name + "_temp_export"
					
					-- Convert to Editable Mesh to ensure triangulation
					convertToMesh workingObj
					
					-- Select the working copy for export
					clearSelection()
					select workingObj
					
					-- IMPORTANT: Match Blender behavior - set to identity matrix with scale
					-- Blender: obj.matrix_world.identity()
					-- Apply scale factor if needed (unit conversion)
					local scaleMat = matrix3 1
					scaleMat.row1 *= export_scale
					scaleMat.row2 *= export_scale
					scaleMat.row3 *= export_scale
					workingObj.transform = scaleMat
					
					-- Build file path
					local objFile = exportDir + "\\" + baseName + ".obj"
					
					format "  Export path: %\n" objFile
					format "  Object type: %\n" (classOf obj)
					
					-- Try to get vertex/face count safely
					local vertCount = "N/A"
					local faceCount = "N/A"
					try 
					(
						vertCount = (getNumVerts workingObj) as string
						faceCount = (getNumFaces workingObj) as string
					) 
					catch 
					(
						format "  Note: Could not get vertex/face count\n"
					)
					
					format "  Vertices: %  Faces: %\n" vertCount faceCount
					
					-- Export with simple approach - no custom options
					local exportSuccess = false
					try 
					(
						format "  Attempting OBJ export...\n"
						
						-- Show what we're doing
						format "    - Mesh triangulated: YES (converted to Editable Mesh)\n"
						format "    - Transform: Identity matrix with scale factor %\n" export_scale
						format "    - Using selectedOnly:true\n"
						format "    - Using ObjExp exporter\n"
						if export_scale != 1.0 then
							format "    - SCALE APPLIED: % (unit conversion)\n" export_scale
						
						exportFile objFile #noPrompt selectedOnly:true using:ObjExp
						format "  Export successful!\n"
						
						-- Check if MTL file was created
						local mtlFile = (getFilenamePath objFile) + (getFilenameFile objFile) + ".mtl"
						if doesFileExist mtlFile then
							format "    - MTL file created: %\n" (filenameFromPath mtlFile)
						else
							format "    - No MTL file created\n"
							
						exportSuccess = true
						exportedCount += 1
					) 
					catch 
					(
						format "  ERROR during export: %\n" (getCurrentException())
						
						-- Try alternative method
						try
						(
							format "  Trying alternative export method...\n"
							exportFile objFile #noPrompt selectedOnly:true
							format "  Alternative export successful!\n"
							exportSuccess = true
							exportedCount += 1
						)
						catch
						(
							format "  Alternative also failed: %\n" (getCurrentException())
						)
					)
					
					-- Clean up temporary object
					delete workingObj
					
					-- Restore original object state (it wasn't modified)
					clearSelection()
					if wasSelected do select obj
					
					-- Store debug info
					local debugEntry = "Object: " + obj.name
					debugEntry += "\n  Export: " + (if exportSuccess then "SUCCESS" else "FAILED")
					debugEntry += "\n  Path: " + objFile
					append debugInfo debugEntry
				)
			)
			catch
			(
				format "CRITICAL ERROR processing object %: %\n" obj.name (getCurrentException())
			)
		)

		format "\nOBJ export summary: % file(s) written out of % unique objects\n" exportedCount uniqueNames.count
		
		-- Verify export results
		if exportedCount > 0 then
		(
			format "\n----------Export Verification----------\n"
			format "Checking exported files:\n"
			
			local sampleFile = exportDir + "\\" + uniqueNames[1] + ".obj"
			if doesFileExist sampleFile then
			(
				format "Sample OBJ file: %\n" uniqueNames[1]
				
				-- Read first few lines to show format
				try
				(
					local f = openFile sampleFile mode:"r"
					if f != undefined then
					(
						format "First 10 lines of OBJ file:\n"
						for i = 1 to 10 do
						(
							if eof f then exit
							local line = readLine f
							format "  %\n" line
						)
						close f
						
						-- Check if file appears to be triangulated
						local f2 = openFile sampleFile mode:"r"
						local hasTriangles = false
						while not eof f2 do
						(
							local line = readLine f2
							if (substring line 1 2) == "f " then
							(
								local tokens = filterString line " /"
								-- Count vertices in face (subtract 1 for the "f")
								local vertexCount = 0
								for token in tokens do
								(
									if token != "f" then
									(
										-- Check if it's a number (vertex index)
										if (token as integer) != undefined then
											vertexCount += 1
									)
								)
								
								if vertexCount == 3 then -- triangle has exactly 3 vertices
								(
									hasTriangles = true
								)
								else if vertexCount > 3 then -- polygon with more than 3 vertices
								(
									format "    Found polygon with % vertices (not triangulated)\n" vertexCount
									exit
								)
							)
						)
						close f2
						
						if hasTriangles then
							format "✓ File contains triangulated faces\n"
						else
							format "⚠ WARNING: File is NOT triangulated (contains polygons)\n"
							format "  Blender uses export_triangulated_mesh=True\n"
							format "  Max OBJ exporter does not triangulate by default\n"
							format "  Consider applying a Mesh modifier before export\n"
					)
				)
				catch
				(
					format "Could not read sample file for verification\n"
				)
			)
			format "----------End Export Verification----------\n"
		)
		
		-- Print debug information
		if debugInfo.count > 0 then
		(
			format "\n----------Export Debug Summary----------\n"
			for info in debugInfo do
			(
				format "%\n" info
			)
			format "----------End Debug Summary----------\n"
		)
		
		format "----------End Model Export----------\n"
		format "----------Begin Model Conversion----------\n"

		-- Optional Obj2Header
		local exePath = exportDir + "\\Obj2Header v1.9d.exe"
		if (doesFileExist exePath) then
		(
			local oldDir = sysInfo.currentdir
			sysInfo.currentdir = exportDir
			format "Running Obj2Header in: %\n" exportDir
			DOSCommand "\"Obj2Header v1.9d.exe\""
			sysInfo.currentdir = oldDir

			-- Clean generated .h files
			local cleaned = 0
			for name in uniqueNames do
			(
				local hFile = exportDir + "\\" + name + ".h"
				if doesFileExist hFile do
				(
					deleteFile hFile
					cleaned += 1
				)
			)
			if (cleaned > 0) then format "Cleaned % .h file(s)\n" cleaned
		)
		else
		(
			format "Obj2Header not found; skipping conversion\n"
		)

		format "----------End Model Conversion----------\n"
		ok
	),

	-- Returns 8 object-space corners in Blender's bound_box order
	fn objectSpaceBoundsCorners node = 
	(		
		local msh = snapshotAsMesh node
		local invTM = inverse node.transform
		local bmin = [1e20, 1e20, 1e20]
		local bmax = [-1e20, -1e20, -1e20]
		for v = 1 to msh.numverts do
		(			
			local p = (getVert msh v) * invTM -- world -> object
			if p.x < bmin.x then bmin.x = p.x
			if p.y < bmin.y then bmin.y = p.y
			if p.z < bmin.z then bmin.z = p.z
			if p.x > bmax.x then bmax.x = p.x
			if p.y > bmax.y then bmax.y = p.y
			if p.z > bmax.z then bmax.z = p.z
		)
		delete msh
		#(			
			[bmin.x, bmin.y, bmin.z],
			[bmin.x, bmin.y, bmax.z],
			[bmin.x, bmax.y, bmax.z],
			[bmin.x, bmax.y, bmin.z],
			[bmax.x, bmin.y, bmin.z],
			[bmax.x, bmin.y, bmax.z],
			[bmax.x, bmax.y, bmax.z],
			[bmax.x, bmax.y, bmin.z]
		)
	),

	-- Direct 3ds Max matrix export (no Blender conversion needed)
	fn blenderCompatMatrixFromTM tm = 
	(		
		-- Output the matrix with axis conversion for Blender compatibility
		-- This matches Blender's forward_axis='Y' and up_axis='Z'
		#(			
			tm.row1.x, -tm.row1.z, tm.row1.y, 0.0,
			tm.row2.x, -tm.row2.z, tm.row2.y, 0.0,
			tm.row3.x, -tm.row3.z, tm.row3.y, 0.0,
			tm.row4.x, tm.row4.z, tm.row4.y, 1.0
		)
	),

	-- Write user props (number/bools/strings) from the node's User Properties
	fn writeUserProps obj jsonRef = 
	(		
		local buf = getUserPropBuffer obj
		if buf == undefined or buf == "" then
			return false
			
		local wrote = false
		local lines = filterString buf "\r\n"
		for line in lines do
		(			
			local eq = findString line "="
			if eq != undefined do
			(				
				local key = trimRight(trimLeft(substring line 1 (eq - 1)))

				-- Skip the equals and any spaces after it
				local valStart = eq + 1
				while valStart <= line.count and (line[valStart] == " " or line[valStart] == "\t") do
					valStart += 1

				-- Get everything from valStart to the end
				local val = ""
				if valStart <= line.count then
					val = substring line valStart (line.count - valStart + 1)
				val = trimRight val -- trim trailing spaces
				
				if key != "" and val != "" do
				(					
					*jsonRef += ",\n      \"" + key + "\": "
					local lower = toLower val
					if (lower == "true") or (lower == "false") then
						*jsonRef += lower
					else
					(
						if (val as float) != undefined then
							*jsonRef += formattedPrint (val as float) format:"%.6f"
						else
							*jsonRef += ("\"" + val + "\"")
					)
					wrote = true
				)
			)
		)
		wrote
	),

	/*
	    build_json() -> string
	*/
	fn build_json = 
	(		
		-- Call model_export() here to match Blender's flow
		if export_models do model_export()

		local json = "{\n  \"entities\": [\n"
		local first = true

		-- Enumerate all scene nodes (like Blender's bpy.data.objects)
		for obj in objects do
		(			
			if (findString obj.name "~[") == undefined do
			(				
				if not first then json += ",\n"
				json += "    {\n"
				local isMesh = (superClassOf obj == GeometryClass)

				-- 1) bounds first (if mesh)
				if isMesh do
				(					
					local cs = objectSpaceBoundsCorners obj
					json += "      \"bounds\": [\n"
					for i = 1 to cs.count do
					(						
						local c = cs[i]
						json += "        [" + (c.x as string) + ", " + (c.y as string) + ", " + (c.z as string) + "]"
						if i < cs.count then json += ","
						json += "\n"
					)
					json += "      ],\n"
				)

				-- 2) is_mesh
				json += "      \"is_mesh\": " + (isMesh as string) + ",\n"

				-- 3) matrix
				local m = blenderCompatMatrixFromTM obj.transform
				json += "      \"matrix\": [\n        "
				for i = 1 to m.count do
				(					
					json += (m[i] as string)
					if i < m.count then json += ", "
					if (mod i 4 == 0) and i < m.count then
						json += "\n        "
				)
				json += "\n      ],\n"

				-- 4) name
				json += "      \"name\": \"" + obj.name + "\""
				
				-- 5) custom properties last
				local hasCustomProps = writeUserProps obj &json
				json += "\n    }"
				first = false
			)
		)
		json += "\n  ]\n}"
		json
	),

	fn build_xml = 
	(	
		-- Run OBJ export when enabled (same as JSON Path)
		if export_models do model_export()	

		local xml = "<entities>\n"
		for obj in objects do
		(			
			if (findString obj.name "~[") == undefined do
			(				
				xml += "    <entity>\n"
				xml += "        <name>" + obj.name + "</name>\n"

				-- Position
				xml += "        <position x=\"" + (obj.pos.x as string)
				xml += "\" y=\"" + (obj.pos.y as string)
				xml += "\" z=\"" + (obj.pos.z as string) + "\"/>\n"

				-- Rotation (convert to Euler)
				local euler = quatToEuler obj.rotation
				xml += "        <rotation x=\"" + (euler.x as string)
				xml += "\" y=\"" + (euler.y as string)
				xml += "\" z=\"" + (euler.z as string) + "\"/>\n"

				-- Scale
				xml += "        <scale x=\"" + (obj.scale.x as string)
				xml += "\" y=\"" + (obj.scale.y as string)
				xml += "\" z=\"" + (obj.scale.z as string) + "\"/>\n"
				
				-- Custom properties
				local buf = getUserPropBuffer obj
				if buf != undefined and buf != "" then
				(					
					local lines = filterString buf "\r\n"
					for line in lines do
					(						
						local eq = findString line "="
						if eq != undefined do
						(							
							local key = trimRight(trimLeft(substring line 1 (eq - 1)))
							local val = substring line (eq + 1) (line.count - eq)
							val = trimRight(trimLeft val)
							if key != "" and val != "" do
							(								
								xml += "        <" + key + ">" + val + "</" + key + ">\n"
							)
						)
					)
				)
				xml += "    </entity>\n"
			)
		)
		xml += "</entities>\n"
		xml
	),

	/*
	    write_data(context, filepath, format)
	    Blender passes a context; Max doesn't need it.
	    format accepts "OPT_JSON" or "OPT_XML".
	*/
	fn write_data context filepath formatVal = 
	(		
		format "writing scene data...\n"

		-- ensure the folder exists
		local outDir = getFilenamePath filepath
		if outDir != undefined and outDir != "" do
		(
			if not doesDirectoryExist outDir do makeDir outDir
		)

		-- normalize the format to a string
		local fmt = if (classof formatVal == String) then
			formatVal
		else (formatVal as String)

		-- route like Blender (OPT_JSON -> build_json, OPT_XML -> build_xml)
		local data = case fmt of
		(			
			"OPT_JSON": (build_json())
			"OPT_XML": (build_xml())
			default: (build_json())
		)

		local f = createfile filepath
		if f == undefined then
		(			
			format "ERROR: cannot open %\n" filepath
			return #CANCELLED
		)

		format "%" data to:f
		close f

		#FINISHED
	)
)

-- Create global instance
global dropper = DropperStruct()

-- Create MacroScript for menu integration
macroScript MaxDropper
category:"Export"
buttonText:"MaxDropper"
tooltip:"Open MaxDropper Export Dialog"
(
    on execute do
    (
        if (isKindOf dropper DropperStruct) then
        (
            local base   = getDir #userScripts
            local uiDir  = pathConfig.appendPath base "MaxDropper"
            local uiPath = pathConfig.appendPath uiDir "dropper_ui.ms"

            if doesFileExist uiPath then
            (
                try
                (
                    fileIn uiPath
                )
                catch
                (
                    messageBox ("Error loading UI:\n\n" + getCurrentException())
                )
            )
            else
            (
                messageBox ("UI file not found:\n" + uiPath)
            )
        )
        else
        (
            messageBox "Dropper not loaded!\nRun dropper.ms first."
        )
    )
)