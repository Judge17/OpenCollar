// kb_sync802_00

string  KB_VERSIONMAJOR      = "8";
string  KB_VERSIONMINOR      = "0";
string  KB_DEVSTAGE          = "400030";
// LEGEND: Major.Minor.ijklmm i=Build j=RC k=Beta l=Alpha mm=KBar Version
string  g_sCollarVersion = "not set";

key KURT_KEY   = "4986014c-2eaa-4c39-a423-04e1819b0fbf";

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

//SetDebugOn() {
//    g_bDebugOn = TRUE;
//    g_iDebugLevel = 0;
//    g_iDebugCounter = 0;
//}
//
//SetDebugOff() {
//    g_bDebugOn = FALSE;
//    g_iDebugLevel = 10;
//}
//
integer g_bDebugOn = FALSE;
integer g_iDebugLevel = 10;
integer KB_DEBUG_CHANNEL           = -617783;
integer g_iDebugCounter = 0;
integer g_iPingCounter = 0;
integer g_iCardRequested = 0;

key     g_kWearer;

//integer KB_HAIL_CHANNEL = -317783;
integer KB_HAIL_CHANNEL00 = -317784;
list g_lCollarSettings = [];
//  list of setttings pulled from the master controller, list format: [Major=Minor, Value] (list of tuples)
list g_lMandatoryValues = [];
float g_fStartDelay = 0.0;
integer g_bGotSettings = FALSE;
integer g_iLineNr = 0;
key     g_kVersionID;
string  g_sTargetCard = ".version";
integer g_bGatherStarted = FALSE;
integer g_bGatherFinished = FALSE;
integer g_bSynchronize = FALSE;
integer g_bStartingSyncValue = FALSE;

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
//integer NOTIFY_OWNERS = 1003;
//integer LOADPIN = -1904;
//integer LINK_CMD_DEBUG = 1999;
integer REBOOT              = -1000;
//integer LINK_UPDATE = -10;
//
integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved
//str must be in form of "token=value"
integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the settings script sends responses on this channel
//integer LM_SETTING_DELETE = 2003;//delete token from settings
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
integer CLEAR_SAYING1               = -75337;
integer SAYING1_CLEARED               = -75337;
*/
integer KB_COLLAR_VERSION           = -34847;
integer KB_REQUEST_VERSION         = -34591;
/*
//added for attachment auth (garvin)
integer AUTH_REQUEST = 600;
integer AUTH_REPLY = 601;
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
    if (sToken == "kbsync00_synchronize") g_bSynchronize = IsTrue(sValue);
//    if (g_bDebugOn) DebugOutput(5, ["SetSetting", sToken, sValue]);
    integer idx = llListFindList(g_lCollarSettings, [sToken]);
    if (~idx) return llListReplaceList(g_lCollarSettings, [sValue], idx + 1, idx + 1);
    idx = GroupIndex(sToken);
    if (~idx) return llListInsertList(g_lCollarSettings, [sToken, sValue], idx);
    return g_lCollarSettings + [sToken, sValue];
}

//DelSetting(string sToken) {
//    sToken = llToLower(sToken);
//    integer i = llGetListLength(g_lCollarSettings) - 1;
//    i = llListFindList(g_lCollarSettings, [sToken]);
//    if (~i) g_lCollarSettings = llDeleteSubList(g_lCollarSettings, i, i + 1);
//}
//
//    FindMajorMinor (major_minor being searched)
//
//    Step through the settings sent by kb_settings_host to see if the input major_minor pair is there
//        If it is, return its index; if it's not, return -1
//

integer IsTrue(string sInput) {
    if ((sInput == "Y") || (sInput == "y") || (sInput == "T") || (sInput == "t")) return TRUE;
    integer iInput = (integer) sInput;
    if (iInput == 0) return FALSE;
    return TRUE;
}

integer FindMajorMinor(string sMajor, string sMinor) {
    string sKey = llToLower(sMajor) + "_" + llToLower(sMinor);

    integer iOffset = llListFindList(g_lMandatoryValues, [sKey]);
    
    return iOffset;
}

InitListen() {
    //  if (g_bDebugOn) DebugOutput(5, ["InitListen", g_iListenHandle, KB_HAIL_CHANNEL00]);
    if (g_iListenHandle == 0) g_iListenHandle = llListen(KB_HAIL_CHANNEL00, "", "", "");
}

DeleteListen() {
    //  if (g_bDebugOn) DebugOutput(5, ["DeleteListen", g_iListenHandle, KB_HAIL_CHANNEL00]);
    if (g_iListenHandle != 0) { llListenRemove(g_iListenHandle); g_iListenHandle = 0; }
}


InitVariables() {
    g_kWearer == llGetOwner();
    g_iDebugCounter = 0;
    g_iPingCounter = 0;
    g_lCollarSettings = [];
    g_lMandatoryValues = [];
    g_iLineNr = 0;
    g_bGotSettings = FALSE;
    g_sCollarVersion = "not set";
    g_bStartingSyncValue = g_bSynchronize;
    
}

//
//    CheckMandatory accepts a string that is a settings entry in the format major_minor=value
//    It checks g_lMandatoryValues to see if there is a required value for this major_minor
//    If there is not, it returns a list [FALSE, 0, "major_minor", ""]
//    If there is, it returns a list [TRUE, (offset pointer), "major_minor", "value"]
//    If the setting is actually metadata from settings_host, it returns [FALSE, 0, "metadata", (token)]
//

list CheckMandatory(string sStr) {
    integer iMinor = llSubStringIndex(sStr, "=");
    string sMajor = llToLower(llGetSubString(sStr, 0, iMinor - 1));
    string sWork = llGetSubString(sStr, iMinor + 1, -1);
    integer iValue = llSubStringIndex(sWork, "~");
    string sMinor = llToLower(llGetSubString(sWork, 0, iValue - 1));
    string sValue = llGetSubString(sWork, iValue + 1, -1);
    //  if (g_bDebugOn) { DebugOutput(0, ["CheckMandatory-1", sMajor, sMinor, sValue]); }
    integer iMandPtr = FindMajorMinor(sMajor, sMinor);  // see if this collar major_minor entry already exists in the host set
    if (iMandPtr >= 0) {
        list lTemp = [TRUE, iMandPtr, sMajor, sMinor, llList2String(g_lMandatoryValues, iMandPtr + 1)];
        //  if (g_bDebugOn) { list lTmp = ["CheckMandatory-4"] + lTemp; DebugOutput(0, lTmp); }
        return lTemp;
    }
    //  if (g_bDebugOn) { list lTmp = ["CheckMandatory-5"]; DebugOutput(0, lTmp); }
    return [FALSE, -1, sMajor, sMinor, sValue];
}

integer MergeInputSettingsToMandatory(list lInput) {
    integer iIdx = 1;
    integer iLimit = llGetListLength(lInput);
    integer iMandIdx = 0;
    //  if (g_bDebugOn) { DebugOutput(0, ["MergeInputSettingsToMandatory-1", iIdx, iLimit] + lInput); }
    while (iIdx < iLimit) {
        string sWork = llList2String(lInput, iIdx);
        //  if (g_bDebugOn) { DebugOutput(0, ["MergeInputSettingsToMandatory-2", iIdx, iLimit, sWork]); }
        list lTemp = CheckMandatory(sWork);
        integer bFound = llList2Integer(lTemp, 0);
        integer iIndex = llList2Integer(lTemp, 1);
        string sMajor = llList2String(lTemp, 2);
        string sMinor = llList2String(lTemp, 3);
        string sValue = llList2String(lTemp, 4);
        //  if (g_bDebugOn) { DebugOutput(0, ["MergeInputSettingsToMandatory-3", iIdx, iLimit, bFound, iIndex, sMajor, sMinor , sValue]); }
        if (bFound) {
            g_lMandatoryValues = llListReplaceList(g_lMandatoryValues, [sValue], iIndex + 1, iIndex + 1);
        } else {
            g_lMandatoryValues += [sMajor + "_" + sMinor, sValue];
        }
        ++iIdx;
    }
    return TRUE;
}

string BuildRequestString(integer iRequest) {
    string sReturn = "ping804<>" + (string) iRequest;
    return sReturn;
}

SendRequest(integer iRequest) {
    llSetTimerEvent(0.0);
    //  if (g_bDebugOn) DebugOutput(5, ["SendRequest", iRequest, BuildRequestString(iRequest), g_fStartDelay]);
    llSetTimerEvent(g_fStartDelay);
    llRegionSay(KB_HAIL_CHANNEL00, BuildRequestString(iRequest));
}

//
//  Cribbed from oc_settings
//

//PrintAll(key kID){
//    integer i=0;
//    integer end = llGetListLength(g_lMandatoryValues);
//    llMessageLinked(LINK_SET, NOTIFY, "0KBar Collar Mandatory Settings: ",kID);
//    llMessageLinked(LINK_SET, NOTIFY, "0settings=nocomma~1", kID);
//    for(i=0;i<end;i+=2){
//        list lTmp = llParseStringKeepNulls(llList2String(g_lMandatoryValues,i),["_"],[]);
//        string sTok = llList2String(lTmp,0);
//        string sVar = llDumpList2String(llList2List(lTmp,1,-1), "_");
//        integer iProcess=TRUE;
//        if(llToLower(sTok)=="settings" && llToLower(sVar) == "nocomma") iProcess=FALSE;
//
//        if(iProcess){
//            integer iStart=TRUE;
//            // Start calculating output
//            string sVal = GetSetting(sTok+"_"+sVar);
//
//            while(sVal!="" && sVal != "NOT_FOUND"){
//                llSleep(0.25);
//                if(llStringLength(sTok+"="+sVar+"~"+sVal)>254){
//                    //begin to auto split strings
//                    // first calculate how much we need to cut
//                    integer iPadding = llStringLength(sTok+"="+sVar+"~");
//                    string sDat = llGetSubString(sVal,0, (254-iPadding));
//                    sVal = llGetSubString(sVal, (254-iPadding)+1,-1);
//                    string sSym;
//                    if(iStart){
//                        iStart=FALSE;
//                        sSym="=";
//                    } else sSym="+";
//                    llMessageLinked(LINK_SET, NOTIFY, "0"+sTok+sSym+sVar+"~"+sDat, kID);
//                } else {
//                    if(iStart)
//                        llMessageLinked(LINK_SET, NOTIFY, "0"+sTok+"="+sVar+"~"+sVal, kID);
//                    else
//                        llMessageLinked(LINK_SET, NOTIFY, "0"+sTok+"+"+sVar+"~"+sVal,kID);
//                    iStart=FALSE;
//                    sVal="";
//                }
//            }
//        }
//    }
//}
//
//string GetSetting(string sToken) {
//    integer i = llListFindList(g_lMandatoryValues, [llToLower(sToken)]);
//    if(i == -1)return "NOT_FOUND";
//    return llList2String(g_lMandatoryValues, i + 1);
//}
//

HandleLinkMessage(integer iSender, integer iNum, string sStr, key kID, string sState) {
    if (iNum == REBOOT) {
        if(sStr == "reboot") {
            llResetScript();
        }
    } else if(iNum == READY) {
        llMessageLinked(LINK_SET, ALIVE, llGetScriptName(), "");
    } else if (iNum == LM_SETTING_RESPONSE) {
        //  if (g_bDebugOn) DebugOutput(5, [sState, "link_message", "setting_response", iSender, iNum, sStr, kID]);
        g_bGatherStarted = TRUE;
        if (sStr == "settings=sent") {
            //. if (g_bDebugOn) { list lTmp = [sState, "link_message", "gathered settings"] + g_lCollarSettings; DebugOutput(5, lTmp); }
            g_bGatherFinished = TRUE;
        }
        list lTmp = llParseString2List(sStr, ["="], []);
        string sTok = llList2String(lTmp, 0);
        string sVal = llList2String(lTmp, 1);
        g_lCollarSettings = SetSetting(sTok, sVal);
    } else if(iNum == LM_SETTING_EMPTY) {
        //. if (g_bDebugOn) DebugOutput(5, [sState, "link_message", "setting_empty", iSender, iNum, sStr, kID]);
        g_bGatherStarted = TRUE;
        string sTok = sStr;
        g_lCollarSettings = SetSetting(sTok, "null");
    } else if (iNum == KB_COLLAR_VERSION) g_sCollarVersion = sStr;
    else if (iNum == KB_REQUEST_VERSION)
        llMessageLinked(LINK_SET,NOTIFY,"0"+llGetScriptName() + " version " + formatVersion(),kID);
}

integer ALIVE = -55;
integer READY = -56;
integer STARTUP = -57;
//
default {
    on_rez(integer iNum){
        llResetScript();
    }

    state_entry() {
//        llOwnerSay(llGetScriptName() + " default state_entry " + (string) llGetFreeMemory());
        llMessageLinked(LINK_SET, ALIVE, llGetScriptName(),"");
        g_bGatherStarted = FALSE;
        g_bGatherFinished = FALSE;
        state init_version;
    }
    
    link_message(integer iSender, integer iNum, string sStr, key kID) {
        HandleLinkMessage(iSender, iNum, sStr, kID, "default");
    }

    state_exit()
    {
        //. if (g_bDebugOn) DebugOutput(5, ["default", "state_exit", llGetFreeMemory(), "bytes free"]);
    }
}

state init_version {
//
//    if the on_rez event is raised while we are in this state, just stop and let default take over; default will switch back to us, and we'll pick back up at state-entry
//
    on_rez(integer iParam){
        //. if (g_bDebugOn) DebugOutput(5, ["init_version", "on_rez", iParam]);
        llResetScript();
    }
    
    state_entry() {
//        llOwnerSay(llGetScriptName() + " init_version state_entry " + (string) llGetFreeMemory());
        //. if (g_bDebugOn) DebugOutput(5, ["init_version", "state_entry", llGetFreeMemory(), "bytes free"]);
        InitVariables();
        if (llGetInventoryKey(g_sTargetCard) == NULL_KEY) { 
            //  if (g_bDebugOn) DebugOutput(0, [g_sTargetCard, "not found"]); 
            state init_params; 
        }

        g_kVersionID = llGetNotecardLine(g_sTargetCard, g_iLineNr);
        llSetTimerEvent(30.0);
    }

    timer() {
        //. if (g_bDebugOn) DebugOutput(5, ["init_version", "timer"]);
        llSetTimerEvent(0.0);
        llMessageLinked(LINK_SET, KB_COLLAR_VERSION, "not set", "");
        state init_params;
    }
    
    dataserver(key kID, string sData) {
        //  if (g_bDebugOn) DebugOutput(0, ["init_version", "dataserver", kID, g_kVersionID, sData]);
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
    
    link_message(integer iSender, integer iNum, string sStr, key kID) {
        HandleLinkMessage(iSender, iNum, sStr, kID, "init_version");
    }
    
    state_exit()
    {
        llSetTimerEvent(0.0);
        //. if (g_bDebugOn) DebugOutput(5, ["init_version", "state_exit", llGetFreeMemory(), "bytes free"]);
    }
}

state init_params {
//
//    if the on_rez event is raised while we are in this state, just stop and let default take over; default will switch back to us, and we'll pick back up at state-entry
//
    on_rez(integer iParam){
        //. if (g_bDebugOn) DebugOutput(5, ["init_params", "on_rez", iParam]);
        llResetScript();
    }
    
    state_entry() {
        //. if (g_bDebugOn) DebugOutput(5, ["init_params", "state_entry", llGetFreeMemory(), "bytes free"]);
        InitListen();
        //  if (g_bDebugOn) DebugOutput(5, ["init_params", "state_entry", "link_message pinging", KB_HAIL_CHANNEL00]);
        g_iCardRequested = 0;
        g_iPingCounter = 0;
        g_fStartDelay = 30.0;
        SendRequest(0);
    }
    
    timer() {
        //. if (g_bDebugOn) DebugOutput(5, ["init_params", "timer"]);
        llSetTimerEvent(0.0);
        ++g_iPingCounter;
        //  if (g_bDebugOn) DebugOutput(5, ["init_params", "timer", "link_message pinging", KB_HAIL_CHANNEL00]);
        SendRequest(g_iCardRequested);
        g_fStartDelay = (float) (15*g_iPingCounter) + 30;
        if (g_fStartDelay > 92.0) state gather_settings;
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
        llSetTimerEvent(0.0);
        //  if (g_bDebugOn) DebugOutput(5, ["init_params", "listen-1", "listen heard", sName, (string) kId, sMessage]);
        list lList = llParseString2List(sMessage, ["<>"], [""]);
        string sArgument = "";
        if (llGetListLength(lList) > 0) {
            g_iCardRequested = -1;
            g_iCardRequested = llList2Integer(lList, 0);
            //  if (g_bDebugOn) DebugOutput(5, ["init_params", "listen-2", g_iCardRequested] + lList);
            if (g_iCardRequested == 999) {
                g_iCardRequested = 0;
                //  if (g_bDebugOn) DebugOutput(5, ["init_params", "listen-3", g_iCardRequested]);
                g_iPingCounter = 0;
                state gather_settings;
            }
            if (g_iCardRequested > 0) {
                MergeInputSettingsToMandatory(lList);
            }
                
            llSetTimerEvent(g_fStartDelay);
            ++g_iCardRequested;
            SendRequest(g_iCardRequested);
        } else {
            g_iCardRequested = 0;
            //  if (g_bDebugOn) DebugOutput(5, ["init_params", "listen-4", g_iCardRequested]);
            g_iPingCounter = 0;
            state gather_settings;
        }
    }
    
    link_message(integer iSender, integer iNum, string sStr, key kID) {
        HandleLinkMessage(iSender, iNum, sStr, kID, "init_params");
    }
    
    state_exit()
    {
        llSetTimerEvent(0.0);
        DeleteListen();
        //. if (g_bDebugOn) DebugOutput(5, ["init_params", "state_exit", llGetFreeMemory(), "bytes free", "Mandatory Values:"] + g_lMandatoryValues);
    }
}

state gather_settings {
//
//    if the on_rez event is raised while we are in this state, just stop and let default take over; default will switch back to us, and we'll pick back up at state-entry
//
    on_rez(integer iParam){
        //. if (g_bDebugOn) DebugOutput(5, ["gather_settings", "on_rez", iParam]);
        llResetScript();
    }
    
    state_entry() {
        //  if (g_bDebugOn) DebugOutput(5, ["gather_settings", "state_entry", llGetFreeMemory(), "bytes free"]);
        g_lCollarSettings = [];
        g_fStartDelay = 60.0;
        llSetTimerEvent(g_fStartDelay);
    }
    
    link_message(integer iSender, integer iNum, string sStr, key kID) {
        HandleLinkMessage(iSender, iNum, sStr, kID, "gather_settings");
        if (g_bGatherFinished)
            state sync_settings;
    }
    
    timer() {
        //. if (g_bDebugOn) DebugOutput(5, ["gather_settings", "timer", g_bGatherStarted]);
        if (g_bGatherFinished)
            state sync_settings;
    }

    state_exit()
    {
        llSetTimerEvent(0.0);
        //  if (g_bDebugOn) { list lTmp = ["gather_settings", "state_exit", llGetFreeMemory(), "bytes free", "CollarSettings"] + g_lCollarSettings; DebugOutput(5, lTmp); }
    }
    
}

//
//
//    At this point, g_lMandatoryValues has all of the settings retrieved from settings_host
//    g_lCollarSettings has the settings retrieved from oc_settings
//    Now we check each mandatory setting to be sure it's set properly in the collar
//

state sync_settings {
//
//    if the on_rez event is raised while we are in this state, just stop and let default take over; default will switch back to us, and we'll pick back up at state-entry
//

    on_rez(integer iParam) {
//        llOwnerSay(llGetScriptName() + " sync_settings on_rez " + (string) llGetFreeMemory());
        llResetScript();
    }
    
    state_entry() {
//        llOwnerSay(llGetScriptName() + " sync_settings state_entry " + (string) llGetFreeMemory());
        //  if (g_bDebugOn) { list lTmp = ["sync_settings", "state_entry-1", llGetFreeMemory(), "bytes free", "Mandatory:"] + g_lMandatoryValues; DebugOutput(0, lTmp); }
        if (!g_bSynchronize) state monitor_settings; // if the sync switch is off, skip this
        
//
//  Check each entry in the existing collar settings to see if there is a matching required entry
//  If there is, and the current value in the collar differs from the required value, update it
//

        list lPendingUpdates = [];
        integer iSettingsLength = llGetListLength(g_lCollarSettings);
        integer iSettingsIndex = 0;
        while (iSettingsIndex < iSettingsLength) {
            integer iOffset = llListFindList(g_lMandatoryValues, [llList2String(g_lCollarSettings, iSettingsIndex)]);
            if (iOffset >= 0) {
                string sMajorMinor = llList2String(g_lCollarSettings, iSettingsIndex);
                string sCollarValue = llList2String(g_lCollarSettings, iSettingsIndex + 1);
                string sMandatoryValue = llList2String(g_lMandatoryValues, iOffset + 1);
                //  if (g_bDebugOn) DebugOutput(0, ["sync_settings", "state_entry-2", sMajorMinor, sCollarValue, sMandatoryValue, iSettingsIndex, iSettingsLength]);
                if (sCollarValue != sMandatoryValue) lPendingUpdates += [sMajorMinor, sMandatoryValue];
            }
            iSettingsIndex += 2;
        }
        //  if (g_bDebugOn) DebugOutput(0, ["sync_settings", "state_entry-3", iSettingsIndex]);
                
//
//  Check each entry in the mandatory collar settings to see if it exists in the collar
//  If there is not, add it
//

        iSettingsLength = llGetListLength(g_lMandatoryValues);
        iSettingsIndex = 0;
        while (iSettingsIndex < iSettingsLength) {
            integer iOffset = llListFindList(g_lCollarSettings, [llList2String(g_lMandatoryValues, iSettingsIndex)]);
            if (iOffset < 0) { // If it doesn't exist, it should (if it does exist, it's already been checked by the earlier loop)
                string sMajorMinor = llList2String(g_lMandatoryValues, iSettingsIndex);
                string sMandatoryValue = llList2String(g_lMandatoryValues, iSettingsIndex + 1);
                //  if (g_bDebugOn) DebugOutput(0, ["sync_settings", "state_entry-4", sMajorMinor, sMandatoryValue, iSettingsIndex, iSettingsLength]);
                lPendingUpdates += [sMajorMinor, sMandatoryValue];
            }
            iSettingsIndex += 2;
        }
        //  if (g_bDebugOn) DebugOutput(0, ["sync_settings", "state_entry-5", iSettingsIndex]);
        iSettingsLength = llGetListLength(lPendingUpdates);
        iSettingsIndex = 0;
        while (iSettingsIndex < iSettingsLength) {
            string sMajorMinor = llList2String(lPendingUpdates, iSettingsIndex);
            string sMandatoryValue = llList2String(lPendingUpdates, iSettingsIndex + 1);
            //  if (g_bDebugOn) DebugOutput(0, ["sync_settings", "state_entry-6", sMajorMinor+"="+sMandatoryValue]);
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, sMajorMinor+"="+sMandatoryValue, KURT_KEY);
            iSettingsIndex += 2;
        }
        state monitor_settings;
    }
    state_exit()
    {
        llSetTimerEvent(0.0);
        //  if (g_bDebugOn) DebugOutput(5, ["sync_settings", "state_exit", llGetFreeMemory(), "bytes free"]);
    }
}

state monitor_settings {
//
//    if the on_rez event is raised while we are in this state, just stop and let default take over; default will switch back to us, and we'll pick back up at state-entry
//
    
    on_rez(integer iParam) {
        //  if (g_bDebugOn) DebugOutput(5, ["monitor_settings", "on_rez", iParam]);
        state default;
    }
    
    state_entry() {
        //  if (g_bDebugOn) { list lTmp = ["monitor_settings", "state_entry", llGetFreeMemory(), "bytes free"]; DebugOutput(0, lTmp); }
    }
    
    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum == REBOOT) {
            if(sStr == "reboot") {
                llResetScript();
            }
        } else if (iNum == LM_SETTING_RESPONSE) {
            //  if (g_bDebugOn) DebugOutput(5, [sState, "link_message", "monitor_settings", iSender, iNum, sStr, kID]);
            if (g_bSynchronize) {
                list lTmp = llParseString2List(sStr, ["="], []);
                string sMajorMinor = llToLower(llList2String(lTmp, 0));
                string sCollarValue = llList2String(lTmp, 1);
                integer iOffset = llListFindList(g_lMandatoryValues, [sMajorMinor]);
                if (iOffset >= 0) {
                    string sMandatoryValue = llList2String(g_lMandatoryValues, iOffset + 1);
                    //  if (g_bDebugOn) DebugOutput(0, ["sync_settings", "link_message-1", sMajorMinor, sCollarValue, sMandatoryValue]);
                    if (sCollarValue != sMandatoryValue) llMessageLinked(LINK_SET, LM_SETTING_SAVE, sMajorMinor+"="+sMandatoryValue, KURT_KEY);
                }
            }
//        } else if(iNum == LM_SETTING_EMPTY) {
//            //. if (g_bDebugOn) DebugOutput(5, [sState, "link_message", "setting_empty", iSender, iNum, sStr, kID]);
//            g_bGatherStarted = TRUE;
//            string sTok = sStr;
//            g_lCollarSettings = SetSetting(sTok, "null");
        } else if (iNum == KB_COLLAR_VERSION) g_sCollarVersion = sStr;
        else if (iNum == KB_REQUEST_VERSION)
            llMessageLinked(LINK_SET,NOTIFY,"0"+llGetScriptName() + " version " + formatVersion(),kID);
    }
}

// kb_sync802_00