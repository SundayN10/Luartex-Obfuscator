--[[
    Polymorphic VM
    Generates different VM implementations each time
]]

local PolymorphicVM = {}
PolymorphicVM.__index = PolymorphicVM

function PolymorphicVM.new(parent)
    local self = setmetatable({}, PolymorphicVM)
    
    self.parent = parent
    self.random = parent.random
    
    return self
end

function PolymorphicVM:generate()
    -- Choose random implementation strategies
    local strategies = {
        stackImpl = self:chooseStackImpl(),
        registerImpl = self:chooseRegisterImpl(),
        dispatchImpl = self:chooseDispatchImpl(),
    }
    
    return self:buildVM(strategies)
end

function PolymorphicVM:chooseStackImpl()
    local impls = {
        "array",      -- Simple array-based stack
        "linked",     -- Linked list stack
        "hybrid",     -- Combination approach
    }
    return impls[self.random:int(1, #impls)]
end

function PolymorphicVM:chooseRegisterImpl()
    local impls = {
        "table",      -- Lua table
        "closure",    -- Closure-based
        "upvalue",    -- Upvalue-based
    }
    return impls[self.random:int(1, #impls)]
end

function PolymorphicVM:chooseDispatchImpl()
    local impls = {
        "switch",     -- if-elseif chain
        "table",      -- Table dispatch
        "computed",   -- Computed goto simulation
    }
    return impls[self.random:int(1, #impls)]
end

function PolymorphicVM:buildVM(strategies)
    local parts = {}
    
    -- Stack implementation
    if strategies.stackImpl == "array" then
        table.insert(parts, [[
            local stk, sp = {}, 0
            local function push(v) sp = sp + 1 stk[sp] = v end
            local function pop() local v = stk[sp] stk[sp] = nil sp = sp - 1 return v end
        ]])
    elseif strategies.stackImpl == "linked" then
        table.insert(parts, [[
            local stk = nil
            local function push(v) stk = {v = v, n = stk} end
            local function pop() local v = stk.v stk = stk.n return v end
        ]])
    else
        table.insert(parts, [[
            local stk, sp = {}, 0
            local function push(v) sp = sp + 1 stk[sp] = v end
            local function pop() sp = sp - 1 return stk[sp + 1] end
        ]])
    end
    
    return table.concat(parts, "\n")
end

return PolymorphicVM
