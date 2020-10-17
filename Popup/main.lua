eventMap = {
    CHAT_MSG_CHANNEL = { true, "Channel", "C", 195, 230, 232 },
    CHAT_MSG_SAY = { true, "Say", "S", 255, 255, 255 },
    CHAT_MSG_GUILD = { true, "Guild", "G", 64, 255, 64 },
    CHAT_MSG_WHISPER = { true, "Whisper", "W", 255, 128, 255 },
    CHAT_MSG_WHISPER_INFORM = { true, "Whisper", "W", 0, 255, 246 },
    CHAT_MSG_YELL = { true, "Yell", "Y", 255, 64, 64 },
    CHAT_MSG_PARTY = { true, "Party", "P", 170, 170, 255 },
    CHAT_MSG_PARTY_LEADER = { true, "Party Leader", "PL", 118, 200, 255 },
    CHAT_MSG_OFFICER = { true, "Officer", "O", 64, 192, 64 },
    CHAT_MSG_RAID = { true, "Raid", "R", 255, 127, 0 },
    CHAT_MSG_RAID_LEADER = { true, "Raid Leader", "RL", 255, 72, 9 },
    CHAT_MSG_RAID_WARNING = { true, "Raid Warning", "RW", 255, 72, 0 },
    CHAT_MSG_INSTANCE_CHAT = { true, "Instance", "I", 255, 127, 0 },
    CHAT_MSG_INSTANCE_CHAT_LEADER = { true, "Instance Leader", "IL", 255, 72, 9 },
    CHAT_MSG_SYSTEM = { true, "System", "SYS", 255, 255, 0 },
    CHAT_MSG_DND = { true, "DND Auto-Reply", "DND", 255, 255, 255 },
    CHAT_MSG_AFK = { true, "AFK Auto-Reply", "AFK", 255, 255, 255 },
    CHAT_MSG_BN_WHISPER = { true, "Battle.Net", "BN", 0, 255, 246 },
    CHAT_MSG_BN_WHISPER_INFORM = { true, "Battle.Net", "BN", 0, 255, 246 },
}

PopupAddon = LibStub("AceAddon-3.0"):NewAddon("Popup", "AceConsole-3.0")
PopupAddon:RegisterChatCommand("pop", "TestPopup")
PopupAddon:RegisterChatCommand("popup", "ShowConfig")

PopupGUI = LibStub("AceGUI-3.0")

function PopupAddon:ShowConfig(input)
    ToggleConfig()
end

function PopupAddon:TestPopup(input)
    PlaySoundFile("Interface\\AddOns\\Popup\\Resources\\popup.ogg", "Master")
    popup(input, 5, 64, 255, 64)
end

function PopupAddon:getDB()
    return self.db
end

function PopupAddon:OnInitialize()
    local defaults = {
        global = {
            enabledChannels = {},
            blacklist = {},
        }
    }
    self.db = LibStub("AceDB-3.0"):New("PopupDB", defaults)
    if self.db.global.whitelist == nil then
        self.db.global.whitelist = {}
        self.db.global.whitelist["CHAT_MSG_SYSTEM"] = {
            [1] = "has died",
            [2] = "has left"
        }
        self.db.global.whitelist["CHAT_MSG_GUILD"] = {
            [1] = "?",
            [2] = "heal",
            [3] = "dps",
            [4] = "tank",
            [5] = "mythic",
            [6] = "raid"
        }
    end
end

function safestr(s) return s or "" end

function contains(s, toFind) return string.find(safestr(s):lower(), toFind:lower()) ~= nil end
