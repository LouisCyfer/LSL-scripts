// this script is licensed with MIT and can be found here:
// https://github.com/LouisCyfer/LSL-scripts
//
// STHC (simple texture hud config) - reciever-part, goes to the linked prim-set (clothes/furniture/etc)
// preconfigured for linked prims and fixed 9 textures

key myOwner = NULL_KEY;
string HUDname = "insertanythingcreativehere"; // exchange for each different object

default
{
    state_entry()
    {
        myOwner = llGetOwner(); // get the owner-key at the beginning, only 1 event on startup instead of every message-event
        llListen(444, "", NULL_KEY, "");
    }
    
    on_rez(integer start_param)
    {
        if(llGetOwner() != myOwner) { llResetScript(); }
    }
    
    listen( integer channel, string name, key id, string message )
    {
        if (channel == 444)
        {
            list msgIncoming = llParseString2List(message, [","], [""]);
            string HUDanswering = llList2String(msgIncoming, 0);
            key HUDOwner = llList2Key(msgIncoming, 1);
           
            if (HUDanswering == HUDname && HUDOwner == myOwner)
            {
                string command = llList2String(msgIncoming, 2);
                key applyTex = NULL_KEY;
                
                // exchange the texture UUID's for your case
                // 89556747-24cb-43ed-920b-47caed15465f = TEXTURE_PLYWOOD | TEXTURE_DEFAULT .. standard SL texture on every newly created prim
                
                if (command == "tex1") { applyTex = "89556747-24cb-43ed-920b-47caed15465f"; }
                else if (command == "tex2") { applyTex = "89556747-24cb-43ed-920b-47caed15465f"; }
                else if (command == "tex3") { applyTex = "89556747-24cb-43ed-920b-47caed15465f"; }
                else if (command == "tex4") { applyTex = "89556747-24cb-43ed-920b-47caed15465f"; }
                else if (command == "tex5") { applyTex = "89556747-24cb-43ed-920b-47caed15465f"; }
                else if (command == "tex6") { applyTex = "89556747-24cb-43ed-920b-47caed15465f"; }
                else if (command == "tex7") { applyTex = "89556747-24cb-43ed-920b-47caed15465f"; }
                else if (command == "tex8") { applyTex = "89556747-24cb-43ed-920b-47caed15465f"; }
                else if (command == "tex9") { applyTex = "89556747-24cb-43ed-920b-47caed15465f"; }
    
                // DEBUG message to owner :P
                // llOwnerSay("message recieved (" + command + "), applying texture " + string(applyTex));
        
                llSetLinkTexture(LINK_SET, applyTex, ALL_SIDES);
            }
        }
    }
}
