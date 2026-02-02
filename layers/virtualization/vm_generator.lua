--[[
    Virtual Machine Generator
    Generates the VM runtime code
]]

local VMGenerator = {}
VMGenerator.__index = VMGenerator

function VMGenerator.new(parent)
    local self = setmetatable({}, VMGenerator)
    
    self.parent = parent
    self.random = parent.random
    self.config = parent.config
    
    self.vmExecuteName = self.random:identifier(16)
    self.vmStackName = self.random:identifier(12)
    self.vmRegistersName = self.random:identifier(12)
    
    return self
end

function VMGenerator:generate(instructions)
    local opcodeHandlers = self:generateOpcodeHandlers(instructions)
    
    local vmCode = string.format([[
local %s, %s
do
    local stack = {}
    local sp = 0
    local registers = {}
    local constants = {}
    local pc = 1
    
    local function push(v)
        sp = sp + 1
        stack[sp] = v
    end
    
    local function pop()
        local v = stack[sp]
        stack[sp] = nil
        sp = sp - 1
        return v
    end
    
    local function peek()
        return stack[sp]
    end
    
    local function readByte(bytecode)
        local b = bytecode[pc]
        pc = pc + 1
        return b or 0
    end
    
    local function readShort(bytecode)
        local h = readByte(bytecode)
        local l = readByte(bytecode)
        return h * 256 + l
    end
    
    local handlers = {
%s
    }
    
    %s = function(bytecode, ...)
        stack = {}
        sp = 0
        registers = {}
        pc = 1
        
        -- Push arguments
        local args = {...}
        for i = 1, #args do
            registers[i - 1] = args[i]
        end
        
        while pc <= #bytecode do
            local opcode = readByte(bytecode)
            local handler = handlers[opcode]
            
            if handler then
                local result = handler(bytecode, registers, stack, push, pop, readShort)
                if result ~= nil then
                    return result
                end
            end
        end
        
        return pop()
    end
end
]], self.vmStackName, self.vmRegistersName,
    opcodeHandlers,
    self.vmExecuteName)
    
    return vmCode
end

function VMGenerator:generateOpcodeHandlers(instructions)
    local handlers = {}
    
    -- NOP
    if instructions.NOP then
        table.insert(handlers, string.format(
            "[%d] = function() end", instructions.NOP.opcode))
    end
    
    -- LOAD constant
    if instructions.LOAD then
        table.insert(handlers, string.format([[
        [%d] = function(bc, reg, stk, push, pop, readShort)
            local idx = readShort(bc)
            push(constants[idx])
        end]], instructions.LOAD.opcode))
    end
    
    -- STORE to register
    if instructions.STORE then
        table.insert(handlers, string.format([[
        [%d] = function(bc, reg, stk, push, pop, readShort)
            local idx = readShort(bc)
            reg[idx] = pop()
        end]], instructions.STORE.opcode))
    end
    
    -- FETCH from register
    if instructions.FETCH then
        table.insert(handlers, string.format([[
        [%d] = function(bc, reg, stk, push, pop, readShort)
            local idx = readShort(bc)
            push(reg[idx])
        end]], instructions.FETCH.opcode))
    end
    
    -- ADD
    if instructions.ADD then
        table.insert(handlers, string.format([[
        [%d] = function(bc, reg, stk, push, pop)
            local b = pop()
            local a = pop()
            push(a + b)
        end]], instructions.ADD.opcode))
    end
    
    -- SUB
    if instructions.SUB then
        table.insert(handlers, string.format([[
        [%d] = function(bc, reg, stk, push, pop)
            local b = pop()
            local a = pop()
            push(a - b)
        end]], instructions.SUB.opcode))
    end
    
    -- MUL
    if instructions.MUL then
        table.insert(handlers, string.format([[
        [%d] = function(bc, reg, stk, push, pop)
            local b = pop()
            local a = pop()
            push(a * b)
        end]], instructions.MUL.opcode))
    end
    
    -- DIV
    if instructions.DIV then
        table.insert(handlers, string.format([[
        [%d] = function(bc, reg, stk, push, pop)
            local b = pop()
            local a = pop()
            push(a / b)
        end]], instructions.DIV.opcode))
    end
    
    -- MOD
    if instructions.MOD then
        table.insert(handlers, string.format([[
        [%d] = function(bc, reg, stk, push, pop)
            local b = pop()
            local a = pop()
            push(a %% b)
        end]], instructions.MOD.opcode))
    end
    
    -- NEG
    if instructions.NEG then
        table.insert(handlers, string.format([[
        [%d] = function(bc, reg, stk, push, pop)
            push(-pop())
        end]], instructions.NEG.opcode))
    end
    
    -- NOT
    if instructions.NOT then
        table.insert(handlers, string.format([[
        [%d] = function(bc, reg, stk, push, pop)
            push(not pop())
        end]], instructions.NOT.opcode))
    end
    
    -- LEN
    if instructions.LEN then
        table.insert(handlers, string.format([[
        [%d] = function(bc, reg, stk, push, pop)
            push(#pop())
        end]], instructions.LEN.opcode))
    end
    
    -- CONCAT
    if instructions.CONCAT then
        table.insert(handlers, string.format([[
        [%d] = function(bc, reg, stk, push, pop)
            local b = pop()
            local a = pop()
            push(tostring(a) .. tostring(b))
        end]], instructions.CONCAT.opcode))
    end
    
    -- EQ
    if instructions.EQ then
        table.insert(handlers, string.format([[
        [%d] = function(bc, reg, stk, push, pop)
            local b = pop()
            local a = pop()
            push(a == b)
        end]], instructions.EQ.opcode))
    end
    
    -- NE
    if instructions.NE then
        table.insert(handlers, string.format([[
        [%d] = function(bc, reg, stk, push, pop)
            local b = pop()
            local a = pop()
            push(a ~= b)
        end]], instructions.NE.opcode))
    end
    
    -- LT
    if instructions.LT then
        table.insert(handlers, string.format([[
        [%d] = function(bc, reg, stk, push, pop)
            local b = pop()
            local a = pop()
            push(a < b)
        end]], instructions.LT.opcode))
    end
    
    -- LE
    if instructions.LE then
        table.insert(handlers, string.format([[
        [%d] = function(bc, reg, stk, push, pop)
            local b = pop()
            local a = pop()
            push(a <= b)
        end]], instructions.LE.opcode))
    end
    
    -- GT
    if instructions.GT then
        table.insert(handlers, string.format([[
        [%d] = function(bc, reg, stk, push, pop)
            local b = pop()
            local a = pop()
            push(a > b)
        end]], instructions.GT.opcode))
    end
    
    -- GE
    if instructions.GE then
        table.insert(handlers, string.format([[
        [%d] = function(bc, reg, stk, push, pop)
            local b = pop()
            local a = pop()
            push(a >= b)
        end]], instructions.GE.opcode))
    end
    
    -- AND
    if instructions.AND then
        table.insert(handlers, string.format([[
        [%d] = function(bc, reg, stk, push, pop)
            local b = pop()
            local a = pop()
            push(a and b)
        end]], instructions.AND.opcode))
    end
    
    -- OR
    if instructions.OR then
        table.insert(handlers, string.format([[
        [%d] = function(bc, reg, stk, push, pop)
            local b = pop()
            local a = pop()
            push(a or b)
        end]], instructions.OR.opcode))
    end
    
    -- JMP
    if instructions.JMP then
        table.insert(handlers, string.format([[
        [%d] = function(bc, reg, stk, push, pop, readShort)
            pc = readShort(bc) + 1
        end]], instructions.JMP.opcode))
    end
    
    -- JMPIF
    if instructions.JMPIF then
        table.insert(handlers, string.format([[
        [%d] = function(bc, reg, stk, push, pop, readShort)
            local addr = readShort(bc)
            if pop() then
                pc = addr + 1
            end
        end]], instructions.JMPIF.opcode))
    end
    
    -- JMPNOT
    if instructions.JMPNOT then
        table.insert(handlers, string.format([[
        [%d] = function(bc, reg, stk, push, pop, readShort)
            local addr = readShort(bc)
            if not pop() then
                pc = addr + 1
            end
        end]], instructions.JMPNOT.opcode))
    end
    
    -- CALL
    if instructions.CALL then
        table.insert(handlers, string.format([[
        [%d] = function(bc, reg, stk, push, pop, readShort)
            local argc = readShort(bc)
            local fn = pop()
            local args = {}
            for i = argc, 1, -1 do
                args[i] = pop()
            end
            local result = fn(table.unpack(args))
            push(result)
        end]], instructions.CALL.opcode))
    end
    
    -- RET
    if instructions.RET then
        table.insert(handlers, string.format([[
        [%d] = function(bc, reg, stk, push, pop, readShort)
            local retc = readShort(bc)
            if retc == 0 then
                return nil
            else
                return pop()
            end
        end]], instructions.RET.opcode))
    end
    
    -- PUSH
    if instructions.PUSH then
        table.insert(handlers, string.format([[
        [%d] = function(bc, reg, stk, push, pop, readShort)
            local idx = readShort(bc)
            push(reg[idx])
        end]], instructions.PUSH.opcode))
    end
    
    -- POP
    if instructions.POP then
        table.insert(handlers, string.format([[
        [%d] = function(bc, reg, stk, push, pop)
            pop()
        end]], instructions.POP.opcode))
    end
    
    -- GETGLOBAL
    if instructions.GETGLOBAL then
        table.insert(handlers, string.format([[
        [%d] = function(bc, reg, stk, push, pop)
            local name = pop()
            push(_G[name])
        end]], instructions.GETGLOBAL.opcode))
    end
    
    return "        " .. table.concat(handlers, ",\n        ")
end

return VMGenerator
