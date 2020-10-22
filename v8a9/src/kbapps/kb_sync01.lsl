// kb_sync01

string  KB_VERSIONMAJOR      = "8";
string  KB_VERSIONMINOR      = "0";
string  KB_DEVSTAGE          = "1a901";
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
//list g_lSayings1 = [];
float g_fStartDelay = 0.0;
integer g_bGotSayings = FALSE;
integer g_iSettings = 0;
//integer g_iSayings1 = 0;
integer g_iLineNr = 0;
key 	g_kVersionID;
//string  g_sTargetCard = ".version";
//integer g_bGatherStarted = FALSE;
//list g_lResets = [];

//integer g_iKBarOptions=0;
//integer g_iGirlStatus=0; // 0=guest, 1=protected, 2=slave
//integer g_iLockStatus=1; // disallow status changes
//integer g_iLogLevel = 0; // minimal logging
//integer g_iLeashedRank = 0;
//key     g_kLeashedTo   = NULL_KEY;
//string  g_sWearerName;

//string  g_sSlaveMessage = "";
/*
integer KB_KBSYNC_KICKSTART        = -34717;
integer KB_NOTICE_LEASHED          = -34691;
integer KB_NOTICE_UNLEASHED        = -34692;

string g_sDrop = "f364b699-fb35-1640-d40b-ba59bdd5f7b7";
*/
//key KURT_KEY   = "4986014c-2eaa-4c39-a423-04e1819b0fbf";
//key SILKIE_KEY = "1a828b4e-6345-4bb3-8d41-f93e6621ba25";

//MESSAGE MAP
//integer CMD_ZERO = 0;
//integer CMD_OWNER = 500;
//integer CMD_TRUSTED = 501;
//integer CMD_GROUP = 502;
//integer CMD_WEARER = 503;
//integer CMD_EVERYONE = 504;
//integer CMD_RLV_RELAY = 507;
//integer CMD_SAFEWORD = 510;
//integer CMD_BLOCKED = 520;
//integer CMD_NOACCESS = 599;

//integer POPUP_HELP = 1001;
//integer NOTIFY = 1002;
//integer NOTIFY_OWNERS = 1003;
integer LOADPIN = -1904;
integer LINK_CMD_DEBUG = 1999;
integer REBOOT              = -1000;
integer LINK_UPDATE = -10;

//integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have sayings saved
//str must be in form of "token=value"
//integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for sayings on this channel
//integer LM_SETTING_RESPONSE = 2002;//the sayings script sends responses on this channel
//integer LM_SETTING_DELETE = 2003;//delete token from sayings
//integer LM_SETTING_EMPTY = 2004;//sent when a token has no value

//integer MENUNAME_REQUEST = 3000;
//integer MENUNAME_RESPONSE = 3001;
//integer MENUNAME_REMOVE = 3003;

//integer RLV_CMD = 6000;
//integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.
//integer RLV_CLEAR = 6002;//RLV plugins should clear their restriction lists upon receiving this message.

//integer ANIM_START = 7000;//send this with the name of an anim in the string part of the message to play the anim
//integer ANIM_STOP = 7001;//send this with the name of an anim in the string part of the message to stop the anim
/*
integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;
integer SENSORDIALOG = -9003;
//integer FIND_AGENT = -9005;
integer KB_LOG_REPORT_STATUS       = -34721;
integer LINK_KB_VERS_REQ = -75301;
integer LINK_KB_VERS_RESP = -75302;
integer LINK_SAYING1               = -75336;
integer CLEAR_SAYING1			   = -75337;
integer SAYING1_CLEARED			   = -75337;
*/
integer KB_COLLAR_VERSION		   = -34847;
integer KB_READY_SAYINGS		   = -34848;
integer KB_SEND_SAYINGS			   = -34849;
integer KB_SET_SAYING			   = -34850;

/*
//added for attachment auth (garvin)
integer AUTH_REQUEST = 600;
integer AUTH_REPLY = 601;
*/
//string UPMENU = "BACK";
//integer g_iCaptureIsActive=FALSE; // If this flag is set, then auth will deny access to it's menus
//integer g_iOpenAccess; // 0: disabled, 1: openaccess
//integer g_iLimitRange=1; // 0: disabled, 1: limited
//integer g_iOwnSelf; // self-owned wearers
//string g_sFlavor = "OwnSelf";
/*
list g_lMenuIDs;
integer g_iMenuStride = 3;
*/
integer g_iListenHandle = 0;
// Get Group or Token, 0=Group, 1=Token
//string SplitToken(string sIn, integer iSlot) {
//    integer i = llSubStringIndex(sIn, "_");
//    if (!iSlot) return llGetSubString(sIn, 0, i - 1);
//    return llGetSubString(sIn, i + 1, -1);
//}
/*
// To add new entries at the end of Groupings
integer GroupIndex(string sToken) {
    sToken = llToLower(sToken);
    string sGroup = SplitToken(sToken, 0);
    integer i = llGetListLength(g_lCollarSettings) - 1;
    // start from the end to find last instance, +2 to get behind the value
    for (; ~i ; i -= 2) {
        if (SplitToken(llList2String(g_lCollarSettings, i - 1), 0) == sGroup) return i + 1;
    }
    return -1;
}

list SetSetting(string sToken, string sValue) {
    sToken = llToLower(sToken);
    // if (g_bDebugOn) DebugOutput(5, ["SetSetting", sToken, sValue]);
    integer idx = llListFindList(g_lCollarSettings, [sToken]);
    if (~idx) return llListReplaceList(g_lCollarSettings, [sValue], idx + 1, idx + 1);
    idx = GroupIndex(sToken);
    if (~idx) return llListInsertList(g_lCollarSettings, [sToken, sValue], idx);
    return g_lCollarSettings + [sToken, sValue];
}

DelSetting(string sToken) {
    sToken = llToLower(sToken);
    integer i = llGetListLength(g_lCollarSettings) - 1;
    i = llListFindList(g_lCollarSettings, [sToken]);
    if (~i) g_lCollarSettings = llDeleteSubList(g_lCollarSettings, i, i + 1);
}
//
//    FindMajorMinor (major_minor being searched)
//
//    Step through the settings sent by kb_settings_host to see if the input major_minor pair is there
//        If it is, return its index; if it's not, return -1
//

integer FindMajorMinor(list lInput, string sInput) {
    integer iInputIdx = 0;
    integer iInputLen = llGetListLength(lInput);
   
    while (iInputIdx < iInputLen) {
        list lParams = llParseString2List(llList2String(lInput, iInputIdx), ["="], []); 
        // now [0] = "major_minor" and [1] = "value"
        string sToken = llList2String(lParams, 0); // now SToken = "major_minor"
        string sValue = llList2String(lParams, 1); // now sValue = "value"
        if (llToLower(sToken) == llToLower(sInput)) return iInputIdx;
        ++iInputIdx;
    }
    return -1;
}
*/
InitListen() {
    // if (g_bDebugOn) DebugOutput(5, ["InitListen", g_iListenHandle, KB_HAIL_CHANNEL00]);
    if (g_iListenHandle == 0) g_iListenHandle = llListen(KB_HAIL_CHANNEL01, "", "", "");
}

DeleteListen() {
    // if (g_bDebugOn) DebugOutput(5, ["DeleteListen", g_iListenHandle, KB_HAIL_CHANNEL00]);
    if (g_iListenHandle != 0) { llListenRemove(g_iListenHandle); g_iListenHandle = 0; }
}


InitVariables() {
    g_iDebugCounter = 0;
    g_iPingCounter = 0;
//    g_lCollarSettings = [];
    g_lSayings = [];
//    g_lSayings1 = [];
    g_iLineNr = 0;
//    g_bGotSayings = FALSE;
    g_bGotSayings = FALSE;
    g_sCollarVersion = "not set";
}

integer MergeInputSayings(list lInput) {
    integer iIdx = 0;
    integer iLimit = llGetListLength(lInput);
    integer iSayingsIdx = 0;
    while (iIdx < iLimit) {
        string sWork = llList2String(lInput, iIdx);
        if (sWork == "kbhostaction=done") return TRUE;
        // if (g_bDebugOn) { DebugOutput(0, ["MergeInputSayings in loop", iIdx, iLimit, sWork]); }
        integer bFound = llListFindList(g_lSayings, [sWork]);
        if (!bFound) {
            g_lSayings += [sWork];
        } 
        ++iIdx;
    }
    return FALSE;
}

default {
    on_rez(integer iParam){
        if (g_bDebugOn) DebugOutput(5, ["default", "on_rez", iParam]);
        if(llGetOwner()!=g_kWearer) llResetScript();
        state init_params;
    }
    
    state_entry()
    {
        if (g_bDebugOn) DebugOutput(5, ["default", "state_entry", llGetFreeMemory(), "bytes free"]);
        if(llGetStartParameter()!=0)state inUpdate;
        g_kWearer = llGetOwner();
        state init_params;
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
        InitListen();
        if (g_bDebugOn) DebugOutput(5, ["init_params", "state_entry", "link_message pinging", KB_HAIL_CHANNEL01]);
//        llSleep(2.0);
        g_lSayings = [];
        llRegionSay(KB_HAIL_CHANNEL01, "ping801");        
        g_iPingCounter = 0;
        g_fStartDelay = 15.0;
        llSetTimerEvent(g_fStartDelay);
    }
    
    link_message(integer iSender,integer iNum,string sStr,key kID) {
        if (iNum == KB_COLLAR_VERSION) {
            g_sCollarVersion = sStr;
        }
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
        if (g_bDebugOn) DebugOutput(5, ["init_params", "listen-1", "listen heard", sName, (string) kId, sMessage]);
        llSetTimerEvent(0.0);
        list lHostSayings = llParseString2List(sMessage, ["%%"], [""]);
        string sFirst = llList2String(lHostSayings, 0);
        string sEndFlag = "kbhostaction=done";
        string sLineID = "";
        string sLineVal = "";
        integer iLineID = 0;
        list lTemp = llParseString2List(sFirst, ["="], [""]);
        sLineID = llList2String(lTemp, 0);
        if (llGetListLength(lTemp) > 1) { sLineVal = llList2String(lTemp, 1); iLineID = llList2Integer(lTemp, 1); }
//
//    TODO: if there ever are enough host sayings to require two messages, this code won't handle it properly
//
        if (sLineID == "kbhostline") {
            if (g_bDebugOn) { list lTemp = ["init_params", "listen-2", "sayings from kb_settings_host"] + lHostSayings; DebugOutput(3, lTemp); }
            list lOutputSayings = llDeleteSubList(lHostSayings, 0, 1);
            if (MergeInputSayings(lOutputSayings)) {
                if (g_bDebugOn) { list lTemp = ["init_params", "listen-3", "sayings ready for output"] + g_lSayings; DebugOutput(5, lTemp); }
                g_bGotSayings = TRUE;
            }
        } else if (sLineID == "kbnosayings") {
             if (g_bDebugOn) { list lTemp = ["init_params", "listen-4", "no sayings found"] + g_lSayings; DebugOutput(5, lTemp); }
            g_lSayings = [];
            g_bGotSayings = TRUE;
        } else if (sLineID == "Notify") {
            if (g_bDebugOn) { list lTemp = ["init_params", "listen-5"] + llParseString2List(sFirst, [" "], [""]); DebugOutput(3, lTemp); }
            list lTemp = llParseString2List(sLineVal, [" "], [""]);
            string sCardNr = llList2String(lTemp, 1);
            integer iCardNr = (integer) sCardNr;
            if (iCardNr == 1) {
                g_lSayings = [];
                g_bGotSayings = TRUE;                
            }
        }
        if (g_bGotSayings) {
            if (g_bDebugOn) DebugOutput(4, ["init_params", "listen-6", "sayings fetched"]);
            llSetTimerEvent(0.0);
            DeleteListen();
            if (g_bDebugOn) DebugOutput(4, ["init_params", "listen", "mandatory sayings"] + g_lSayings);            
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
        //
        //    At this point, g_lSayings has all of the sayings retrieved from sayings_host
        //    g_lCollarsayings has the sayings retrieved from oc_sayings
        //    Now we check each mandatory setting to be sure it's set properly in the collar
        //

        if (g_bDebugOn) DebugOutput(0, ["Merge Sayings-1"]);
//        g_bMergeInProgress = TRUE;
        integer iSayingsLen = llGetListLength(g_lSayings);
        if (g_bDebugOn) DebugOutput(0, ["Merge Sayings-2", iSayingsLen]);

        if (iSayingsLen > 0) llMessageLinked(LINK_SET, KB_READY_SAYINGS, "", "");
    }

    link_message(integer iSender,integer iNum,string sStr,key kID) {
        if (iNum == KB_COLLAR_VERSION) {
            g_sCollarVersion = sStr;
        } else if (iNum == KB_SEND_SAYINGS) {
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
            }
            ++iSayingsIdx;
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