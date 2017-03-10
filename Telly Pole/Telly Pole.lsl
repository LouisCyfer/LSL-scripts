// this script is licensed with MIT and can be found here:
// https://github.com/LouisCyfer/LSL-scripts

// pre-variable-setups
string version = "Telly Pole v0.2";
key Owner; key currUser; integer status = FALSE; integer locationLimit = 9;

list locationNames = []; list LocationTargets = []; list invalidLocs = [];
list requestIDs = []; integer queueDone = FALSE; integer reQueue = 0;
integer idx = 0; integer max = 0; integer tpTo = 0;
integer timerCounter = 0;

// dialogchannel-setups
integer dialogChannel; integer listener;
resetListen(key gID) { llListenRemove(listener); listener = llListen(dialogChannel, "", gID, ""); }
resetListenChannel() { dialogChannel = -1 - (integer)("0x" + llGetSubString( (string)llGetKey(), -7, -1) ); }

showLocations()
{ // printing locations in chat
    string locMsg = "";
    idx = 0; max = llGetListLength(requestIDs);
    
    if(max > 0)
    {
        locMsg = "\n\Valid Locations:";
        
        do
        {
            locMsg += "\n" + (string)idx + " --> " + llList2String(locationNames, idx);
            if(currUser == Owner) { locMsg += " | " + llList2String(LocationTargets, idx); }
            
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
                // llOwnerSay("reqID " + (string)idx + " = " + (string)reqID);
            }
            else { invalidLocs += itemName; }
            idx++;
        } while(idx < max);
    }
}

handleRequests(key id, string data)
{ // every request goes here, unanswered requests silently fail, sadly (might need a workaround later)
    integer reqID = llListFindList(requestIDs, [id]);
    
    if(reqID == -1) { llOwnerSay("Something went wrong! cound not process request id " + (string)id); }
    else
    {
        LocationTargets = llListInsertList(LocationTargets, [(vector)data], reqID);
        if(reqID == llGetListLength(requestIDs) - 1) { queueDone = TRUE; }
    }
}
        
showMainMenu(key gKey, integer ShowMenu)
{ // main function for the menu/dialog
    list buttons = [];
    list addButtons = [];
    list mainButtons = [];
    string DialogTxt = "\n\n"+ version;
    string currentButton = "";
    tpTo = -1;
    
    if(ShowMenu == 0)
    {
        list currStatus = ["●►○", "●"];
        
        if(status == FALSE) { currStatus = ["○►●", "○"]; }
        
        string statusMsg = "Current Status " + llList2String(currStatus, 1); // ● = enabled  ○ = disabled
        DialogTxt += "\n\n" + statusMsg + "\n\nNOTE:\n  --> script reacts instantly to changes\n  --> only the owner can toggle | ● = on  ○ = off";
        string toggleButton = "toggle " + llList2String(currStatus, 0);
        
        if(status == TRUE) { DialogTxt += "\n  --> ':: locations ::' prints full location names in chat"; }
        if(currUser != Owner) { toggleButton = " "; }
        mainButtons = [toggleButton, " ", ":: EXIT ::"];
        
        idx = 0; max = llGetListLength(locationNames);
    
        if(max > 0 && status == TRUE)
        {
            // DialogTxt += "\n\nLocations:";
            addButtons = [];
            mainButtons = llListReplaceList(mainButtons, [":: locations ::"], 1, 1);
            
            while(idx<max)
            {
                currentButton = "location " + (string)(idx + 1);
                addButtons += currentButton;
                idx++;
            }
        }
    }
    else
    {
        tpTo = ShowMenu - 1;
        mainButtons = [":: teleport ::", ":: back ::", ":: EXIT ::"];
    }
    
    buttons = mainButtons + addButtons;
    llDialog(gKey, DialogTxt, buttons, dialogChannel);
}

teleportUser()
{ // main teleport function
    // llMapDestination("", llList2Vector(LocationTargets, targetIndex), ZERO_VECTOR);
    llRequestPermissions(currUser, PERMISSION_TELEPORT);
    // llRequestExperiencePermissions(currUser, "");
}

init()
{ // this is for the pre-start/initiation
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
                // the user added another item or changed anything, so we do another queue at the end of the current
                // (stacks up very quickly and not seen it happen so slow, hope it won't be making issues)
                
                reQueue -= 1;
                rescanLocations();
                llOwnerSay("re-running requests, please be patient!");
            }
            else
            { // all requests done!
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
        { // make sure theres nothing in background interferring things
            currUser = llDetectedKey(0);
            if(currUser == Owner)
            { // sadly it makes currently just sense by making it owner-only
                resetListen(currUser);
                showMainMenu(currUser, 0);
            }
        }
    }
    
    experience_permissions(key av)
    {
        // *possible future implentation*
        //llTeleportAgent(av, llList2String(locationNames, tpTo), llList2Vector(LocationTargets, tpTo), ZERO_VECTOR);
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
    
    dataserver(key id, string data) { handleRequests(id, data); }
    
    run_time_permissions(integer perm)
    {
        if(PERMISSION_TELEPORT & perm)
        {
            llOwnerSay("tpTo=" + (string)tpTo);
            llTeleportAgent(currUser, llList2String(locationNames, tpTo), llList2Vector(LocationTargets, tpTo), ZERO_VECTOR);
        }
    }
    
    listen(integer chan, string name, key id, string msg)
    {
        if(chan == dialogChannel)
        { // handle all the dialog's
            if(msg == " " || msg == ":: EXIT ::") { }
            else
            {
                list parsedMsg = llParseString2List(msg, [" "], [""]);
                llOwnerSay("chan=" + (string)chan + " | msg=" + msg + " | parsedMsg0=" + llList2String(parsedMsg, 0) + " | parsedMsg1=" + llList2String(parsedMsg, 1));
                
                integer menuID = 0;
                
                if(llList2String(parsedMsg, 0) == "location")
                {
                    menuID = llList2Integer(parsedMsg, 1);
                }
                else if(msg == "toggle ○►●" || msg == "toggle ●►○") { status = !status; }
                else if(msg == ":: locations ::") { showLocations(); }
                else if(msg == ":: teleport ::") { menuID = -1; teleportUser(); }
                
                if(menuID >= 0) { showMainMenu(currUser, menuID); }
            }
        }
    }
}
