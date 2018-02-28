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

    if #StudentAccount == 1 then
        local messages = SendStudentEvents(1)
        for i,p in ipairs(messages) do
            love.graphics.draw(p, 100, 100)
        end
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
        ["NewStudentAccount"] = function(peer, forename, surname, email, password) CreateNewStudent(peer, forename, surname, email, password) end,
        ["NewTeacherAccount"] = function(peer, forename, surname, email, password) CreateNewTeacher(peer, forename, surname, email, password) end,
        ["StudentLogin"] = function(peer, email, password) LoginStudent(peer, email, password) end,
        ["TeacherLogin"] = function(peer, email, password) LoginTeacher(peer, email, password) end,
        ["NewClass"] = function(peer, classname) MakeNewClass(peer, classname) end,
        ["StudentClassJoin"] = function(peer, classJoinCode) AddStudentToClass(peer, classJoinCode) end,

        -- Potentiall need fixing:

        ["NewTeacher"] = function(peer, forename, surname, email, password) AddNewTeacher(peer, forename, surname, email, password) end,

        ["NewTournament"] = function(peer, classname, maxduration, matches) MakeNewTournament(peer, classname, maxduration, matches) end,
        ["NextGame"] = function(peer) SendNextGame(peer) end,
        ["RequestReport"] = function(peer, studentID) end,                           -- Request a student's report
        ["SendReport"] = function(peer, teacherID, report) end,                      -- Send student report to teacher
        ["OfferStudentID"] = function(peer, studentID, password) ReceiveStudentID(peer, tonumber(studentID), password) end,           -- Non-new student attempting to connect
        ["OfferTeacherID"] = function(peer, teacherID, password) ReceiveTeacherID(peer, tonumber(teacherID), password) end            -- Non-new teacher attempting to connect
    }
    if messageResponses[first] then messageResponses[first](event.peer, unpack(messageTable))end
end

function split(peerMessage)
    local messageTable = {}
    peerMessage = peerMessage.."....."
    local length = #peerMessage
    local dots = 0
    local last = 1
    for i = 1,length do
        local c = string.sub(peerMessage, i, i)
        if c == '.' then
            dots = dots + 1
        end
        if dots == 5 then
            local word = string.sub(peerMessage, last, i-5)
            last = i + 1
            table.insert(messageTable, word)
            dots = 0
        end
    end

    --[[
    for word in peerMessage:gmatch("[^,%s]+") do         -- Possibly write a better expression - try some basic email regex?
        table.insert(messageTable, word)
    end
    ]]--
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
    local teacherID = peerInfo.ID                       -- Only valid if the peer is a teacher (must be a teacher to reach this subroutine)
    if TeacherClassExists(classname, teacherID) then 
        SendInfo(peer, "NewClassReject" + classname + "This class already exists. Please choose a different name.", false, peerInfo.ID)                     
    else
        local classJoinCode = generateClassJoinCode()
        addClass(classname, teacherID, classJoinCode)
        SendInfo(peer, "NewClassAccept" + classname + classJoinCode, false, peerInfo.ID)
    end
end

function AddStudentToClass(peer, classJoinCode)
    local peerInfo = IdentifyPeer(peer)
    local studentID = peerInfo.ID
    local class = ConfirmClassCode(classJoinCode)
    if class then
        local classAddSuccess = AddStudentClass(studentID, class.classID) 
        if classAddSuccess then
            SendInfo(peer, "JoinClassSuccess" + class.className, true, studentID)
        else
            SendInfo(peer, "JoinClassFail" + "You are already in a class!", true, studentID)
            return
        end
    else
        SendInfo(peer, "JoinClassFail" + "Invalid Class Code", true, studentID)
        return
    end
    local teacherID = class.teacherID
    local teacherPeer = FindTeacher(teacherID)
    SendInfo(teacherPeer, "StudentJoinedClass" + class.className + studentID, false, teacherID)
end

function MakeNewTournament(peer, classname, maxduration, matches)
    local peerInfo = IdentifyPeer(peer)
    local teacherID = peerInfo.ID
    local classID = FindClassID(teacherID, classname)
    if ClassTournamentExists(classID) then
        SendInfo(peer, "NewTournamentReject" + classname + "This class is already in a tournament. Please wait for it to finish.", false, peerInfo.ID)
    else
        addTournament(classID, maxduration, matches)
        SendInfo(peer, "NewTournamentAccept" + classname, false, peerInfo.ID)
    end
end

function SendNextGame(peer)
    local peerInfo = IdentifyPeer(peer)
    local studentID = peerInfo.ID
    local classID = FindStudentClass(studentID)
    if not ClassTournamentExists(classID) then          -- Conditions to check for next match
        SendInfo(peer, "NoCurrentTournament" + classID, true, studentID)
        return
    end
    local gameID = FindTournamentGame(studentID)     -- Send student the info for both players. The student program calculates the questions, easing the central server's workload.
    if gameID then 
        local levels = FindGameLevels(gameID)
        SendInfo(peer, "NextGame" + levels[1] + levels[2], true, studentID)
    else
        SendInfo(peer, "NoNewGames", true, studentID)
    end

end

function CreateNewStudent(peer, forename, surname, email, password)
    if EmailTaken(email) then
        peer:send("NewAccountReject" + "This email address is already in use. Please use a different email.")
    else
        local newStudentID = addStudentAccount(forename, surname, email, password)
        peer:send("NewAccountAccept")
    end
end

function CreateNewTeacher(peer, forename, surname, email, password)
    if EmailTaken(email) then
        peer:send("NewAccountReject" + "This email address is already in use. Please use a different email.")
    else
        local newTeacherID = addTeacherAccount(forename, surname, email, password)
        peer:send("NewAccountAccept" + TeacherAccount[newTeacherID].Forename + TeacherAccount[newTeacherID].Surname + TeacherAccount[newTeacherID].EmailAddress + TeacherAccount[newTeacherID].Password)
    end
end

function LoginStudent(peer, email, password)
    local StudentID = ValidateStudentLogin(email, password)
    if StudentID then
        local className = FindStudentClassName(StudentID)
        peer:send("LoginSuccess" + (className or ""))               -- Send all info needed by the student: classname, level
        SendStudentMissedEvents(peer, StudentID)
        addClient(peer, true, StudentID)
    else 
        peer:send("LoginFail" + "Please verify all fields are correct.")
    end
end

function LoginTeacher(peer, email, password)
    local TeacherID = ValidateTeacherLogin(email, password)
    if TeacherID then
        local teacherInfo = FetchTeacherInfo(TeacherID)
        peer:send("LoginSuccess" + teacherInfo.students + teacherInfo.classes + teacherInfo.tournaments)    -- Send all info needed by the teacher: classes
        SendTeacherMissedEvents(peer, teacherID)
        addClient(peer, false, TeacherID)
    else 
        peer:send("LoginFail" + "Please verify all fields are correct.")
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

function listEvent(message, isStudent, ID)
    if isStudent then 
        addStudentMissedEvent(ID, message)
    elseif not isStudent then
        addTeacherMissedEvent(ID, message)
    end
end

function SendStudentMissedEvents(peer, ID)
    local missedEvents = {}
    missedEvents = SendStudentEvents(ID)
    for i,message in ipairs(missedEvents) do
        SendInfo(peer, message, true, ID)
    end
    ClearStudentEvents(ID)
end

function SendTeacherMissedEvents(peer, ID)
    local missedEvents = {}
    missedEvents = SendTeacherEvents(ID)
    for i,message in ipairs(missedEvents) do
        SendInfo(peer, message, false, ID)
    end
    ClearTeacherEvents(ID)
end




