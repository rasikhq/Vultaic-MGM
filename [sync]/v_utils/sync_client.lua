data = {}

function setArenaData(element, key, value)
    if not data[element] then
        data[element] = {}
    end
    if getElementData(element, key) == value then
        return false
    end
    data[element][key] = true
    setElementData(element, key, value, false)
    local key, value = transformData(key, value)
    triggerServerEvent("onClientChangeArenaData", localPlayer, element, key, value)
end

function getArenaData(element, key)
    return getElementData(element, key)
end

addEvent("onArenaDataChanged", true)
addEventHandler("onArenaDataChanged", root,
function(key, value)
    if not key then
        if isElement(source) and data[source] then
            for key, value in pairs(data[source]) do
                setElementData(source, key, nil, false)
            end
        end
    else
        local key, value = replaceDataIDs(key, value)
        if not data[source] then
            data[source] = {}
        end
        data[source][key] = true
        setElementData(source, key, value, false)
        triggerEvent("onClientArenaDataChanged", source, key, value)
    end
end, true, "high")

addEvent("receiveArenaData", true)
addEventHandler("receiveArenaData", root,
function(newData)
    for element, elementData in pairs(data) do
        if isElement(element) then
            for key, value in pairs(elementData) do
                setElementData(element, key, nil, false)
            end
        end
    end
    data = newData
    for element, elementData in pairs(data) do
        if isElement(element) then
            for key, value in pairs(elementData) do
                local key, value = replaceDataIDs(key, value)
                setElementData(element, key, value, false)
            end
        end
    end
end, true, "high")