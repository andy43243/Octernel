--[[
    Wazy UI Library
    A clean, mobile-optimized UI library for Roblox
    Load from GitHub: loadstring(game:HttpGet('YOUR_GITHUB_RAW_LINK'))()
]]

-- Prevent multiple loads
if getgenv().WazyLoaded then 
    return getgenv().WazyUI
end 
getgenv().WazyLoaded = true

-- Services
local Services = setmetatable({}, {
    __index = function(self, service)
        return game:GetService(service)
    end
})

local Players = Services.Players
local RunService = Services.RunService
local UserInputService = Services.UserInputService
local TweenService = Services.TweenService
local CoreGui = Services.CoreGui
local HttpService = Services.HttpService

-- Locals
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera
local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- Utility Functions
local function clamp(n, min, max)
    return math.min(math.max(n, min), max)
end

local function rgb(r, g, b)
    return Color3.fromRGB(r, g, b)
end

local function dim2(xscale, xoffset, yscale, yoffset)
    return UDim2.new(xscale, xoffset, yscale, yoffset)
end

-- Mobile scaling (larger elements for mobile)
local MobileScale = IsMobile and 1.4 or 1
local MinButtonSize = IsMobile and 50 or 30

-- Wazy Library
local Wazy = {
    directory = "WazyUI",
    flags = {},
    connections = {},
    opened = true,
}

Wazy.__index = Wazy

-- Create directory
if not isfolder then
    function isfolder() return false end
    function makefolder() end
    function writefile() end
    function readfile() return "" end
end

if not isfolder(Wazy.directory) then
    makefolder(Wazy.directory)
end

-- Library Functions
function Wazy:Tween(obj, properties, time, style)
    local tween = TweenService:Create(
        obj, 
        TweenInfo.new(time or 0.25, style or Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), 
        properties
    )
    tween:Play()
    return tween
end

function Wazy:Connection(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(self.connections, connection)
    return connection
end

function Wazy:Draggify(frame)
    local dragging = false
    local dragStart, startPos

    local function update(input)
        if dragging then
            local delta = input.Position - dragStart
            local newPos = dim2(
                0,
                clamp(startPos.X.Offset + delta.X, 0, Camera.ViewportSize.X - frame.AbsoluteSize.X),
                0,
                clamp(startPos.Y.Offset + delta.Y, 0, Camera.ViewportSize.Y - frame.AbsoluteSize.Y)
            )
            self:Tween(frame, {Position = newPos}, 0.1, Enum.EasingStyle.Linear)
        end
    end

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)

    frame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    self:Connection(UserInputService.InputChanged, update)
end

function Wazy:Create(class, properties)
    local obj = Instance.new(class)
    for prop, value in pairs(properties) do
        if prop ~= "Parent" then
            obj[prop] = value
        end
    end
    if properties.Parent then
        obj.Parent = properties.Parent
    end
    return obj
end

function Wazy:Unload()
    for _, connection in pairs(self.connections) do
        connection:Disconnect()
    end
    if self.ScreenGui then
        self.ScreenGui:Destroy()
    end
    getgenv().WazyLoaded = nil
    getgenv().WazyUI = nil
end

-- Window Creation
function Wazy:CreateWindow(options)
    options = options or {}
    local windowName = options.Name or "Wazy UI"
    local windowSize = options.Size or dim2(0, 550 * MobileScale, 0, 650 * MobileScale)

    -- Create ScreenGui
    self.ScreenGui = self:Create("ScreenGui", {
        Name = "WazyUI",
        Parent = CoreGui,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false,
    })

    -- Main Window
    local Window = self:Create("Frame", {
        Name = "Window",
        Size = windowSize,
        Position = dim2(0.5, -windowSize.X.Offset/2, 0.5, -windowSize.Y.Offset/2),
        BackgroundColor3 = rgb(25, 25, 30),
        BorderSizePixel = 0,
        Parent = self.ScreenGui,
    })

    -- Add UICorner
    self:Create("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = Window,
    })

    -- Top Bar
    local TopBar = self:Create("Frame", {
        Name = "TopBar",
        Size = dim2(1, 0, 0, 40 * MobileScale),
        BackgroundColor3 = rgb(30, 30, 35),
        BorderSizePixel = 0,
        Parent = Window,
    })

    self:Create("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = TopBar,
    })

    -- Title
    local Title = self:Create("TextLabel", {
        Name = "Title",
        Size = dim2(1, -100 * MobileScale, 1, 0),
        Position = dim2(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = windowName,
        TextColor3 = rgb(255, 255, 255),
        TextSize = 16 * MobileScale,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = TopBar,
    })

    -- Close Button (Mobile & Desktop)
    local CloseButton = self:Create("TextButton", {
        Name = "CloseButton",
        Size = dim2(0, 35 * MobileScale, 0, 35 * MobileScale),
        Position = dim2(1, -40 * MobileScale, 0, 2.5 * MobileScale),
        BackgroundColor3 = rgb(220, 50, 50),
        BorderSizePixel = 0,
        Text = "×",
        TextColor3 = rgb(255, 255, 255),
        TextSize = 24 * MobileScale,
        Font = Enum.Font.GothamBold,
        Parent = TopBar,
    })

    self:Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = CloseButton,
    })

    CloseButton.MouseButton1Click:Connect(function()
        self.opened = not self.opened
        self:Tween(Window, {
            Size = self.opened and windowSize or dim2(0, windowSize.X.Offset, 0, 40 * MobileScale)
        }, 0.3)
    end)

    -- Container for Tabs
    local TabContainer = self:Create("Frame", {
        Name = "TabContainer",
        Size = dim2(1, -20, 1, -60 * MobileScale),
        Position = dim2(0, 10, 0, 45 * MobileScale),
        BackgroundTransparency = 1,
        Parent = Window,
    })

    -- Make draggable
    self:Draggify(TopBar)

    local WindowAPI = {
        Window = Window,
        TabContainer = TabContainer,
        Tabs = {},
        CurrentTab = nil,
    }

    function WindowAPI:CreateTab(options)
        options = options or {}
        local tabName = options.Name or "Tab"

        -- Tab Frame
        local TabFrame = self:Create("Frame", {
            Name = tabName,
            Size = dim2(1, 0, 1, 0),
            BackgroundColor3 = rgb(20, 20, 25),
            BorderSizePixel = 0,
            Visible = #self.Tabs == 0,
            Parent = TabContainer,
        })

        self:Create("UICorner", {
            CornerRadius = UDim.new(0, 6),
            Parent = TabFrame,
        })

        -- Scrolling Frame
        local ScrollFrame = self:Create("ScrollingFrame", {
            Name = "ScrollFrame",
            Size = dim2(1, -10, 1, -10),
            Position = dim2(0, 5, 0, 5),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = rgb(100, 100, 110),
            CanvasSize = dim2(0, 0, 0, 0),
            Parent = TabFrame,
        })

        local Layout = self:Create("UIListLayout", {
            Padding = UDim.new(0, 8 * MobileScale),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = ScrollFrame,
        })

        Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            ScrollFrame.CanvasSize = dim2(0, 0, 0, Layout.AbsoluteContentSize.Y + 10)
        end)

        table.insert(self.Tabs, TabFrame)
        if not self.CurrentTab then
            self.CurrentTab = TabFrame
        end

        return {
            Frame = TabFrame,
            ScrollFrame = ScrollFrame,
            CreateButton = function(_, opts) return Wazy:CreateButton(ScrollFrame, opts) end,
            CreateToggle = function(_, opts) return Wazy:CreateToggle(ScrollFrame, opts) end,
            CreateSlider = function(_, opts) return Wazy:CreateSlider(ScrollFrame, opts) end,
            CreateDropdown = function(_, opts) return Wazy:CreateDropdown(ScrollFrame, opts) end,
            CreateTextbox = function(_, opts) return Wazy:CreateTextbox(ScrollFrame, opts) end,
            CreateLabel = function(_, opts) return Wazy:CreateLabel(ScrollFrame, opts) end,
            CreateColorPicker = function(_, opts) return Wazy:CreateColorPicker(ScrollFrame, opts) end,
        }
    end

    return WindowAPI
end

-- UI Elements
function Wazy:CreateButton(parent, options)
    options = options or {}
    local name = options.Name or "Button"
    local callback = options.Callback or function() end

    local Button = self:Create("TextButton", {
        Name = name,
        Size = dim2(1, -10, 0, math.max(35 * MobileScale, MinButtonSize)),
        BackgroundColor3 = rgb(45, 45, 55),
        BorderSizePixel = 0,
        Text = name,
        TextColor3 = rgb(255, 255, 255),
        TextSize = 14 * MobileScale,
        Font = Enum.Font.Gotham,
        Parent = parent,
    })

    self:Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = Button,
    })

    Button.MouseButton1Click:Connect(callback)

    return Button
end

function Wazy:CreateToggle(parent, options)
    options = options or {}
    local name = options.Name or "Toggle"
    local default = options.Default or false
    local flag = options.Flag or name
    local callback = options.Callback or function() end

    self.flags[flag] = default

    local Toggle = self:Create("Frame", {
        Name = name,
        Size = dim2(1, -10, 0, math.max(35 * MobileScale, MinButtonSize)),
        BackgroundColor3 = rgb(45, 45, 55),
        BorderSizePixel = 0,
        Parent = parent,
    })

    self:Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = Toggle,
    })

    local Label = self:Create("TextLabel", {
        Name = "Label",
        Size = dim2(1, -50 * MobileScale, 1, 0),
        Position = dim2(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = rgb(255, 255, 255),
        TextSize = 14 * MobileScale,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Toggle,
    })

    local ToggleBox = self:Create("TextButton", {
        Name = "ToggleBox",
        Size = dim2(0, math.max(30 * MobileScale, MinButtonSize-5), 0, math.max(20 * MobileScale, MinButtonSize-15)),
        Position = dim2(1, -40 * MobileScale, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = default and rgb(100, 200, 100) or rgb(70, 70, 75),
        BorderSizePixel = 0,
        Text = "",
        Parent = Toggle,
    })

    self:Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = ToggleBox,
    })

    local function updateToggle()
        local value = self.flags[flag]
        self:Tween(ToggleBox, {
            BackgroundColor3 = value and rgb(100, 200, 100) or rgb(70, 70, 75)
        }, 0.2)
        callback(value)
    end

    ToggleBox.MouseButton1Click:Connect(function()
        self.flags[flag] = not self.flags[flag]
        updateToggle()
    end)

    updateToggle()
    return Toggle
end

function Wazy:CreateSlider(parent, options)
    options = options or {}
    local name = options.Name or "Slider"
    local min = options.Min or 0
    local max = options.Max or 100
    local default = options.Default or min
    local flag = options.Flag or name
    local callback = options.Callback or function() end

    self.flags[flag] = default

    local Slider = self:Create("Frame", {
        Name = name,
        Size = dim2(1, -10, 0, math.max(50 * MobileScale, MinButtonSize + 15)),
        BackgroundColor3 = rgb(45, 45, 55),
        BorderSizePixel = 0,
        Parent = parent,
    })

    self:Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = Slider,
    })

    local Label = self:Create("TextLabel", {
        Name = "Label",
        Size = dim2(1, -20, 0, 20 * MobileScale),
        Position = dim2(0, 10, 0, 5),
        BackgroundTransparency = 1,
        Text = name .. ": " .. default,
        TextColor3 = rgb(255, 255, 255),
        TextSize = 13 * MobileScale,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Slider,
    })

    local SliderBack = self:Create("Frame", {
        Name = "SliderBack",
        Size = dim2(1, -20, 0, math.max(8 * MobileScale, 8)),
        Position = dim2(0, 10, 1, -12 * MobileScale),
        BackgroundColor3 = rgb(30, 30, 35),
        BorderSizePixel = 0,
        Parent = Slider,
    })

    self:Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = SliderBack,
    })

    local SliderFill = self:Create("Frame", {
        Name = "SliderFill",
        Size = dim2((default - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = rgb(100, 150, 255),
        BorderSizePixel = 0,
        Parent = SliderBack,
    })

    self:Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = SliderFill,
    })

    local dragging = false

    local function update(input)
        local sizeX = clamp((input.Position.X - SliderBack.AbsolutePosition.X) / SliderBack.AbsoluteSize.X, 0, 1)
        local value = math.floor(min + (max - min) * sizeX)
        self.flags[flag] = value
        Label.Text = name .. ": " .. value
        SliderFill.Size = dim2(sizeX, 0, 1, 0)
        callback(value)
    end

    SliderBack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            update(input)
        end
    end)

    SliderBack.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    self:Connection(UserInputService.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)

    return Slider
end

function Wazy:CreateDropdown(parent, options)
    options = options or {}
    local name = options.Name or "Dropdown"
    local list = options.Options or {}
    local default = options.Default or (list[1] or "None")
    local flag = options.Flag or name
    local callback = options.Callback or function() end

    self.flags[flag] = default

    local Dropdown = self:Create("Frame", {
        Name = name,
        Size = dim2(1, -10, 0, math.max(35 * MobileScale, MinButtonSize)),
        BackgroundColor3 = rgb(45, 45, 55),
        BorderSizePixel = 0,
        Parent = parent,
    })

    self:Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = Dropdown,
    })

    local Label = self:Create("TextLabel", {
        Name = "Label",
        Size = dim2(1, -50 * MobileScale, 1, 0),
        Position = dim2(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = name .. ": " .. default,
        TextColor3 = rgb(255, 255, 255),
        TextSize = 13 * MobileScale,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Dropdown,
    })

    local DropButton = self:Create("TextButton", {
        Name = "DropButton",
        Size = dim2(0, 30 * MobileScale, 0, 25 * MobileScale),
        Position = dim2(1, -35 * MobileScale, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = rgb(60, 60, 70),
        BorderSizePixel = 0,
        Text = "▼",
        TextColor3 = rgb(255, 255, 255),
        TextSize = 12 * MobileScale,
        Font = Enum.Font.Gotham,
        Parent = Dropdown,
    })

    self:Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = DropButton,
    })

    local DropFrame = self:Create("Frame", {
        Name = "DropFrame",
        Size = dim2(1, 0, 0, 0),
        Position = dim2(0, 0, 1, 5),
        BackgroundColor3 = rgb(40, 40, 50),
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 10,
        Parent = Dropdown,
    })

    self:Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = DropFrame,
    })

    local DropLayout = self:Create("UIListLayout", {
        Padding = UDim.new(0, 2),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = DropFrame,
    })

    local isOpen = false

    DropButton.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        DropFrame.Visible = isOpen
        if isOpen then
            self:Tween(DropFrame, {Size = dim2(1, 0, 0, #list * (30 * MobileScale) + (#list - 1) * 2)}, 0.2)
        else
            self:Tween(DropFrame, {Size = dim2(1, 0, 0, 0)}, 0.2)
        end
    end)

    for _, option in ipairs(list) do
        local OptionButton = self:Create("TextButton", {
            Name = option,
            Size = dim2(1, 0, 0, 28 * MobileScale),
            BackgroundColor3 = rgb(50, 50, 60),
            BorderSizePixel = 0,
            Text = option,
            TextColor3 = rgb(255, 255, 255),
            TextSize = 12 * MobileScale,
            Font = Enum.Font.Gotham,
            Parent = DropFrame,
        })

        self:Create("UICorner", {
            CornerRadius = UDim.new(0, 4),
            Parent = OptionButton,
        })

        OptionButton.MouseButton1Click:Connect(function()
            self.flags[flag] = option
            Label.Text = name .. ": " .. option
            isOpen = false
            DropFrame.Visible = false
            self:Tween(DropFrame, {Size = dim2(1, 0, 0, 0)}, 0.2)
            callback(option)
        end)
    end

    return Dropdown
end

function Wazy:CreateTextbox(parent, options)
    options = options or {}
    local name = options.Name or "Textbox"
    local placeholder = options.Placeholder or "Enter text..."
    local flag = options.Flag or name
    local callback = options.Callback or function() end

    self.flags[flag] = ""

    local Textbox = self:Create("Frame", {
        Name = name,
        Size = dim2(1, -10, 0, math.max(60 * MobileScale, MinButtonSize + 25)),
        BackgroundColor3 = rgb(45, 45, 55),
        BorderSizePixel = 0,
        Parent = parent,
    })

    self:Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = Textbox,
    })

    local Label = self:Create("TextLabel", {
        Name = "Label",
        Size = dim2(1, -20, 0, 20 * MobileScale),
        Position = dim2(0, 10, 0, 5),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = rgb(255, 255, 255),
        TextSize = 13 * MobileScale,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Textbox,
    })

    local Input = self:Create("TextBox", {
        Name = "Input",
        Size = dim2(1, -20, 0, 25 * MobileScale),
        Position = dim2(0, 10, 1, -30 * MobileScale),
        BackgroundColor3 = rgb(30, 30, 35),
        BorderSizePixel = 0,
        Text = "",
        PlaceholderText = placeholder,
        TextColor3 = rgb(255, 255, 255),
        PlaceholderColor3 = rgb(120, 120, 130),
        TextSize = 12 * MobileScale,
        Font = Enum.Font.Gotham,
        ClearTextOnFocus = false,
        Parent = Textbox,
    })

    self:Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = Input,
    })

    Input.FocusLost:Connect(function(enter)
        if enter then
            self.flags[flag] = Input.Text
            callback(Input.Text)
        end
    end)

    return Textbox
end

function Wazy:CreateLabel(parent, options)
    options = options or {}
    local text = options.Text or "Label"

    local Label = self:Create("TextLabel", {
        Name = "Label",
        Size = dim2(1, -10, 0, math.max(25 * MobileScale, MinButtonSize - 5)),
        BackgroundColor3 = rgb(45, 45, 55),
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = rgb(255, 255, 255),
        TextSize = 13 * MobileScale,
        Font = Enum.Font.Gotham,
        TextWrapped = true,
        Parent = parent,
    })

    self:Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = Label,
    })

    return Label
end

function Wazy:CreateColorPicker(parent, options)
    options = options or {}
    local name = options.Name or "Color Picker"
    local default = options.Default or Color3.fromRGB(255, 255, 255)
    local flag = options.Flag or name
    local callback = options.Callback or function() end

    self.flags[flag] = default

    local ColorPicker = self:Create("Frame", {
        Name = name,
        Size = dim2(1, -10, 0, math.max(35 * MobileScale, MinButtonSize)),
        BackgroundColor3 = rgb(45, 45, 55),
        BorderSizePixel = 0,
        Parent = parent,
    })

    self:Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = ColorPicker,
    })

    local Label = self:Create("TextLabel", {
        Name = "Label",
        Size = dim2(1, -50 * MobileScale, 1, 0),
        Position = dim2(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = rgb(255, 255, 255),
        TextSize = 13 * MobileScale,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = ColorPicker,
    })

    local ColorBox = self:Create("Frame", {
        Name = "ColorBox",
        Size = dim2(0, math.max(30 * MobileScale, MinButtonSize - 5), 0, math.max(25 * MobileScale, MinButtonSize - 10)),
        Position = dim2(1, -35 * MobileScale, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = default,
        BorderSizePixel = 0,
        Parent = ColorPicker,
    })

    self:Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = ColorBox,
    })

    local ColorButton = self:Create("TextButton", {
        Size = dim2(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        Parent = ColorBox,
    })

    ColorButton.MouseButton1Click:Connect(function()
        -- Simple RGB picker (cycles through rainbow)
        local h, s, v = Color3.toHSV(self.flags[flag])
        h = (h + 0.1) % 1
        local newColor = Color3.fromHSV(h, s, v)
        self.flags[flag] = newColor
        ColorBox.BackgroundColor3 = newColor
        callback(newColor)
    end)

    return ColorPicker
end

-- Set as global
getgenv().WazyUI = Wazy

return Wazy
