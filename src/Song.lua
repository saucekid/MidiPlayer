-- Song
-- 0866
-- November 03, 2020



local Song = {}
Song.__index = Song
Song.Speed = 1
Song.MissPercent = 0

local MIDI = require(script.Parent.MIDI)
local Input = require(script.Parent.Input)

local RunService = game:GetService("RunService")

getgenv().rightNotePitches = {}
getgenv().leftNotePitches = {}

local function GetTimeLength(score)
    local length = 0
    for i, track in ipairs(score) do
        if (i == 1) then continue end
        length = math.max(length, track[#track][2])
    end
    return length
end

local function chance(x) 
    if math.random(1,100) <= x then 
        return true
    else 
        return false
    end  
end  

function Song.new(file)

    local score = MIDI.midi2score(readfile(file))

    local fullname = file:match("([^/^\\]+)$")
    local name = fullname:match("^([^%.]+)") or ""

    local self = setmetatable({

        Name = name;
        Path = file;
        TimePosition = 0;
        TimeLength = 0;
        Timebase = score[1];
        IsPlaying = false;

        _score = score;
        _usPerBeat = 0;
        _lastTimePosition = 0;
        _length = GetTimeLength(score);
        _eventStatus = {};
        _updateConnection = nil;

    }, Song)

    self.TimeLength = (self._length / self.Timebase)

    return self

end


function Song:Update(timePosition, lastTimePosition)
    for _,track in next, self._score, 1 do
        local pos = (_ % 4) 
        for _,event in ipairs(track) do
            if (event[1] == "note") then
                local pitch = event[5]
                if pos == 2 then
                    getgenv().rightNotePitches = {}
                    getgenv().rightNotePitches[pitch] = true
                elseif pos == 3 then
                    getgenv().leftNotePitches = {}
                    getgenv().leftNotePitches[pitch] = true
                end
            end
            local eventTime = (event[2] / self.Timebase)
            if (timePosition >= eventTime) then
                if (lastTimePosition <= eventTime) then
                    self:_parse(event)
                end
            end
        end
    end
end


function Song:Step(deltaTime)
    self._lastTimePosition = self.TimePosition
    if (self._usPerBeat ~= 0) then
        self.TimePosition += (deltaTime / (self._usPerBeat / 1000000))  * self.Speed
    else
        self.TimePosition += deltaTime * self.Speed
    end
end


function Song:JumpTo(timePosition)
    self.TimePosition = timePosition
    self._lastTimePosition = timePosition
end


function Song:Play()
    self._updateConnection = RunService.RenderStepped:Connect(function(dt)
        self:Update(self.TimePosition, self._lastTimePosition)
        self:Step(dt)
        if (self.TimePosition >= self.TimeLength) then
            self:Pause()
        end
    end)
    self:Update(0, 0)
    self.IsPlaying = true
end


function Song:Stop()
    if (self._updateConnection) then
        self._updateConnection:Disconnect()
        self._updateConnection = nil
        self.IsPlaying = false
    end
    self._lastTimePosition = 0
end


function Song:Pause()
    if (self._updateConnection) then
        self._updateConnection:Disconnect()
        self._updateConnection = nil
        self.IsPlaying = false
    end
end


function Song:_parse(event)
    --[[

        Event:
            Event name  [String]
            Start time  [Number]
            ...

        Note:
            Event name  [String]
            Start time  [Number]
            Duration    [Number]
            Channel     [Number]
            Pitch       [Number]
            Velocity    [Number]

    ]]
    local eventName = event[1]

    if (eventName == "set_tempo") then
        self._usPerBeat = event[3]
    elseif (eventName == "song_position") then
        self.TimePosition = (event[3] / self.Timebase)
        print("set timeposition timebase", self.Timebase)
    elseif (eventName == "note") then
        if self.MissPercent > 0 then
            task.spawn(function()
                local random1 = chance(self.MissPercent)
                local random2 = chance(self.MissPercent)
                local random3 = chance(self.MissPercent)
                if random1 then wait(math.random(0.1, 0.5)) end
                if not random3 then Input.Hold(not random2 and event[5] or event[5] - 1, event[3] / self.Timebase) end
            end)
        else
            Input.Hold(event[5], event[3] / self.Timebase)
        end
    end
end


function Song.FromTitle(midiTitle)
    return Song.new("midi/" .. midiTitle .. ".mid")
end


Song.Destroy = Song.Stop

return Song