// kb_status

string  KB_VERSIONMAJOR      = "8";
string  KB_VERSIONMINOR      = "0";
string  KB_DEVSTAGE          = "1a9";
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
    llSay(KB_DEBUG_CHANNEL, llGetScriptName() + " " + (string) g_iDebugCounter + " " + final);
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

key     g_kWearer;

key g_kGroup = "";
integer g_iGroupEnabled = FALSE;

string g_sParentMenu = "Apps";
string g_sSubMenu = "KBStatus";
integer g_iRunawayDisable=0;
integer g_iSWActive = 1;
integer KB_HAIL_CHANNEL = -317783;
integer g_bPrepareToSend = FALSE;
list g_lHostSettings = [];
list g_lCollarSettings = [];
list g_lMandatoryValues = [];
list g_lSayings1 = [];
float g_fStartDelay = 0.0;
integer g_bGotSettings = FALSE;
integer g_bGotSayings = FALSE;
integer g_iSettings = 0;
integer g_iSayings1 = 0;
integer g_iLineNr = 0;
key 	g_kVersionID;
string  g_sTargetCard = ".version";

//integer g_iKBarOptions=0;
//integer g_iGirlStatus=0; // 0=guest, 1=protected, 2=slave
//integer g_iLockStatus=1; // disallow status changes
integer g_iLogLevel = 0; // minimal logging
//integer g_iLeashedRank = 0;
//key     g_kLeashedTo   = NULL_KEY;
//string  g_sWearerName;

string  g_sSlaveMessage = "";
/*
integer KB_KBSYNC_KICKSTART        = -34717;
integer KB_NOTICE_LEASHED          = -34691;
integer KB_NOTICE_UNLEASHED        = -34692;

string g_sDrop = "f364b699-fb35-1640-d40b-ba59bdd5f7b7";
*/
key KURT_KEY   = "4986014c-2eaa-4c39-a423-04e1819b0fbf";
key SILKIE_KEY = "1a828b4e-6345-4bb3-8d41-f93e6621ba25";

//MESSAGE MAP
integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
integer CMD_TRUSTED = 501;
integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
integer CMD_EVERYONE = 504;
//integer CMD_RLV_RELAY = 507;
//integer CMD_SAFEWORD = 510;
integer CMD_BLOCKED = 520;
integer CMD_NOACCESS = 599;

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

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

integer RLV_CMD = 6000;
//integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.
//integer RLV_CLEAR = 6002;//RLV plugins should clear their restriction lists upon receiving this message.

//integer ANIM_START = 7000;//send this with the name of an anim in the string part of the message to play the anim
//integer ANIM_STOP = 7001;//send this with the name of an anim in the string part of the message to stop the anim

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

/*
//added for attachment auth (garvin)
integer AUTH_REQUEST = 600;
integer AUTH_REPLY = 601;
*/
string UPMENU = "BACK";
integer g_iCaptureIsActive=FALSE; // If this flag is set, then auth will deny access to it's menus
//integer g_iOpenAccess; // 0: disabled, 1: openaccess
//integer g_iLimitRange=1; // 0: disabled, 1: limited
//integer g_iOwnSelf; // self-owned wearers
//string g_sFlavor = "OwnSelf";

list g_lMenuIDs;
integer g_iMenuStride = 3;
integer g_iListenHandle = 0;

string g_sSettingToken = "auth_";
string g_sGlobalToken = "global_";

key g_kLeashedTo = NULL_KEY; 
integer g_iLeashedRank = 0;

integer bool(integer a){
    if(a)return TRUE;
    else return FALSE;
}

list g_lCheckboxes=["⬜","⬛"];
string Checkbox(integer iValue, string sLabel) {
    return llList2String(g_lCheckboxes, bool(iValue))+" "+sLabel;
}

Dialog(string sID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName, integer iSensor) {
    key kMenuID = llGenerateKey();
    if (iSensor)
        llMessageLinked(LINK_SET, SENSORDIALOG, sID +"|"+sPrompt+"|0|``"+(string)AGENT+"`10`"+(string)PI+"`"+llList2String(lChoices,0)+"|"+llDumpList2String(lUtilityButtons, "`")+"|" + (string)iAuth, kMenuID);
    else
        llMessageLinked(LINK_SET, DIALOG, sID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iIndex = llListFindList(g_lMenuIDs, [sID]);
    if (~iIndex) { //we've alread given a menu to this user.  overwrite their entry
        g_lMenuIDs = llListReplaceList(g_lMenuIDs, [sID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
    } else { //we've not already given this user a menu. append to list
        g_lMenuIDs += [sID, kMenuID, sName];
    }
}

SetSWActive(integer iNew, integer iSave) {
    if (g_iSWActive == iNew) return; // no need to check for equality or inequality from this point forward
    g_iSWActive = iNew;
    if (g_iSWActive) SaveAndResend(g_sGlobalToken + "swactive", (string) g_iSWActive);
    else DeleteAndResend(g_sGlobalToken + "swactive");
}

SetLogLevel(integer iNew, integer iSave, key kID) {
    if ((iNew < 0) || (iNew > 9)) return;
    if (g_iLogLevel == iNew) return;
    g_iLogLevel = iNew;
    if (iSave) SaveAndResend(g_sGlobalToken + "loglevel", (string) g_iLogLevel);
    llMessageLinked(LINK_SET,NOTIFY,"1"+"Log level is now " + (string) g_iLogLevel + ".",kID);
}

SetDebugLevel(string sLevel) {
    integer iNew = (integer) sLevel;
    g_iDebugLevel = iNew;
    if (g_iDebugLevel > 9) g_bDebugOn = FALSE;
    else g_bDebugOn = TRUE;
    if (g_bDebugOn) {DebugOutput(0, ["Debug Level", g_iDebugLevel, "Debug Status", g_bDebugOn]); }
}
/*
string TranslateButtons(string sInput) {
    list lTranslation=[
        "KBar ☑", "kbar on",
        "KBar ☐", "kbar off",
        "guest", "kbarstat 0",
        "protect", "kbarstat 1",
        "slave", "kbarstat 2",
        "StatLock ☑", "statlock on",
        "StatLock ☐", "statlock off",
        "Safeword ☑", "safeword on",
        "Safeword ☐", "safeword off",
        "Diagnose", "diagnose",
        "LogLevel", "loglevel",
        "KickStart", "kickstart"
    ];
    integer buttonIndex=llListFindList(lTranslation,[sInput]);
    string sOutput = sInput;
    if (~buttonIndex) sOutput = llList2String(lTranslation,buttonIndex+1);
    return sOutput;
}
*/
HandleSettings(string sStr) {
    if (!g_bPrepareToSend) return;

    integer iDx = llListFindList(g_lCollarSettings, [sStr]);
    if (iDx < 0) {
        g_lCollarSettings += [sStr];
        if (g_bDebugOn) DebugOutput(3, ["adding", sStr]);
    } else { if (g_bDebugOn) DebugOutput(3, ["not adding, duplicated", sStr]); }
    
    if (g_bDebugOn) DebugOutput(0, g_lCollarSettings);
    list lParams = llParseString2List(sStr, ["="], []); // now [0] = "major_minor" and [1] = "value"
    string sToken = llList2String(lParams, 0); // now SToken = "major_minor"
    string sValue = llList2String(lParams, 1); // now sValue = "value"
    integer i = llSubStringIndex(sToken, "_");
    if (llToLower(llGetSubString(sToken, 0, i)) == llToLower(g_sGlobalToken)) { // if "major_" = "global_"
        sToken = llGetSubString(sToken, i + 1, -1);
        if (sToken == "slavemsg") g_sSlaveMessage = sValue;
        else if (sToken == "loglevel") SetLogLevel((integer) sValue, FALSE, (key) g_kWearer);
        else if (sToken == "swactive") SetSWActive((integer) sValue, FALSE);
        else if(sToken == "checkboxes"){
            g_lCheckboxes = llCSV2List(sValue);
        }
//    } else if(llGetSubString(sToken,0,i)=="capture_") { // if "major_" = "capture_"
//        if(llGetSubString(sToken,i+1,-1)=="isActive") {
//            g_iCaptureIsActive=TRUE;
//        }
    } else if(llGetSubString(sToken,0,i)=="leash_") {
        if (g_bDebugOn) DebugOutput(3, [sStr, sToken]);
        if(llGetSubString(sToken,i+1,-1)=="leashedto") {
            list lLeashed = llParseString2List(sValue, [","], []);
            if (llList2Integer(lLeashed, 2) > 0) {å
                g_kLeashedTo = llList2Key(lLeashed, 0); 
                g_iLeashedRank = llList2Integer(lLeashed, 1);
            }
        }
    }
}

HandleDeletes(string sStr) {
    if (!g_bPrepareToSend) return;
    list lParams = llParseString2List(sStr, ["_"],[]);
    string sToken = llList2String(lParams,0);
    string sVariable = llList2String(lParams,1);
//    if (sToken=="capture") {
//        if (sVariable == "isActive") g_iCaptureIsActive=FALSE;
    if (sToken == "global") {
        if (sVariable == "swactive") SetSWActive(FALSE, FALSE);
    }
    integer iDx = llListFindList(g_lCollarSettings, [sStr]);
    if (iDx >= 0) g_lCollarSettings = llDeleteSubList(g_lCollarSettings, iDx, iDx);
}
/*
ConfirmMenu(key kAv, integer iAuth) {
    string sPrompt = "\n[Confirmation]";
    sPrompt += "\nYou are about to permit the Judge to change your protection status if he pleases.";
    sPrompt += "\nIf you do only he can change you back.";
    sPrompt += "\nPlease confirm your choice or cancel now (you can come back anytime to grant permission).";
    list lButtons = ["Confirm", "Cancel"];
    Dialog(kAv, sPrompt, lButtons, [UPMENU], 0, iAuth, "Confirm",FALSE);
}
*/
LogLevelMenu(key kAv, integer iAuth) {
    string sPrompt = "\n[Logging Level]";
    sPrompt += "\nSelect a log leve between 0 and 9.";
    sPrompt += "\n0 means minimum logging, 9 means maximum, other numbers somewhere in between";
    list lButtons = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"];
    Dialog(kAv, sPrompt, lButtons, [UPMENU], 0, iAuth, "LogLevel",FALSE);
}

StatMenu(key kAv, integer iAuth) {
    string sPrompt = "\n[KBar Status " + formatVersion() + " " + (string) llGetFreeMemory() + " bytes free]\n";
    sPrompt += "Collar version " + g_sCollarVersion + "\n";
    sPrompt += "\nThis is a K-Bar plugin; for support, wire roan (Silkie Sabra), K-Bar Ranch.\n";

    if (g_iSWActive) sPrompt += "\nSafeword enabled"; else sPrompt += "\nSafeword disabled";

    list lButtons = []; // ["KickStart"];
    if ((iAuth == CMD_OWNER) || g_bDebugOn) lButtons += ["Debug", "LogLevel", "Kickstart", Checkbox(g_iSWActive, "Safeword")];

    Dialog(kAv, sPrompt, lButtons, [UPMENU], 0, iAuth, "Stat",FALSE);
}

DebugMenu(key keyID, integer iAuth) {
    string sPrompt = "\n[KB Status Debug Level (less is more)] "+ formatVersion() + ", " + (string) llGetFreeMemory() + " bytes free.\nCurrent debug level: " + (string) g_iDebugLevel;
    list lMyButtons = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10"];
    Dialog(keyID, sPrompt, lMyButtons, [UPMENU], 0, iAuth, "Debug", FALSE);
}

HandleMenus(string sStr, key kID) {
    integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iMenuIndex) {
        list lMenuParams = llParseString2List(sStr, ["|"], []);
        key kAv = (key)llList2String(lMenuParams, 0);
        string sMessage = llList2String(lMenuParams, 1);
        // integer iPage = (integer)llList2String(lMenuParams, 2);
        integer iAuth = (integer)llList2String(lMenuParams, 3);
        string sMenu=llList2String(g_lMenuIDs, iMenuIndex + 1);
        g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
        //Debug(sMessage);
        if (sMenu == "Stat") {
//llOwnerSay("link_message " + sMessage);
            if (sMessage == UPMENU)
                llMessageLinked(LINK_SET, iAuth, "menu " + g_sParentMenu, kAv);
            else if (llToLower(sMessage) == "debug") DebugMenu(kAv, iAuth);
            else {
                if (llToLower(sMessage) == llToLower(Checkbox(TRUE, "Safeword"))) UserCommand(iAuth, "safeword on", kAv, TRUE);
                else if (llToLower(sMessage) == llToLower(Checkbox(FALSE, "Safeword"))) UserCommand(iAuth, "safeword off", kAv, TRUE);
                else if (llToLower(sMessage) == "Kickstart") llResetScript();
            }
        } else if (sMenu == "Debug") {
            SetDebugLevel(sMessage);
            StatMenu(kAv, iAuth);
        } else if (sMenu == "LogLevel") {
            SetLogLevel((integer) sMessage, TRUE, kID);
            StatMenu(kAv, iAuth);
        }
    }
}

UserCommand(integer iNum, string sStr, key kID, integer iRemenu) { // here iNum: auth value, sStr: user command, kID: avatar id
//llOwnerSay ("UserCommand("+(string)iNum+","+sStr+","+(string)kID+")");
    string sMessage = llToLower(sStr);
    list lParams = llParseString2List(sStr, [" "], []);
    string sCommand = llToLower(llList2String(lParams, 0));
    string sAction = llToLower(llList2String(lParams, 1));
    if (sStr == "menu "+g_sSubMenu){
        StatMenu(kID, iNum);
    } else if (sCommand == "safeword") {
        if ((iNum == CMD_OWNER) || g_bDebugOn) {
           if (sAction == "on") {
                SetSWActive(TRUE, TRUE);
                llMessageLinked(LINK_SET,NOTIFY,"1"+"Your safeword has been enabled.",(key) g_kWearer);
            } else {
                SetSWActive(FALSE, TRUE);
                    llMessageLinked(LINK_SET,NOTIFY,"1"+"Your safeword has been disabled.",(key) g_kWearer);
            }
        }
        else
            llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS% to safeword function",kID);
        if (iRemenu) StatMenu(kID, iNum);
    } else if (sCommand == "loglevel") {
//        llMessageLinked(LINK_SET, LINK_KB_VERS_REQ, "", kID);
        if ((iNum == CMD_OWNER) || g_bDebugOn) {
            LogLevelMenu(kID, iNum);
        }
        else
            llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS% to log level function",kID);
    } else if (sCommand == "debug") {
        if ((iNum == CMD_OWNER) || g_bDebugOn) {
            DebugMenu(kID, iNum);
        }
        else
            llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS% to debug function",kID);
    }
    else if (sCommand == llToLower(UPMENU))
        llMessageLinked(LINK_SET, iNum, "menu "+g_sParentMenu, kID);
}

SaveAndResend(string sToken, string sValue) {
//    llMessageLinked(LINK_SET, LM_SETTING_RESPONSE, sToken+"="+sValue,""); //// LEGACY OPTION. New scripts will hear LM_SETTING_SAVE
    llMessageLinked(LINK_SET, LM_SETTING_SAVE, sToken+"="+sValue,"");
}

DeleteAndResend(string sToken) {
//    llMessageLinked(LINK_SET, LM_SETTING_RESPONSE, sToken+"=",""); //// LEGACY OPTION. New scripts will hear LM_SETTING_DELETE
    llMessageLinked(LINK_SET, LM_SETTING_DELETE, sToken,"");
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
    if (g_bDebugOn) DebugOutput(5, ["InitListen", g_iListenHandle, KB_HAIL_CHANNEL]);
    if (g_iListenHandle == 0) g_iListenHandle = llListen(KB_HAIL_CHANNEL, "", "", "");
}

InitVariables() {
    g_kWearer = llGetOwner();
    g_iDebugCounter = 0;
    g_iPingCounter = 0;
    g_lCollarSettings = [];
    g_lHostSettings = [];
    g_lMandatoryValues = [];
    g_lSayings1 = [];
    g_iLineNr = 0;
    g_bGotSettings = FALSE;
    g_bGotSayings = FALSE;
    g_sCollarVersion = "not set";
    g_kVersionID = llGetNotecardLine(g_sTargetCard, g_iLineNr);
}

MergeInputSettingsToMandatory(list lInput) {
    integer iIdx = 0;
    integer iLimit = llGetListLength(lInput);
    integer iMandIdx = 0;
    while (iIdx < iLimit) {
        string sWork = llList2String(lInput, iIdx);
        if (g_bDebugOn) { DebugOutput(0, ["MergeInputSettingsToMandatory in loop", iIdx, iLimit, sWork]); }
        list lParams = llParseString2List(sWork, ["="], []); // now [0] = "major_minor" and [1] = "value"
        string sToken = llList2String(lParams, 0); // now SToken = "major_minor"
        string sValue = llList2String(lParams, 1); // now sValue = "value"
        integer iMandPtr = FindMajorMinor(g_lMandatoryValues, sToken);  // see if this collar major_minor entry already exists in the host set
        if (iMandPtr < 0) g_lMandatoryValues += [sToken, sValue, FALSE];
        else {
            list lTemp = [sToken, sValue, FALSE];
            g_lMandatoryValues = llListReplaceList(g_lMandatoryValues, lTemp, iMandPtr, iMandPtr + 2);
        }
        ++iIdx;
    }
}

MergeInputSayings1ToMandatory(list lInput) {
    integer iIdx = 0;
    integer iLimit = llGetListLength(lInput);
    integer iMandIdx = 0;
    while (iIdx < iLimit) {
        string sEntry = llList2String(lInput, iIdx);
        integer iPtr = llListFindList(g_lSayings1, [sEntry]);
        if (iPtr < 0) g_lSayings1 += [sEntry];
        ++iIdx;
    }
}

/*
DeleteListen() {
    llListenRemove(g_iListenHandle);
    g_iListenHandle = 0;
    if (g_bDebugOn) DebugOutput(5, ["DeleteListen", g_iListenHandle, KB_HAIL_CHANNEL]);
}
*/

default {
    on_rez(integer iParam){
        if(llGetOwner()!=g_kWearer) llResetScript();
    }
    state_entry()
    {
        if(llGetStartParameter()!=0)state inUpdate;
        SetDebugOff();
        g_kWearer = llGetOwner();
        state init_version;
    }
}

state init_version {
//
//    if the on_rez event is raised while we are in this state, just stop and let default take over; default will switch back to us, and we'll pick back up at state-entry
//
    on_rez(integer iParam){
        if(llGetOwner()!=g_kWearer) llResetScript();
        state default;
    }
    
    state_entry() {
        InitVariables();
        llSetTimerEvent(30.0);
    }

    timer() {
        llSetTimerEvent(0.0);
        state init_params;
    }
    
    dataserver(key kID, string sData) {
        if (g_bDebugOn) DebugOutput(0, ["dataserver", sData]);
        if (kID == g_kVersionID) {
            if (sData != EOF) {
                string sWork = llStringTrim(sData, STRING_TRIM);
                if (sWork != "") {
                    list lData = llParseString2List(sWork, ["="], []);
                    if (llGetListLength(lData) > 1) {
                        if (llList2String(lData, 0) == "version") g_sCollarVersion = llList2String(lData, 1);
                    } else 
                        g_kVersionID = llGetNotecardLine(g_sTargetCard, g_iLineNr);
                }
            } else {
                llSetTimerEvent(0.0);
                state init_params;
            }
        }
    } 
}

state init_params {
//
//    if the on_rez event is raised while we are in this state, just stop and let default take over; default will switch back to us, and we'll pick back up at state-entry
//
    on_rez(integer iParam){
        if(llGetOwner()!=g_kWearer) llResetScript();
        state default;
    }
    
    state_entry() {
        InitListen();
        if (g_bDebugOn) DebugOutput(5, ["link_message pinging", KB_HAIL_CHANNEL]);
        llSleep(2.0);
        llRegionSay(KB_HAIL_CHANNEL, "ping801");        
        g_iPingCounter = 0;
        g_fStartDelay = 15.0;
        llSetTimerEvent(g_fStartDelay);
    }
    
    timer() {
        llSetTimerEvent(0.0);
        ++g_iPingCounter;
        if (g_bDebugOn) DebugOutput(5, ["link_message pinging", KB_HAIL_CHANNEL]);
        llRegionSay(KB_HAIL_CHANNEL, "ping751");     
        g_fStartDelay = (float) (15*g_iPingCounter);
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
//    kb_settings_host also collects the sayings used in kb_programmer; they are also sent as a string list delimited by '%%'
//
//
//
//
//
//
    listen(integer iChannel, string sName, key kId, string sMessage) {
        if (g_bDebugOn) DebugOutput(5, ["listen heard", sName, (string) kId, sMessage]);
        llSetTimerEvent(0.0);
        list lHostSettings = llParseString2List(sMessage, ["%%"], [""]);
        string sFirst = llList2String(lHostSettings, 0);
        string sEndFlag = "kbhostaction=done";
        string sLineID = "";
        integer iLineID = 0;
        list lTemp = llParseString2List(sFirst, ["="], [""]);
        sLineID = llList2String(lTemp, 0);
        if (llGetListLength(lTemp) > 1) iLineID = llList2Integer(lTemp, 1);
        if (sLineID == "kbhostline" || sLineID == "kbhostaction") {
            if (g_bDebugOn) { list lTemp = ["settings from kb_settings_host"] + lHostSettings; DebugOutput(3, lTemp); }
            list lOutputSettings = llDeleteSubList(lHostSettings, 0, 1);
            MergeInputSettingsToMandatory(lOutputSettings);
            if (sLineID == "kbhostaction") {
                if (g_bDebugOn) { list lTemp = ["settings ready for output"] + g_lMandatoryValues; DebugOutput(5, lTemp); }
                g_bGotSettings = TRUE;
            }
        } else if (sLineID == "kbnosettings") {
            if (g_bDebugOn) { list lTemp = ["no settings found"] + g_lMandatoryValues; DebugOutput(5, lTemp); }
            g_bGotSettings = TRUE;
        } else if (sLineID == "kbsayings1line" || sLineID == "kbsayings1action") {
            if (g_bDebugOn) { list lTemp = ["sayings 1 from kb_settings_host"] + lHostSettings; DebugOutput(3, lTemp); }
            list lOutputSayings = llParseString2List(sMessage, ["%%"], [""]);
            MergeInputSayings1ToMandatory(lOutputSayings);
            if (sLineID == "kbsayings1action") {
                if (g_bDebugOn) { list lTemp = ["sayings1 ready for output"] + g_lSayings1; DebugOutput(5, lTemp); }
                g_bGotSayings = TRUE;
            }
        } else if (sLineID == "kbnosayings") {
            if (g_bDebugOn) { list lTemp = ["no sayings1 found"] + g_lSayings1; DebugOutput(5, lTemp); }
            g_bGotSayings = TRUE;
        } else if (sLineID == "Notify") {
            // TODO: process 'no xx card' messages
        }
        if (g_bGotSettings && g_bGotSayings) {
            DebugOutput(4, ["settings and sayings fetched"]);
        }
    }
}

/*
default {
    on_rez(integer iParam) {
//        llResetScript();
        g_iDebugCounter = 0;
        g_lCollarSettings = [];
        g_lHostSettings = [];
        g_iLineNr = 0;
        InitListen();
        g_sCollarVersion = "not set";
        g_kVersionID = llGetNotecardLine(g_sTargetCard, g_iLineNr);
        g_kWearer = llGetOwner();
        llMessageLinked(LINK_SET, MENUNAME_REQUEST, g_sSubMenu, NULL_KEY);
        llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, NULL_KEY);
        g_bPrepareToSend = TRUE; // only once per rez
        g_fStartDelay = 15.0; 
        llSetTimerEvent(g_fStartDelay);
    }

    state_entry() {
        if (llGetStartParameter()==825) llSetRemoteScriptAccessPin(0);
        g_iListenHandle = llListen(KB_HAIL_CHANNEL, "", "", "");
        g_kWearer = llGetOwner();
        llMessageLinked(LINK_SET, MENUNAME_REQUEST, g_sSubMenu, NULL_KEY);
        llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, NULL_KEY);
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if(iNum == MENUNAME_REQUEST && sStr == g_sParentMenu) {
            llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
        }
        else if (iNum >= CMD_OWNER && iNum <= CMD_EVERYONE) UserCommand(iNum, sStr, kID, FALSE);
        else if (iNum == LM_SETTING_RESPONSE) {
            if (sStr == "settings=sent" && g_bPrepareToSend) {
                if (g_bDebugOn) DebugOutput(5, ["link_message", sStr, g_fStartDelay]);
                llSetTimerEvent(0.0);
                if (g_fStartDelay > 5.0) { g_fStartDelay -= 1.0; llSetTimerEvent(g_fStartDelay); }
                else { g_fStartDelay = 5.0; llSetTimerEvent(g_fStartDelay); }
            } else {
                HandleSettings(sStr);
            }
        } else if( iNum == LM_SETTING_DELETE) {
            list lParams = llParseString2List(sStr, ["_"],[]);
            string sToken = llList2String(lParams,0);
            string sVariable = llList2String(lParams,1);
            if(sToken=="capture") {
                if(sVariable=="isActive")g_iCaptureIsActive=FALSE;
            }
        } else if (iNum == DIALOG_RESPONSE) {
            HandleMenus(sStr, kID);
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
        } else if (iNum == LOADPIN && sStr == llGetScriptName()) {
            integer iPin = (integer)llFrand(99999.0)+1;
            llSetRemoteScriptAccessPin(iPin);
            llMessageLinked(iSender, LOADPIN, (string)iPin+"@"+llGetScriptName(),llGetKey());
        }
        else if (iNum == REBOOT && sStr == "reboot") llResetScript();
        else if(iNum == LINK_CMD_DEBUG) {
            integer onlyver=0;
            if(sStr == "ver")onlyver=1;
            llInstantMessage(kID, llGetScriptName() +" SCRIPT VERSION: "+g_sScriptVersion);
            if(onlyver)return; // basically this command was: <prefix> versions
        }
    }

    listen(integer iChannel, string sName, key kId, string sMessage) {
        g_bPrepareToSend = FALSE;
        if (g_bDebugOn) DebugOutput(5, ["listen heard", sName, (string) kId, sMessage]);
//        llOwnerSay("heard "+ sName + " " + (string) kId);
//        llOwnerSay((string) llGetOwnerKey(kId));
//        llOwnerSay(llKey2Name(llGetOwnerKey(kId)));
        g_lHostSettings = llParseString2List(sMessage, ["%%"], [""]);
        string sFirst = llList2String(g_lHostSettings, 0);
        list lTemp = llParseString2List(sFirst, ["="], [""]);
        string sLineID = llList2String(lTemp, 0);
        integer iLineID = llList2Integer(lTemp, 1);
        if (sLineID == "kbhostline" || sLineID == "kbhostaction") {
            if (g_bDebugOn) { list lTemp = ["settings from kb_settings_host"] + g_lHostSettings; DebugOutput(3, lTemp); }
//        if (g_bDebugOn) DebugOutput(3, g_lHostSettings);
//        g_lHostSettings += lSettings;
            list lOutputSettings = [];
            integer iCollarPtr = 0;
//
//        Need to step through collar settings
//            anything in the collar set that's not in the host set gets included as-is in the output set
//            if the host set and collar set both address the same variable with different values, the host set wins
//            anything in the host set, whether corrected or not, goes to the output set
//

            integer iCollarIdx = 0;
            integer iCollarLen = llGetListLength(g_lCollarSettings);
            while (iCollarIdx < iCollarLen) {
                string sWork = llList2String(g_lCollarSettings, iCollarIdx);
                if (g_bDebugOn) { DebugOutput(0, ["in loop", iCollarIdx, iCollarLen, sWork]); }
                list lParams = llParseString2List(sWork, ["="], []); // now [0] = "major_minor" and [1] = "value"
                string sToken = llList2String(lParams, 0); // now SToken = "major_minor"
                string sValue = llList2String(lParams, 1); // now sValue = "value"
                integer iHostPtr = FindMajorMinor(g_lHostSettings, sToken);  // see if this collar major_minor entry already exists in the host set
                if (iHostPtr > 0) {  // if it does, see if its value is different
                    string sCandidate = llList2String(g_lHostSettings, iHostPtr); // extract the host setting string
                    lParams = llParseString2List(sCandidate, ["="], []); // split it into candidate pieces
                    string sCandToken = llList2String(lParams, 0); // now SCandToken = "major_minor"
                    string sCandValue = llList2String(lParams, 1); // now sCandValue = "value"
                    if (llToLower(sValue) == llToLower(sCandValue)) {
                        lOutputSettings += [sWork]; // if they're the same, just move the entry to the output list
                    } else {
                        sWork = sCandToken + "=" + sCandValue; // if they're different, use the one from kb_settings_host
                        lOutputSettings += [sWork];
                    }
                } else {
                    lOutputSettings += [sWork]; // if there's no matching entry, just move the entry to the output list
                }
                ++iCollarIdx;
            }        
            integer iHostIdx = 0;
            integer iHostLen = llGetListLength(g_lHostSettings);
            while (iHostIdx < iHostLen) {
                string sHostSetting = llList2String(g_lHostSettings, iHostIdx);
                list lParams = llParseString2List(sHostSetting, ["="], []); // now [0] = "major_minor" and [1] = "value"
                string sToken = llList2String(lParams, 0); // now SToken = "major_minor"
                if (sToken != "kbhostline" && sToken != "kbhostaction") {
                    integer iExists = llListFindList(lOutputSettings, [sHostSetting]);
                    if (g_bDebugOn) DebugOutput(3, ["final check", sHostSetting, iExists]);
                    if (iExists < 0) lOutputSettings += [sHostSetting];
                }
                ++iHostIdx;
            }

            if (g_bDebugOn) DebugOutput(5, ["settings ready for output"]);
            if (g_bDebugOn) DebugOutput(5, lOutputSettings);

            while (llGetListLength(lOutputSettings) > 0) {
                string sCurrent = llList2String(lOutputSettings, 0);
//                list lCurrent = llParseString2List(sCurrent, ["="], [""]);
//                if (llList2String(lCurrent, 0) == "kbhostline") g_lHostSettings = llDeleteSubList(g_lHostSettings, 0, 0);
//                else if (llList2String(lCurrent, 0) == "kbhostaction") g_lHostSettings = llDeleteSubList(g_lHostSettings, 0, 0);
//                else { 
                    llMessageLinked(LINK_SET, LM_SETTING_SAVE, sCurrent, "");
                    if (g_bDebugOn) DebugOutput(5, ["sent", LINK_SET, LM_SETTING_SAVE, sCurrent]);
                    lOutputSettings = llDeleteSubList(lOutputSettings, 0, 0);
//                }
            }
        } else if (sLineID == "kbsayings1line" || sLineID == "kbsayings1action") {
            if (g_bDebugOn) { list lTemp = ["sayings 1 from kb_settings_host"] + g_lHostSettings; DebugOutput(3, lTemp); }
            integer iHostIdx = 1;
            integer iHostLen = llGetListLength(g_lHostSettings);
            string sPackage = "";
            while (iHostIdx < iHostLen) {
//                sPackage = "";
                string sHostSaying = llList2String(g_lHostSettings, iHostIdx);
                integer iCalcLength = llStringLength(sPackage) + llStringLength("%%") + llStringLength(sHostSaying);
                if (iCalcLength < 1024) {
                    sPackage += "%%";
                    sPackage += sHostSaying;
                } else {
                    if (g_bDebugOn) DebugOutput(5, ["kbsayings1 link_message-1 sending", sPackage]);
                    llMessageLinked(LINK_SET, LINK_SAYING1, sPackage, "");
                    sPackage = sHostSaying;
                }
                ++iHostIdx;
            }
            if (g_bDebugOn) DebugOutput(5, ["kbsayings1 link_message-2 sending", sPackage]);
            if (llStringLength(sPackage) > 0) llMessageLinked(LINK_SET, LINK_SAYING1, sPackage, "");
        } else if (sLineID == "Notify") {
            // TODO: process 'no xx card' messages
        }
//        DeleteListen();
    }
    
    changed(integer iChange) {
        if (iChange & CHANGED_OWNER) llResetScript();
//
//        if (iChange & CHANGED_REGION) {
//            if (g_iProfiled){
//                llScriptProfiler(1);
//                Debug("profiling restarted");
//            }
//        }
//
    }
//
//}

*/
state inUpdate {
    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if(iNum == REBOOT)llResetScript();
    }
    
    on_rez(integer iNum) {
        llResetScript();
    }
}


// kb_status