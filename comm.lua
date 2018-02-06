-- This central server communicates with both students and teachers, enabling conmmunication between them.
-- This manages everything from creating and joining classes to tournament participation.
-- Functions in Pascal Case send are based on responding to a peer. 
-- Functions in lowerCamelCase are mainly for the program's use.

Server = Object:extend()

require "enet"

local clients = {}                      -- Keep track of connected apps in the format: { peer, isStudent, ID } ID IS A STRING IN THIS CASE
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
    elseif event.type == "receive" then 
        respondToMessage(event)
    elseif event.type == "disconnect" then
        removeClient(event.peer)
    end
end

function respondToMessage(event)   
    local messageTable = split(event.data)
    local first = messageTable[1]                   -- Find the description attached to the message
    table.remove(messageTable, 1)                   -- Remove the description, leaving only the rest of the data
    local messageResponses = {                      -- Table specfifying the appropriate response to each message description
        ["NewStudent"] = function(peer, forename, surname, email, password, classCode) AddNewStudent(peer, forename, surname, email, password, classCode) end,
        ["NewTeacher"] = function(peer, forename, surname, email, password) AddNewTeacher(peer, forename, surname, email, password) end,
        ["NewClass"] = function(peer, classname) MakeNewClass(peer, classname) end,
        ["NewTournament"] = function(peer, classname, maxduration, matches) MakeNewTournament(peer, classname, maxduration, matches) end,
        ["NextMatch"] = function(peer) SendNextMatch(peer) end,
        ["RequestReport"] = function(peer, studentID) end,                           -- Request a student's report
        ["SendReport"] = function(peer, teacherID, report) end,                      -- Send student report to teacher
        ["OfferStudentID"] = function(peer, studentID, password) ReceiveStudentID(peer, tonumber(studentID), password) end,           -- Non-new student attempting to connect
        ["OfferTeacherID"] = function(peer, teacherID, password) ReceiveTeacherID(peer, tonumber(teacherID), password) end            -- Non-new teacher attempting to connect
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

function addClient(peer, isStudent, ID)
    table.insert(clients, { peer = peer, isStudent = isStudent, ID = ID })
end

function removeClient(peer)
    for i, client in ipairs(clients) do
        if client.peer == peer then
            table.remove(clients, i)
        end
    end
end

function SendInfo(peer, message, isStudent, ID)     -- Sends outgoing information. Also checks is peer is still online. NOT USED FOR NEW STUDENTS
    local user = IdentifyPeer(peer)
    if user then                                    -- Checks if peer is online. Clearly only valid if user is not new.
        peer:send(message)
    else                                            -- If user is not new and not online, store message for later
        listEvent(message, isStudent, ID)
    end
end

function MakeNewClass(peer, classname)
    local peerInfo = IdentifyPeer(peer)
    local teacherID = peerInfo.ID                       -- Only valid if the peer is a teacher
    if TeacherClassExists(classname, teacherID) then 
        SendInfo(peer, "NewClassReject" + classname + "This class already exists. Please choose a different name.", false, peerInfo.ID)                     
    else
        local classJoinCode = generateClassJoinCode()
        addClass(classname, teacherID, classJoinCode)
        SendInfo(peer, "NewClassAccept" + classname + classJoinCode, false, peerInfo.ID)
    end
end

function MakeNewTournament(peer, classname, maxduration, matches)
    local peerInfo = IdentifyPeer(peer)
    local teacherID = peerInfo.ID
    if TeacherTournamentExists(classname, teacherID) then
        SendInfo(peer, "NewTournamentReject" + classname + "This class is already in a tournament. Please wait for it to finish.", false, peerInfo.ID)
    else
        addTournament(classname, maxduration, matches)
        SendInfo(peer, "NewTournamentAccept" + classname, false, peerInfo.ID)
    end
end

function SendNextMatch(peer)
    local peerInfo = IdentifyPeer(peer)
    local studentID = peerInfo.ID
    local classname = FindStudentClass(studentID)
    if not TeacherTournamentExists(classname) then          -- Conditions to check for next match
        SendInfo(peer, "NoCurrentTournament", true, studentID)
        return
    end
    local studentsInfo = FindTournamentMatch(studentID)     -- Send student the info for both players. The student program calculates the questions, easing the central server's workload.
    if studentsInfo then 
        SendInfo(peer, "NextMatch" + table.serialize(studentsInfo), true, studentID)
    else
        SendInfo(peer, "NoNewMatches", true, studentID)
    end


end

function AddNewStudent(peer, forename, surname, email, password, classCode)
    local classInfo = ConfirmClassCode(classCode)
    local className = classInfo.className
    local teacherID = classInfo.TeacherID
    if EmailTaken(email) then
        peer:send("NewStudentReject" + "This email address is already in use. Please use a different email.")
    elseif className == "" or className == nil then                 -- If the class code given wasn't valid
        peer:send("NewStudentReject" + "This class code is invalid. Please ask your teacher for help.")
    else
        local newStudentID = addStudentAccount(forename, surname, email, password, className)
        local teacherPeer = FindTeacher(teacherID)          -- Will be false if teacher is not online
        peer:send("NewStudentAccept" + newStudentID + className)
        SendInfo(teacherPeer, "NewStudentAccept" + forename + surname + email + className, false, teacherID)
        addClient(peer, true, newStudentID)
    end
end

function AddNewTeacher(peer, forename, surname, email, password)
    if EmailTaken(email) then
        peer:send("NewTeacherReject" + "This email address is already in use. Please use a different email.")
    else
        local newTeacherID = addTeacherAccount(forename, surname, email, password)
        peer:send("NewTeacherAccept" + newTeacherID)
        addClient(peer, false, newTeacherID)
    end
end

function IdentifyPeer(peer)
    for i, client in ipairs(clients) do
        if client.peer == peer then
            return { isStudent = client.isStudent, ID = client.ID}
        end
    end
    return false
end

function FindTeacher(teacherID)
    for i, client in ipairs(clients) do
        if not client.isStudent and client.ID == teacherID then
            return client.peer
        end
    end
    return false
end

function ReceiveStudentID(peer, studentID, password)
    if ValidateStudentID(studentID, password) then
        peer:send("WelcomeBackStudent")
        addClient(peer, true, studentID)
        sendStudentMissedEvents(peer, studentID)
    end
end

function ReceiveTeacherID(peer, teacherID, password)
    if ValidateTeacherID(teacherID, password) then
        peer:send("WelcomeBackTeacher")
        addClient(peer, false, teacherID)
        sendTeacherMissedEvents(peer, teacherID)
    end
end

function listEvent(message, isStudent, ID)
    if isStudent then 
        AddStudentEvent(ID, message)
    elseif not isStudent then
        AddTeacherEvent(ID, message)
    end
end

function sendStudentMissedEvents(peer, ID)
    local missedEvents = {}
    missedEvents = SendStudentEvents(ID)
    for i,message in ipairs(missedEvents) do
        SendInfo(peer, message, true, ID)
    end
    ClearStudentEvents(ID)
end

function sendTeacherMissedEvents(peer, ID)
    local missedEvents = {}
    if ID ~= 1 then return end
    missedEvents = SendTeacherEvents(ID)
    for i,message in ipairs(missedEvents) do
        SendInfo(peer, message, false, ID)
    end
    ClearTeacherEvents(ID)
end


