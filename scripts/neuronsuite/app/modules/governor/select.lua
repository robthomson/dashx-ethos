local function openPage(pidx, title, script)

    if neuronsuite.utils.apiVersionCompare(">=", "12.09") then
        -- load new menu with 3 pages
        neuronsuite.app.ui.openPage(pidx, title, "governor/governor.lua")        
    else
        -- load legacy single page rf2.2
        neuronsuite.app.ui.openPage(pidx, title, "governor/governor_legacy.lua")
    end

end

return {
    pages = nil, 
    openPage = openPage,
    event = nil,
    wakeup = nil,  
}