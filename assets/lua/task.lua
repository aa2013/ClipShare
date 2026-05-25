-- ===============
-- 此库地址：https://github.com/aa2013/lua-async-await
-- 此库是根据 https://github.com/walterCui/lua-async 修改而来
-- 因原作者的库分散在了多个文件且命名部分跟随 C#, 部分跟随lua，所以统一修改并合并到一个文件中
-- ===============
local co = coroutine
local isFunction = function(fun)
    return "function" == type(fun);
end

-- ================
-- waitable
-- ================
local getAwaiter = function()
    local task = {
        isCompleted = false,
        onCompletedList = {},
        result = nil,
    };

    function task:onCompleted(fun)
        if isFunction(fun) then
            if self.isCompleted then
                fun(self.result)
            else
                table.insert(self.onCompletedList, fun)
            end
        end
    end

    function task:done ()
        if self.isCompleted then
            return
        end
        self.isCompleted = true;
        for i, v in ipairs(self.onCompletedList) do
            local ok, err = pcall(v, self.result)
            if not ok then
                error(err)
            end
        end
    end
    return task;
end

local isAwaiter = function(awaiter)
    if awaiter == nil or "table" ~= type(awaiter) or awaiter.isCompleted == nil then
        return false
    end

    if awaiter.onCompleted == nil or "function" ~= type(awaiter.onCompleted) then
        return false
    end
    return true
end

-- ================
-- async
-- ================
local async = function(fun)
    return function(...)
        if not isFunction(fun) then
            return
        end

        local thread = co.create(fun)
        local next = nil
        local awaiter = getAwaiter()
        next = function(...)
            local state, moveNext = co.resume(thread, ...)
            if not state then
                awaiter.error = moveNext
                awaiter:done()
                return
            end
            if "dead" ~= co.status(thread) then
                if isFunction(moveNext) then
                    moveNext(next)
                end
            else
                awaiter.result = moveNext
                awaiter:done()
            end
        end

        next(...)

        return awaiter
    end
end

local await = function(awaiter)

    if not co.isyieldable() then
        error("not yield")
        return
    end

    if awaiter == nil or "table" ~= type(awaiter) then
        return
    end

    if awaiter.isCompleted == nil or awaiter.isCompleted then
        if awaiter.error ~= nil then
            error(awaiter.error, 0)
        end
        return awaiter.result
    end

    local ok, value = co.yield(function(continuation)
        if awaiter.isCompleted then
            continuation(awaiter.error == nil, awaiter.error or awaiter.result)
        else
            awaiter:onCompleted(function()
                continuation(awaiter.error == nil, awaiter.error or awaiter.result)
            end)
        end
    end)
    if not ok then
        error(value, 0)
    end
    return value
end

local asyncWrapper = function(fun, ...)
    async(fun)(...)
end

-- ================
-- Task
-- ================

local taskWhenAny = function(...)
    local task = getAwaiter()
    local awaiters = { ... }

    if #awaiters == 0 then
        task:done()
        return task
    end
    local done = function()
        task:done()
    end
    for i, v in ipairs(awaiters) do
        if isAwaiter(v) then
            if v.isCompleted then
                task:done()
            else
                v:onCompleted(done)
            end
        end
    end

    return task
end

local taskWhenAll = function(...)
    local task = getAwaiter()
    local awaiters = { ... }
    local taskLen = #awaiters

    if taskLen == 0 then
        task:done()
        return task
    end

    local doneCount = 0
    local done = function()
        doneCount = doneCount + 1
        if doneCount >= taskLen then
            task:done()
        end
    end
    for i, v in ipairs(awaiters) do
        if isAwaiter(v) then
            if v.isCompleted then
                done()
            else
                v:onCompleted(done)
            end
        end
    end

    return task
end

return {
    async = async,
    await = await,
    asyncWrapper = asyncWrapper,
    create = getAwaiter,
    whenAny = taskWhenAny,
    whenAll = taskWhenAll,
}
