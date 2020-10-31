// kb_sync01

string  KB_VERSIONMAJOR      = "8";
string  KB_VERSIONMINOR      = "0";
string  KB_DEVSTAGE          = "1a101";
string  g_sScriptVersion = "";
string  g_sCollarVersion = "not set";

string formatVersion() {
    return KB_VERSIONMAJOR + "." + KB_VERSIONMINOR + "." + KB_DEVSTAGE;
}

DebugOutput(integer iLevel, list ITEMS) {
    if (g_iDebugLevel > iLevel) return;
    ++g_iDebugCounter;
    integer i=0;
    integer end=llGetListLength(ITEMS);
    string final;
    for(i=0;i<end;i++){
        final+=llList2String(ITEMS,i)+" ";
    }
    llSay(KB_DEBUG_CHANNEL, llGetScriptName() + " " + formatVersion() + " " + (string) g_iDebugCounter + " " + final);
}

SetDebugOn() {
    g_bDebugOn = TRUE;
    g_iDebugLevel = 0;
    g_iDebugCounter = 0;
}

SetDebugOff() {
    g_bDebugOn = FALSE;
    g_iDebugLevel = 10;
}

integer g_bDebugOn = TRUE;
integer g_iDebugLevel = 0;
integer KB_DEBUG_CHANNEL           = -617783;
integer g_iDebugCounter = 0;
integer g_iPingCounter = 0;

key     g_kWearer;

//key g_kGroup = "";
//integer g_iGroupEnabled = FALSE;

string g_sParentMenu = "Apps";
string g_sSubMenu = "KBSync";
//integer g_iRunawayDisable=0;
//integer g_iSWActive = 1;
integer KB_HAIL_CHANNEL = -317783;
integer KB_HAIL_CHANNEL01 = -317785;
//list g_lCollarSettings = [];
list g_lSayings = [];
list g_lHostSayings = [];
float g_fStartDelay = 0.0;
integer g_bGotSayings = FALSE;
integer g_iSettings = 0;
//integer g_iSayings1 = 0;
integer g_iLineNr = 0;
key 	g_kVersionID;
integer LOADPIN = -1904;
integer LINK_CMD_DEBUG = 1999;
integer REBOOT              = -1000;
integer LINK_UPDATE = -10;

integer NOTIFY = 1002;

integer KB_COLLAR_VERSION		   = -34847;
integer KB_READY_SAYINGS		   = -34848;
integer KB_SEND_SAYINGS			   = -34849;
integer KB_SET_SAYING			   = -34850;
integer KB_REQUEST_VERSION         = -34591;


integer g_iListenHandle = 0;

InitListen() {
    // if (g_bDebugOn) DebugOutput(5, ["InitListen", g_iListenHandle, KB_HAIL_CHANNEL00]);
    if (g_iListenHandle == 0) g_iListenHandle = llListen(KB_HAIL_CHANNEL01, "", "", "");
}

DeleteListen() {
    // if (g_bDebugOn) DebugOutput(5, ["DeleteListen", g_iListenHandle, KB_HAIL_CHANNEL00]);
    if (g_iListenHandle != 0) { llListenRemove(g_iListenHandle); g_iListenHandle = 0; }
}


InitVariables() {
    g_kWearer == llGetOwner();
    g_iDebugCounter = 0;
    g_iPingCounter = 0;
    g_lSayings = [];
    g_lHostSayings = [];
    g_bGotSayings = FALSE;
    g_fStartDelay = 15.0;
    g_iLineNr - 0;
    g_sCollarVersion = "not set";
}

MergeInputSayings() {
    string sWork = llList2String(g_lHostSayings, 0);
    g_lHostSayings = llDeleteSubList(g_lHostSayings, 0, 0);
    if (g_bDebugOn) DebugOutput(0, ["MergeInputSayings-1", sWork, llGetListLength(g_lSayings)]);
    list lTemp = llParseString2List(sWork, ["="], [""]);
    string sLeft = "";
    if (llGetListLength(lTemp) > 1) {
        sLeft = llList2String(lTemp, 0);
        if (sLeft == "kbhostline") return;
        if (sLeft == "kbhostaction") {
            g_bGotSayings = TRUE;
            return;
        }
        if (sWork == "kbnosayings") {
             if (g_bDebugOn) { list lTemp = ["init_params", "listen-4", "no sayings found"] + g_lSayings; DebugOutput(5, lTemp); }
            g_lSayings = [];
            g_bGotSayings = FALSE;
            return;
        }
        if (sWork == "Notify") {
            g_lSayings = [];
            g_bGotSayings = FALSE;
            return;
        }
    } else {
        integer iFound = llListFindList(g_lSayings, [sWork]);
        if (iFound < 0) {
            if (g_bDebugOn) DebugOutput(0, ["MergeInputSayings-2", sWork]);
            g_lSayings += [sWork];
        }
    }
}

integer ALIVE = -55;
integer READY = -56;
integer STARTUP = -57;

default {
    on_rez(integer iNum){
        llResetScript();
    }

    state_entry()
    {
        if (g_bDebugOn) DebugOutput(5, ["default", "state_entry", llGetFreeMemory(), "bytes free"]);
        llMessageLinked(LINK_SET, ALIVE, llGetScriptName(),"");
    }
        
    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if(iNum == REBOOT) {
            if(sStr == "reboot") {
                llResetScript();
            }
        } else if(iNum == READY) llMessageLinked(LINK_SET, ALIVE, llGetScriptName(), "");
        else if(iNum == STARTUP) state init_params;
        else if (iNum == KB_COLLAR_VERSION) g_sCollarVersion = sStr;
        else if (iNum == KB_REQUEST_VERSION)
                llMessageLinked(LINK_SET,NOTIFY,"0"+llGetScriptName() + " version " + formatVersion(),kID);

    }

    state_exit()
    {
        if (g_bDebugOn) DebugOutput(5, ["default", "state_exit", llGetFreeMemory(), "bytes free"]);
    }
}

state init_params {
//
//    if the on_rez event is raised while we are in this state, just stop and let default take over; default will switch back to us, and we'll pick back up at state-entry
//
    on_rez(integer iParam){
        if (g_bDebugOn) DebugOutput(5, ["init_params", "on_rez", iParam]);
        state default;
    }
    
    state_entry() {
        if (g_bDebugOn) DebugOutput(5, ["init_params", "state_entry", llGetFreeMemory(), "bytes free"]);
        InitVariables();
        InitListen();
        if (g_bDebugOn) DebugOutput(5, ["init_params", "state_entry", "link_message pinging", KB_HAIL_CHANNEL01]);
        llRegionSay(KB_HAIL_CHANNEL01, "ping801");        
        llSetTimerEvent(g_fStartDelay);
    }
    
    link_message(integer iSender,integer iNum,string sStr,key kID) {
        if (iNum == KB_COLLAR_VERSION) g_sCollarVersion = sStr;
        else if (iNum == KB_REQUEST_VERSION)
            llMessageLinked(LINK_SET,NOTIFY,"0"+llGetScriptName() + " version " + formatVersion(),kID);
    }
    
    timer() {
        if (g_bDebugOn) DebugOutput(5, ["init_params", "timer"]);
        llSetTimerEvent(0.0);
        ++g_iPingCounter;
        if (g_bDebugOn) DebugOutput(5, ["init_params", "timer", "link_message pinging", KB_HAIL_CHANNEL01, g_iPingCounter, g_fStartDelay]);
        if (llGetListLength(g_lSayings) > 0) state sync_sayings;
        llRegionSay(KB_HAIL_CHANNEL01, "ping801");     
        g_fStartDelay = (float) (45*g_iPingCounter);
        llSetTimerEvent(g_fStartDelay);
    }
//
//    kb_settings_host collects any sayings values for this specific collar and sends them in large batches
//    Each batch is a list in string form with sayings separated by '%%' and is sent via chat on the hailing channel
//    kb_settings_host uses llRegionSayTo, so there is no chance of confusion between collar destinations
//    A batch sequence number appears as 'kbhostline=nnn' in each batch; 'kbhostaction=done' signals that all values have been sent
//
//    Starting in 8.0.1a9, 'kbnosayings' indicates that no sayings were found for this collar
//
//    Notify = No 01 Card means the same thing
//
//
    listen(integer iChannel, string sName, key kId, string sMessage) {
        if (g_bDebugOn) DebugOutput(5, ["init_params", "listen-1", "listen heard", sName, (string) kId, sMessage, llGetListLength(g_lHostSayings)]);
        llSetTimerEvent(0.0);
        if (g_bDebugOn) DebugOutput(5, ["init_params", "listen-2"] + g_lHostSayings);
        list lHostSayings = llParseString2List(sMessage, ["%%"], [""]);
        g_lHostSayings += lHostSayings;
        if (g_bDebugOn) DebugOutput(5, ["init_params", "listen-2"] + lHostSayings + ["long list"] + g_lHostSayings);
//
//    TODO: if there ever are enough host sayings to require two messages, this code won't handle it properly
//
        while (llGetListLength(g_lHostSayings) > 0) MergeInputSayings();
        
        if (g_bGotSayings) {
            if (g_bDebugOn) { list lTemp = ["init_params", "listen-4", "sayings ready for output"] + g_lSayings; DebugOutput(5, lTemp); }
            state sync_sayings;
        }
    }

    state_exit()
    {
        llSetTimerEvent(0.0);
        DeleteListen();
        if (g_bDebugOn) DebugOutput(5, ["init_params", "state_exit", llGetFreeMemory(), "bytes free"]);
    }
}

state sync_sayings {
//
//    if the on_rez event is raised while we are in this state, just stop and let default take over; default will switch back to us, and we'll pick back up at state-entry
//

    on_rez(integer iParam) {
        if (g_bDebugOn) DebugOutput(5, ["sync_sayings", "on_rez", iParam]);
        state default;
    }
    
    state_entry() {
        if (g_bDebugOn) DebugOutput(0, ["sync_sayings", "state_entry", llGetFreeMemory(), "bytes free", "Mandatory:"] + g_lSayings);
//
//    At this point, g_lSayings has all of the sayings retrieved from sayings_host
//    g_lCollarsayings has the sayings retrieved from oc_sayings
//    Now we check each mandatory setting to be sure it's set properly in the collar
//

        if (g_bDebugOn) DebugOutput(0, ["Merge Sayings-1"]);
        integer iSayingsLen = llGetListLength(g_lSayings);
        if (g_bDebugOn) DebugOutput(0, ["Merge Sayings-2", iSayingsLen]);

        if (iSayingsLen > 0) llMessageLinked(LINK_SET, KB_READY_SAYINGS, "", "");
    }

    link_message(integer iSender,integer iNum,string sStr,key kID) {
        if (iNum == KB_COLLAR_VERSION) g_sCollarVersion = sStr;
        else if (iNum == KB_REQUEST_VERSION)
            llMessageLinked(LINK_SET,NOTIFY,"0"+llGetScriptName() + " version " + formatVersion(),kID);
        else if (iNum == KB_SEND_SAYINGS) {
            integer iSayingsIdx = 0;
            integer iSayingsLen = llGetListLength(g_lSayings);
            integer iMsgCount = 0;
            while (iSayingsIdx < iSayingsLen) {
                string sSaying = llList2String(g_lSayings, iSayingsIdx);
                if (g_bDebugOn) DebugOutput(0, ["Merge Sayings-3", iSayingsIdx, iSayingsLen, sSaying]);
                llMessageLinked(LINK_SET, KB_SET_SAYING, sSaying, "");
                ++iMsgCount;
                if (iMsgCount > 19) {
                    iMsgCount = 0;
                    llSleep(2.0);
                }
                ++iSayingsIdx;
            }
            if (g_bDebugOn) DebugOutput(0, ["Merge Sayings-6"]);           
        }
    }
    
    state_exit()
    {
        llSetTimerEvent(0.0);
        if (g_bDebugOn) DebugOutput(5, ["sync_sayings", "state_exit", llGetFreeMemory(), "bytes free", "Sayings"] + g_lSayings);
    }
}

state inUpdate {
    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if(iNum == REBOOT)llResetScript();
    }
    
    on_rez(integer iNum) {
        llResetScript();
    }
}


// kb_sync01