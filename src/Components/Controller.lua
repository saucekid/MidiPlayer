-- Controller
-- 0866
-- November 03, 2020



local midiPlayer = script:FindFirstAncestor("MidiPlayer")
local Signal = require(midiPlayer.Util.Signal)
local Date = require(midiPlayer.Util.Date)
local Thread = require(midiPlayer.Util.Thread)
local Song = require(midiPlayer.Song)
local FastTween = require(midiPlayer.FastTween)
local Preview = require(midiPlayer.Components.Preview)

local Controller = {
    CurrentSong = nil;
    FileLoaded = Signal.new();
}

getgenv().LeftHand = true;
getgenv().RightHand = true;

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local main, controller


function Controller:Select(filePath)
    if (self.CurrentSong) then
        self.CurrentSong:Destroy()
    end
    getgenv().LeftHand = true;
    getgenv().RightHand = true;
    controller.RightHand.ImageTransparency = 0
    controller.LeftHand.ImageTransparency = 0
    self.CurrentSong = Song.new(filePath)
    self.FileLoaded:Fire(self.CurrentSong)
    self:Update()
    Preview:Draw(self.CurrentSong)
end


function Controller:Update()
    local song = self.CurrentSong

    if (song) then
        main.Title.Text = song.Name

        if (song.TimePosition) then
            local date = Date.new(song.TimePosition)
            controller.Time.Text = ("%s:%s"):format(
                tostring(date.Minute),
                ("%02i"):format(tostring(date.Second % 60))
            )
        end
        controller.Speed.Text = tostring(math.floor(song.Speed * 10) / 10).. "x"
        controller.SpeedScrubber.Progress.Size = UDim2.fromScale(math.min(1, song.Speed / 2), 1)
        controller.Miss.Text = tostring(math.round(song.MissPercent)).. "%"
        controller.MissScrubber.Progress.Size = UDim2.fromScale(math.min(1, song.MissPercent / 100), 1)
        controller.Scrubber.Progress.Size = UDim2.fromScale(math.min(1, song.TimePosition / song.TimeLength), 1)
        controller.Scrubber.Fill.Size = UDim2.fromScale(1 - controller.Scrubber.Progress.Size.X.Scale, 1)
        controller.Resume.Image = (song.IsPlaying and "rbxassetid://5915789609") or "rbxassetid://5915551861"

    else
        main.Title.Text = "No song selected"
        controller.Time.Text = "0:00"
        controller.Speed.Text = "1x"
        controller.Miss.Text = "0%"
        controller.Scrubber.Progress.Size = UDim2.fromScale(0, 1)
        controller.Scrubber.Fill.Size = UDim2.fromScale(1, 1)
        controller.Resume.Image = "rbxassetid://5915551861"
        controller.RightHand.ImageTransparency = 0
        controller.LeftHand.ImageTransparency = 0
    end
end


function Controller:Init(frame)

    main = frame.Main
    controller = main.Controller

    self:_startHandButtons()

    self:_startScrubber()
    self:_startSpeedScrubber()
    self:_startMissScrubber()

    self:_startPlaybackButton()

    self:_startHidePreviewButton()

    Thread.DelayRepeat(1/60, function()
        if (self.CurrentSong) then
            Preview:Update(self.CurrentSong.TimePosition * self.CurrentSong.Timebase)
        end
    end)

    RunService.Heartbeat:Connect(function()
        self:Update()
    end)

end


function Controller:_startHidePreviewButton()
    local togglePreview = main.TogglePreview
    togglePreview.MouseButton1Down:Connect(function()
        getgenv()._hideSongPreview = (not getgenv()._hideSongPreview)
        if (getgenv()._hideSongPreview) then
            FastTween(togglePreview.Fill, { 0.1 }, { Size = UDim2.new() })
        else
            FastTween(togglePreview.Fill, { 0.1 }, { Size = UDim2.new(1, -12, 1, -12) })
        end
    end)
end


function Controller:_startPlaybackButton()
    local playback = controller.Resume
    playback.MouseButton1Down:Connect(function()
        if (not self.CurrentSong) then return end
        if (self.CurrentSong.IsPlaying) then
            self.CurrentSong:Pause()
        else
            self.CurrentSong:Play()
        end
        self:Update()
    end)
end

function Controller:_startHandButtons()
    local right = controller.RightHand
    local left = controller.LeftHand

    left.MouseButton1Down:Connect(function()
        if (getgenv().LeftHand) then
            Preview:hideHand("left")
            FastTween(left, { 0.1 }, { ImageTransparency = 0.5 })
        else
            Preview:showHand("left")
            FastTween(left, { 0.1 }, { ImageTransparency = 0 })
        end
        getgenv().LeftHand = not getgenv().LeftHand
    end)

    right.MouseButton1Down:Connect(function()
        if (getgenv().RightHand) then
            Preview:hideHand("right")
            FastTween(right, { 0.1 }, { ImageTransparency = 0.5 })
        else
            Preview:showHand("right")
            FastTween(right, { 0.1 }, { ImageTransparency = 0 })
        end
        getgenv().RightHand = not getgenv().RightHand
    end)
end



function Controller:_startScrubber()

    -- https://devforum.roblox.com/t/draggable-property-is-hidden-on-gui-objects/107689/5

    local absSize = controller.Scrubber.AbsoluteSize

    local dragging
    local dragInput

    local function update(input)
        local song = self.CurrentSong
        local absPos = controller.Scrubber.AbsolutePosition
        if (song) then
            song:JumpTo(math.clamp((input.Position.X - absPos.X) / absSize.X, 0, 1) * song.TimeLength)
        end
        self:Update()
    end

    controller.Scrubber.Hitbox.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1) then
            dragging = true
            input.Changed:Connect(function()
                if (input.UserInputState == Enum.UserInputState.End) then
                    dragging = false
                end
            end)
            update(input)
        end
    end)

    controller.Scrubber.Hitbox.InputChanged:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseMovement) then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if (input == dragInput and dragging) then
            if (self.CurrentSong) then
                self.CurrentSong:Pause()
            end
            update(input)
        end
    end)

end

function Controller:_startSpeedScrubber()

    -- https://devforum.roblox.com/t/draggable-property-is-hidden-on-gui-objects/107689/5

    local absSize = controller.SpeedScrubber.AbsoluteSize

    local dragging
    local dragInput

    local function update(input)
        local song = self.CurrentSong
        local absPos = controller.SpeedScrubber.AbsolutePosition
        if (song) then
            song.Speed = (math.clamp((input.Position.X - absPos.X) / absSize.X, 0, 1) * 2)
        end
        self:Update()
    end

    controller.SpeedScrubber.Hitbox.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1) then
            dragging = true
            input.Changed:Connect(function()
                if (input.UserInputState == Enum.UserInputState.End) then
                    dragging = false
                end
            end)
            update(input)
        end
    end)

    controller.SpeedScrubber.Hitbox.InputChanged:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseMovement) then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if (input == dragInput and dragging) then
            update(input)
        end
    end)

end


function Controller:_startMissScrubber()

    -- https://devforum.roblox.com/t/draggable-property-is-hidden-on-gui-objects/107689/5

    local absSize = controller.MissScrubber.AbsoluteSize

    local dragging
    local dragInput

    local function update(input)
        local song = self.CurrentSong
        local absPos = controller.MissScrubber.AbsolutePosition
        if (song) then
            song.MissPercent = (math.clamp((input.Position.X - absPos.X) / absSize.X, 0, 1) * 100)
        end
        self:Update()
    end

    controller.MissScrubber.Hitbox.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1) then
            dragging = true
            input.Changed:Connect(function()
                if (input.UserInputState == Enum.UserInputState.End) then
                    dragging = false
                end
            end)
            update(input)
        end
    end)

    controller.MissScrubber.Hitbox.InputChanged:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseMovement) then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if (input == dragInput and dragging) then
            update(input)
        end
    end)

end

return Controller
