-- This central server communicates with both students and teachers, enabling conmmunication between them.
-- This manages everything from creating and joining classes to tournament participation.
-- Functions in Pascal Case include a message to be sent to a peer
-- Functions in lowerCamelCase are mainly for the server's internal use.

Server = Object:extend()

require "enet"

local clients = {}                      -- Keep track of connected apps in the format: { peer, isStudent, ID }. THE ID IS A STRING IN THIS CASE. The peer is an object used to communicate with the user (a feature of ENet).
local events = {}


-------------------- LOCAL FUNCTIONS:

local function CreateNewStudent(peer, forename, surname, email, password)    -- Create a new student account. First check if it is valid.
    if EmailTaken(email) then
        peer:send("NewAccountReject" + "This email address is already in use. Please use a different email.")
    else
        local newStudentID = addStudentAccount(forename, surname, email, password)
        peer:send("NewAccountAccept")
    end
end

local function CreateNewTeacher(peer, forename, surname, email, password)     -- Create a new teacher account. First check if it is valid.
    if EmailTaken(email) then                                           -- Prevents users creating multiple accounts with the same email. A user only needs one account; if a teacher wishes to create a student program, they can do so with a different email.
        peer:send("NewAccountReject" + "This email address is already in use. Please use a different email.")
    else
        local newTeacherID = addTeacherAccount(forename, surname, email, password)
        peer:send("NewAccountAccept" + TeacherAccount[newTeacherID].Forename + TeacherAccount[newTeacherID].Surname + TeacherAccount[newTeacherID].EmailAddress + TeacherAccount[newTeacherID].Password)
    end
end

local function identifyPeer(peer)         -- Given a peer object (a feature of ENet), return the user's information. This can be found in the list of clients online; if the peer is not found, then that user is not considered online (or has not logged in)
    for i, client in ipairs(clients) do
        if client.peer == peer then
            return { isStudent = client.isStudent, ID = client.ID}
        end
    end
    return false
end

local function findTeacherPeer(teacherID)     -- Return the peer object (a feature of ENet) given a teacher's ID. If no ID is found, the teacher is not currently online in the server's perspective.
    for i, client in ipairs(clients) do
        if not client.isStudent and client.ID == teacherID then
            return client.peer
        end
    end
    return false
end

local function findStudentPeer(studentID)             -- If a student is online, then return the peer object (used for communicating with them) from the client list. Otherwise, return false (student is offline)
    for i, client in ipairs(clients) do
        if client.isStudent and client.ID == studentID then
            return client.peer
        end
    end
    return false
end

local function split(peerMessage)     -- Splits every message received into the components: instruction and additional information.
    -- Each separate piece of information in the message is separated by the string: '.....'
    -- The function thereofore returns a table including each part of the message
    local messageTable = {}
    peerMessage = peerMessage..".....9"
    local length = #peerMessage
    local dots = 0
    local last = 1
    for i = 1,length do
        local c = string.sub(peerMessage, i, i)
        if c == '.' then
            dots = dots + 1
        else
            if dots >= 5 then
                local word = string.sub(peerMessage, last, i - 6)
                if word == "0" then word = "" end                     -- Account for the server sending blank info
                last = i
                table.insert(messageTable, word)
            end
            dots = 0
        end
    end
    return messageTable
end

local function addClient(peer, isStudent, ID)     -- Called when a user logs in. This adds the user to the list of connected clients
    table.insert(clients, { peer = peer, isStudent = isStudent, ID = ID })
end

local function removeClient(peer)
    for i, client in ipairs(clients) do
        if client.peer == peer then
            table.remove(clients, i)
        end
    end
end

local function listEvent(message, isStudent, ID)  -- When a student or teacher is offline, add the outgoing message to the appropriate MissedEvent table (Student or Teacher). This message is to be sent to them when they next come online.
    if isStudent then
        addStudentMissedEvent(ID, message)
    elseif not isStudent then
        addTeacherMissedEvent(ID, message)
    end
end

local function SendInfo(peer, message, isStudent, ID)     -- Sends outgoing information. Also checks is peer is still online. NOT USED FOR NEW STUDENTS.
    -- If the peer is online, the message is sent. Otherwise, the message is added to a list of missed events (separate lists for students and teachers)
    local user = identifyPeer(peer)
    if user then                                    -- Checks if peer is online. Clearly only valid if user is not new.
        peer:send(message)
    else                                            -- If user is not new and not online, store message for later
        listEvent(message, isStudent, ID)
    end
end

local function MakeNewClass(peer, classname)              -- Respond to teacher asking to create a new class. Checks whether the class is valid.
    local peerInfo = identifyPeer(peer)
    local teacherID = peerInfo.ID                       -- Only valid if the peer is a teacher (must be a teacher to reach this subroutine)
    if TeacherClassExists(classname, teacherID) then
        SendInfo(peer, "NewClassReject" + classname + "This class already exists. Please choose a different name.", false, peerInfo.ID)
    else
        local classJoinCode = GenerateClassJoinCode()
        addClass(classname, teacherID, classJoinCode)
        SendInfo(peer, "NewClassAccept" + classname + classJoinCode, false, peerInfo.ID)
    end
end


local function AddStudentToClass(peer, classJoinCode)     -- Respond to student asking to join a class (ie. when the student enters a joinCode).
    local peerInfo = identifyPeer(peer)
    local studentID = peerInfo.ID
    local student = StudentInfo(studentID)
    local class = ConfirmClassCode(classJoinCode)
    if class then
        local classAddSuccess = AddStudentClass(studentID, class.classID)
        if classAddSuccess then
            SendInfo(peer, "JoinClassSuccess" + class.className, true, studentID)
        else                                        -- Error handling: this should never be called. The student can't get to the joinCode screen if they are already in a class. This ensures the server will function as normal if this does happen.
            SendInfo(peer, "JoinClassFail" + "You are already in a class!", true, studentID)
            return
        end
    else
        SendInfo(peer, "JoinClassFail" + "Invalid Class Code", true, studentID)
        return
    end
    local teacherID = class.teacherID
    local teacherPeer = findTeacherPeer(teacherID)
    SendInfo(teacherPeer, "StudentJoinedClass" + studentID + student.Forename + student.Surname + student.Ratings + student.Level + class.className + student.Statistics, false, teacherID)
end

local function NotifyStudentsOfTournament(classID, roundTime, qsPerMatch)            -- Notifies all students in a class that a tournament has started. Called at very start of tournament.
    local studentIDs = FindStudentsInClass(classID)
    for i,studentID in ipairs(studentIDs) do
        local studentPeer = findStudentPeer(studentID)
        SendInfo(studentPeer or 0, "NewTournament" + roundTime + qsPerMatch, true, studentID)
    end
end

local function MakeNewTournament(peer, classname, roundTime, qsPerMatch)  -- Response to a teacher asking to create a new tournament. Checks if this request is valid, creates tournaments and begins setting it up.
    local peerInfo = identifyPeer(peer)
    local teacherID = peerInfo.ID
    local classID = FindClassID(teacherID, classname)
    local classSize = FindClassSize(classID)
    if TournamentUnfinished(classID) then
        SendInfo(peer, "NewTournamentReject" + classname + "This class is already in a tournament. Please wait for it to finish.", false, teacherID)
    elseif classSize < 3 then
        SendInfo(peer, "MewTournamentReject" + classname + "This class does not have enough students for a tournament!", false, teacherID)
    else
        DeletePreviousTournament(classID)
        local tournamentID = addTournament(classID, roundTime, qsPerMatch)
        SendInfo(peer, "NewTournamentAccept" + classname + roundTime + qsPerMatch, false, teacherID)
        NotifyStudentsOfTournament(classID, roundTime, qsPerMatch)
        EnrollStudents(classID, tournamentID)
        NextRound(tournamentID)
    end
end

local function StudentMatchFinished(peer, score)              -- Response to a student completing a match. Checks whether the opponent has completed the match yet.
    local student = identifyPeer(peer)
    local scoreboardID1 = FindCurrentScoreboardID(student.ID)
    local tournament = ReturnScoreboardTournament(scoreboardID1)
    local matchComplete = CheckOpponentMatchComplete(scoreboardID1)
    if matchComplete then
        print("StudentID: "..(student.ID or "nil"))
        print("Match Complete: "..tournament.TournamentID)
        local incompleteMatch = GetIncompleteMatchAgainst(scoreboardID1)
        CompleteMatch(incompleteMatch.FromScoreboardID, incompleteMatch.ToScoreboardID, incompleteMatch.Score, score)
        CheckRoundFinished(tournament.TournamentID, os.date('*t'))
    else
        print("StudentID: "..(student.ID or "nil"))
        print("ScoreboardID: "..(scoreboardID1 or "nil"))
        local currentMatch = FindCurrentMatch(scoreboardID1)
        addIncompleteMatch(currentMatch.FromScoreboardID, currentMatch.ToScoreboardID, score)
    end
end

local function SendStudentMissedEvents(peer, ID)  -- Called when a student logs in. Checks for any messages the student missed while offline, sends them, and deletes them from the StudentMissedEvent table.
    local missedEvents = {}
    missedEvents = SendStudentEvents(ID)
    for i,event in ipairs(missedEvents) do
        SendInfo(peer, event, true, ID)
    end
    ClearStudentEvents(ID)
end

local function RemindStudentOfMatch(peer, StudentID)        -- When a student logs in, their program is reminded of the current match available for them to participate in.
    local scoreboardID = FindCurrentScoreboardID(StudentID)
    if not scoreboardID then return end                     -- Return if no tournament is available
    local match = FindCurrentMatch(scoreboardID)
    local tournament = ReturnScoreboardTournament(scoreboardID)

    peer:send("CurrentTournament" + tournament.RoundLength + tournament.QsPerMatch)
    --SendInfo(peer, "CurrentTournament" + tournament.RoundLength + tournament.QsPerMatch, true, S)
    if match then                          -- If no match is available
        local student1 = ReturnScoreboardStudent(match.FromScoreboardID)
        local student2 = ReturnScoreboardStudent(match.ToScoreboardID)
        peer:send("CurrentMatch" + tournament.RoundLength + tournament.QsPerMatch + tournament.LastRound + student1.Ratings + student2.Ratings + match.QuestionSeed)
        --SendInfo(peer, "CurrentMatch" + tournament.RoundLength + tournament.QsPerMatch + tournament.LastRound + student1.Ratings + student2.Ratings + match.QuestionSeed, true, StudentID)
    end
end

local function LoginStudent(peer, email, password)                            -- Response to a student's request to log in. Validates their information and, if correct, logs them in, adding them to the list of online clients and sending back information the student program may need (eg. classname if any)
    local StudentID = ValidateStudentLogin(email, password)
    if StudentID then
        local student = ReturnStudent(StudentID)
        local className = FindStudentClassName(StudentID)
        local ratings = FindStudentRatings(StudentID)
        peer:send("LoginSuccess" + student.Forename.." "..student.Surname + (className or 0) + ratings + student.Level + student.Statistics)          -- Send all info needed by the student: classname, ratings. This does not pass through the SendInfo function since the student is not yet in the list of clients online (they are considered offline).
        addClient(peer, true, StudentID)
        SendStudentMissedEvents(peer, StudentID)
        if IsStudentInMatch(StudentID) then RemindStudentOfMatch(peer, StudentID) end
    else
        peer:send("LoginFail" + "Please verify all fields are correct.")
    end
    print("Missed Events:")
    printTable(StudentMissedEvent)
end

local function SendTeacherMissedEvents(peer, ID)  -- Called when a teacher logs in. Checks for any messages the teacher missed while offline, sends them, and deletes them from the TeacherMissedEvent table.
    local missedEvents = {}
    missedEvents = SendTeacherEvents(ID)
    for i,event in ipairs(missedEvents) do
        SendInfo(peer, event, false, ID)
    end
    ClearTeacherEvents(ID)
end

local function LoginTeacher(peer, email, password)        -- Response to a teacher's request to log in. Validates the information and returns any data needed by the teacher program. Also adds the teacher to the list of clients online.
    local TeacherID = ValidateTeacherLogin(email, password)
    if TeacherID then
        local teacherInfo = FetchTeacherInfo(TeacherID)
        peer:send("LoginSuccess" + teacherInfo.students + teacherInfo.classes + teacherInfo.tournaments)    -- Send all info needed by the teacher: classes
        addClient(peer, false, TeacherID)
        SendTeacherMissedEvents(peer, TeacherID)
    else
        peer:send("LoginFail" + "Please verify all fields are correct.")
    end
end

local function LogoutStudent(peer, newRating, newLevel, statistics)     -- Response to student request to log out.
    local student = identifyPeer(peer)
    if student then
        peer:send("LogoutSuccess")          -- Sends message directly to student and not through the SendInfo function, since the student will be removed from the client list.
        UpdateStudentRatings(student.ID, newRating, newLevel)
        UpdateStudentStatistics(student.ID, statistics)
        removeClient(peer)                  -- Remove the student from the list of users logged in.
    end
end

local function LogoutTeacher(peer)                -- Response to teacher request to log out.
    if peer then
        peer:send("LogoutSuccess")
        removeClient(peer)
    end
end

local function respondToMessage(event)        -- Defines its own protocol for communication.
    -- This function lists every request that can be received, describing the action that should be taken and the breakdown of information in the message.
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
        ["StudentLogout"] = function(peer, rating, level, statistics) LogoutStudent(peer, rating, level, statistics) end,
        ["TeacherLogout"] = function(peer) LogoutTeacher(peer) end,
        ["NewTournament"] = function(peer, classname, roundTime, qsPerMatch) MakeNewTournament(peer, classname, roundTime, qsPerMatch) end,
        ["StudentMatchFinished"] = function(peer, score) StudentMatchFinished(peer, score) end,

        -- Potentially need fixing:

        --["NewTeacher"] = function(peer, forename, surname, email, password) AddNewTeacher(peer, forename, surname, email, password) end,
        --["NewTournament"] = function(peer, classname, maxduration, matches) MakeNewTournament(peer, classname, maxduration, matches) end,
        --["NextGame"] = function(peer) SendNextGame(peer) end,
        --["RequestReport"] = function(peer, studentID) end,                           -- Request a student's report
        --["SendReport"] = function(peer, teacherID, report) end,                      -- Send student report to teacher
        --["OfferStudentID"] = function(peer, studentID, password) ReceiveStudentID(peer, tonumber(studentID), password) end,           -- Non-new student attempting to connect
        --["OfferTeacherID"] = function(peer, teacherID, password) ReceiveTeacherID(peer, tonumber(teacherID), password) end            -- Non-new teacher attempting to connect
    }
    if messageResponses[first] then messageResponses[first](event.peer, unpack(messageTable))end        -- Find the appropriate request in the list and carry out the response function
end

local function handleEvent(event)             -- Called immediately whenever a message is received. Broken up into different types of messages that can be received
    if event.type == "connect" then     -- Sent by a client who wishes to connect to the server
        serverPeer = event.peer
    elseif event.type == "receive" then -- Most messages (except connect and disconnect messages)
        respondToMessage(event)
    elseif event.type == "disconnect" then  -- Sent by a connected client who wishes to disconnect
        removeClient(event.peer)
    end
end


-------------------- GLOBAL FUNCTIONS:

function Server:new()                   -- Called each time a new server is created. Only one server is created in this program.
    host = enet.host_create(serverLoc)                -- At home on Mezon2G
end

function Server:draw()                  -- Mostly used for debugging: prints items onscreen related with the server (eg list of clients)
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

    for i,event in ipairs(TeacherMissedEvent) do
        if event.Message then love.graphics.print(event.Message, 300, 100 + i * 50) end
    end
end

function Server:update(dt)              -- Called every dt seconds to update the server (to see if any new messages have arrived)
    event = host:service(100)
    if event then
        table.insert(events, event)
        handleEvent(event)
    end
end

-- DEBUG:
function Server:keypressed(key)
   if key == 'n' then clients = {}; events = {} end
end

function NotifyStudentsOfNewMatch(TournamentID, nextPairings)
    local startDay = FindTournamentRoundStart(TournamentID)
    for scoreboard1,scoreboard2 in pairs(nextPairings) do
        local match = FindCurrentMatch(scoreboard1)
        local student1 = ReturnScoreboardStudent(scoreboard1)
        local studentPeer1 = findStudentPeer((student1 or { StudentID = -1 }).StudentID)
        local student2 = ReturnScoreboardStudent(scoreboard2)
        local studentPeer2 = findStudentPeer((student2 or { StudentID = -1 }).StudentID)
        if not student1 or not student2 then                -- Check whether one of the students is the dummy (issued when there is an odd number of players)
            if not student2 then SendInfo(studentPeer1, "ByeReceived", true, student1.StudentID) end
        else
            print(startDay)
            print(student1.StudentID)
            print(student1.Ratings)
            print(student2.Ratings)
            print(match.QuestionSeed)
            SendInfo(studentPeer1, "NewMatch" + startDay + student1.Ratings + student2.Ratings + match.QuestionSeed + student2.Forename.." "..student2.Surname, true, student1.StudentID)
        end
    end
    print("Student Missed Events:")
    printTable(StudentMissedEvent)
end

function NotifyStudentsOfMatchResult(Scoreboard1, Scoreboard2, Score1, Score2)      -- Sends the results of a tournament round to each student (except the student with a bye), stating whether they won or lost their match
    local student1 = ReturnScoreboardStudent(Scoreboard1)
    local student2 = ReturnScoreboardStudent(Scoreboard2)
    local result
    if Score1 > Score2 then
        result = 3
    else
        result = 0
    end
    if student1 and student2 then
        local studentPeer1 = findStudentPeer(student1.StudentID)
        local studentPeer2 = findStudentPeer(student2.StudentID)
        SendInfo(studentPeer1, "MatchResults" + student2.Forename.." "..student2.Surname + result, true, student1.StudentID)
        SendInfo(studentPeer2, "MatchResults" + student1.Forename.." "..student1.Surname + (3 - result), true, student2.StudentID)
    end
end

function NotifyStudentsOfTournamentEnd(TournamentID, rankedStudents)        -- Notifies the students at the end of a tournament. Gives each student the names of the runners up and their own rank at the end of the tournament
    local winners = { FindStudentName(rankedStudents[1].ID), FindStudentName(rankedStudents[2].ID), FindStudentName(rankedStudents[3].ID) }
    for i,s in ipairs(rankedStudents) do
        local studentPeer = findStudentPeer(s.ID)
        SendInfo(studentPeer, "TournamentResults" + table.serialize(winners) + i, true, s.ID)
    end
end

function SendTeacherTournamentEnd(teacherID, classname, ranking)
    local teacherPeer = findTeacherPeer(teacherID)
    SendInfo(teacherPeer, "TournamentFinished" + classname + ranking, false, teacherID)
end
