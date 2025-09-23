/* 
    MaxDropper - 3ds Max Scene Exporter
    Version: 1.1.0
    Author: Kenneth Schuetz
    Description: Exports scene object data to JSON/XML with OBJ model export
*/

/* 
    ===== Dropper (MaxScript 1:1 scaffold) ===== 
    Matches Blender counterpart name & call flow
*/

struct DropperStruct

(	
	export_models = true, 		-- UI will set this
	models_dir 	  = undefined, 	-- UI will set this (folder) or leave undefined

	/*
	    model_export() - OBJ export implementation
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

		local uniqueNames = #()
		local exportedCount = 0

		for obj in objects do
		(
			if superClassOf obj ==  GeometryClass do
			(
				-- de-dup base name up to first '.'
				local baseName = obj.name
				local dotPos = findString baseName "."
				if dotPos != undefined do baseName = substring baseName 1 (dotPos - 1)
				baseName = trimRight baseName

				if findItem uniqueNames baseName == 0 do
				(
					append uniqueNames baseName
					select obj
					local savedTM = obj.transform
					obj.transform = matrix3 1

					-- No trailing space after .obj
					local objFile = exportDir + "\\" + baseName + ".obj"
					format "Exporting OBJ: %  ->  %\n" obj.name objFile
					try (
						exportFile objFile #noPrompt selectedOnly:true using:ObjExp
					) catch (
						exportFile objFile #noPrompt selectedOnly:true
					)
					exportedCount += 1

					obj.transform = savedTM
					clearSelection()
				)
			)
		)

		format "OBJ export summary: % file(s) written)\n" exportedCount
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
			local p = ( getVert msh v )* invTM -- world -> object
			if p.x < bmin.x then
				bmin.x = p.x
			if p.y < bmin.y then
				bmin.y = p.y
			if p.z < bmin.z then
				bmin.z = p.z
			if p.x > bmax.x then
				bmax.x = p.x
			if p.y > bmax.y then
				bmax.y = p.y
			if p.z > bmax.z then
				bmax.z = p.z
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
		-- Just output the matrix as-is in row-major order
		#(			
			tm.row1.x, -tm.row1.z, tm.row1.y,  0.0,
			tm.row2.x, -tm.row2.z, tm.row2.y,  0.0,
			tm.row3.x, -tm.row3.z, tm.row3.y,  0.0,
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
				local key = trimRight( trimLeft( substring line 1( eq - 1 ) ) )

				-- Different approach: skip the equals and any spaces after it
				local valStart = eq + 1

				-- Skip any leading spaces after the equals
				while
					valStart <= line.count and( line[valStart] == " " or line[valStart] == "\t" ) do
					valStart += 1

				-- Now get everything from valStart to the end
				local val = ""
				if valStart <= line.count then
					val = substring line valStart( line.count - valStart + 1 )
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
			if( findString obj.name "~[" )== undefined do
			(				
				if not first then
					json += ",\n"
				json += "    {\n"
				local isMesh = ( superClassOf obj == GeometryClass )

				-- 1) bounds first (if mesh)
				if isMesh do
				(					
					local cs = objectSpaceBoundsCorners obj
					json += "      \"bounds\": [\n"
					for i = 1 to cs.count do
					(						
						local c = cs[i]
						json += "        [" +( c.x as string )+ ", " +( c.y as string )+ ", " +( c.z as string )+ "]"
						if i < cs.count then
							json += ","
						json += "\n"
					)
					json += "      ],\n"
				)

				-- 2) is_mesh
				json += "      \"is_mesh\": " +( isMesh as string )+ ",\n"

				-- 3) matrix
				local m = blenderCompatMatrixFromTM obj.transform
				json += "      \"matrix\": [\n        "
				for i = 1 to m.count do
				(					
					json +=( m[i] as string )
					if i < m.count then
						json += ", "
					if( mod i 4 == 0 ) and i < m.count then
						json += "\n        "
				)
				json += "\n      ],\n"

				-- 4) name
				json += "      \"name\": \"" + obj.name + "\""
				
				-- 5) custom properties last (matching Blender lines 86-91)
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
			if( findString obj.name "~[" )== undefined do
			(				
				xml += "    <entity>\n"
				xml += "        <name>" + obj.name + "</name>\n"

				-- Position
				xml += "        <position x=\"" +( obj.pos.x as string )
				xml += "\" y=\"" +( obj.pos.y as string )
				xml += "\" z=\"" +( obj.pos.z as string )+ "\"/>\n"

				-- Rotation (convert to Euler)
				local euler = quatToEuler obj.rotation
				xml += "        <rotation x=\"" +( euler.x as string )
				xml += "\" y=\"" +( euler.y as string )
				xml += "\" z=\"" +( euler.z as string )+ "\"/>\n"

				-- Scale
				xml += "        <scale x=\"" +( obj.scale.x as string )
				xml += "\" y=\"" +( obj.scale.y as string )
				xml += "\" z=\"" +( obj.scale.z as string )+ "\"/>\n"
				
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
							local key = trimRight( trimLeft( substring line 1( eq - 1 ) ) )
							local val = substring line( eq + 1 )( line.count - eq )
							val = trimRight( trimLeft val )
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

		-- ensure the folder exists (prevents createFile from failing silently)
		local outDir = getFilenamePath filepath
		if outDir != undefined and outDir != "" do
		(
			if not doesDirectoryExist outDir do makeDir outDir
		)

		-- normalize the format to a string
		local fmt = if( classof formatVal == String ) then
			formatVal
		else( formatVal as String )

		-- route like Blender (OPT_JSON -> build_json, OPT_XML -> build_xml)
		local data =
		case fmt of
		(			
			"OPT_JSON":( build_json() )
			"OPT_XML":( build_xml() )
			default:( build_json() )
		)

		local f = createfile filepath
		if f == undefined then
		(			
			format "ERROR: cannot open %\n" filepath
			return #CANCELLED
		)

		format "%" data to: f
		close f

		#FINISHED
	)
)

-- Create global instance
global dropper = DropperStruct()

-- Create MacroScript for menu integration (no 'quiet:' to avoid parser issues)
macroScript MaxDropper
category:"Export"
buttonText:"MaxDropper"
tooltip:"Open MaxDropper Export Dialog"
(
    on execute do
    (
        -- Avoid '::' to keep editors/parsers happy
        if (isKindOf dropper DropperStruct) then
        (
            local base   = getDir #userScripts
            local uiDir  = pathConfig.appendPath base "MaxDropper"
            local uiPath = pathConfig.appendPath uiDir "dropper_ui.ms"

            if doesFileExist uiPath then
            (
                try
                (
                    fileIn uiPath  -- no quiet:, fewer false positives
                    -- The UI file should show its dialog when it loads
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
