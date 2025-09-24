/*
    MaxDropper UI - User Interface for MaxDropper
    Version: 1.2.0
    Author: Kenneth Schuetz
    Description: UI dialog for MaxDropper export functionality with scale control
*/

-- UI Dialog for MaxDropper
rollout MaxDropperDialog "MaxDropper Export" width:360 height:460
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

    -- OBJ Export
    group "OBJ Export"
    (
        checkbox chk_exportObjs       "Export OBJ Models" checked:true
        checkbox chk_customModelsPath "Use custom models folder" checked:false

        label    lbl_models "Models Folder:" align:#left enabled:false
        edittext txt_models "" width:250 align:#left enabled:false
        button   btn_browse_models "Browse..." width:70 align:#right offset:[0,-24] enabled:false
        
        -- Scale control
        label    lbl_scale "Export Scale:" align:#left
        spinner  spn_scale "" range:[0.001, 1000.0, 10.0] type:#float scale:0.01 fieldwidth:60 align:#left
        dropdownlist ddl_presets "" items:#(
            "Custom",
            "1.0 (No scaling)",
            "10.0 (Current project)",
            "100.0 (m to cm)",
            "0.01 (cm to m)",
            "0.0254 (inches to m)",
            "39.3701 (m to inches)"
        ) width:150 align:#right offset:[0,-24]
        label lbl_scale_hint "Scales OBJ vertices during export" align:#left offset:[0,-5]
    )
    
    -- Status
    group "Status"
    (
        label       lbl_status "Ready to export" align:#left
        progressbar pb_progress value:0 height:10
    )
    
    -- Buttons
    button btn_export "Export Scene" width:160 height:35 pos:[10,415]
    button btn_close  "Close"        width:160 height:35 pos:[180,415]
    
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
        -- enable/disable OBJ-related controls
        chk_customModelsPath.enabled = state
        lbl_scale.enabled = state
        spn_scale.enabled = state
        ddl_presets.enabled = state
        lbl_scale_hint.enabled = state

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
    
    on ddl_presets selected idx do
    (
        case idx of
        (
            1: () -- Custom - don't change spinner
            2: spn_scale.value = 1.0      -- No scaling
            3: spn_scale.value = 10.0     -- Current project
            4: spn_scale.value = 100.0    -- m to cm
            5: spn_scale.value = 0.01     -- cm to m
            6: spn_scale.value = 0.0254   -- inches to m
            7: spn_scale.value = 39.3701  -- m to inches
        )
    )
    
    on spn_scale changed val do
    (
        -- When spinner changes, set dropdown to "Custom" unless it matches a preset
        local presetIdx = case val of
        (
            1.0:     2
            10.0:    3
            100.0:   4
            0.01:    5
            0.0254:  6
            39.3701: 7
            default: 1
        )
        ddl_presets.selection = presetIdx
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

        -- Wire UI → struct
        dropper.export_models = chk_exportObjs.checked
        dropper.models_dir    = if (chk_exportObjs.checked and chk_customModelsPath.checked) then txt_models.text else undefined
        dropper.export_scale  = spn_scale.value  -- Set the scale value
        
        -- Report scale setting
        if chk_exportObjs.checked then
            format "Export scale set to: %\n" spn_scale.value

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
            if chk_exportObjs.checked then
                print ("OBJ models exported with scale: " + (spn_scale.value as string))
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
        else
        (
            -- Set spinner to current dropper scale value
            spn_scale.value = dropper.export_scale
        )

        -- sync OBJ path controls with initial checkbox states
        chk_customModelsPath.enabled = chk_exportObjs.checked
        lbl_scale.enabled = chk_exportObjs.checked
        spn_scale.enabled = chk_exportObjs.checked
        ddl_presets.enabled = chk_exportObjs.checked
        lbl_scale_hint.enabled = chk_exportObjs.checked
        lbl_models.enabled           = false
        txt_models.enabled           = false
        btn_browse_models.enabled    = false
        
        -- Set initial dropdown selection based on scale value
        local presetIdx = case spn_scale.value of
        (
            1.0:     2
            10.0:    3
            100.0:   4
            0.01:    5
            0.0254:  6
            39.3701: 7
            default: 1
        )
        ddl_presets.selection = presetIdx
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
print "Scale control added for OBJ export"