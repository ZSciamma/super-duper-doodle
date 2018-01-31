Server = Object:extend()

require "enet"

local clients = {}                      -- Keep track of connected apps in the format: { peer, isStudent, ID }
local events = {}

function Server:new()
    host = enet.host_create(serverLoc)                -- At home on Mezon2G
end

function Server:draw()
    love.graphics.setColor(0, 0, 0)
    love.graphics.print("Events:", 10, 150)
    love.graphics.print("Clients:", love.graphics.getWidth() - 305, 150)
    for i, event in ipairs(events) do
        love.graphics.print(event.peer:index().." says "..event.data, 15, 200 + 15 * i)
    end

    for i,client in ipairs(clients) do
        love.graphics.print("ClientNo: "..client.peer:index()..", Is Student: "..tostring(client.isStudent)..", ID: "..client.ID, love.graphics.getWidth() - 300, 200 + 15 * i)
    end
end


function Server:update(dt)
    event = host:service(100)
    if event then 
        table.insert(events, event)
        handleEvent(event) 
    end
end

function handleEvent(event)
    if event.type == "connect" then
        serverPeer = event.peer
        if (not TeacherID) and profileComplete then
            event.peer:send("TeacherJoinRequest" + myForename + mySurname + myEmail)
        end
    elseif event.type == "receive" then 
        respondToMessage(event)
    elseif event.type == "disconnect" then
        --removeClient(event.peer)
    end
end

function respondToMessage(event)   
    local messageTable = split(event.data)
    local first = messageTable[1]                   -- Find the description attached to the message
    table.remove(messageTable, 1)                   -- Remove the description, leaving only the rest of the data
    local messageResponses = {                      -- Table specfifying the appropriate response to each message description
        ["NewStudent"] = function(peer, forename, surname, email, password, className) AddNewStudent(peer, forename, surname, email, password, className) end,
        ["NewTeacher"] = function(peer, forename, surname, email, password) AddNewTeacher(peer, forename, surname, email, password) end,
        ["NewClass"] = function(peer, classname) MakeNewClass(peer, classname) end,
        ["RequestReport"] = function(peer, studentID) end,                           -- Request a student's report
        ["SendReport"] = function(peer, teacherID, report) end,                      -- Send student report to teacher
        ["StudentID"] = function(peer, studentID) receivestudentID(studentID) end
    }
    if messageResponses[first] then messageResponses[first](event.peer, unpack(messageTable))end
end

function split(peerMessage)
    local messageTable = {}
    for word in peerMessage:gmatch("[^%s,]+") do         -- Possibly write a better expression - try some basic email regex?
        table.insert(messageTable, word)
    end
    return messageTable
end

function MakeNewClass(peer, classname)
    local peerInfo = IdentifyTeacher(peer)
    local teacherID = peerInfo.ID                       -- Only valid if the peer is a teacher, as verified by the next if statement (but this shouldn't be possible)
    if peerInfo.isStudent or TeacherClassExists(classname, teacherID) then 
        peer:send("NewClassReject" + classname + "This class already exists. Please choose a different name.")                     
    else
        local classJoinCode = generateClassJoinCode()
        addClass(classname, teacherID, classJoinCode)
        peer:send("NewClassAccept" + classname + classJoinCode)
    end
end

function AddNewStudent(peer, forename, surname, email, password, classCode)
    local className = ConfirmClassCode(classCode)
    if StudentEmailTaken(email) then
        peer:send("NewStudentReject" + "This email address is already in use. Please use a different email.")
    elseif className == "" then                 -- If the class code given wasn't valid
        peer:send("NewStudentReject" + "This class code is invalid. Please ask your teacher for help.")
    else
        local newStudentID = addStudentAccount(forename, surname, email, password, className)
        peer:send("NewStudentAccept" + newStudentID)
        table.insert(clients, { peer = peer, isStudent = true, ID = newStudentID })
    end
end

function AddNewTeacher(peer, forename, surname, email, password)
    if TeacherEmailTaken(email) then
        peer:send("NewTeacherReject" + "This email address is already in use. Please use a different email.")
    else
        local newTeacherID = addTeacherAccount(forename, surname, email, password)
        peer:send("NewTeacherAccept" + newTeacherID)
        table.insert(clients, { peer = peer, isStudent = false, ID = newTeacherID })
    end
end

function StudentClassAcceptRequest(peer, forename, surname, email, classname)        
    -- Ask the teacher whether or not they accept the student
    if true then

        peer:send("AcceptJoinRequest" + forename + surname + email + classname)
    end
end

function IdentifyTeacher(peer)
    local peerIndex = peer.index
    for i, client in ipairs(clients) do
        if client.peer == peer then
            return { isStudent = client.peer.isStudent, ID = client.peer.ID}
        end
    end
    return false
end


