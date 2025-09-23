/* 
    MaxDropper - 3ds Max Scene Exporter
    Version: 0.1.0
    Author: Kenneth Schuetz
    Description: Exports scene object data to JSON/XML format
*/

struct MaxDropperExporter (

    -- Build JSON string from scene objects
    fn buildSimpleJSON = (
        local json = "{\n"
        json += "  \"entities\": [\n"
    
        local firstObj = true
        for obj in objects do (
            -- Skip objects with ~[ in name (like Blender version)
            if findString obj.name "~[" == undefined then (
                if not firstObj then json += ",\n"

                json += "    {\n"
                json += "      \"name\": \"" + obj.name + "\",\n"
                json += "      \"position\": {\"x\": " + (obj.pos.x as string) + ", \"y\": " + (obj.pos.y as string) + ", \"z\": " + (obj.pos.z as string) + "},\n"

                -- Get rotation in degrees
                local rot = obj.rotation as EulerAngles
                json += "      \"rotation\": {\"x\": " + (rot.x as string) + ", \"y\": " + (rot.y as string) + ", \"z\": " + (rot.z as string) + "},\n"

                json += "      \"scale\": {\"x\": " + (obj.scale.x as string) + ", \"y\": " + (obj.scale.y as string) + ", \"z\": " + (obj.scale.z as string) + "},\n"
                
                -- Add is_mesh flag (check if object is geometry)
                local isMesh = (superClassOf obj == GeometryClass)
                json += "      \"is_mesh\": " + (isMesh as string)

                -- Add bounding box for mesh objects
                if isMesh then (
                    json += ",\n      \"bounds\": [\n"

                    -- Get bounding box corners (8 points)
                    local bmin = obj.min
                    local bmax = obj.max

                    -- Define 8 corners of bounding box
                    json += "        [" + (bmin.x as string) + ", " + (bmin.y as string) + ", " + (bmin.z as string) + "],\n"
                    json += "        [" + (bmax.x as string) + ", " + (bmin.y as string) + ", " + (bmin.z as string) + "],\n"
                    json += "        [" + (bmin.x as string) + ", " + (bmax.y as string) + ", " + (bmin.z as string) + "],\n"
                    json += "        [" + (bmax.x as string) + ", " + (bmax.y as string) + ", " + (bmin.z as string) + "],\n"
                    json += "        [" + (bmin.x as string) + ", " + (bmin.y as string) + ", " + (bmax.z as string) + "],\n"
                    json += "        [" + (bmax.x as string) + ", " + (bmin.y as string) + ", " + (bmax.z as string) + "],\n"
                    json += "        [" + (bmin.x as string) + ", " + (bmax.y as string) + ", " + (bmax.z as string) + "],\n"
                    json += "        [" + (bmax.x as string) + ", " + (bmax.y as string) + ", " + (bmax.z as string) + "]\n"
                    json += "      ]"
                )
                
                -- Add transformation matrix (4x4, row-major like Blender)
                json += ",\n      \"matrix\": [\n        "
                
                local tm = obj.transform
                local matrixVals = #()
                
                -- Extract matrix values in row-major order
                -- Row 1
                append matrixVals tm.row1.x
                append matrixVals tm.row1.y
                append matrixVals tm.row1.z
                append matrixVals 0.0
                -- Row 2
                append matrixVals tm.row2.x
                append matrixVals tm.row2.y
                append matrixVals tm.row2.z
                append matrixVals 0.0
                -- Row 3
                append matrixVals tm.row3.x
                append matrixVals tm.row3.y
                append matrixVals tm.row3.z
                append matrixVals 0.0
                -- Row 4 (translation)
                append matrixVals tm.row4.x
                append matrixVals tm.row4.y
                append matrixVals tm.row4.z
                append matrixVals 1.0
                
                -- Output matrix values
                for i = 1 to matrixVals.count do (
                    json += (matrixVals[i] as string)
                    if i < matrixVals.count then json += ", "
                    if mod i 4 == 0 and i < matrixVals.count then json += "\n        "
                )
                
                json += "\n      ]"
                
                -- Add custom properties
                local userProps = getUserPropBuffer obj
                if userProps != "" and userProps != undefined then (
                    -- Parse user properties (format: key=value, one per line)
                    local lines = filterString userProps "\r\n"
                    for line in lines do (
                        local equalPos = findString line "="
                        if equalPos != undefined then (
                            local key = substring line 1 (equalPos - 1)
                            local value = substring line (equalPos + 1) -1
                            
                            -- Trim spaces from key
                            key = trimLeft (trimRight key)
                            value = trimLeft (trimRight value)
                            
                            if key != "" then (
                                json += ",\n      \"" + key + "\": "
                                
                                -- Check if value is boolean
                                if value == "true" or value == "false" then (
                                    json += value
                                )
                                -- Check if value is number
                                else if (value as float) != undefined then (
                                    json += value
                                )
                                -- Otherwise treat as string
                                else (
                                    json += "\"" + value + "\""
                                )
                            )
                        )
                    )
                )
                
                json += "\n    }"

                firstObj = false
            )
        )

        json += "\n  ]\n"
        json += "}\n"

        return json
    ),

    -- Export JSON to file (internal)
    fn exportJSON filepath = (
        local jsonContent = buildSimpleJSON()

        -- Create/open file for writing
        local outFile = createFile filepath
        if outFile != undefined then (
            format "%" jsonContent to:outFile
            close outFile
            print ("Successfully exported to: " + filepath)
            return true
        ) else (
            print ("ERROR: Could not create file: " + filepath)
            return false
        )
    ),

    -- Public export function
    fn export filepath = (
        -- Ensure .json extension
        if (getFilenameType filepath) != ".json" then (
            filepath = filepath + ".json"
        )

        print ("MaxDropper: Exporting scene to " + filepath)
        local result = exportJSON filepath
        
        if result then (
            print "MaxDropper: Export Complete!"
        ) else (
            print "MaxDropper: Export Failed!"
        )

        return result
    ),

    -- Test function - export to temp directory
    fn testExport = (
        local tempPath = (GetDir #temp) + "\\maxdropper_test.json"
        print "--- Starting Export Test ---"
        export tempPath
        print "--- Export Test Complete ---"
    )
)

-- Create Instance
global maxDropper = MaxDropperExporter()

-- Example usage message
print "MaxDropper loaded! Usage:"
print "  maxDropper.export \"C:\\\\path\\\\to\\\\file.json\""
print "  maxDropper.testExport()"
