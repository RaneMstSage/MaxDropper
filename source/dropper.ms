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

                json += "      \"scale\": {\"x\": " + (obj.scale.x as string) + ", \"y\": " + (obj.scale.y as string) + ", \"z\": " + (obj.scale.z as string) + "}\n"
                json += "    }"

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
