/*
    MaxDropper UI - User Interface for MaxDropper
    Version: 1.1.0
    Author: Kenneth Schuetz
    Description: UI dialog for MaxDropper export functionality with working custom models path
*/

-- UI Dialog for MaxDropper
rollout MaxDropperDialog "MaxDropper Export" width:360 height:400
(
    -- Export Format
    group "Export Format"
    (
        radioButtons rdo_format "Format:" labels:#("JSON", "XML") default:1 columns:2
    )
    
    -- Export Paths (JSON/XML)
    group "Export Paths"
    (
        label    lbl_export "Export Path:" align:#left
        edittext txt_path   "" width:250 align:#left
        button   btn_browse "Browse..." width:70 align:#right offset:[0,-24]
    )

    -- OBJ Export (these controls were missing in your script)
    group "OBJ Export"
    (
        checkbox chk_exportObjs       "Export OBJ Models" checked:true
        checkbox chk_customModelsPath "Use custom models folder" checked:false

        label    lbl_models "Models Folder:" align:#left enabled:false
        edittext txt_models "" width:250 align:#left enabled:false
        button   btn_browse_models "Browse..." width:70 align:#right offset:[0,-24] enabled:false
    )
    
    -- Status
    group "Status"
    (
        label       lbl_status "Ready to export" align:#left
        progressbar pb_progress value:0 height:10
    )
    
    -- Buttons
    button btn_export "Export Scene" width:160 height:35 pos:[10,355]
    button btn_close  "Close"        width:160 height:35 pos:[180,355]
    
    -- Events
    on rdo_format changed state do
    (
        if txt_path.text != "" then
        (
            local basePath = getFilenamePath txt_path.text + getFilenameFile txt_path.text
            local ext = if state == 1 then ".json" else ".xml"
            txt_path.text = basePath + ext
        )
    )
    
    on btn_browse pressed do
    (
        local ext     = if rdo_format.state == 1 then "json" else "xml"
        local typeStr = if rdo_format.state == 1 then "JSON files (*.json)|*.json" else "XML files (*.xml)|*.xml"
        local filename = getSaveFileName caption:"Save MaxDropper Export" filename:("scene_export." + ext) types:typeStr
        if filename != undefined do txt_path.text = filename
    )
    
    on chk_exportObjs changed state do
    (
        -- enable/disable custom path controls together
        chk_customModelsPath.enabled = state

        local en = state and chk_customModelsPath.checked
        lbl_models.enabled        = en
        txt_models.enabled        = en
        btn_browse_models.enabled = en

        if not state then
        (
            chk_customModelsPath.checked = false
            txt_models.text = ""
        )
    )

    on chk_customModelsPath changed state do
    (
        lbl_models.enabled        = state
        txt_models.enabled        = state
        btn_browse_models.enabled = state
        if not state do txt_models.text = ""
    )
    
    on btn_browse_models pressed do
    (
        local folderPath = getSavePath caption:"Select Models Export Folder"
        if folderPath != undefined do txt_models.text = folderPath
    )
    
    on btn_export pressed do
    (
        lbl_status.text   = "Exporting..."
        pb_progress.value = 30

        if dropper == undefined then
        (
            messageBox "Dropper not loaded! Please run dropper.ms first."
            pb_progress.value = 0
            lbl_status.text   = "Error: Dropper not loaded"
            return()
        )

        -- Resolve / confirm output path
        local ext     = if rdo_format.state == 1 then "json" else "xml"
        local typeStr = if rdo_format.state == 1 then "JSON files (*.json)|*.json" else "XML files (*.xml)|*.xml"
        local p       = txt_path.text

        if (p == "") then
        (
            -- Only prompt IF empty
            local picked = getSaveFileName caption:"Save MaxDropper Export" filename:("scene_export." + ext) types:typeStr
            if picked == undefined then
            (
                lbl_status.text   = "Export cancelled"
                pb_progress.value = 0
                return()
            )
            p = picked
        )
        else
        (
            -- Normalize / optionally change extension to current format
            local curExt = toLower (getFilenameType p) -- includes leading dot (".json")
            if (curExt == "") then
            (
                p = p + "." + ext
            )
            else if (curExt != ("." + ext)) then
            (
                local want = (getFilenamePath p) + (getFilenameFile p) + "." + ext
                local ok = queryBox ("Change extension to ." + ext + "?\n\n" + p + "\n  →  " + want) title:"Confirm Extension"
                if ok then p = want
            )
        )

        -- Confirm overwrite if file exists
        if doesFileExist p then
        (
            local overwrite = queryBox ("File exists:\n" + p + "\n\nOverwrite?") title:"Confirm Overwrite"
            if not overwrite then
            (
                lbl_status.text   = "Export cancelled"
                pb_progress.value = 0
                return()
            )
        )

        -- Reflect final path in UI
        txt_path.text = p

        -- Wire UI → struct (don’t call model_export directly)
        dropper.export_models = chk_exportObjs.checked
        dropper.models_dir    = if (chk_exportObjs.checked and chk_customModelsPath.checked) then txt_models.text else undefined

        -- Figure format and export
        local fmt = if rdo_format.state == 1 then "OPT_JSON" else "OPT_XML"

        local result = undefined
        try ( result = dropper.write_data undefined p fmt ) catch
        (
            print "Error during export"
            result = #ERROR
        )

        if result == #FINISHED then
        (
            pb_progress.value = 100
            lbl_status.text   = "Export complete!"
            print ("MaxDropper export completed: " + p)
        )
        else
        (
            pb_progress.value = 0
            lbl_status.text   = "Export failed!"
            print "MaxDropper export failed"
        )
    )
    
    on btn_close pressed do destroyDialog MaxDropperDialog
    
    -- Initialize UI state
    on MaxDropperDialog open do
    (
        -- No default path: user must choose each time
        txt_path.text = ""

        if dropper == undefined then
            lbl_status.text = "Warning: Dropper not loaded"

        -- sync OBJ path controls with initial checkbox states
        chk_customModelsPath.enabled = chk_exportObjs.checked
        lbl_models.enabled           = false
        txt_models.enabled           = false
        btn_browse_models.enabled    = false
    )
)


-- Function to show the UI
fn ShowMaxDropperUI = (
    -- Check if dialog already exists and destroy it
    try (destroyDialog MaxDropperDialog) catch ()
    
    -- Create new dialog
    createDialog MaxDropperDialog
    
    -- Check if dropper exists and warn if not
    if dropper == undefined then (
        messageBox "Warning: Dropper not loaded!\nPlease run dropper.ms first for full functionality." title:"MaxDropper UI"
    )
)

-- Create MacroScript for menu integration
macroScript MaxDropperUI 
    category:"Export" 
    buttonText:"MaxDropper UI" 
    tooltip:"Open MaxDropper Export Dialog" 
(
    on execute do (
        ShowMaxDropperUI()
    )
)

-- Auto-show UI when script is run
ShowMaxDropperUI()

-- Usage message
print "MaxDropper UI loaded!"
print "Use ShowMaxDropperUI() to open the dialog"
print "Custom models path functionality enabled"