// kb_status

string  KB_VERSIONMAJOR      = "8";
string  KB_VERSIONMINOR      = "0";
string  KB_DEVSTAGE          = "a102";
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
    g_bDebugOn = TRUE;
    g_iDebugLevel = 0;
}

integer g_bDebugOn = FALSE;
integer g_iDebugLevel = 10;
integer KB_DEBUG_CHANNEL           = -617783;
integer g_iDebugCounter = 0;

string g_sWearerID;
key g_kWearer;

key g_kGroup = "";
integer g_iGroupEnabled = FALSE;

string g_sParentMenu = "Apps";
string g_sSubMenu = "KBStatus";
integer g_iRunawayDisable=0;
integer g_iSWActive = 1;
integer KB_HAIL_CHANNEL = -317783;
list g_lHostSettings = [];
list g_lCollarSettings = [];
float g_fStartDelay = 0.0;
integer g_iSettings = 0;
integer g_iSayings1 = 0;
integer g_iLineNr = 0;
integer g_iLogLevel = 0; // minimal logging
string  g_sSlaveMessage = "";
string  g_sSlaveName = "";
string  g_sKBarTitle = "";

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
integer LM_SETTING_EMPTY = 2004;

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
integer KB_COLLAR_VERSION           = -34847;
integer LINK_KB_VERS_REQ = -75301;
integer LINK_KB_VERS_RESP = -75302;
integer KB_REQUEST_VERSION         = -34591;
string UPMENU = "BACK";
//integer g_iCaptureIsActive=FALSE; // If this flag is set, then auth will deny access to it's menus
//integer g_iOpenAccess; // 0: disabled, 1: openaccess
//integer g_iLimitRange=1; // 0: disabled, 1: limited
//integer g_iOwnSelf; // self-owned wearers
//string g_sFlavor = "OwnSelf";

list g_lMenuIDs;
integer g_iMenuStride = 3;
integer g_iListenHandle = 0;

string g_sSettingToken = "auth_";
string g_sGlobalToken = "global_";
string g_sTitlerToken = "titler_";

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

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kID, kMenuID, sName];
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

HandleSettings(string sStr) {

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
    if (g_bDebugOn) DebugOutput(3, ["HandleSettings-2", llToLower(llGetSubString(sToken, 0, i)), llToLower(g_sGlobalToken), llToLower(g_sTitlerToken)]);
    if (llToLower(llGetSubString(sToken, 0, i)) == llToLower(g_sGlobalToken)) { // if "major_" = "global_"
        sToken = llGetSubString(sToken, i + 1, -1);
        if (g_bDebugOn) DebugOutput(3, ["HandleSettings-3", sToken, sValue]);
        if (sToken == "slavemsg") g_sSlaveMessage = sValue;
        else if (sToken == "loglevel") SetLogLevel((integer) sValue, FALSE, (key) g_sWearerID);
        else if (sToken == "swactive") SetSWActive((integer) sValue, FALSE);
        else if(sToken == "checkboxes"){
            g_lCheckboxes = llCSV2List(sValue);
        }
    } else if (llToLower(llGetSubString(sToken, 0, i)) == llToLower(g_sTitlerToken)) { // if "major_" = "titler_" 
        sToken = llGetSubString(sToken, i + 1, -1);
        if (g_bDebugOn) DebugOutput(3, ["HandleSettings-4", sToken, sValue]);
        if (sToken == "slavename") g_sSlaveName = sValue;
        else if (sToken == "kbartitle") g_sKBarTitle = sValue;
    }
}

HandleDeletes(string sStr) {
    list lParams = llParseString2List(sStr, ["_"],[]);
    string sToken = llList2String(lParams,0);
    string sVariable = llList2String(lParams,1);
    integer i = llSubStringIndex(sToken, "_");
    if (llToLower(llGetSubString(sToken, 0, i)) == llToLower(g_sGlobalToken)) { // if "major_" = "global_"
        sToken = llGetSubString(sToken, i + 1, -1);
        if (sToken == "slavemsg") g_sSlaveMessage = "";
        else if (sToken == "loglevel") SetLogLevel(FALSE, FALSE, (key) g_sWearerID);
        else if (sToken == "swactive") SetSWActive(FALSE, FALSE);
    } else if (llToLower(llGetSubString(sToken, i + 1, -1)) == llToLower(g_sTitlerToken)) { // if "major_" = "titler_" 
        sToken = llGetSubString(sToken, i + 1, -1);
        if (sToken == "slavename") g_sSlaveName = "";
        else if (sToken == "kbartitle") g_sKBarTitle = "";
    }
}

LogLevelMenu(key kAv, integer iAuth) {
    string sPrompt = "\n[Logging Level]";
    sPrompt += "\nSelect a log leve between 0 and 9.";
    sPrompt += "\n0 means minimum logging, 9 means maximum, other numbers somewhere in between";
    list lButtons = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"];
    Dialog(kAv, sPrompt, lButtons, [UPMENU], 0, iAuth, "LogLevel");
    
}

StatMenu(key kAv, integer iAuth) {
    string sPrompt = "\n[KBar Status " + formatVersion() + " " + (string) llGetFreeMemory() + " bytes free]\n";
    sPrompt += "Collar version " + g_sCollarVersion + "\n";
    sPrompt += "\nThis is a K-Bar plugin; for support, wire roan (Silkie Sabra), K-Bar Ranch.\n";

    if (g_iSWActive) sPrompt += "\nSafeword enabled"; else sPrompt += "\nSafeword disabled";
    sPrompt += "\nKBar Title: " + g_sKBarTitle;
    sPrompt += "\nSlave Name: " + g_sSlaveName;
    sPrompt += "\nLogin Message: " + g_sSlaveMessage; 

    list lButtons = []; // ["KickStart"];
//    if ((iAuth == CMD_OWNER) || g_bDebugOn) lButtons += ["Debug", "LogLevel", "Kickstart", Checkbox(g_iSWActive, "Safeword")];
    if ((iAuth == CMD_OWNER) || g_bDebugOn) lButtons += ["KBarTitle", "SlaveName", "SlaveMessage", "KBVersions", Checkbox(g_iSWActive, "Safeword")];

    Dialog(kAv, sPrompt, lButtons, [UPMENU], 0, iAuth, "Stat");
}

DebugMenu(key keyID, integer iAuth) {
    string sPrompt = "\n[KB Status Debug Level (less is more)] "+ formatVersion() + ", " + (string) llGetFreeMemory() + " bytes free.\nCurrent debug level: " + (string) g_iDebugLevel;
    list lMyButtons = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10"];
    Dialog(keyID, sPrompt, lMyButtons, [UPMENU], 0, iAuth, "Debug");
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
            if (sMessage == UPMENU)
                llMessageLinked(LINK_SET, iAuth, "menu " + g_sParentMenu, kAv);
            else if (llToLower(sMessage) == "debug") DebugMenu(kAv, iAuth);
            else {
                if (llToLower(sMessage) == llToLower(Checkbox(TRUE, "Safeword"))) UserCommand(iAuth, "safeword on", kAv, TRUE);
                else if (llToLower(sMessage) == llToLower(Checkbox(FALSE, "Safeword"))) UserCommand(iAuth, "safeword off", kAv, TRUE);
                else if (llToLower(sMessage) == "slavename") Dialog(kAv, "What is the slave's name?", [], [], 0, iAuth, "Textbox~Name");
                else if (llToLower(sMessage) == "slavemessage") Dialog(kAv, "What message at login?", [], [], 0, iAuth, "Textbox~Msg");
                else if (llToLower(sMessage) == "kbartitle") Dialog(kAv, "What is the KBar Title?", [], [], 0, iAuth, "Textbox~KBTitle");
                else if (llToLower(sMessage) == "kbversions") {
                    llMessageLinked(LINK_SET, KB_REQUEST_VERSION, "", kAv);
                    StatMenu(kAv, iAuth);
                }
            }
        } else if (sMenu == "Debug") {
            SetDebugLevel(sMessage);
            StatMenu(kAv, iAuth);
        } else if (sMenu == "LogLevel") {
            SetLogLevel((integer) sMessage, TRUE, kID);
            StatMenu(kAv, iAuth);
        } else if (sMenu == "Textbox~Name") {
            g_sSlaveName = sMessage;
            SaveAndResend(g_sTitlerToken + "SlaveName", sMessage);
            StatMenu(kAv, iAuth);
        } else if (sMenu == "Textbox~Msg") {
            g_sSlaveMessage = sMessage;
            SaveAndResend(g_sGlobalToken + "SlaveMsg", sMessage);
            StatMenu(kAv, iAuth);
        } else if (sMenu == "Textbox~KBTitle") {
            g_sKBarTitle = sMessage;
            SaveAndResend(g_sTitlerToken + "KBarTitle", sMessage);
            StatMenu(kAv, iAuth);
        }
    }
}

UserCommand(integer iNum, string sStr, key kID, integer iRemenu) { // here iNum: auth value, sStr: user command, kID: avatar id
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
                llMessageLinked(LINK_SET,NOTIFY,"1"+"Your safeword has been enabled.",(key) g_sWearerID);
            } else {
                SetSWActive(FALSE, TRUE);
                    llMessageLinked(LINK_SET,NOTIFY,"1"+"Your safeword has been disabled.",(key) g_sWearerID);
            }
        }
        else
            llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS% to safeword function",kID);
        if (iRemenu) StatMenu(kID, iNum);
    } else if (sCommand == "loglevel") {
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
    llMessageLinked(LINK_SET, LM_SETTING_SAVE, sToken+"="+sValue,"");
}

DeleteAndResend(string sToken) {
    llMessageLinked(LINK_SET, LM_SETTING_DELETE, sToken,"");
}

MenuResponse() {
//    llMessageLinked(LINK_SET, MENUNAME_REQUEST, g_sSubMenu, NULL_KEY);
    llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, NULL_KEY);
}

Init() {
    g_iDebugCounter = 0;
    g_sCollarVersion = "not set";
    g_sWearerID = llGetOwner();
}

integer ALIVE = -55;
integer READY = -56;
integer STARTUP = -57;
default
{
    on_rez(integer iNum){
        llResetScript();
    }
    
    state_entry(){
        llMessageLinked(LINK_SET, ALIVE, llGetScriptName(),"");
    }
    
    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if(iNum == REBOOT) {
            if(sStr == "reboot") {
                llResetScript();
            }
        } else if(iNum == READY) {
            llMessageLinked(LINK_SET, ALIVE, llGetScriptName(), "");
        } else if(iNum == STARTUP) {
            state active;
        }
    }
}

state active
{
    state_entry()
    {
        g_kWearer = llGetOwner();
        Init();
    }
    on_rez(integer i) {
        if(llGetOwner()!=g_kWearer) llResetScript();
        Init();
        MenuResponse();
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if(iNum == MENUNAME_REQUEST && sStr == g_sParentMenu) {
            llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
        }
        else if (iNum >= CMD_OWNER && iNum <= CMD_EVERYONE) UserCommand(iNum, sStr, kID, FALSE);
        else if (iNum == LM_SETTING_RESPONSE) {
            HandleSettings(sStr);
        } else if((iNum == LM_SETTING_DELETE) || (iNum == LM_SETTING_EMPTY)) {
            HandleDeletes(sStr);
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
        else if (iNum == KB_COLLAR_VERSION) g_sCollarVersion = sStr;
        else if (iNum == KB_REQUEST_VERSION)
            llMessageLinked(LINK_SET,NOTIFY,"0"+"Collar version " + g_sCollarVersion + "\n" + llGetScriptName() + " version " + formatVersion(),kID);
        else if (iNum == LINK_CMD_DEBUG) {
            integer onlyver=0;
            if(sStr == "ver")onlyver=1;
            llInstantMessage(kID, llGetScriptName() +" SCRIPT VERSION: "+g_sScriptVersion);
            if(onlyver)return; // basically this command was: <prefix> versions
        }
    }

    changed(integer iChange) {
        if (iChange & CHANGED_OWNER) llResetScript();
    }
}

// kb_status