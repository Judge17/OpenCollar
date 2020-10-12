// kb_sync00

string  KB_VERSIONMAJOR      = "8";
string  KB_VERSIONMINOR      = "0";
string  KB_DEVSTAGE          = "1a911";
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

integer g_bDebugOn = FALSE;
integer g_iDebugLevel = 10;
integer KB_DEBUG_CHANNEL           = -617783;
integer g_iDebugCounter = 0;
integer g_iPingCounter = 0;
integer g_bMergeInProgress = FALSE;

key     g_kWearer;

key g_kGroup = "";
integer g_iGroupEnabled = FALSE;

string g_sParentMenu = "Apps";
string g_sSubMenu = "KBSync";
integer g_iRunawayDisable=0;
integer g_iSWActive = 1;
integer KB_HAIL_CHANNEL = -317783;
integer KB_HAIL_CHANNEL00 = -317784;
list g_lCollarSettings = [];
list g_lMandatoryValues = [];
//list g_lSayings1 = [];
float g_fStartDelay = 0.0;
integer g_bGotSettings = FALSE;
integer g_bGotSayings = FALSE;
integer g_iSettings = 0;
//integer g_iSayings1 = 0;
integer g_iLineNr = 0;
key 	g_kVersionID;
string  g_sTargetCard = ".version";
integer g_bGatherStarted = FALSE;

//integer g_iKBarOptions=0;
//integer g_iGirlStatus=0; // 0=guest, 1=protected, 2=slave
//integer g_iLockStatus=1; // disallow status changes
integer g_iLogLevel = 0; // minimal logging
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
integer NOTIFY = 1002;
integer NOTIFY_OWNERS = 1003;
integer LOADPIN = -1904;
integer LINK_CMD_DEBUG = 1999;
integer REBOOT              = -1000;
integer LINK_UPDATE = -10;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved
//str must be in form of "token=value"
integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the settings script sends responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from settings
integer LM_SETTING_EMPTY = 2004;//sent when a token has no value

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
string SplitToken(string sIn, integer iSlot) {
    integer i = llSubStringIndex(sIn, "_");
    if (!iSlot) return llGetSubString(sIn, 0, i - 1);
    return llGetSubString(sIn, i + 1, -1);
}

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

InitListen() {
    // if (g_bDebugOn) DebugOutput(5, ["InitListen", g_iListenHandle, KB_HAIL_CHANNEL00]);
    if (g_iListenHandle == 0) g_iListenHandle = llListen(KB_HAIL_CHANNEL00, "", "", "");
}

DeleteListen() {
    // if (g_bDebugOn) DebugOutput(5, ["DeleteListen", g_iListenHandle, KB_HAIL_CHANNEL00]);
    if (g_iListenHandle != 0) { llListenRemove(g_iListenHandle); g_iListenHandle = 0; }
}


InitVariables() {
    g_iDebugCounter = 0;
    g_iPingCounter = 0;
    g_lCollarSettings = [];
    g_lMandatoryValues = [];
//    g_lSayings1 = [];
    g_iLineNr = 0;
    g_bGotSettings = FALSE;
//    g_bGotSayings = FALSE;
    g_sCollarVersion = "not set";
}

integer MergeInputSettingsToMandatory(list lInput) {
    integer iIdx = 0;
    integer iLimit = llGetListLength(lInput);
    integer iMandIdx = 0;
    while (iIdx < iLimit) {
        string sWork = llList2String(lInput, iIdx);
//        if (g_bDebugOn) { DebugOutput(0, ["MergeInputSettingsToMandatory in loop", iIdx, iLimit, sWork]); }
        list lParams = llParseString2List(sWork, ["="], []); // now [0] = "major_minor" and [1] = "value"
        // if (g_bDebugOn) { list lTmp = ["MergeInputSettingsToMandatory"] + lParams; DebugOutput(0, lTmp); }
        string sToken = llList2String(lParams, 0); // now SToken = "major_minor"
//        if (g_bDebugOn) { list lTmp = ["MergeInputSettingsToMandatory"] + [sToken] + lParams + g_lMandatoryValues; DebugOutput(0, lTmp); }
        if (sToken == "kbhostaction") return FALSE;
        if (sToken != "kbhostline") {
            string sValue = llList2String(lParams, 1); // now sValue = "value"
            integer iMandPtr = FindMajorMinor(g_lMandatoryValues, sToken);  // see if this collar major_minor entry already exists in the host set
            if (iMandPtr < 0) g_lMandatoryValues += [sToken, sValue];
            else {
                list lTemp = [sToken, sValue];
                g_lMandatoryValues = llListReplaceList(g_lMandatoryValues, lTemp, iMandPtr, iMandPtr + 1);
            }
        }
        ++iIdx;
    }
    return TRUE;
}
//
//    At this point, g_lMandatoryValues has all of the settings retrieved from settings_host
//    g_lCollarSettings has the settings retrieved from oc_settings
//    Now we check each mandatory setting to be sure it's set properly in the collar
//

MergeMandatorySettings() {
    // if (g_bDebugOn) { list lTmp = ["MergeMandatorySettings-1"] + [g_bMergeInProgress]; DebugOutput(0, lTmp); }
    g_bMergeInProgress = TRUE;
    integer iMandLen = llGetListLength(g_lMandatoryValues);
//    if (g_bDebugOn) { list lTmp = ["MergeMandatorySettings-2"] + [iMandLen]; DebugOutput(0, lTmp); }
    if (iMandLen == 0) return;
    integer iMandIdx = 0;
    integer iCollarIdx = 0;
    while (iMandIdx < iMandLen) {
        // if (g_bDebugOn) { list lTmp = ["MergeMandatorySettings-3"] + [iMandIdx, iMandLen]; DebugOutput(0, lTmp); }
        string sMandToken = llList2String(g_lMandatoryValues, iMandIdx);
        integer iCollarPtr = llListFindList(g_lCollarSettings, [sMandToken]);
        if (iCollarPtr >= 0) {
            string sMandValue = llList2String(g_lMandatoryValues, iMandIdx + 1);
            string sCollarValue = llList2String(g_lCollarSettings, iCollarPtr + 1);
//            if (g_bDebugOn) { list lTmp = ["MergeMandatorySettings-4"] + [sMandToken, sMandValue, sCollarValue]; DebugOutput(0, lTmp); }
            if (sMandValue != sCollarValue) {
//                if (g_bDebugOn) { list lTmp = ["MergeMandatorySettings-5"] + [sMandToken + "=" + sMandValue]; DebugOutput(0, lTmp); }
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, sMandToken + "=" + sMandValue, "");
            }
        }
        iMandIdx+=2;
    }
    g_bMergeInProgress = FALSE;
    // if (g_bDebugOn) { list lTmp = ["MergeMandatorySettings-6"] + [g_bMergeInProgress]; DebugOutput(0, lTmp); }
}

default {
    on_rez(integer iParam){
        // if (g_bDebugOn) DebugOutput(5, ["default", "on_rez", iParam]);
        if(llGetOwner()!=g_kWearer) llResetScript();
        state init_version;
    }
    state_entry()
    {
        // if (g_bDebugOn) DebugOutput(5, ["default", "state_entry", llGetFreeMemory(), "bytes free"]);
        if(llGetStartParameter()!=0)state inUpdate;
        g_kWearer = llGetOwner();
        state init_version;
    }
    state_exit()
    {
        // if (g_bDebugOn) DebugOutput(5, ["default", "state_exit", llGetFreeMemory(), "bytes free"]);
    }
}

state init_version {
//
//    if the on_rez event is raised while we are in this state, just stop and let default take over; default will switch back to us, and we'll pick back up at state-entry
//
    on_rez(integer iParam){
        // if (g_bDebugOn) DebugOutput(5, ["init_version", "on_rez", iParam]);
        if(llGetOwner()!=g_kWearer) llResetScript();
        state default;
    }
    
    state_entry() {
        // if (g_bDebugOn) DebugOutput(5, ["init_version", "state_entry", llGetFreeMemory(), "bytes free"]);
        InitVariables();
        if (llGetInventoryKey(g_sTargetCard) == NULL_KEY) { 
            // if (g_bDebugOn) DebugOutput(0, [g_sTargetCard, "not found"]); 
            state init_params; 
        }

        g_kVersionID = llGetNotecardLine(g_sTargetCard, g_iLineNr);
        llSetTimerEvent(30.0);
    }

    timer() {
        // if (g_bDebugOn) DebugOutput(5, ["init_version", "timer"]);
        llSetTimerEvent(0.0);
        llMessageLinked(LINK_SET, KB_COLLAR_VERSION, "not set", "");
        state init_params;
    }
    
    dataserver(key kID, string sData) {
        // if (g_bDebugOn) DebugOutput(0, ["init_version", "dataserver", kID, g_kVersionID, sData]);
        if (kID == g_kVersionID) {
            if (sData != EOF) {
                string sWork = llStringTrim(sData, STRING_TRIM);
                if (sWork != "") {
                    list lData = llParseString2List(sWork, ["="], []);
                    if (llGetListLength(lData) > 1) {
                        if (llList2String(lData, 0) == "version") {
                            g_sCollarVersion = llList2String(lData, 1);
                            llSetTimerEvent(0.0);
                            llMessageLinked(LINK_SET, KB_COLLAR_VERSION, g_sCollarVersion, "");
                            state init_params;
                        }
                    } else 
                        g_kVersionID = llGetNotecardLine(g_sTargetCard, g_iLineNr);
                }
            } else {
                llSetTimerEvent(0.0);
                llMessageLinked(LINK_SET, KB_COLLAR_VERSION, "not set", "");
                state init_params;
            }
        }
    } 

    state_exit()
    {
        llSetTimerEvent(0.0);
        // if (g_bDebugOn) DebugOutput(5, ["init_version", "state_exit", llGetFreeMemory(), "bytes free"]);
    }
}

state init_params {
//
//    if the on_rez event is raised while we are in this state, just stop and let default take over; default will switch back to us, and we'll pick back up at state-entry
//
    on_rez(integer iParam){
        // if (g_bDebugOn) DebugOutput(5, ["init_params", "on_rez", iParam]);
        state default;
    }
    
    state_entry() {
        // if (g_bDebugOn) DebugOutput(5, ["init_params", "state_entry", llGetFreeMemory(), "bytes free"]);
        InitListen();
        // if (g_bDebugOn) DebugOutput(5, ["init_params", "state_entry", "link_message pinging", KB_HAIL_CHANNEL00]);
//        llSleep(2.0);
        llRegionSay(KB_HAIL_CHANNEL00, "ping801");        
        g_iPingCounter = 0;
        g_fStartDelay = 15.0;
        llSetTimerEvent(g_fStartDelay);
    }
    
    timer() {
        // if (g_bDebugOn) DebugOutput(5, ["init_params", "timer"]);
        llSetTimerEvent(0.0);
        ++g_iPingCounter;
        // if (g_bDebugOn) DebugOutput(5, ["init_params", "timer", "link_message pinging", KB_HAIL_CHANNEL00]);
        llRegionSay(KB_HAIL_CHANNEL00, "ping801");     
        g_fStartDelay = (float) (45*g_iPingCounter);
        llSetTimerEvent(g_fStartDelay);
    }
//
//    kb_settings_host collects any mandatory settings values for this specific collar and send them in large batches
//    Each batch is a list in string form with settings keys and values separated by '%%' and is sent via chat on the hailing channel
//    kb_settings_host uses llRegionSayTo, so there is no chance of confusion between collar destinations
//    A batch sequence number appears as 'kbhostline=nnn' in each batch; 'kbhostaction=done' signals that all values have been sent
//
//    Starting in 8.0.1a9, 'kbnosettings' indicates that no mandatory settings values were found for this collar
//
//    Notify = No 00 Card means the same thing
//
//
    listen(integer iChannel, string sName, key kId, string sMessage) {
        // if (g_bDebugOn) DebugOutput(5, ["init_params", "listen"]);
        // if (g_bDebugOn) DebugOutput(5, ["init_params", "listen-1", "listen heard", sName, (string) kId, sMessage]);
        llSetTimerEvent(0.0);
        list lHostSettings = llParseString2List(sMessage, ["%%"], [""]);
        string sFirst = llList2String(lHostSettings, 0);
        string sEndFlag = "kbhostaction=done";
        string sLineID = "";
        string sLineVal = "";
        integer iLineID = 0;
        list lTemp = llParseString2List(sFirst, ["="], [""]);
        sLineID = llList2String(lTemp, 0);
        if (llGetListLength(lTemp) > 1) { sLineVal = llList2String(lTemp, 1); iLineID = llList2Integer(lTemp, 1); }
        if (sLineID == "kbhostline" || sLineID == "kbhostaction") {
//            if (g_bDebugOn) { list lTemp = ["init_params", "listen-2", "settings from kb_settings_host"] + lHostSettings; DebugOutput(3, lTemp); }
//            list lOutputSettings = llDeleteSubList(lHostSettings, 0, 1);
            if (MergeInputSettingsToMandatory(lHostSettings)) {
                if (sLineID == "kbhostaction") {
                    // if (g_bDebugOn) { list lTemp = ["init_params", "listen-3", "settings ready for output"] + g_lMandatoryValues; DebugOutput(5, lTemp); }
                    g_bGotSettings = TRUE;
                } 
            } else {
                g_bGotSettings = TRUE;
            }
        } else if (sLineID == "kbnosettings") {
            // if (g_bDebugOn) { list lTemp = ["init_params", "listen-4", "no settings found"] + g_lMandatoryValues; DebugOutput(5, lTemp); }
            g_lMandatoryValues = [];
            g_bGotSettings = TRUE;
        } else if (sLineID == "Notify") {
            // if (g_bDebugOn) { list lTemp = ["init_params", "listen-5"] + llParseString2List(sFirst, [" "], [""]); DebugOutput(3, lTemp); }
            list lTemp = llParseString2List(sLineVal, [" "], [""]);
            string sCardNr = llList2String(lTemp, 1);
            integer iCardNr = (integer) sCardNr;
            if (iCardNr == 0) {
                g_lMandatoryValues = [];
                g_bGotSettings = TRUE;                
            }
        }
        if (g_bGotSettings) {
//            DebugOutput(4, ["init_params", "listen-6", "settings fetched"]);
            llSetTimerEvent(0.0);
            DeleteListen();
//            list lTmp = ["init_params", "listen", "mandatory settings"] + g_lMandatoryValues;
//            DebugOutput(4, lTmp);            
            state gather_settings;
        }
    }

    state_exit()
    {
        llSetTimerEvent(0.0);
        // if (g_bDebugOn) DebugOutput(5, ["init_params", "state_exit", llGetFreeMemory(), "bytes free"]);
    }
}

state gather_settings {
//
//    if the on_rez event is raised while we are in this state, just stop and let default take over; default will switch back to us, and we'll pick back up at state-entry
//
    on_rez(integer iParam){
        // if (g_bDebugOn) DebugOutput(5, ["gather_settings", "on_rez", iParam]);
        state default;
    }
    
    state_entry() {
        // if (g_bDebugOn) DebugOutput(5, ["gather_settings", "state_entry", llGetFreeMemory(), "bytes free"]);
        g_lCollarSettings = [];
        g_bGatherStarted = FALSE;
        g_fStartDelay = 60.0;
        llSetTimerEvent(g_fStartDelay);
    }
    
    link_message(integer iSender,integer iNum,string sStr,key kID){
        if (iNum == LM_SETTING_RESPONSE) {
            // if (g_bDebugOn) DebugOutput(5, ["gather_settings", "link_message", "setting_response", iSender, iNum, sStr, kID]);
            if (sStr == "settings=sent" && g_bGatherStarted) {
//                if (g_bDebugOn) { list lTmp = ["gather_settings", "link_message", "gathered settings"] + g_lCollarSettings; DebugOutput(5, lTmp); }
                llSetTimerEvent(0.0);
                state sync_settings;
            }
            list lTmp = llParseString2List(sStr, ["="], []);
            string sTok = llList2String(lTmp, 0);
            string sVal = llList2String(lTmp, 1);
            g_lCollarSettings = SetSetting(sTok, sVal);            
        } else if(iNum == LM_SETTING_EMPTY) {
            // if (g_bDebugOn) DebugOutput(5, ["gather_settings", "link_message", "setting_empty", iSender, iNum, sStr, kID]);
            string sTok = sStr;
            g_lCollarSettings = SetSetting(sTok, "null");            
        }
    }
    
    timer() {
//        if (g_bDebugOn) DebugOutput(5, ["gather_settings", "timer", g_bGatherStarted]);
        if (g_bGatherStarted) {
            llSetTimerEvent(0.0);
            state sync_settings;
        }
        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "ALL", g_kWearer);
        g_bGatherStarted = TRUE;
    }

    state_exit()
    {
        llSetTimerEvent(0.0);
        // if (g_bDebugOn) DebugOutput(5, ["gather_settings", "state_exit", llGetFreeMemory(), "bytes free"]);
    }
    
}

state sync_settings {
//
//    if the on_rez event is raised while we are in this state, just stop and let default take over; default will switch back to us, and we'll pick back up at state-entry
//

    on_rez(integer iParam){
        // if (g_bDebugOn) DebugOutput(5, ["sync_settings", "on_rez", iParam]);
        state default;
    }
    
    state_entry() {
        // if (g_bDebugOn) { list lTmp = ["sync_settings", "state_entry", llGetFreeMemory(), "bytes free", "Mandatory:"] + g_lMandatoryValues; DebugOutput(0, lTmp); }
        MergeMandatorySettings();
    }
    
    link_message(integer iSender,integer iNum,string sStr,key kID){
        if (iNum == LM_SETTING_RESPONSE) {
            // if (g_bDebugOn) DebugOutput(5, ["sync_settings", "link_message", "setting_response", iSender, iNum, sStr, kID]);
            list lTmp = llParseString2List(sStr, ["="], []);
            string sTok = llList2String(lTmp, 0);
            string sVal = llList2String(lTmp, 1);
            g_lCollarSettings = SetSetting(sTok, sVal);
            if (g_bMergeInProgress) llSetTimerEvent(5.0); else MergeMandatorySettings();
        } else if(iNum == LM_SETTING_EMPTY) {
            // if (g_bDebugOn) DebugOutput(5, ["gather_settings", "link_message", "setting_empty", iSender, iNum, sStr, kID]);
            string sTok = sStr;
            g_lCollarSettings = SetSetting(sTok, "null");            
            if (g_bMergeInProgress) llSetTimerEvent(5.0); else MergeMandatorySettings();
        }
    }
    
    timer() {
        // if (g_bDebugOn) DebugOutput(5, ["sync_settings", "timer", g_bMergeInProgress]);
        if (!g_bMergeInProgress) {
            llSetTimerEvent(0.0);
            MergeMandatorySettings();
        }
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


// kb_sync00