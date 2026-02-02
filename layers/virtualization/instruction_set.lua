--[[
    Custom Instruction Set Generator
    Generates a unique set of VM instructions
]]

local InstructionSet = {}
InstructionSet.__index = InstructionSet

-- Base instruction types
InstructionSet.BASE_OPCODES = {
    "NOP",       -- No operation
    "LOAD",      -- Load constant
    "STORE",     -- Store to variable
    "FETCH",     -- Fetch variable
    "ADD",       -- Addition
    "SUB",       -- Subtraction
    "MUL",       -- Multiplication
    "DIV",       -- Division
    "MOD",       -- Modulo
    "POW",       -- Power
    "NEG",       -- Negation
    "NOT",       -- Logical not
    "LEN",       -- Length
    "CONCAT",    -- String concatenation
    "EQ",        -- Equal
    "NE",        -- Not equal
    "LT",        -- Less than
    "LE",        -- Less or equal
    "GT",        -- Greater than
    "GE",        -- Greater or equal
    "AND",       -- Logical and
    "OR",        -- Logical or
    "JMP",       -- Unconditional jump
    "JMPIF",     -- Jump if true
    "JMPNOT",    -- Jump if false
    "CALL",      -- Function call
    "RET",       -- Return
    "NEWTABLE",  -- Create table
    "SETTABLE",  -- Set table field
    "GETTABLE",  -- Get table field
    "GETGLOBAL", -- Get global
    "SETGLOBAL", -- Set global
    "PUSH",      -- Push to stack
    "POP",       -- Pop from stack
    "DUP",       -- Duplicate top of stack
    "SWAP",      -- Swap top two stack items
}

function InstructionSet.new(parent)
    local self = setmetatable({}, InstructionSet)
    
    self.parent = parent
    self.random = parent.random
    self.config = parent.config
    
    return self
end

function InstructionSet:generate()
    local instructions = {}
    local usedOpcodes = {}
    
    -- Shuffle base opcodes
    local shuffledBases = {}
    for _, op in ipairs(self.BASE_OPCODES) do
        table.insert(shuffledBases, op)
    end
    self.random:shuffle(shuffledBases)
    
    -- Assign random opcodes
    for i, name in ipairs(shuffledBases) do
        local opcode
        repeat
            opcode = self.random:int(0, 255)
        until not usedOpcodes[opcode]
        
        usedOpcodes[opcode] = true
        
        instructions[name] = {
            name = name,
            opcode = opcode,
            index = i,
        }
    end
    
    -- Generate opcode lookup table
    instructions._byOpcode = {}
    for name, instr in pairs(instructions) do
        if type(instr) == "table" and instr.opcode then
            instructions._byOpcode[instr.opcode] = instr
        end
    end
    
    return instructions
end

function InstructionSet:getOpcode(instructions, name)
    local instr = instructions[name]
    return instr and instr.opcode or nil
end

function InstructionSet:getByOpcode(instructions, opcode)
    return instructions._byOpcode[opcode]
end

return InstructionSet
