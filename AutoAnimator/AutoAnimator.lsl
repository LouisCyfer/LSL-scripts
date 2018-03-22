// version 1.2

integer used = FALSE;
key currUser = NULL_KEY;
string animation = "";
integer dialogChannel;
integer listener;

list invList; //list of all anims
list animPos; //list of all anim-positions
list animRot; //list of all anim-rotations

integer currAnimID = 0;
integer maxPages = 0;
integer currPAGEid = 0;
string lastAnim = "";
rotation standardRot = <0, 0, 0.0, 1>; // ZERO_ROTATION;
vector standardVec = <0.0, 0.0, 0.1>;
integer sMenuID = 0;
integer inputID = 0;

vector currAniPos;
rotation currAniRot;

init()
{
    llOwnerSay("loading...");
    dialogChannel = -1 - (integer)("0x" + llGetSubString( (string)llGetKey(), -7, -1) );
    
    rotation Rot = standardRot;
    vector Vec = standardVec;
    
    llSitTarget(Vec, Rot);
    
    resetAnimList();
    llOwnerSay("done.");
}

//Sets / Updates the sit target moving the avatar on it if necessary.
UpdateSitTarget(vector pos, rotation rot)
{//Using this while the object is moving may give unpredictable results.
    llSitTarget(pos, rot);//Set the sit target
    // key user = llAvatarOnSitTarget();
    currUser = llAvatarOnSitTarget();
    if(currUser)//true if there is a user seated on the sittarget, if so update their position
    {
        vector size = llGetAgentSize(currUser);
        if(size)//This tests to make sure the user really exists.
        {
            //We need to make the position and rotation local to the current prim
            rotation localrot = ZERO_ROTATION;
            vector localpos = ZERO_VECTOR;
            
            if(llGetLinkNumber() > 1)//only need the local rot if it's not the root.
            { localrot = llGetLocalRot(); localpos = llGetLocalPos(); }
            
            integer linkNum = llGetNumberOfPrims();
            do
            {
                if(currUser == llGetLinkKey( linkNum ))//just checking to make sure the index is valid.
                {
                    //<0.008906, -0.049831, 0.088967> are the coefficients for a parabolic curve that best fits real avatars. It is not a perfect fit.
                    float fAdjust = ((((0.008906 * size.z) + -0.049831) * size.z) + 0.088967) * size.z;
                    llSetLinkPrimitiveParamsFast(linkNum, [PRIM_POS_LOCAL, (pos + <0.0, 0.0, 0.4> - (llRot2Up(rot) * fAdjust)) * localrot + localpos, PRIM_ROT_LOCAL, rot * localrot]);
                    jump end; //cheaper but a tad slower then return
                }
            }while( --linkNum );
        }
        else
        {//It is rare that the sit target will bork but it does happen, this can help to fix it.
            // llUnSit(user);
            ejectUser();
        }
    }
    @end;
}//Written by Strife Onizuka, size adjustment and improvements provided by Talarus Luan

resetCURR()
{
    if (sMenuID == 2) // pos
    { currAniPos = standardVec; animPos = llListReplaceList((animPos = []) + animPos, [ (string)currAniPos ], currAnimID, currAnimID); }
    if (sMenuID == 3) // rot
    { currAniRot = standardRot; animRot = llListReplaceList((animRot = []) + animRot, [ (string)currAniRot ], currAnimID, currAnimID); }    
    UpdateSitTarget(currAniPos, currAniRot);
}

updateLists(integer listID, string ID, float val)
{    
    vector newPos = ZERO_VECTOR;
    rotation newRot = ZERO_ROTATION;

    currAniPos = (vector)llList2String(animPos, currAnimID);
    currAniRot = (rotation)llList2String(animRot, currAnimID);
                        
    if (listID == 2) // pos
    {
        if (ID == "X") { newPos.x += val; }  else if (ID == "Y") { newPos.y += val; } else if (ID == "Z") { newPos.z += val; }
        currAniPos += newPos;
        animPos = llListReplaceList((animPos = []) + animPos, [ (string)currAniPos ], currAnimID, currAnimID);
    }
    else if (listID == 3) // rot
    {
        if (ID == "X") { newRot.x += val; }  else if (ID == "Y") { newRot.y += val; } else if (ID == "Z") { newRot.z += val; }
        currAniRot += newRot;
        currAniRot.s = 1;
        animRot = llListReplaceList((animRot = []) + animRot, [ (string)currAniRot ], currAnimID, currAnimID);
    }
    
    UpdateSitTarget(currAniPos, currAniRot);
}

resetAnimList()
{    
    integer max = llGetInventoryNumber(INVENTORY_ALL);  // Count of all items in prim's contents
    string ItemName;
    integer i = 0;
    do
    {
        ItemName = llGetInventoryName(INVENTORY_ALL, i);
        if (llGetInventoryType(ItemName) == INVENTORY_ANIMATION)
        { invList += ItemName; animRot += (string)standardRot; animPos += (string)standardVec; llOwnerSay("anim >" + ItemName + "< loaded."); }
    } while (++i < max);
    
    maxPages = llCeil(llGetListLength(invList) / 6);
    lastAnim = llList2String(invList, 0);
    // llOwnerSay("total inventor items: " + (string)llGetInventoryNumber(INVENTORY_ANIMATION));
    llOwnerSay((string)llGetListLength(invList) + " animations loaded" + " (" + (string)(maxPages + 1) + " pages filled)\n~ " + (string)llGetFreeMemory() + " bytes of free memory available ~" );
}

resetListen(key gID) { llListenRemove(listener); listener = llListen(dialogChannel, "", gID, ""); }

showMenu(key gKey, integer pID, integer subMenu)
{
    list options; integer showInput = FALSE; inputID = 0;
    string InfoText = "\ncurrent animation: " + lastAnim + " (ID: " + (string)currAnimID + ")";
    
    if (pID > maxPages) { pID = maxPages; } else if (pID < 0) { pID = 0; }    
    if (subMenu > 0)
    {
        options += ":: BACK ::";
        
        if (subMenu == 1)
        {
            InfoText += "\n\nNote: if you add or remove any animations you might need to reset the script and re-setup the positions/rotations!";
            options += [ ":: edit POS ::", ":: edit ROT ::", ":: stand up ::" ];
            if (gKey == llGetOwner()) { options += ":: RESET ALL ::"; }
        }
        else if (subMenu == 2) // pos
        {
            InfoText += "\npos:" + (string)currAniPos + "\nrot: " + (string)currAniRot;
            options += [ ":: input POS ::", ":: reset POS ::", "X - 0.1", "Y - 0.1", "Z - 0.1", "X + 0.1", "Y + 0.1", "Z + 0.1" ];
        }
        else if (subMenu == 3) // rot
        {
            InfoText += "\npos:" + (string)currAniPos + "\nrot: " + (string)currAniRot;
            options += [ ":: input ROT ::", ":: reset ROT ::", "X - 0.1", "Y - 0.1", "Z - 0.1", "X + 0.1", "Y + 0.1", "Z + 0.1" ];
        }
        else if (subMenu == 4) // manual input POS
        {
            showInput = TRUE; inputID = 1;
            InfoText += "\nInput postion array like X,Y,Z\npos:" + (string)currAniPos + "\n\n[Do Not Press the Enter Key to Submit!]";
        }
        else if (subMenu == 5) // manual input ROT
        {
            showInput = TRUE; inputID = 2;
            InfoText += "\nInput rotation array like X,Y,Z\nrot: " + (string)currAniRot + "\n\n[Do Not Press the Enter Key to Submit!]";
        }
    }
    else
    {
        InfoText += "\n\n:: PAGE " + (string)(pID + 1) + "/" + (string)(maxPages + 1) + " ::";
        string prev = ":: prev page ::";
        string next = ":: next page ::";
        
        if (pID == maxPages) { next = "- N/A -"; } else if (pID == maxPages -1) { next = ":: last page ::"; }
        if (pID == 0) { prev = "- N/A -"; } else if (pID == 1) { prev = ":: first page ::"; }
        
        options = [ prev, next,  ":: MENU ::" ];
        
        integer index = (pID * 6);
        integer endIDX = (index + 6);
            
        if (endIDX >= llGetListLength(invList) ) { endIDX = llGetListLength(invList); }
        do { options += llList2String(invList, index); } while (++index < endIDX);
            
        currPAGEid = pID;
    }

    if (showInput == FALSE) { llDialog(gKey, InfoText, options, dialogChannel); }
    else { llTextBox(gKey, InfoText, dialogChannel); }
}

ejectUser()
{
    if (animation) { llStopAnimation(animation); }
    llUnSit(currUser);
    resetListen(currUser);
    used = FALSE;
}

Reset()
{
    llOwnerSay("ejecting the current user and resetting script");
    ejectUser();
    llResetScript();
}

AskUser(key User) { llRequestPermissions(User, PERMISSION_TRIGGER_ANIMATION); }

default
{
    state_entry() { init(); }
 
    changed(integer change)
    {
        if (change & CHANGED_LINK)
        { 
            currUser = llAvatarOnSitTarget();
            string newName = (string)llParseString2List(llKey2Name(currUser), ["Resident"], [] );
            newName = llStringTrim(newName, STRING_TRIM);
            
            if(currUser != NULL_KEY)
            { if(used == FALSE) { used = TRUE; AskUser(currUser); resetListen(currUser); showMenu(currUser, currPAGEid, 0); } }
            else { ejectUser(); }
        }
    }
    
    run_time_permissions(integer perm)
    {
        if (perm & PERMISSION_TRIGGER_ANIMATION)
        { animation = lastAnim; if (animation) { llStopAnimation("sit"); llStartAnimation(animation); } }
    }
    
    touch_start(integer total_number)
    {        
        key ID = llDetectedKey(0);
                
        if(used == TRUE && ID == currUser)
        { resetListen(ID); AskUser(ID); showMenu(ID, currPAGEid, 0); }
    }
    
    listen(integer channel, string name, key id, string message) 
    {
        if (used == TRUE && id == currUser )
        {
            if (inputID == 0)
            {
                if (message == ":: stand up ::") { ejectUser(); }
                else if (message == ":: RESET ALL ::") { Reset(); }            
                else
                {                
                    if (message == ":: next page ::" || message == ":: last page ::") { currPAGEid += 1; }
                    else if (message == ":: prev page ::" || message == ":: first page ::") { currPAGEid -= 1; }
                    else if (message == ":: MENU ::") { sMenuID = 1; }
                    else if (message == ":: reset POS ::" || message == ":: reset ROT ::") { resetCURR(); }
                    else if (message == ":: edit POS ::") { sMenuID = 2; }
                    else if (message == ":: edit ROT ::") { sMenuID = 3; }
                    else if (message == ":: BACK ::") { if (sMenuID == 2 || sMenuID == 3 ) { sMenuID = 1; }  else { sMenuID = 0; } }
                    else if (message == ":: input POS ::") { sMenuID = 4; }
                    else if (message == ":: input ROT ::") { sMenuID = 5; }
                    else if (message == "X - 0.1" || message == "Y - 0.1" || message == "Z - 0.1" || message == "X + 0.1" || message == "Y + 0.1" || message == "Z + 0.1")
                    {                    
                        message = (string)llParseString2List(message, [" "], [] );
                        string floatID = llGetSubString(message, 0, 0);
                        float floatVal = (float)llGetSubString(message, 1,  llStringLength(message));                    
                        updateLists(sMenuID, floatID, floatVal);
                    }
                    else
                    {
                        integer i = 0;
                        integer max = llGetListLength(invList);
                        integer found = FALSE;
                        
                        do { if (message == llList2String(invList, i)) { currAnimID = i; i = max; found = TRUE; } }
                        while (++i < max);
                        
                        if (found == TRUE)
                        {
                            llStopAnimation(animation);         
                            animation = message;
                            lastAnim = animation;
                            llStartAnimation(animation);
                            
                            currAniPos = (vector)llList2String(animPos, currAnimID);
                            currAniRot = (rotation)llList2String(animRot, currAnimID);
                            UpdateSitTarget(currAniPos, currAniRot);
                        }
                    }
                    showMenu(id, currPAGEid, sMenuID);
                }
            }
            else
            {                
                sMenuID = inputID + 1;                        
                list Floats = llParseString2List(message, [","], [] );
                
                if (llGetListLength(Floats) == 3)
                {
                    updateLists(sMenuID, "X", (float)llList2Float(Floats,0));
                    updateLists(sMenuID, "Y", (float)llList2Float(Floats,1));
                    updateLists(sMenuID, "Z", (float)llList2Float(Floats,2));
                }
                                
                showMenu(id, currPAGEid, sMenuID);
            }
        }
    }
}
