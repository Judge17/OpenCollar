
//K-Bar tplimits

string  g_sModule = "tplim";
list    g_lMenuIDs;
integer g_iMenuStride = 3;

string  g_sSubMenu           = "TPLimits"; // Name of the submenu
string  g_sParentMenu        = "Apps";     // name of the menu, where the menu plugs in
string  g_sChatCommand       = "tplim";    // every menu should have a chat command
string  BUTTON_PARENTMENU    = g_sParentMenu;
key     g_kWebLookup;
string  KB_VERSION           = "7.5";
string  KB_DEVSTAGE          = "d";
string  g_sScriptVersion = "";
integer LINK_CMD_DEBUG=1999;

//integer g_bDebugOn = FALSE;
//key     g_kDebugKey = NULL_KEY;
key KURT_KEY   = "4986014c-2eaa-4c39-a423-04e1819b0fbf";
key SILKIE_KEY = "1a828b4e-6345-4bb3-8d41-f93e6621ba25";

//DebugOutput(integer iLevel, list ITEMS) {
//    if (g_iDebugLevel > iLevel) return;
DebugOutput(list ITEMS) {
    ++g_iDebugCounter;
    integer i=0;
    integer end=llGetListLength(ITEMS);
    string final;
    for(i=0;i<end;i++){
        final+=llList2String(ITEMS,i)+" ";
    }
    llSay(KB_DEBUG_CHANNEL, llGetScriptName() + " " + (string) g_iDebugCounter + " " + final);
//    llOwnerSay(llGetScriptName() + " " + (string) g_iDebugCounter + " " + final);
}

integer g_bDebugOn = FALSE;
integer g_iDebugLevel = 10;
integer KB_DEBUG_CHANNEL           = -617783;
integer g_iDebugCounter = 0;

SetDebugOn(key kID) {
    g_bDebugOn = TRUE;
    g_iDebugLevel = 0;
    g_iDebugCounter = 0;
    llMessageLinked(LINK_SET,NOTIFY,"0"+"TP debug active.", kID);
}

SetDebugOff(key kID) {
    g_bDebugOn = FALSE;
    g_iDebugLevel = 10;
    llMessageLinked(LINK_SET,NOTIFY,"0"+"TP debug inactive.", kID);
}

integer g_iRLVOn         = FALSE; //Assume RLV is off until we hear otherwise

key     g_kWearer = NULL_KEY;       // key of the current wearer to reset only on owner changes

string  g_sScript;                  // part of script name used for settings
//integer g_iKBarOptions=0;
//integer g_iGirlStatus=0; // 0=guest, 1=protected, 2=slave
list    g_lPairs = [];

integer CMD_OWNER = 500;
integer CMD_TRUSTED = 501;
integer CMD_WEARER = 503;

integer NOTIFY              = 1002;

integer LM_SETTING_SAVE     = 2000;
integer LM_SETTING_REQUEST  = 2001;
integer LM_SETTING_RESPONSE = 2002;
integer LM_SETTING_DELETE   = 2003;

integer MENUNAME_REQUEST    = 3000;
integer MENUNAME_RESPONSE   = 3001;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

integer RLV_OFF      = 6100;
integer RLV_ON       = 6101;

integer KB_NOTICE_LEASHED          = -34691;
integer KB_NOTICE_UNLEASHED        = -34692;
integer KB_SET_REGION_NAME         = -34693;
integer KB_REM_REGION_NAME         = -34694;
integer KB_REQUEST_VERSION         = -34591;

string UPMENU = "BACK";

string  ACTIVATE   = "Activate";
string  DEACTIVATE = "Deactivate";
string  FORCERESET = "ForceReset";
string  DEBUGON = "DebugOn";
string  DEBUGOFF = "DebugOff";
string  CURFEW = "Curfew";

integer g_iActive      = FALSE;
integer g_iCurfewActive = FALSE;
integer g_iLeashedRank = 0;
key     g_kLeashedTo   = NULL_KEY;

integer g_iSecondsBeforeBoot = 0;

integer bool(integer a){
    if(a)return TRUE;
    else return FALSE;
}

list g_lCheckboxes=["⬜","⬛"];
string Checkbox(integer iValue, string sLabel) {
    return llList2String(g_lCheckboxes, bool(iValue))+" "+sLabel;
}

list    PLUGIN_BUTTONS = [];

list    g_lButtons;

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) //we've alread given a menu to this user.  overwrite their entry
        g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
    else //we've not already given this user a menu. append to list
        g_lMenuIDs += [kID, kMenuID, sName];
}

InitPluginButtons() {
    PLUGIN_BUTTONS = [ACTIVATE, DEACTIVATE, DEBUGON, DEBUGOFF];
    string sWork = Checkbox(FALSE,"Active");
    PLUGIN_BUTTONS += [sWork];
    sWork = Checkbox(TRUE,"Active");
    PLUGIN_BUTTONS += [sWork];
}

DoMenu(key keyID, integer iAuth) {
    if (keyID == NULL_KEY) { return; }
    string s1;
    string s2;
    string s3;
    string s4;
    string s5;
    
    list lButtons = [];
    string sPrompt = "";

    if (g_iActive) {
        s2 = "Restrictions engaged\n";
    } else {
        s2 = "No restrictions\n";
    }
    lButtons += Checkbox(g_iActive, "Active");
    
    if ((keyID == KURT_KEY) || ((keyID == SILKIE_KEY) && (g_kWearer != keyID))) {
        lButtons += Checkbox(g_bDebugOn, "Debug");
    }
    
    s3 = "Leashed level: " + (string) g_iLeashedRank + "\n"; 
    s4 = llGetScriptName() + " " + (string) llGetFreeMemory() + " bytes free\n";
    s1 = "Approved regions:" + llList2CSV(dumpRegions()) + "\n";
    s5 = "Version " + KB_VERSION + KB_DEVSTAGE + "\n";

    sPrompt += "\nThis is a K-Bar plugin; for support, wire roan (Silkie Sabra), K-Bar Ranch.\n";

    sPrompt += s1 + s2 + s3 + s4 + s5 + "\nPick an option.";

    list lMyButtons = lButtons;

    Dialog(keyID, sPrompt, lMyButtons, [UPMENU], 0, iAuth, "mainmenu");
}

UserCommand(integer iNum, string sStr, key kID) {
    if(!(iNum >= CMD_OWNER && iNum <= CMD_WEARER)) return;
    // a validated command from a owner, secowner, groupmember or the wearer has been received
    list lParams = llParseString2List(sStr, [" "], []);
    //string sCommand = llToLower(llList2String(lParams, 0));
    //string sValue = llToLower(llList2String(lParams, 1));
    // So commands can accept a value
    if(sStr == g_sChatCommand || sStr == "menu " + g_sSubMenu) {
        // an authorized user requested the plugin menu by typing the menus chat command
        DoMenu(kID, iNum);
    }
    else if ((llGetSubString(sStr, 0, llStringLength(g_sChatCommand + " " + ACTIVATE) - 1) == g_sChatCommand + " " + ACTIVATE) || (sStr == Checkbox(TRUE, "Active"))) {
        if (iNum==CMD_OWNER) {
            g_iActive = TRUE;
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, "KBTP_engaged=y", "");
            llMessageLinked(LINK_SET,NOTIFY,"0"+"TP restrictions active.", kID);
        } else {
            llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS% to activate limits",kID);
        }
        DoMenu(kID, iNum);
    }
    else if ((llGetSubString(sStr, 0, llStringLength(g_sChatCommand + " " + DEACTIVATE) - 1) == g_sChatCommand + " " + DEACTIVATE) || (sStr == Checkbox(FALSE, "Active"))) {
        if (iNum == CMD_OWNER) {
            g_iActive = FALSE;
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, "KBTP_engaged=n", "");
            llMessageLinked(LINK_SET,NOTIFY,"0"+"TP restrictions inactive.", kID);
        } else {
            llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS% to deactivate limits", kID);
        }
        DoMenu(kID, iNum);
    }
    else if ((llGetSubString(sStr, 0, llStringLength(g_sChatCommand + " " + DEBUGON) - 1) == g_sChatCommand + " " + DEBUGON) || (sStr == Checkbox(TRUE, "Debug"))) {
        if ((kID == KURT_KEY) || ((kID == SILKIE_KEY) && (g_kWearer != kID))) {
            SetDebugOn(kID);
        } else {
            llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS% to activate TP debug",kID);
        }
        DoMenu(kID, iNum);
    }
    else if ((llGetSubString(sStr, 0, llStringLength(g_sChatCommand + " " + DEBUGOFF) - 1) == g_sChatCommand + " " + DEBUGOFF) || (sStr == Checkbox(FALSE, "Debug"))) {
        if ((kID == KURT_KEY) || ((kID == SILKIE_KEY) && (g_kWearer != kID))) {
            SetDebugOff(kID);
        } else {
            llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS% to deactivate TP debug", kID);
        }
        DoMenu(kID, iNum);
    }
/*
    else if(llGetSubString(sStr, 0, llStringLength(g_sChatCommand + " " + FORCERESET) - 1) == g_sChatCommand + " " + FORCERESET) {
        checkMemory(TRUE);
*/
}

list dumpRegions() {
    integer iIdx = 0;
    integer iLen = llGetListLength(g_lPairs);
    list lRet = [];
    for (iIdx = 0; iIdx < iLen; ++iIdx) {
        string sEntry = llList2String(g_lPairs, iIdx);
        list lEntry = llParseString2List(sEntry, ["~"], []);
        string sEntryName = llList2String(lEntry, 1);
        if (llListFindList(lRet, [sEntryName]) < 0) {
            lRet += [sEntryName];
        }
    }
    return lRet;
}

addOccurrence(string sName, string sRegion) {
    if (g_bDebugOn) { DebugOutput(["addOccurrence ", sName, sRegion]); }
    string sEntry = sName + "~" + sRegion;
    integer iIdx = llListFindList(g_lPairs, [sEntry]);
    if (iIdx < 0) {
        g_lPairs += [sEntry];
    }
}

deleteOccurence(string sName) {
    integer iIdx = findOccurrence(sName);
    if (iIdx >= 0) {
        g_lPairs = llDeleteSubList(g_lPairs, iIdx, iIdx);
    }
}

integer findOccurrence(string sName) {
    if (g_bDebugOn) { DebugOutput(["findOccurrence ", sName]); }
    integer iIdx = 0;
    integer iLen = llGetListLength(g_lPairs);
    for (iIdx = 0; iIdx < iLen; ++iIdx) {
        string sEntry = llList2String(g_lPairs, iIdx);
        if (g_bDebugOn) { DebugOutput(["findOccurrence entry ", sEntry]); }
        list lEntry = llParseString2List(sEntry, ["~"], []);
        string sEntryName = llList2String(lEntry, 0);
        if (sEntryName == sName) {
            if (g_bDebugOn) { DebugOutput(["findOccurrence returned ", iIdx]); }
            return iIdx;
        }
    }
    if (g_bDebugOn) { DebugOutput(["findOccurrence returned -1"]); }
    return -1;
}

integer findRegion(string sName) {
    integer iIdx = 0;
    integer iLen = llGetListLength(g_lPairs);
    for (iIdx = 0; iIdx < iLen; ++iIdx) {
        string sEntry = llList2String(g_lPairs, iIdx);
        list lEntry = llParseString2List(sEntry, ["~"], []);
        string sEntryName = llList2String(lEntry, 1);
        if (sEntryName == sName) { if (g_bDebugOn) { DebugOutput(["findRegion returning TRUE"]); } return TRUE; }
    }
    if (g_bDebugOn) { DebugOutput(["findRegion returning FALSE"]); }
    return FALSE;
}

parseSettings(integer iSender, integer iNum, string sStr, key kID) {
    // response from setting store have been received
    // parse the answer
    
    list lParams = llParseString2List(sStr, ["="], []); // now [0] = "major_minor" and [1] = "value"
    string sToken = llList2String(lParams, 0); // now SToken = "major_minor"
    string sValue = llList2String(lParams, 1); // now sValue = "value"
    integer i = llSubStringIndex(sToken, "_");
    string sTokenMajor = llToLower(llGetSubString(sToken, 0, i - 1));  // now sTokenMajor = "major"
    string sTokenMinor = "";
    if (i > 0 ) sTokenMinor = llToLower(llGetSubString(sToken, i + 1, -1));  // now sTokenMinor = "minor"
    if (g_bDebugOn) { DebugOutput(["parseSettings", iNum, sStr, sTokenMajor, sTokenMinor, sValue]); }
    if (iNum == LM_SETTING_RESPONSE) {
        if (sTokenMajor == "bookmarks") {
            if (g_bDebugOn) { DebugOutput([sTokenMajor, " ", sValue]); }
            list lparts = llParseString2List(sValue, ["("], [""]);
            string sRegion = llStringTrim(llList2String(lparts, 0), STRING_TRIM);
            addOccurrence(sTokenMinor, sRegion);
        }
        else if(sTokenMajor == "kbtp") {
            if (sTokenMinor == "engaged")  {
//                if (g_bDebugOn) { DebugOutput([sToken, " ", sValue]); }
                if ((sValue == "y") || (sValue == "Y")) {
                    g_iActive = TRUE;
                    checkStatus(TRUE);
                } else {
                    g_iActive = FALSE;
                }
            }
        } 
        else if (sTokenMajor == "leash") {
            if (sTokenMinor = "leashedto") {
                list lLeashed = llParseString2List(sValue, [","], []);
                if (g_bDebugOn) { list lTemp = ["saving settings", sTokenMajor, sTokenMinor] + lLeashed; DebugOutput(lTemp); }
                if (llList2Integer(lLeashed, 1) > 0) {
                    g_kLeashedTo = llList2Key(lLeashed, 0); 
                    g_iLeashedRank = llList2Integer(lLeashed, 1);
                    checkStatus(TRUE);
                }
            }
        }
        else if (sTokenMajor == "global") {
            if (sTokenMinor == "checkboxes") {
                if (g_bDebugOn) { DebugOutput([sTokenMajor, sTokenMinor, sValue]); }
                g_lCheckboxes = llCSV2List(sValue);
            }
        }
    }
    else if (iNum == LM_SETTING_DELETE) {
        if (sTokenMajor == "leash") {
            if (sTokenMinor = "leashedto") {
            if (g_bDebugOn) { DebugOutput(["Delete ", sToken]); }
                g_kLeashedTo = NULL_KEY; 
                g_iLeashedRank = 0; 
                checkStatus(TRUE);
            }
        }
    }
    else if (iNum == KB_NOTICE_LEASHED) {
        if (g_bDebugOn) { DebugOutput(["Notice:leashed"]); }
        list lLeashed = llParseString2List(sStr, [","], []);
        g_kLeashedTo = llList2Key(lLeashed, 0); 
        g_iLeashedRank = llList2Integer(lLeashed, 1); 
        checkStatus(TRUE);
    }
    else if (iNum == KB_NOTICE_UNLEASHED) {
        if (g_bDebugOn) { DebugOutput(["Notice:unleashed"]); }
        g_kLeashedTo = NULL_KEY; 
        g_iLeashedRank = 0; 
        checkStatus(TRUE);
    }
    else if (iNum == KB_REM_REGION_NAME) {
        list lparts = llParseString2List(sValue, ["_"], [""]);
        string sRegion = llStringTrim(llList2String(lparts, 1), STRING_TRIM);
        deleteOccurence(sRegion);
    }
}

integer RegOK(string sRegion) {
    return findRegion(sRegion);
}

integer LeashOK() {
    if (g_bDebugOn) { DebugOutput(["LeashOK ", "g_kLeashedTo " + (string) g_kLeashedTo]); }
    if (g_kLeashedTo != NULL_KEY) {
        if (g_bDebugOn) { DebugOutput(["LeashOK ", "g_iLeashedRank " + (string) g_iLeashedRank]); }
        if ((g_iLeashedRank == CMD_OWNER) || (g_iLeashedRank == CMD_TRUSTED)) {  return TRUE; }
    }
    return FALSE;
}

integer checkOK(integer bFirstTime, string sRegion) {

/*
    checkOK is an extension of checkStatus. It handles the actual logic to decide whether the wearer is
        allowed in the region currently occupied
*/

    llSetTimerEvent(0.0);
    if (g_bDebugOn) { DebugOutput(["checkOK ", "g_iActive " + (string) g_iActive]); }
    if (!g_iActive) return TRUE;
    if (LeashOK()) return TRUE;
    if (RegOK(sRegion)) return TRUE;
    if ((findOccurrence("Home") >= 0) ||
        (findOccurrence("home") >= 0) ||
        (findOccurrence("DefaultHome") >= 0) ||
        (findOccurrence("defaulthome") >= 0)) {
            if (g_bDebugOn) { 
                DebugOutput(["checkOK ", 
                "g_iSecondsBeforeBoot " + (string) g_iSecondsBeforeBoot,
                "bFirstTime " + (string) bFirstTime]); 
            }
            if (bFirstTime) {
                g_iSecondsBeforeBoot = 30;
                llSetTimerEvent(5.0);
            }
    } else {
        llMessageLinked(LINK_SET,NOTIFY,"0"+"DefaultHome and Home bookmarks both missing.", g_kWearer);
    }
    return FALSE;
/*    
    llMessageLinked(LINK_SET,NOTIFY,"0"+"you are not allowed in this region unless you are leashed.", g_kWearer);
    if (findOccurrence("Home") >= 0) {
        llMessageLinked(LINK_THIS, CMD_OWNER, "tp Home", g_kWearer);
    } 
    else if (findOccurrence("home") >= 0) {
        llMessageLinked(LINK_THIS, CMD_OWNER, "tp home", g_kWearer);
    }
    else if (findOccurrence("DefaultHome") >= 0) {
        llMessageLinked(LINK_THIS, CMD_OWNER, "tp DefaultHome", g_kWearer);
    }
    else if (findOccurrence("defaulthome") >= 0) {
        llMessageLinked(LINK_THIS, CMD_OWNER, "tp defaulthome", g_kWearer);
    } else {
        llMessageLinked(LINK_SET,NOTIFY,"0"+"DefaultHome and Home bookmarks both missing.", g_kWearer);
    }
*/
}

checkMemory(integer iForce) {
    if (iForce) {
        llMessageLinked(LINK_SET,NOTIFY,"0"+"kbtplim is resetting due to forced input.", g_kWearer);
        llResetScript();
    } else {
        if (llGetFreeMemory() < 6000) {
            llMessageLinked(LINK_SET,NOTIFY,"0"+"kbtplim is resetting due to minimum available memory.", g_kWearer);
            llResetScript();
        }
    }
}

integer checkStatus(integer bFirstTime) {
/*
    checkOK is an extension of checkStatus. It handles the actual logic to decide whether the wearer is
        allowed in the region currently occupied
*/
    if (bFirstTime) {
        g_iSecondsBeforeBoot = 0;
        llSetTimerEvent(0.0);
    }
    if (checkOK(bFirstTime, llGetRegionName())) {
        if (g_bDebugOn) { DebugOutput(["checkStatus returning TRUE"]); }
        return TRUE;
    } else {
        if (g_bDebugOn) { DebugOutput(["checkStatus returning FALSE"]); }
        return FALSE;
    }
}

default  {
    changed(integer iChange) {
        if(iChange & CHANGED_OWNER) { llResetScript(); }

        if (iChange & CHANGED_REGION) { checkStatus(TRUE); }

        if (iChange & CHANGED_REGION) { checkMemory(FALSE); }
    }

    state_entry() {
        g_sScript = llStringTrim(llList2String(llParseString2List(llGetScriptName(), ["-"], []), 1), STRING_TRIM) + "_";
        g_sScriptVersion = KB_VERSION + KB_DEVSTAGE;
        // store key of wearer
        g_kWearer = llGetOwner();
        InitPluginButtons();
        // sleep a second to allow all scripts to be initialized
        // send request to main menu and ask other menus if they want to register with us
        llMessageLinked(LINK_THIS, MENUNAME_REQUEST, g_sSubMenu, NULL_KEY);
        llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, NULL_KEY);
        llSleep(1.5);
        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "bookmarks", "");
    }

    on_rez(integer iParam) {
        if (g_bDebugOn) { DebugOutput(["on_rez ", "wearer ",  g_kWearer]); }
        if(llGetOwner() != g_kWearer) {
        // Reset if wearer changed
            llResetScript();
        }
        checkMemory(FALSE);
    }

    // listen for linked messages from OC scripts
    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if(iNum == MENUNAME_REQUEST && sStr == g_sParentMenu) {
            llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
        }
        else if (iNum >= CMD_OWNER && iNum <= CMD_WEARER) {
            UserCommand(iNum, sStr, kID);
        }
        else if(iNum == RLV_OFF) { // rlvoff -> we have to turn the menu off too
            g_iRLVOn = FALSE;
        }
        else if(iNum == RLV_ON) { // rlvon -> we have to turn the menu on again
            g_iRLVOn = TRUE;
        }
        else if(iNum == LM_SETTING_RESPONSE) {
            parseSettings(iSender, iNum, sStr, kID);
        }
        else if(iNum == LM_SETTING_DELETE) {
            parseSettings(iSender, iNum, sStr, kID);
        }
        else if ((iNum == KB_NOTICE_LEASHED) || iNum == (KB_SET_REGION_NAME)
              || (iNum == KB_NOTICE_UNLEASHED) || iNum == (KB_REM_REGION_NAME)) {
            parseSettings(iSender, iNum, sStr, kID);
        }

        else if(iNum == DIALOG_RESPONSE) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (iMenuIndex != -1) {
                list lMenuParams = llParseStringKeepNulls(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0); // avatar using the menu
                string sMessage = llList2String(lMenuParams, 1); // button label
                integer iPage = (integer)llList2String(lMenuParams, 2); // menu page
                integer iAuth = (integer)llList2String(lMenuParams, 3); // auth level of avatar
                list lParams =  llParseStringKeepNulls(sStr, ["|"], []);
                string sMenuType = llList2String(g_lMenuIDs, iMenuIndex + 1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
                if (sMenuType == "mainmenu") {
                    if (sMessage == UPMENU)
                        llMessageLinked(LINK_ROOT, iAuth, "menu "+BUTTON_PARENTMENU, kAv);
                    else if (sMessage == ACTIVATE) {
                        UserCommand(iAuth, g_sChatCommand + " " + ACTIVATE, kAv);
                    }
                    else if(sMessage == DEACTIVATE) {
                        UserCommand(iAuth, g_sChatCommand + " " + DEACTIVATE, kAv);
                    }
                    else if(sMessage == FORCERESET) {
                        UserCommand(iAuth, g_sChatCommand + " " + FORCERESET, kAv);
                    }
                    else if(sMessage == DEBUGON) {
                        UserCommand(iAuth, g_sChatCommand + " " + DEBUGON, kAv);
                    }
                    else if(sMessage == DEBUGOFF) {
                        UserCommand(iAuth, g_sChatCommand + " " + DEBUGOFF, kAv);
                    }
                    else if(sMessage == Checkbox(FALSE,"Active")) {
                        UserCommand(iAuth, g_sChatCommand + " " + ACTIVATE, kAv);
                    }
                    else if(sMessage == Checkbox(TRUE,"Active")) {
                        UserCommand(iAuth, g_sChatCommand + " " + DEACTIVATE, kAv);
                    }
                    else if(sMessage == Checkbox(FALSE,"Debug")) {
                        UserCommand(iAuth, g_sChatCommand + " " + DEBUGON, kAv);
                    }
                    else if(sMessage == Checkbox(TRUE,"Debug")) {
                        UserCommand(iAuth, g_sChatCommand + " " + DEBUGOFF, kAv);
                    }
                }
            }
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
        }
    }
    
    timer() {
        llSetTimerEvent(0.0);
        if (g_bDebugOn) { DebugOutput(["timer ", "seconds left " + (string) g_iSecondsBeforeBoot]); }
        if (checkStatus(FALSE)) {
            llMessageLinked(LINK_SET,NOTIFY,"0"+"removal aborted.", g_kWearer);
            g_iSecondsBeforeBoot = 0;
        } else {
            if (g_iSecondsBeforeBoot > 0) {
                string sMsg = "you are not allowed in this region unless you are leashed. you have " + (string) g_iSecondsBeforeBoot + " seconds left.";
                g_iSecondsBeforeBoot -= 5;
                llMessageLinked(LINK_SET,NOTIFY,"0"+sMsg, g_kWearer);
                llSetTimerEvent(5.0);
            } else {
                llSetTimerEvent(0.0);
                if (findOccurrence("Home") >= 0) {
                    llMessageLinked(LINK_THIS, CMD_OWNER, "tp Home", g_kWearer);
                } else if (findOccurrence("home") >= 0) {
                    llMessageLinked(LINK_THIS, CMD_OWNER, "tp home", g_kWearer);
                } else if (findOccurrence("DefaultHome") >= 0) {
                    llMessageLinked(LINK_THIS, CMD_OWNER, "tp DefaultHome", g_kWearer);
                } else if (findOccurrence("defaulthome") >= 0) {
                    llMessageLinked(LINK_THIS, CMD_OWNER, "tp defaulthome", g_kWearer);
                } else { llMessageLinked(LINK_SET,NOTIFY,"0"+"TP home failed.", g_kWearer);
                }
            }
        }
    }
}

// kb_tplim
