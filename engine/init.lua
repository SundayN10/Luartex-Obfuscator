--[[
    Luartex Engine Module Loader
]]

local Engine = {}

Engine.Pipeline = require("engine.pipeline")
Engine.Analyzer = require("engine.analyzer")
Engine.Transformer = require("engine.transformer")
Engine.Optimizer = require("engine.optimizer")

return Engine
