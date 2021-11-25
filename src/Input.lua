-- Input
-- 0866
-- November 03, 2020



local Input = {}

local VirtualInputManager = game:GetService("VirtualInputManager")
local keypress = getfenv(0).keypress
local keyrelease = getfenv(0).keyrelease

local VK_LSHIFT = 0x10

local NOTE_MAP = "1!2@34$5%6^78*9(0qQwWeErtTyYuiIoOpPasSdDfgGhHjJklLzZxcCvVbBnm"
local UPPER_MAP = "!@ $%^ *( QWE TY IOP SD GHJ LZ CVB"
local LOWER_MAP = "1234567890qwertyuiopasdfghjklzxcvbnm"

local Thread = require(script.Parent.Util.Thread)
local Maid = require(script.Parent.Util.Maid)

local inputMaid = Maid.new()

local Words ={
    ["Zero"]="0",
    ["One"]="1",
    ["Two"]="2",
    ["Three"]="3",
    ["Four"]="4",
    ["Five"]="5",
    ["Six"]="6",
    ["Seven"]="7",
    ["Eight"]="8",
    ["Nine"]="9",
}

local function CharacterToWord(char)
    local wordfound
    for word, v in pairs(Words) do
        if v == char then
            wordfound = word
        end
    end
    return wordfound or char:upper()
end

local function GetKey(pitch)
    local idx = (pitch + 1 - 36)
    if (idx > #NOTE_MAP or idx < 1) then
        return
    else
        local key = NOTE_MAP:sub(idx, idx)
        return key, UPPER_MAP:find(key, 1, true)
    end
end


function Input.IsUpper(pitch)
    local key, upperMapIdx = GetKey(pitch)
    if (not key) then return end
    return upperMapIdx
end


function Input.Press(pitch)
    local key, upperMapIdx = GetKey(pitch)
    if (not key) then return end
    if (upperMapIdx) then
        local keyToPress = LOWER_MAP:sub(upperMapIdx, upperMapIdx)
        VirtualInputManager:SendKeyEvent(true,Enum.KeyCode.LeftShift,false,game)
        VirtualInputManager:SendKeyEvent(true,CharacterToWord(keyToPress),false,game)
        VirtualInputManager:SendKeyEvent(false,Enum.KeyCode.LeftShift,false,game)
    else
        VirtualInputManager:SendKeyEvent(true,CharacterToWord(key),false,game)
    end
end


function Input.Release(pitch)
    local key, upperMapIdx = GetKey(pitch)
    if (not key) then return end
    if (upperMapIdx) then
        local keyToPress = LOWER_MAP:sub(upperMapIdx, upperMapIdx)
        VirtualInputManager:SendKeyEvent(false,CharacterToWord(keyToPress),false,game)
    else
        VirtualInputManager:SendKeyEvent(false,CharacterToWord(key),false,game)
    end
end


function Input.Hold(pitch, duration)
    print(pitch)
    print(LeftHand)
    if getgenv().leftNotePitches[pitch] and not getgenv().LeftHand then return end
    if getgenv().rightNotePitches[pitch] and not getgenv().RightHand then return end
    if (inputMaid[pitch]) then
        inputMaid[pitch] = nil
    end
    Input.Release(pitch)
    Input.Press(pitch)
    inputMaid[pitch] = Thread.Delay(duration, Input.Release, pitch)
end


return Input