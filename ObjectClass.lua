---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by yangyiqiang.
--- DateTime: 2021/8/25 11:44


--- 自带对象池的ObjectClass
---
local _class = {} --virtual table
-- 自定义类型
local _class_type = {
    class = 1,
    instance = 2,
}

local object_pool = {object_dic = {}}
function object_pool:register(class_type)
    assert(class_type ~= nil)
    self.object_dic[class_type] = {}
end

function object_pool:release(obj)
    local pool = self.object_dic[obj._class_type]
    pool[#pool + 1] = obj
end

function object_pool:claim(class_type,...)
    assert(class_type ~= nil)
    local pool = self.object_dic[class_type]
    local obj = pool[#pool]
    if obj then
        -- 已经存在
        pool[#pool] = nil
        do
            local create
            create = function(c, ...)
                if c.super then
                    create(c.super, ...)
                end
                if c.ctor then
                    c.ctor(c, ...)
                end
            end
            create(obj, ...)
        end
        --print("get object from pool")
        return obj
    else
        -- 生成新对象
        local obj = {}
        obj.class_name = class_type.class_name
        obj._class_type = class_type
        obj.__type = _class_type.instance

        -- 在初始化之前注册基类方法
        setmetatable(obj, {
            __index = _class[class_type],
        })
        -- 调用初始化方法
        do
            local create
            create = function(c, ...)
                if c.super then
                    create(c.super, ...)
                end
                if c.ctor then
                    c.ctor(obj, ...)
                end
            end
            create(class_type, ...)
        end

        -- 注册release方法
        obj.__release = function(self)
            local now_super = self._class_type
            while now_super ~= nil do
                if now_super.__release then
                    now_super.__release(self)
                end
                now_super = now_super.super
            end
            object_pool:release(self)
        end
        return obj
    end
end

function object_class(class_name,super)
    assert(type(class_name) == "string" and #class_name > 0 ,"Invalid class name : ",class_name)
    -- 生成一个类类型
    local class_type = {}
    -- 在创建对象的时候自动调用
    class_type.class_name = class_name
    class_type.super = super
    class_type.new = function(...)
        return object_pool:claim(class_type,...)
    end

    local virtual_table = {}
    assert(_class[class_type] == nil, "Already defined class : ", class_name)
    _class[class_type] = virtual_table
    object_pool:register(class_type)

    setmetatable(class_type, {
        __newindex = function(t,k,v)
            virtual_table[k] = v
        end
    ,
        __index = virtual_table,
    })

    if super then
        setmetatable(virtual_table, {
            __index = function(t,k)
                local ret = _class[super][k]
                return ret
            end
        })
    end

    return class_type
end

-- test
--[[
local baseClass = object_class("baseClass")
function baseClass:ctor(a,b)
    print("baseClass:ctor()",a,b)
    self.name = "baseClass"
    self.a = a
    self.b = b
end

function baseClass:print()
    print(self.name,self.a,self.b)
end

function baseClass:release()
    print("baseClass:release()")
    self:__release()
end

local classA = object_class("classA",baseClass)
function classA:ctor(a,b)
    self.name = "classA"
    print("classA:ctor()",a,b)
    self.a = a
    self.b = b
end

function classA:release()
    print("classA:release()")
    self:__release()
end

local classB = object_class("classB",baseClass)
function classB:ctor(a,b)
    print("classB:ctor()",a,b)
    self.name = "classB"
    self.a = a
    self.b = b
end

function classB:release()
    print("classB:release()")
    self:__release()
end

local classC = object_class("classC",baseClass)
function classC:ctor(a,b)
    print("classC:ctor()",a,b)
    self.name = "classC"
    self.a = a
    self.b = b
end

function classC:release()
    print("classC:release()")
    self:__release()
end

local c = classC.new(100,59)
c:print()
c:release()

local cc = classC.new(100,59)
cc:print()
--]]