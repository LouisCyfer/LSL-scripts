// this script is licensed with MIT and can be found here:
// https://github.com/LouisCyfer/LSL-scripts
//
// STHC (simple texture hud config) - sender-part, goes to the HUD
// preconfigured for linked prims and fixed 9 textures

key myOwner = NULL_KEY;
string HUDname = "insertanythingcreativehere";

// exchange for your needs
list buttons = ["texture1","texture2","texture3","texture4","texture5","texture6","texture7","texture8","texture9"];

default
{
    state_entry()
    {
        myOwner = llGetOwner();
        llListen(0,"",myOwner,"");
        llListen(25,"",myOwner,"");
        llListen(444, "", NULL_KEY, "");
    }
    
    on_rez(integer start_param)
    {
        if(llGetOwner() != myOwner) { llResetScript(); }
    }
    
    listen(integer channel,string name,key id,string message)
    {
        llListen(444, "", NULL_KEY, "");
        
        if (id == myOwner && channel == 25)
        {
            string answer = "";
            llOwnerSay("message=" + message);
            
            if(message == llList2String(buttons, 0)) { answer = "tex1"; }
            else if(message == llList2String(buttons, 1)) { answer = "tex2"; }
            else if(message == llList2String(buttons, 2)) { answer = "tex3"; }
            else if(message == llList2String(buttons, 3)) { answer = "tex4"; }
            else if(message == llList2String(buttons, 4)) { answer = "tex5"; }
            else if(message == llList2String(buttons, 5)) { answer = "tex6"; }
            else if(message == llList2String(buttons, 6)) { answer = "tex7"; }
            else if(message == llList2String(buttons, 7)) { answer = "tex8"; }
            else if(message == llList2String(buttons, 8)) { answer = "tex9"; }
                  
            llWhisper(444, HUDname + ","  + string(myOwner) + "," + answer);
        }
    }

    touch_start(integer total_number)
    {
        if(llDetectedKey(0) == myOwner) { llDialog(myOwner, "please choose a texture", buttons, 25); } 
    }
}
