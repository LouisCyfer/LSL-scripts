string version = "Telly Pole v0.1";
key Owner; key currUser; integer dialogChannel; integer listener;

integer status = FALSE;
integer locationLimit = 9;

list locationNames = [];
list invalidLocs = [];

key HttpRequest;

list requestIDs = [];
list requestsDone = [];
integer queueDone = FALSE;
integer reQueue = 0;

list LocationTargets = [];

integer idx = 0; integer max = 0;

integer timerCounter = 0;

resetListen(key gID) { llListenRemove(listener); listener = llListen(dialogChannel, "", gID, ""); }
resetListenChannel() { dialogChannel = -1 - (integer)("0x" + llGetSubString( (string)llGetKey(), -7, -1) ); }

showLocations()
{
    string locMsg = "";
    idx = 0; max = llGetListLength(requestIDs);
    
    if(max > 0)
    {
        locMsg = "\n\Valid Locations:";
        
        do
        {
            locMsg += "\n" + (string)idx + " --> " + llList2String(locationNames, idx);
            
            if(currUser == Owner)
            {
                locMsg += " | " + llList2String(LocationTargets, idx);
            }
            
            idx++;
        } while(idx < max);
        
        if(currUser == Owner) { llOwnerSay(locMsg); }
        else { llInstantMessage(currUser, locMsg); }
    }    
    
    // artificial sleep to make the IM proceed and send an Owner message if there are invalid locations that exceeded the limit
    if(currUser == Owner && llGetListLength(invalidLocs) > 0)
    {
        llSleep(1);
        locMsg = "\nWARNING! Invalid Locations found! (will not show up in menu, limit=" + (string)locationLimit + "):";
        locMsg += "\n --> " + llDumpList2String(invalidLocs, "\n --> ");
        llOwnerSay(locMsg);
    }
}

rescanLocations()
{    
    // reset lists
    locationNames = [];
    invalidLocs = [];
    requestIDs = [];
    LocationTargets = [];
    requestsDone = [];
    queueDone = FALSE;
    
    // set the complete-timer
    llSetTimerEvent(0.1);
    
    // prepare the upcoming while-loop
    idx = 0; max = llGetInventoryNumber(INVENTORY_LANDMARK);
    
    // some string adjustments :D
    string LMamountInfo = (string)max + " landmark";
    if(max == 0 || max > 1) { LMamountInfo += "s"; }
    
    string info = LMamountInfo + " found.";
    integer proceed = FALSE;
    
    if(max > 0)
    {
        proceed = TRUE;
        info += "\nPlease be patient while I request the dataserver values ..";
    }
    else { queueDone = TRUE; }
    
    llOwnerSay(info);
    
    if(proceed == TRUE)
    {
        // collect all the landmark names
        string itemName = "";
        do
        {
            itemName = llGetInventoryName(INVENTORY_LANDMARK, idx);
            if(idx < locationLimit)
            {
                locationNames += itemName;
                requestIDs += llRequestInventoryData(itemName);
                requestsDone += FALSE;
                // llOwnerSay("reqID " + (string)idx + " = " + (string)reqID);
            }
            else { invalidLocs += itemName; }
            idx++;
        } while(idx < max);
    }
}

handleRequests(key id, string data)
{
    integer reqID = llListFindList(requestIDs, [id]);
    
    if(reqID == -1)
    {
        llOwnerSay("Something went wrong! cound not process request id " + (string)id);
    }
    else
    {
        LocationTargets = llListInsertList(LocationTargets, [(vector)data], reqID);
        if(reqID == llGetListLength(requestsDone) - 1) { queueDone = TRUE; }
    }
}
        
showMainMenu(key gKey, integer ShowMenu)
{
    string DialogTxt = "\n\n"+ version;
    list currStatus = ["●►○", "●"];
    
    if(status == FALSE) { currStatus = ["○►●", "○"]; }
    
    string statusMsg = "Current Status " + llList2String(currStatus, 1); // ● = enabled  ○ = disabled
    DialogTxt += "\n\n" + statusMsg + "\n\nNOTE:\n  --> script reacts instantly to changes\n  --> only the owner can toggle | ● = on  ○ = off\n  --> ':: locations ::' prints full location names in chat";
    
    list buttons = [];
    string toggleButton = "toggle " + llList2String(currStatus, 0);
    
    if(currUser != Owner) { toggleButton = " "; }
    
    list mainButtons = [toggleButton,":: locations ::", ":: EXIT ::"];
    
    list addButtons = [];
    string currentButton = "";
    
    idx = 0; max = llGetListLength(locationNames);
    
    if(max > 0 && status == TRUE)
    {
        // DialogTxt += "\n\nLocations:";
        addButtons = [];
        while(idx<max)
        {
            currentButton = llList2String(locationNames, idx);
            
            // make LM-name fit into a button if longer than 10 characters
            if (llStringLength(currentButton) > 10)
            {
                currentButton = llGetSubString(currentButton, 0, 10);
            }
            
            // DialogTxt += "\n" + (string)(idx + 1) + " --> " + currentButton;
            // llOwnerSay("currentButton=" + currentButton);
            
            currentButton = "location " + (string)(idx + 1);
            
            addButtons += currentButton;
            idx++;
        }
    }
    
    // llOwnerSay("addButtons=" + llDumpList2String(addButtons, ", "));
    
    buttons = mainButtons + addButtons;
    llDialog(gKey, DialogTxt, buttons, dialogChannel);
}

init()
{
    llSay(0, version + " starting up, please be patient!");
    Owner = llGetOwner();
    currUser = Owner;
    
    resetListenChannel();
    resetListen(Owner);
    rescanLocations();
}

default
{
    on_rez(integer start_param) { resetListenChannel(); }

    state_entry()
    {
        init();
        // llSay(0, "Hello, Avatar!");
    }
    
    timer()
    {
        // llOwnerSay("reQueue=" + (string)reQueue + " | queueDone=" + (string)queueDone);
        
        if(queueDone == TRUE)
        {
            if(reQueue > 0)
            {
                reQueue -= 1;
                rescanLocations();
                llOwnerSay("re-running requests, please be patient!");
            }
            else
            {
                llSetTimerEvent(0);
                showLocations();
                llOwnerSay("Requests proceeding done!");
                llSay(0, "ready!");
            }
        }
    }
    
    touch_start(integer total_number)
    {
        if(queueDone == TRUE)
        {
            currUser = llDetectedKey(0);
            resetListen(currUser);
            showMainMenu(currUser, 0);
        }
    }
    
    changed(integer change)
    {
        if (change & CHANGED_INVENTORY)
        {
            llOwnerSay("My inventory changed, rescanning.. ");
            
            if(queueDone == TRUE) { rescanLocations(); }
            else { reQueue += 1; }
        }
    }
    
    dataserver(key id, string data)
    {
        handleRequests(id, data);
    }
    
    listen(integer chan, string name, key id, string msg)
    {
        if(chan == dialogChannel)
        {
            llOwnerSay("chan=" + (string)chan + " | name=" + name + " | id=" + (string)id + "msg=" + msg);
            
            if(msg == " " || msg == ":: EXIT ::") { }
            else
            {
                if(msg == "toggle ○►●" || msg == "toggle ●►○")
                {
                    // if(status == TRUE) { status = FALSE; }
                    // else if(status == FALSE) { status = TRUE; }
                    status = !status;
                }
                else if(msg == ":: locations ::")
                {
                    showLocations();
                    // HttpRequest = llHTTPRequest( "https://cap.secondlife.com/cap/0/b713fe80-283b-4585-af4d-a3b7d9a32492?var=region&grid_x=1000&grid_y=1000",[],"");
                }
                showMainMenu(currUser, 0);
            }
        }
    }
}
