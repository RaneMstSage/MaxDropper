-- MaxDropper Startup Loader
(
    -- Load dropper.ms only
    local dropperPath = (getDir #userScripts) + "\\MaxDropper\\dropper.ms"
    if doesFileExist dropperPath then (
        fileIn dropperPath
        if ::dropper != undefined then (
            print "MaxDropper loaded at startup"
        )
    )
)