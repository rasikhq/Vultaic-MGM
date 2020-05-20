data = {}

addEvent("core:onPlayerJoinArena", true)
addEvent("core:onPlayerLeaveArena", true)
addEvent("onClientChangeArenaData", true)

function setArenaData(element, key, value, arenaElement)
    if not isElement(element) then
        return false
    end
    if not isElement(arenaElement) then
        if getElementType(element) == "arena" then
            arenaElement = element
        elseif getElementType(element) == "player" and isElement(getElementParent(element)) then
            arenaElement = getElementParent(element)
            if getElementType(arenaElement) ~= "arena" then
                return false  
            end
        else
            return false
        end
    end
    if not data[arenaElement] then
        data[arenaElement] = {}
        data[arenaElement][element] = {}
    elseif not data[arenaElement][element] then
        data[arenaElement][element] = {}
    end
    if type(value) ~= "table" and getElementData(element, key) == value then
        return false
    end
    setElementData(element, key, value, false)
    local key, value = transformData(key, value)
    data[arenaElement][element][key] = value
    triggerClientEvent(arenaElement, "onArenaDataChanged", element, key, value)
end

function getArenaData(element, key)
    return getElementData(element, key)
end

function sendArenaData()
    local arenaElement = getElementParent(source)
    if not isElement(arenaElement) or getElementType(arenaElement) ~= "arena" then
        return false
    end
    triggerClientEvent(source, "receiveArenaData", source, data[arenaElement] or {})
end
addEventHandler("core:onPlayerJoinArena", root, sendArenaData, true, "high")

function removePlayerArenaData()
    local arenaElement = getElementParent(source)
    if not isElement(arenaElement) or getElementType(arenaElement) ~= "arena" then
        return false
    end
    if data[arenaElement] and data[arenaElement][source] then
        for key, value in pairs(data[arenaElement][source]) do
            setElementData(source, key, nil, false)
        end
        data[arenaElement][source] = nil
    end
    triggerClientEvent(source, "receiveArenaData", source, {})
    triggerClientEvent(arenaElement, "onArenaDataChanged", source)
end
addEventHandler("core:onPlayerLeaveArena", root, removePlayerArenaData, true, "low")

function clientSetArenaData(element, key, value)
    local arenaElement = getElementParent(source)
    if not isElement(arenaElement) or getElementType(arenaElement) ~= "arena" then
        return false
    end
    local key, value = replaceDataIDs(key, value)
    setArenaData(element, key, value, arenaElement)
end
addEventHandler("onClientChangeArenaData", root, clientSetArenaData)