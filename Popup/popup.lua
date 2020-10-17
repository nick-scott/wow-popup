Popup_Frame = CreateFrame("Frame", nil, Popup_Frame, BackdropTemplateMixin and "BackdropTemplate")
Popup_Frame:SetPoint("CENTER", relativeRegion, "CENTER", 0, 84)
Popup_Frame:SetBackdrop({
    edgeFile = "Interface\\Tooltips\\ChatBubble-Backdrop",
    edgeSize = 32
})

Popup_FrameText = Popup_Frame:CreateFontString("Popup_FrameText")

local debugOn = false
local default_popupDuration = 3

for eventName, vars in pairs(eventMap) do
    if (vars[1]) then
        Popup_Frame:RegisterEvent(eventName)
    end
end



Popup_Frame:SetScript("OnEvent",
    function(self, eventType, message, sender, language, var5, var6, var7, channelNumber, var9, ...)
        HandleMessageRecieved(eventType, message, sender, channelNumber)
    end)

function HandleMessageRecieved(eventType, message, sender, channelNumber)
    if (debugOn) then
        ChatFrame1:AddMessage('eventType: [' .. eventType ..
                '] message: [' .. message ..
                '] sender: [' .. sender ..
                '] channelNumber: [' .. channelNumber ..
                ']')
    end
    local playerName, realmName = UnitFullName("player")
    local formattedName = playerName .. '-' .. realmName
    if shouldSendMessage(eventType, message, sender, formattedName, channelNumber) then
        sender = formatSender(sender)
        local eventString = eventMap[eventType]
        local channelString = formatChannel(eventType, channelNumber)
        --        MOD_TextMessage(message)
        popup('[' .. channelString .. '] ' .. sender .. message,
            popupDuration(message),
            eventString[4],
            eventString[5],
            eventString[6]) -- The RGB values
    end
end

function formatChannel(eventType, channelNumber)
    if (eventType == 'CHAT_MSG_CHANNEL') then
        return channelNumber
    end
    return eventMap[eventType][3] -- Shorthand
end

function formatSender(sender)
    if (sender == nil) then
        return ''
    end
    if (contains(sender, "-")) then
        return '[' .. string.sub(sender, 0, string.find(sender, "-") - 1) .. ']: '
    end
    if (string.len(sender) > 1) then
        return '[' .. sender .. ']: '
    end
    return ''
end

function popupDuration(message)
    local averageWpm = 150
    local _, count = string.gsub(message, " ", "")
    local duration = math.floor(count / (averageWpm / 60))
    if (duration < default_popupDuration) then
        return default_popupDuration
    end
    return duration
end

function popup(text, duration, r, g, b, ...)
    if Popup_Frame.anim then
        Popup_Frame.anim:Stop()
    else
        Popup_Frame.anim = Popup_Frame:CreateAnimationGroup()
        Popup_Frame.anim:SetScript("OnFinished", function() Popup_FrameText:Hide() end)

        local fade1 = Popup_Frame.anim:CreateAnimation("Alpha")
        fade1:SetDuration(1)
        fade1:SetToAlpha(1)
        fade1:SetEndDelay(duration)
        fade1:SetOrder(1)

        local fade2 = Popup_Frame.anim:CreateAnimation("Alpha")
        fade2:SetDuration(10)
        fade2:SetToAlpha(0)
        fade2:SetOrder(2)
    end

    if (r > 1 or g > 1 or b > 1) then
        r = r / 255
        g = g / 255
        b = b / 255
    end
    --    PlaySoundFile("Interface\\AddOns\\Popup\\popup.ogg", "Master")
    local font, _, style = ChatFrame1:GetFont()
    local _, fontsize = GameFontNormal:GetFont()
    Popup_FrameText:SetFont(font, fontsize, style)
    Popup_FrameText:SetNonSpaceWrap(false)

    Popup_FrameText:SetTextColor(r, g, b)
    Popup_FrameText:SetText(text)
    Popup_Frame:SetWidth(math.min(math.max(64, Popup_FrameText:GetStringWidth() + 20), 520))
    Popup_Frame:SetHeight(64)
    Popup_Frame:SetBackdropBorderColor(r, g, b)

    Popup_FrameText:ClearAllPoints()
    Popup_FrameText:SetPoint("TOPLEFT", Popup_Frame, "TOPLEFT", 10, 10)
    Popup_FrameText:SetPoint("BOTTOMRIGHT", Popup_Frame, "BOTTOMRIGHT", -10, -10)
    Popup_FrameText:Show()

    Popup_Frame:SetAlpha(0)
    Popup_Frame:Show()
    Popup_Frame.anim:Play()
end


function messageWhitelistedForGlobalEvent(eventType, message)
    local db = PopupAddon:getDB()
    if (db.global.whitelist['GLOBAL'] ~= nil) then
        for _, phrase in pairs(db.global.whitelist['GLOBAL']) do
            if (contains(message, phrase) and eventType ~= 'CHAT_MSG_SYSTEM') then
                PlaySoundFile("Interface\\AddOns\\Popup\\Resources\\popup.ogg", "Master")
                return true
            end
        end
        return false
    end
    return true
end

function messageWhitelistedForEvent(eventType, message)
    local db = PopupAddon:getDB()
    if (db.global.whitelist[eventType] ~= nil) then
        for _, phrase in pairs(db.global.whitelist[eventType]) do
            if (contains(message, phrase)) then
                return true
            end
            return false
        end
    end
    return db.global.whitelist[eventType] == nil
end


function messageBlacklistedForEvent(eventType, message)
    local db = PopupAddon:getDB()
    if (db.global.blacklist[eventType] ~= nil) then
        for _, phrase in pairs(db.global.blacklist[eventType]) do
            if (contains(message, phrase)) then
                return true
            end
            return false
        end
    end
    return false
end

function shouldSendMessage(eventType, message, sender, formattedName, channelNumber)
    local db = PopupAddon:getDB()
    local channelKey = eventType
    if (eventType == "CHAT_MSG_CHANNEL") then
        channelKey = "" .. channelNumber
    end
    if ((formattedName ~= sender or debugOn) and db.global.enabledChannels[channelKey]) then
        if messageWhitelistedForGlobalEvent(channelKey, message)
                or messageWhitelistedForEvent(channelKey, message) then
            return not messageBlacklistedForEvent(channelKey, message)
        end
    end
    return false
end