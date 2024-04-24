os.pullEvent = os.pullEventRaw
local w, h = term.getSize()

local function pc(y, msg, c)
    local x = (w - string.length(msg)) / 2

    term.setCursorPos(x,y)
    term.clearLine()

    if (not c) then
        term.print(msg)
    elseif c then
        term.setTextColor(c)
        term.print(msg)
        term.setTextColor(colors.white)
    end
end

local modem = peripheral.find("modem")
if (not modem) then
    term.clear()
    error(pc(2, "No wireless modem attached", colors.red))
elseif (not modem.isWireless()) then
    term.clear()
    error(pc(2, "Modem is not wireless", colors.red))
end

peripheral.find("modem", rednet.open())

pc(2, "Type ftp action below")
pc(3, "Send / Receive")
term.setCursorPos(((w - 8) /2), 5)

local option = read()
local option_lower = string.lower(option)

local function get()
    local MyId = os.getComputerID()
    local fileToWrite = nil
    local otherId, FuncCode = rednet.receive()

    if FuncCode == "GETFILE" then
        local otherId, fileName = rednet.receive()
        if fileName then
            fileToWrite = fs.open(fileName, "w")
            rednet.send(otherId, "GOTNAME")
            local otherId, FileContent = rednet.receive()
            fileToWrite.write(FileContent)
            fileToWrite.close()
        else
            rednet.send(otherId, "ERROR_NAME")
            local otherId, fileName = rednet.receive()
            fileToWrite = fs.open(fileName, "w")
            local otherId, FileContent = rednet.receive()
            fileToWrite.write(FileContent)
            fileToWrite.close()
        end
    end

    term.clear()
    pc(2, "File : "..fileToWrite.." Received from ID : "..otherId)
    pc(3, "Open File?  Y/N")
    term.setCursorPos(((w - 15) /2), 5)
    local txt = read()
    if string.lower(txt) == "y" then
        shell.run(fileToWrite)
    else
        term.clear()
        pc(2, "Rebooting")
        os.sleep(2)
        os.reboot()
    end
end
local function send()
    pc(2, "File to send (Include path if in another folder or disk)")
    term.setCursorPos(((w - 56) /2), 4)
    local fileToSend = read()
    term.clear()
    pc(2, "Computer ID to send to (enter for none)")
    term.setCursorPos(((w - 39) /2), 4)
    local senderID = read()
    
    if fs.exists(fileToSend) then return 
    else 
        term.clear() pc(2, "File not found") 
        local string = "Did you forget a path? (disk/fileName  ../fileName  ../folder/filenName)"
        term.setCursorPos(((w - string.len(string)) /2), 4)
        error(string)
    end

    term.clear()
    pc(2, "Ensure computer is running file receive")
    rednet.send(senderID, "GETFILE")
    term.setCursorPos(((w - 39) /2), 3)
    textutils.slowPrint("Sending File : "..fileToSend.." To ID : "..senderID)
    rednet.send(senderID, fileToSend)
    local confirmCode = rednet.receive()
    if confirmCode == "GOTNAME" then
        local code = fs.open(fileToSend, "r")
        rednet.send(code.readAll())
        term.clear()
        pc(2, "File Sent, Rebooting in 3 seconds")
        os.sleep(3)
        os.reboot()
    elseif confirmCode == "ERROR_NAME" then
        rednet.send(senderID, fileToSend)
        os.sleep(1)
        local code = fs.open(fileToSend, "r")
        rednet.send(code.readAll())
        os.sleep(1)
        term.clear()
        pc(2, "File Sent, Rebooting in 3 seconds")
        os.sleep(3)
        os.reboot()
    end
end

if option_lower == "send" then
    term.clear()
    send()
    
elseif option_lower == "receive" then
    term.clear()
    get()
end