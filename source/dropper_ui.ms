/*
    MaxDropper UI - User Interface for MaxDropper
    Version: 1.0.0
    Author: Kenneth Schuetz
    Description: UI dialog for MaxDropper export functionality
*/

-- UI Dialog for MaxDropper
rollout MaxDropperDialog "MaxDropper Export" width:350 height:280 (
    -- UI Controls
    group "Export Paths" (
        label lbl_json "JSON Export Path:" align:#left
        edittext txt_path "" width:250 align:#left
        button btn_browse "Browse..." width:70 align:#right offset:[0,-24]
        
        checkbox chk_customModelsPath "Use Custom Models Path" checked:false
        label lbl_models "Models Folder:" align:#left enabled:false
        edittext txt_models "" width:250 align:#left enabled:false
        button btn_browse_models "Browse..." width:70 align:#right offset:[0,-24] enabled:false
    )
    
    group "Export Options" (
        checkbox chk_exportObjs "Export OBJ Models" checked:true
    )
    
    group "Status" (
        label lbl_status "Ready to export" align:#left
        progressbar pb_progress value:0 height:10
    )
    
    -- Buttons
    button btn_export "Export Scene" width:160 height:35 pos:[10,235]
    button btn_close "Close" width:160 height:35 pos:[180,235]
    
    -- Events
    on btn_browse pressed do (
        local filename = getSaveFileName caption:"Save MaxDropper Export" \
            filename:"scene_export.json" \
            types:"JSON files (*.json)|*.json"
        
        if filename != undefined then (
            txt_path.text = filename
            -- Remove .json if present since export function adds it
            if (getFilenameType filename) == ".json" then (
                txt_path.text = getFilenamePath filename + getFilenameFile filename
            )
        )
    )
    
    on chk_customModelsPath changed state do (
        lbl_models.enabled = state
        txt_models.enabled = state
        btn_browse_models.enabled = state
        if not state then (
            txt_models.text = ""
        )
    )
    
    on btn_browse_models pressed do (
        local folderPath = getSavePath caption:"Select Models Export Folder"
        if folderPath != undefined then (
            txt_models.text = folderPath
        )
    )
    
    on chk_exportObjs changed state do (
        if not state then (
            chk_customModelsPath.checked = false
            chk_customModelsPath.enabled = false
        ) else (
            chk_customModelsPath.enabled = true
        )
    )
    
    on btn_export pressed do (
        if txt_path.text != "" then (
            lbl_status.text = "Exporting JSON..."
            pb_progress.value = 30
            
            -- Call the export function
            if maxDropper != undefined then (
                local result = false
                
                if chk_customModelsPath.checked and txt_models.text != "" then (
                    -- Store the custom path in a global variable
                    global maxDropperCustomModelsPath = txt_models.text
                )
                
                result = maxDropper.export txt_path.text exportObjs:chk_exportObjs.checked
                
                if result then (
                    pb_progress.value = 100
                    lbl_status.text = "Export complete!"
                ) else (
                    pb_progress.value = 0
                    lbl_status.text = "Export failed!"
                )
            ) else (
                messageBox "MaxDropper not loaded! Please run dropper.ms first."
                pb_progress.value = 0
                lbl_status.text = "Error: MaxDropper not loaded"
            )
        ) else (
            messageBox "Please select an export path first"
        )
    )
    
    on btn_close pressed do (
        destroyDialog MaxDropperDialog
    )
)

-- Function to show the UI
fn ShowMaxDropperUI = (
    -- Check if maxDropper exists
    if maxDropper != undefined then (
        createDialog MaxDropperDialog
    ) else (
        -- Try to load it
        local dropperPath = (getDir #userScripts) + "\\MaxDropper\\dropper.ms"
        if doesFileExist dropperPath then (
            fileIn dropperPath
            if maxDropper != undefined then (
                createDialog MaxDropperDialog
            ) else (
                messageBox "Failed to load MaxDropper!"
            )
        ) else (
            messageBox "MaxDropper not found at: " + dropperPath
        )
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
