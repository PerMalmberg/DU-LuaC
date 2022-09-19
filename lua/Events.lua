--- Adds event handling to an object's instance
---@param obj T The object you are adding events to
function library.addEventHandlers(obj)
  -- Does nothing when obj is null or already has events
  if (not obj) or (obj.onEvent and obj.triggerEvent) then
    return false
  end

  -- Makes sure we're applying it to a table
  if 'table' ~= type(obj) then
    error('You can only add event handlers to table objects!')
  end

  -- Adds a event handler counter
  local eventHandlerIds = 0

  -- This will store the event handlers
  local eventHandlers = {}

  -- Adds event handler
  obj.onEvent = (function (self, event, handler, selfRef)
    -- Self reference passed to the event
    selfRef = selfRef or self
    if 'table' ~= type(selfRef) then
      error('The value of self must be a table!')
    end

    -- If event handler is not a function or callable object, trigger an error
    local signalHandlerError = function(arg)
       error(string.format('Event handler must be a function or a callable object, got "%s"', type(arg)))
    end

    if 'table' == type(handler) then
      -- We got a table, check if it is callable
      local mt = getmetatable(handler)
      if mt and mt.__call then
        local originalHander = handler
        -- The table is a callable, redefine the handler to call the object
        handler = function(s, ...)
          originalHander(s, ...)
        end
      else
        signalHandlerError(handler)
      end
    elseif 'function' ~= type(handler) then
      signalHandlerError(handler)
    end

    -- Adds event handler array if missing
    if not eventHandlers[event] then
      eventHandlers[event] = {}
    end

    -- Adds the actual handler and returns a number identifying it (for removal)
    eventHandlerIds = eventHandlerIds + 1
    eventHandlers[event][eventHandlerIds] = { handler, selfRef }

    -- Returns the ID for later removal
    return eventHandlerIds
  end)

  -- Removes event handler
  obj.clearEvent = (function (self, event, handlerId)
    if eventHandlers[event] and eventHandlers[event][handlerId] then
      eventHandlers[event][handlerId] = nil
    end
  end)

  -- Triggers event
  obj.triggerEvent = (function (self, event, ...)
    -- Processes each of the handlers
    for _, handler in pairs(eventHandlers[event] or {}) do
      handler[1](handler[2], ...)
    end
  end)

  -- Returns true to indicate success
  return true
end