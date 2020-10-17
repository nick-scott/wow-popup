local configShown = false
local scroll = nil

function ToggleConfig()
    if not configShown then
        configShown = true
        local ConfigFrame = PopupGUI:Create("Frame")
        ConfigFrame:SetTitle("Popup Config")
        ConfigFrame:SetStatusText(nil)
        --ConfigFrame:SetCallback("OnClose", HandleOnClose)
        ConfigFrame:SetCallback("OnClose", function(widget) HandleOnClose(widget) end)
        ConfigFrame:SetLayout("Fill")

        local tabs = PopupGUI:Create("TabGroup")
        tabs:SetLayout("Flow")
        tabs:SetTabs({
            { value = "whitelist", text = "Whitelist" },
            { value = "blacklist", text = "Blacklist" },
            { value = "config", text = "Config" },
            { value = "test", text = "Test" },
        })
        tabs:SetCallback("OnGroupSelected", SelectGroup)
        tabs:SelectTab("config")
        ConfigFrame:AddChild(tabs)
    end
end

function SelectGroup(container, event, group)
    container:ReleaseChildren()
    local db = PopupAddon:getDB()
    local scrollcontainer = PopupGUI:Create("SimpleGroup") -- "InlineGroup" is also good
    scrollcontainer:SetFullWidth(true)
    scrollcontainer:SetFullHeight(true) -- probably?
    scrollcontainer:SetLayout("Fill") -- important!

    scroll = PopupGUI:Create("ScrollFrame")
    scroll:SetLayout("Flow") -- probably?
    scrollcontainer:AddChild(scroll)
    if group == "config" then
        DrawConfigContainer(scroll)
    elseif group == "whitelist" then
        DrawPhrasesContainer(db.global.whitelist)
    elseif group == "blacklist" then
        DrawPhrasesContainer(db.global.blacklist)
    elseif group == "test" then
        DrawTestContainer(scroll)
    end
    container:AddChild(scrollcontainer)
end


function DrawConfigContainer(container)
    local header = PopupGUI:Create("Heading")
    header:SetText("Channels to monitor")
    header:SetFullWidth(true)
    container:AddChild(header)
    addChannelSelectCheckbox(container, "1", "General (1)")
    addChannelSelectCheckbox(container, "2", "Trade (2)")
    addChannelSelectCheckbox(container, "22", "Local Defense (3)")
    for eventName, vars in pairs(eventMap) do
        if (not contains(eventName, "inform") and not contains(eventName, "channel")) then
            addChannelSelectCheckbox(container, eventName, vars[2] .. " (" .. vars[3] .. ")")
        end
    end
end

function DrawWhitelistContainer(container)
    container:ReleaseChildren()
    local db = PopupAddon:getDB()
    local header = PopupGUI:Create("Heading")
    local selectedChannel = "GLOBAL"
    header:SetText("Adding a whitelisted phase suppresses other popups for that channel")
    header:SetFullWidth(true)
    container:AddChild(header)

    createChannelDropdown(container, function(value) selectedChannel = value end)

    local messageBox = PopupGUI:Create("EditBox")
    messageBox:SetLabel("Message")
    messageBox:SetWidth(200)
    container:AddChild(messageBox)

    local button = PopupGUI:Create("Button")
    button:SetText("Add")
    button:SetWidth(100)
    button:SetCallback("OnClick", function(button)
        addWhitelistedPhrase(selectedChannel, messageBox:GetText())
        DrawWhitelistContainer(container)
    end)
    container:AddChild(button)

    local header = PopupGUI:Create("Heading")
    header:SetText("Click to remove phrase")
    header:SetFullWidth(true)
    container:AddChild(header)

    for channel, values in pairs(db.global.whitelist) do
        addWhitelistSection(container, channel, values)
    end
end

function DrawPhrasesContainer(phraseListDB)
    scroll:ReleaseChildren()
    local db = phraseListDB
    local selectedChannel = "GLOBAL"
    createChannelDropdown(scroll, function(value) selectedChannel = value end)

    local messageBox = PopupGUI:Create("EditBox")
    messageBox:SetLabel("Message")
    messageBox:SetWidth(200)
    scroll:AddChild(messageBox)

    local button = PopupGUI:Create("Button")
    button:SetText("Add")
    button:SetWidth(100)
    button:SetCallback("OnClick", function(button)
        addPhrase(selectedChannel, messageBox:GetText(), db)
        DrawPhrasesContainer(db)
    end)
    scroll:AddChild(button)

    local header = PopupGUI:Create("Heading")
    header:SetText("Click to remove phrase")
    header:SetFullWidth(true)
    scroll:AddChild(header)

    if (phraseListDB ~= nil) then
        for channel, values in pairs(db) do
            addPhraseSection(scroll, channel, values, db)
        end
    end
end

function DrawBlacklistContainer(container) end

function DrawTestContainer(container)
    local eventDropdown = PopupGUI:Create("Dropdown")
    for eventName, vars in pairs(eventMap) do
        eventDropdown:AddItem(eventName, eventName)
    end
    eventDropdown:SetValue("CHAT_MSG_CHANNEL")
    eventDropdown:SetLabel("Event")
    container:AddChild(eventDropdown)

    local channelDropdown = PopupGUI:Create("Dropdown")
    channelDropdown:SetLabel("Channel #")
    channelDropdown:AddItem(1, 1)
    channelDropdown:AddItem(2, 2)
    channelDropdown:AddItem(22, 22)
    channelDropdown:SetValue(1)
    container:AddChild(channelDropdown)

    local messageBox = PopupGUI:Create("EditBox")
    messageBox:SetLabel("Message")
    messageBox:SetWidth(200)
    container:AddChild(messageBox)

    local button = PopupGUI:Create("Button")
    button:SetText("Test")
    button:SetWidth(200)
    button:SetCallback("OnClick", function(button)
        HandleMessageRecieved(eventDropdown:GetValue(), messageBox:GetText(), "Test", channelDropdown:GetValue())
    end)
    container:AddChild(button)
end

function createChannelDropdown(container, onChangeCallback)
    local eventDropdown = PopupGUI:Create("Dropdown")
    eventDropdown:AddItem("GLOBAL", "GLOBAL")
    eventDropdown:AddItem("1", "General (1)")
    eventDropdown:AddItem("2", "Trade (2)")
    eventDropdown:AddItem("22", "Local Defence (3)")
    for eventName, vars in pairs(eventMap) do
        if eventName ~= "CHAT_MSG_CHANNEL" and not contains(eventName, "inform") then
            eventDropdown:AddItem(eventName, vars[2])
        end
    end
    eventDropdown:SetValue("GLOBAL")
    eventDropdown:SetLabel("Event")
    eventDropdown:SetCallback("OnValueChanged",
        function(event)
            onChangeCallback(event:GetValue())
        end)

    container:AddChild(eventDropdown)
end

function HandleOnClose(widget)
    PopupGUI:Release(widget)
    configShown = false
end


function addPhrase(channel, phrase, phraseDB)
    if not phraseDB[channel] then
        phraseDB[channel] = {}
    end
    phraseDB[channel][#phraseDB[channel] + 1] = phrase
end

function removePhrase(channel, key, phraseDB)
    if phraseDB[channel] then
        phraseDB[channel][key] = nil
        if (#phraseDB[channel] == 0) then
            phraseDB[channel] = nil
        end
    end
end

function addPhraseSection(container, channel, values, phraseDB)
    if (#values > 0) then
        local header = PopupGUI:Create("InlineGroup")
        if channel == "GLOBAL" then
            header:SetTitle("GLOBAL (sound on match)")
        elseif channel == "1" then
            header:SetTitle("General")
        elseif channel == "2" then
            header:SetTitle("Trade")
        elseif channel == "22" then
            header:SetTitle("Local Defense")
        else
            header:SetTitle(eventMap[channel][2])
        end
        header:SetFullWidth(true)
        container:AddChild(header)
        for key, subValues in pairs(values) do
            local label = PopupGUI:Create("InteractiveLabel")
            label:SetText(subValues)
            label:SetCallback("OnEnter", function() label:SetColor(255, 0, 0) end)
            label:SetCallback("OnLeave", function() label:SetColor(255, 255, 255) end)
            label:SetCallback("OnClick", function(button)
                removePhrase(channel, key, phraseDB)
                DrawPhrasesContainer(phraseDB)
            end)
            header:AddChild(label)
        end
    end
end

function addChannelSelectCheckbox(container, key, label)
    local checkbox = PopupGUI:Create("CheckBox")
    local db = PopupAddon:getDB()
    checkbox:SetLabel(label)
    if not db.global.enabledChannels then
        db.global.enabledChannels = {}
    end
    if (db.global.enabledChannels[key] or db.global.enabledChannels[key] == nil) then
        db.global.enabledChannels[key] = true
        checkbox:SetValue(true)
    end
    checkbox:SetCallback("OnValueChanged", function(checkbox)
        db.global.enabledChannels[key] = checkbox:GetValue()
    end)
    container:AddChild(checkbox)
end




