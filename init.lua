--[[
    ██╗     ██╗   ██╗ █████╗ ██████╗ ████████╗███████╗██╗  ██╗
    ██║     ██║   ██║██╔══██╗██╔══██╗╚══██╔══╝██╔════╝╚██╗██╔╝
    ██║     ██║   ██║███████║██████╔╝   ██║   █████╗   ╚███╔╝ 
    ██║     ██║   ██║██╔══██║██╔══██╗   ██║   ██╔══╝   ██╔██╗ 
    ███████╗╚██████╔╝██║  ██║██║  ██║   ██║   ███████╗██╔╝ ██╗
    ╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚══════╝╚═╝  ╚═╝
    
    Luartex Obfuscator v1.0.0
    The Ultimate Lua Protection System
    
    Discord: https://discord.gg/GpucUKeCtF
]]

local Luartex = {}
Luartex._VERSION = "1.0.0"
Luartex._AUTHOR = "Luartex Team"
Luartex._DISCORD = "https://discord.gg/GpucUKeCtF"

-- Core imports
local Config = require("config")
local Logger = require("core.logger")
local Pipeline = require("engine.pipeline")
local Presets = require("presets")
local Parser = require("core.parser")
local Compiler = require("core.compiler")
local Random = require("core.random")

-- Layer imports
local StringEncryption = require("layers.string_encryption")
local ControlFlow = require("layers.control_flow")
local Virtualization = require("layers.virtualization")
local AntiTamper = require("layers.anti_tamper")
local AntiDump = require("layers.anti_dump")
local Mutation = require("layers.mutation")
local Decoys = require("layers.decoys")

--[[
    Create new Luartex instance
]]
function Luartex.new(options)
    local self = setmetatable({}, { __index = Luartex })
    
    options = options or {}
    
    -- Initialize components
    self.config = Config.merge(Config.defaults, options)
    self.logger = Logger.new(self.config.logLevel)
    self.random = Random.new(self.config.seed)
    self.pipeline = Pipeline.new(self)
    
    -- Layer instances
    self.layers = {
        stringEncryption = StringEncryption.new(self),
        controlFlow = ControlFlow.new(self),
        virtualization = Virtualization.new(self),
        antiTamper = AntiTamper.new(self),
        antiDump = AntiDump.new(self),
        mutation = Mutation.new(self),
        decoys = Decoys.new(self),
    }
    
    -- Statistics
    self.stats = {
        inputSize = 0,
        outputSize = 0,
        layersApplied = 0,
        processingTime = 0,
        stringsEncrypted = 0,
        functionsVirtualized = 0,
    }
    
    self.logger:info("Luartex Obfuscator v" .. Luartex._VERSION .. " initialized")
    
    return self
end

--[[
    Load a preset configuration
]]
function Luartex:usePreset(presetName)
    local preset = Presets.get(presetName)
    
    if not preset then
        self.logger:error("Preset not found: " .. tostring(presetName))
        self.logger:info("Available presets: " .. table.concat(Presets.list(), ", "))
        return self
    end
    
    self.logger:info("Loading preset: " .. presetName)
    
    -- Apply preset configuration
    self.config = Config.merge(self.config, preset.config or {})
    self.activePreset = preset
    
    return self
end

--[[
    Main obfuscation function
]]
function Luartex:obfuscate(source, options)
    options = options or {}
    
    -- Merge options with preset
    if options.preset then
        self:usePreset(options.preset)
    end
    
    local startTime = os.clock()
    self.stats.inputSize = #source
    
    self.logger:info("=" .. string.rep("=", 50))
    self.logger:info("Starting Luartex Obfuscation")
    self.logger:info("=" .. string.rep("=", 50))
    self.logger:info("Input size: " .. #source .. " bytes")
    
    -- Step 1: Parse source code
    self.logger:info("[1/8] Parsing source code...")
    local ast, parseErr = Parser.parse(source)
    if not ast then
        self.logger:error("Parse error: " .. tostring(parseErr))
        return nil, parseErr
    end
    
    -- Step 2: Analyze code
    self.logger:info("[2/8] Analyzing code structure...")
    self.pipeline:analyze(ast)
    
    -- Step 3: Apply mutation layer
    if self.config.layers.mutation then
        self.logger:info("[3/8] Applying mutation layer...")
        ast = self.layers.mutation:apply(ast)
    end
    
    -- Step 4: Apply string encryption
    if self.config.layers.stringEncryption then
        self.logger:info("[4/8] Encrypting strings...")
        ast = self.layers.stringEncryption:apply(ast)
    end
    
    -- Step 5: Apply control flow obfuscation
    if self.config.layers.controlFlow then
        self.logger:info("[5/8] Obfuscating control flow...")
        ast = self.layers.controlFlow:apply(ast)
    end
    
    -- Step 6: Apply decoys
    if self.config.layers.decoys then
        self.logger:info("[6/8] Injecting decoys...")
        ast = self.layers.decoys:apply(ast)
    end
    
    -- Step 7: Apply anti-tamper
    if self.config.layers.antiTamper then
        self.logger:info("[7/8] Adding anti-tamper protection...")
        ast = self.layers.antiTamper:apply(ast)
    end
    
    -- Step 8: Virtualize (if enabled)
    if self.config.layers.virtualization then
        self.logger:info("[8/8] Virtualizing code...")
        ast = self.layers.virtualization:apply(ast)
    end
    
    -- Compile back to Lua
    self.logger:info("Compiling protected code...")
    local output, compileErr = Compiler.compile(ast, {
        minify = self.config.minify,
        addWatermark = self.config.addWatermark,
    })
    
    if not output then
        self.logger:error("Compile error: " .. tostring(compileErr))
        return nil, compileErr
    end
    
    -- Apply anti-dump wrapper
    if self.config.layers.antiDump then
        self.logger:info("Applying anti-dump wrapper...")
        output = self.layers.antiDump:wrap(output)
    end
    
    -- Calculate stats
    self.stats.outputSize = #output
    self.stats.processingTime = os.clock() - startTime
    
    self.logger:info("=" .. string.rep("=", 50))
    self.logger:info("Obfuscation Complete!")
    self.logger:info("=" .. string.rep("=", 50))
    self.logger:info(string.format("Output size: %d bytes (%.1fx)", 
        self.stats.outputSize, 
        self.stats.outputSize / self.stats.inputSize))
    self.logger:info(string.format("Processing time: %.3fs", self.stats.processingTime))
    
    return output
end

--[[
    Obfuscate a file
]]
function Luartex:obfuscateFile(inputPath, outputPath)
    local file, err = io.open(inputPath, "r")
    if not file then
        self.logger:error("Cannot open file: " .. tostring(err))
        return nil, err
    end
    
    local source = file:read("*a")
    file:close()
    
    local result, obfErr = self:obfuscate(source)
    if not result then
        return nil, obfErr
    end
    
    if outputPath then
        local outFile, writeErr = io.open(outputPath, "w")
        if not outFile then
            self.logger:error("Cannot write file: " .. tostring(writeErr))
            return nil, writeErr
        end
        
        outFile:write(result)
        outFile:close()
        
        self.logger:info("Output written to: " .. outputPath)
    end
    
    return result
end

--[[
    Get obfuscation statistics
]]
function Luartex:getStats()
    return self.stats
end

--[[
    Quick obfuscation function (static)
]]
function Luartex.obfuscate(source, options)
    local instance = Luartex.new(options)
    return instance:obfuscate(source, options)
end

return Luartex
