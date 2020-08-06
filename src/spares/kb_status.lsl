
//K-Bar Version 20191224 1415 kb_status

// collar settings retains everything - need to merge in host settings and figure out how to send the difference
// useful key: f03fba89-80e8-6d03-4071-109d85252c72

string g_sScriptVersion = "7.5b";

DebugOutput(list ITEMS){
    integer i=0;
    integer end=llGetListLength(ITEMS);
    string final;
    for(i=0;i<end;i++){
        final+=llList2String(ITEMS,i)+" ";
    }
//    llInstantMessage(kID, llGetScriptName() +final);
    llOwnerSay(llGetScriptName() + " " + final);
}
integer g_bDebugOn = FALSE;

string  KB_VERSION = "7.5";
string  KB_DEVSTAGE = "b";

string g_sWearerID;

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
float g_fStartDelay = 0.0;

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
integer LM_SETTING_SAVE = 2000;
//integer LM_SETTING_REQUEST = 2001;
integer LM_SETTING_RESPONSE = 2002;
integer LM_SETTING_DELETE = 2003;
//integer LM_SETTING_EMPTY = 2004;

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
    if (g_iSWActive == iNew) return;
    g_iSWActive = iNew;
    if (g_iSWActive) { 
        if (iSave) SaveAndResend(g_sGlobalToken + "swactive", (string) g_iSWActive);
    } else {
        if (iSave) DeleteAndResend(g_sGlobalToken + "swactive");
    }
}

SetLogLevel(integer iNew, integer iSave) {
    if ((iNew < 0) || (iNew > 9)) return;
    if (g_iLogLevel == iNew) return;
    g_iLogLevel = iNew;
    if (iSave) SaveAndResend(g_sGlobalToken + "loglevel", (string) g_iLogLevel);
}

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

HandleSettings(string sStr) {
    if (!g_bPrepareToSend) return;

    integer iDx = llListFindList(g_lCollarSettings, [sStr]);
    if (iDx < 0) {
        g_lCollarSettings += [sStr];
        if (g_bDebugOn) DebugOutput(["adding", sStr]);
    } else { if (g_bDebugOn) DebugOutput(["not adding, duplicated", sStr]); }
    
    if (g_bDebugOn) DebugOutput(g_lCollarSettings);
    list lParams = llParseString2List(sStr, ["="], []); // now [0] = "major_minor" and [1] = "value"
    string sToken = llList2String(lParams, 0); // now SToken = "major_minor"
    string sValue = llList2String(lParams, 1); // now sValue = "value"
    integer i = llSubStringIndex(sToken, "_");
    if (llToLower(llGetSubString(sToken, 0, i)) == llToLower(g_sGlobalToken)) { // if "major_" = "global_"
        sToken = llGetSubString(sToken, i + 1, -1);
        if (sToken == "slavemsg") g_sSlaveMessage = sValue;
        else if (sToken == "loglevel") SetLogLevel((integer) sValue, FALSE);
        else if (sToken == "swactive") SetSWActive((integer) sValue, FALSE);
        else if(sToken == "checkboxes"){
            g_lCheckboxes = llCSV2List(sValue);
        }
    } else if(llGetSubString(sToken,0,i)=="capture_") { // if "major_" = "capture_"
        if(llGetSubString(sToken,i+1,-1)=="isActive") {
            g_iCaptureIsActive=TRUE;
        }
    } else if(llGetSubString(sToken,0,i)=="leash_") {
        if (g_bDebugOn) DebugOutput([sStr, sToken]);
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
    if (sToken=="capture") {
        if (sVariable == "isActive") g_iCaptureIsActive=FALSE;
    } else if (sToken == "global") {
        if (sVariable == "swactive") SetSWActive(FALSE, FALSE);
    }
    integer iDx = llListFindList(g_lCollarSettings, [sStr]);
    if (iDx >= 0) g_lCollarSettings = llDeleteSubList(g_lCollarSettings, iDx, iDx);
}

ConfirmMenu(key kAv, integer iAuth) {
    string sPrompt = "\n[Confirmation]";
    sPrompt += "\nYou are about to permit the Judge to change your protection status if he pleases.";
    sPrompt += "\nIf you do only he can change you back.";
    sPrompt += "\nPlease confirm your choice or cancel now (you can come back anytime to grant permission).";
    list lButtons = ["Confirm", "Cancel"];
    Dialog(kAv, sPrompt, lButtons, [UPMENU], 0, iAuth, "Confirm",FALSE);
}

LogLevelMenu(key kAv, integer iAuth) {
    string sPrompt = "\n[Logging Level]";
    sPrompt += "\nSelect a log leve between 0 and 9.";
    sPrompt += "\n0 means minimum logging, 9 means maximum, other numbers somewhere in between";
    list lButtons = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"];
    Dialog(kAv, sPrompt, lButtons, [UPMENU], 0, iAuth, "LogLevel",FALSE);
}

StatMenu(key kAv, integer iAuth) {
    if(g_iCaptureIsActive){
        llMessageLinked(LINK_SET,NOTIFY,"0%NOACCESS% while capture is active",kAv);
        return;
    }

    string sPrompt = "\n[KBar Status " + KB_VERSION + KB_DEVSTAGE + "]; " + (string) llGetFreeMemory() + " bytes free";
    if (g_iSWActive) sPrompt += "\nSafeword enabled"; else sPrompt += "\nSafeword disabled";

    list lButtons = []; // ["KickStart"];
    if (iAuth == CMD_OWNER) lButtons += ["Diagnose", "LogLevel"];
    if (iAuth == CMD_OWNER) {
        lButtons += [Checkbox(g_iSWActive, "Safeword")];
    }
    Dialog(kAv, sPrompt, lButtons, [UPMENU], 0, iAuth, "Stat",FALSE);
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
            else {
                string sCmd = TranslateButtons(sMessage);
                UserCommand(iAuth, sCmd, kAv, TRUE);
            }
        } else if (sMenu == "LogLevel") {
            SetLogLevel((integer) sMessage, TRUE);
            llMessageLinked(LINK_SET,NOTIFY,"1"+"Log level is now " + (string) g_iLogLevel + ".",kID);
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
        if(g_iCaptureIsActive){
            llMessageLinked(LINK_SET,NOTIFY,"0%NOACCESS% while capture is active",kID);
            return;
        }
        StatMenu(kID, iNum);
    } else if (sCommand == "safeword") {
        if (kID == KURT_KEY) {
           if (sAction == "on") {
                SetSWActive(TRUE, TRUE);
                llMessageLinked(LINK_SET,NOTIFY,"1"+"Your safeword has been enabled.",(key) g_sWearerID);
            } else {
                SetSWActive(FALSE, TRUE);
                    llMessageLinked(LINK_SET,NOTIFY,"1"+"Your safeword has been disabled.",(key) g_sWearerID);
            }
        }
        else
            llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS% to safeword function",kID);
        if (iRemenu) StatMenu(kID, iNum);
    } else if (sCommand == "diagnose") {
//        llMessageLinked(LINK_SET, LINK_KB_VERS_REQ, "", kID);
        llMessageLinked(LINK_SET, KB_LOG_REPORT_STATUS, "", kID);
    } else if (sCommand == "loglevel") {
        LogLevelMenu(kID, iNum);
        return;
    }
//    else if (sCommand == UPMENU)
//        llMessageLinked(LINK_ROOT, iNum, "menu "+g_sParentMenu, kID);
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

integer FindMajorMinor(string sInput) {
    integer iHostIdx = 0;
    integer iHostLen = llGetListLength(g_lHostSettings);
   
    while (iHostIdx < iHostLen) {
        list lParams = llParseString2List(llList2String(g_lHostSettings, iHostIdx), ["="], []); 
        // now [0] = "major_minor" and [1] = "value"
        string sToken = llList2String(lParams, 0); // now SToken = "major_minor"
        string sValue = llList2String(lParams, 1); // now sValue = "value"
        if (llToLower(sToken) == llToLower(sInput)) return iHostIdx;
        ++iHostIdx;
    }
    return -1;
}

default {
    on_rez(integer iParam) {
//        llResetScript();
        g_lCollarSettings = [];
        g_lHostSettings = [];
        if (g_iListenHandle == 0) g_iListenHandle = llListen(KB_HAIL_CHANNEL, "", "", "");
        g_sWearerID = llGetOwner();
        llMessageLinked(LINK_SET, MENUNAME_REQUEST, g_sSubMenu, NULL_KEY);
        llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, NULL_KEY);
        g_bPrepareToSend = TRUE; // only once per rez
        g_fStartDelay = 15.0; 
        llSetTimerEvent(g_fStartDelay);
    }

    state_entry() {
        if (llGetStartParameter()==825) llSetRemoteScriptAccessPin(0);
        g_iListenHandle = llListen(KB_HAIL_CHANNEL, "", "", "");
        g_sWearerID = llGetOwner();
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
                if (g_bDebugOn) DebugOutput(["link_message", sStr, g_fStartDelay]);
                llSetTimerEvent(0.0);
                if (g_fStartDelay > 11.0) { g_fStartDelay = 10.0; llSetTimerEvent(g_fStartDelay); }
                else if (g_fStartDelay > 6.0) { g_fStartDelay = 5.0; llSetTimerEvent(g_fStartDelay); }
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
        if (g_bDebugOn) DebugOutput(["listen heard", sName, (string) kId, sMessage]);
//        llOwnerSay("heard "+ sName + " " + (string) kId);
//        llOwnerSay((string) llGetOwnerKey(kId));
//        llOwnerSay(llKey2Name(llGetOwnerKey(kId)));
        g_lHostSettings = llParseString2List(sMessage, ["%%"], [""]);
        if (g_bDebugOn) DebugOutput(["settings from kb_settings_host"]);
        if (g_bDebugOn) DebugOutput(g_lHostSettings);
//        g_lHostSettings += lSettings;
        list lOutputSettings = [];
        integer iCollarPtr = 0;
//
//    Need to step through collar settings
//        anything in the collar set that's not in the host set gets included as-is in the output set
//        if the host set and collar set both address the same variable with different values, the host set wins
//        anything in the host set, whether corrected or not, goes to the output set
//

        integer iCollarIdx = 0;
        integer iCollarLen = llGetListLength(g_lCollarSettings);
        while (iCollarIdx < iCollarLen) {
            string sWork = llList2String(g_lCollarSettings, iCollarIdx);
            if (g_bDebugOn) { DebugOutput(["in loop", iCollarIdx, iCollarLen, sWork]); }
            list lParams = llParseString2List(sWork, ["="], []); // now [0] = "major_minor" and [1] = "value"
            string sToken = llList2String(lParams, 0); // now SToken = "major_minor"
            string sValue = llList2String(lParams, 1); // now sValue = "value"
            integer iHostPtr = FindMajorMinor(sToken);  // see if this collar major_minor entry already exists in the host set
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
                if (g_bDebugOn) DebugOutput(["final check", sHostSetting, iExists]);
                if (iExists < 0) lOutputSettings += [sHostSetting];
            }
            ++iHostIdx;
        }

        if (g_bDebugOn) DebugOutput(["settings ready for output"]);
        if (g_bDebugOn) DebugOutput(lOutputSettings);

        while (llGetListLength(lOutputSettings) > 0) {
            string sCurrent = llList2String(lOutputSettings, 0);
//            list lCurrent = llParseString2List(sCurrent, ["="], [""]);
//            if (llList2String(lCurrent, 0) == "kbhostline") g_lHostSettings = llDeleteSubList(g_lHostSettings, 0, 0);
//            else if (llList2String(lCurrent, 0) == "kbhostaction") g_lHostSettings = llDeleteSubList(g_lHostSettings, 0, 0);
//            else { 
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, sCurrent, "");
                if (g_bDebugOn) DebugOutput(["sent", LINK_SET, LM_SETTING_SAVE, sCurrent]);
                lOutputSettings = llDeleteSubList(lOutputSettings, 0, 0);
//            }
        }
        llListenRemove(g_iListenHandle);
        g_iListenHandle = 0;
    }
    
    changed(integer iChange) {
        if (iChange & CHANGED_OWNER) llResetScript();
/*
        if (iChange & CHANGED_REGION) {
            if (g_iProfiled){
                llScriptProfiler(1);
                Debug("profiling restarted");
            }
        }
*/
    }
    timer() {
        llSetTimerEvent(0.0);
        if (g_bDebugOn) DebugOutput(["link_message pinging", KB_HAIL_CHANNEL]);
        llRegionSay(KB_HAIL_CHANNEL, "ping");        
    }
}

// kb_status