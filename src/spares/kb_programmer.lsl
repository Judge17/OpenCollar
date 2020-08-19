
//K-Bar Version 20191224 1415 1800 kb_programmer

key KURT_KEY   = "4986014c-2eaa-4c39-a423-04e1819b0fbf";
key SILKIE_KEY = "1a828b4e-6345-4bb3-8d41-f93e6621ba25";

string g_sModule = "programmer";

integer g_iCount = 28;
list            g_lTempLines = [];    // The resulting data pushed into a list
integer         g_iLine;              // The line count for the card reader
key             g_kQuery;             // The key of the card being read
string          g_sNoteCardName = "kbprograms"; // The name of the card being read

string g_sSubMenu = "Programs";      // Name of the submenu
string g_sParentMenu = "Apps";       // name of the menu, where the menu plugs in
string g_sChatCommand = "kbprogram"; // every menu should have a chat command

integer LINK_KB_VERS_REQ = -75301;
integer LINK_KB_VERS_RESP = -75302;
string  KB_VERSION = "7.4";
string  KB_DEVSTAGE = "c";

string g_sWearer;
key    g_kIndexLookup;
key    g_kTextLookup;

key g_kMenuID = NULL_KEY;           // menu handler
key g_kAddPhraseSave = NULL_KEY;
key g_kRemoveMenu = NULL_KEY;

string g_sAddPhrasePrompt = "Enter saying to add or blank to del.";

key g_kWearer;                      // key of the current wearer to reset only on owner changes
integer g_iReshowMenu=FALSE; // some command need to wait on a processing or need to run through the auth sstem before they can show a menu again, they can use the variable and call the menu if it is set to true

list g_lLocalbuttons = []; // any local, not changing buttons which will be used in this plugin, leave empty or add buttons as you like
list g_lButtons = [];

integer g_iProgramming = FALSE;
integer g_iAutoLoop = FALSE;
integer g_iAutoCount = 0;

integer g_iMsgDelay = 0;

string PROGRAM_ON = "Program_On";
string PROGRAM_OFF = "Program_Off";
string PROGRAM_CONSTANT = "Program_Loop";
string PROGRAM_TIMER = "Program_Timer";
string PROGRAM_CLEAR = "PROGRAM_CLEAR";
string CLEARALL = "ClearAll";
string ADDSAYING = "AddSaying";
string DELSAYING = "DelSaying";
string LISTSAYINGS = "ListSayings";
string RELOAD = "Reload";
string PROGRUN_SETTING = "programrun";
string PROGLOOP_SETTING = "progloop";
string SHORT_PROGRUN = "progon";
string SHORT_PROGRUNOFF = "progoff";
string SHORT_PROGNOTIMER = "noauto";
string SHORT_PROGTIMER = "autooff";

//list g_lOptions = [ PROGRUN_SETTING, PROGLOOP_SETTING ];
//list g_lSettings = [ PROGRUN_SETTING, "n", PROGLOOP_SETTING, "n" ];

//integer LINK_AUTH           = LINK_SET; // = 2;
//integer LINK_SET         = LINK_SET; // = 3;
//integer LINK_RLV            = LINK_SET; // = 4;
//integer LINK_SET           = LINK_SET; // = 5;
//integer LINK_ANIM           = LINK_SET; // = 6;
//integer LINK_UPDATE         = -10;

integer CMD_OWNER           = 500;
integer CMD_WEARER          = 503;
integer NOTIFY              = 1002;

integer LM_SETTING_SAVE     = 2000;
integer LM_SETTING_REQUEST  = 2001;
integer LM_SETTING_RESPONSE = 2002;
integer LM_SETTING_DELETE   = 2003;

integer MENUNAME_REQUEST    = 3000;
integer MENUNAME_RESPONSE   = 3001;
integer MENUNAME_REMOVE     = 3003;

integer DIALOG              = -9000;
integer DIALOG_RESPONSE     = -9001;
integer DIALOG_TIMEOUT      = -9002;

string UPMENU               = "BACK";
string g_sGlobalToken       = "global_";
string g_sProgToken         = "kbwhisper_";

list g_lIndex = [];
integer g_iIndex = 0;
integer g_iIndCount = 0;
string g_sIndName = "";

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

list g_lMenuIDs;//3-strided list of avkey, dialogid, menuname
integer g_iMenuStride = 3;

integer randIntBetween(integer min, integer max) {
    integer i = min + randInt(max - min);
    return i;
}

integer randInt(integer n) {
    return (integer) llFrand(n + 1);
}

integer coin_toss() {
  if( llFrand(1.0) < .5 ) return TRUE;
  return FALSE;
}

string g_sScript = "kbprograms_";

string PeelToken(string in, integer slot) {
    integer i = llSubStringIndex(in, "_");
    if (!slot) return llGetSubString(in, 0, i);
    return llGetSubString(in, i + 1, -1);
}

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
  key kMenuID = llGenerateKey();
  llMessageLinked(LINK_SET, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

  integer iIndex = llListFindList(g_lMenuIDs, [kID]);
  if (~iIndex) //we've alread given a menu to this user.  overwrite their entry
    g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
  else //we've not already given this user a menu. append to list
    g_lMenuIDs += [kID, kMenuID, sName];
}
/*
integer isTrue(string sIn) {
  string sWork = llToLower(sIn);
  if ((sWork == "y") || (sWork == "yes") || (sWork == "true") || (sWork == "1")) {
    return TRUE;
  }
  return FALSE;
}

integer setSetting(string sSetting, string sValue) {
    integer iIndex = llListFindList(g_lSettings, [sSetting]);
    if (iIndex == -1) {   //we don't alread have this exact setting.  add it
        g_lSettings += [sSetting, sValue];
        return TRUE;
    } else {   //we already have a setting for this option.  update it.
        string sTest = llList2String(g_lSettings, iIndex + 1);
        if (isTrue(sValue) != isTrue(sTest)) {
            g_lSettings = llListReplaceList(g_lSettings, [sSetting, sValue], iIndex, iIndex + 1);
            return TRUE;
        }
    }
    return FALSE;
}

integer getSetting(string sSetting) {
    integer iI = llListFindList(g_lSettings, [sSetting]);
    if (iI == -1) return FALSE;
    return isTrue(llList2String(g_lSettings, iI + 1));
}

UpdateSettings() {
    g_iProgramming = getSetting(PROGRUN_SETTING);
//      llOwnerSay("kb_programmer UpdateSettings g_iProgramming set to " + (string) g_iProgramming);
    if (g_iProgramming) {
        unsetTimer();
        setTimer();
    }
    g_iAutoLoop = getSetting(PROGLOOP_SETTING);
//      llOwnerSay("kb_programmer UpdateSettings g_iAutoLoop set to " + (string) g_iAutoLoop);
}

SaveSettings() {
    string token = g_sScript + "List";
    //save to DB
    if (llGetListLength(g_lSettings)>0) {
        llMessageLinked(LINK_SET, LM_SETTING_SAVE, token + "=" + llDumpList2String(g_lSettings, ","), "");
    } else {
        llMessageLinked(LINK_SET, LM_SETTING_DELETE, token, "");
    }
}
*/
DoMenu(key keyID, integer iAuth) {
    string s1;
    string s2;
//    string s3;
    string s4;
    string s5;
    string sPrompt ="\n" + llGetScriptName() + " v" + KB_VERSION + KB_DEVSTAGE;
    
    list lButtons = g_lLocalbuttons + g_lButtons + [ADDSAYING, DELSAYING, LISTSAYINGS, RELOAD];

    s1 = "\nCurrent delay " + (string) g_iMsgDelay + " seconds; iteration " + (string) g_iAutoCount + "\n";

    if (g_iProgramming) {
        s2 = "Whispers enabled "; 
        lButtons += [PROGRAM_OFF];
    } else {
        s2 = "Whispers disabled ";
        lButtons += [PROGRAM_ON];
    }
    if (g_iAutoLoop) {   
        s2 += "endless loop\n"; 
        lButtons += [PROGRAM_TIMER];
    } else {
        s2 += "on timer\n";
        lButtons += [PROGRAM_CONSTANT];
    }
    s4 = llGetScriptName() + " " + (string) llGetFreeMemory() + " bytes free\n";
    s5 = (string) g_iCount + " sayings ready\n";

    sPrompt += "\n" + s1 + s2 + s4 +s5 + "Pick an option.\n";
    if (keyID == NULL_KEY) { return; }
    
    lButtons = llListSort(lButtons, 1, TRUE); // resort menu buttons alphabetical
    // and display the menu
    Dialog(keyID, sPrompt, lButtons, [UPMENU], 0, iAuth, "ProgMenu");
}

setTimer() {
    llSetTimerEvent(0.0);
    g_iMsgDelay = randIntBetween(1, 600) + 1;
    llSetTimerEvent((float) g_iMsgDelay);
}

unsetTimer() {
    llSetTimerEvent(0.0);
    g_iMsgDelay = 0;
}

integer selectOne(integer iLow, integer iHigh) {
    integer iLowBound = iLow;
    integer iHighBound = iHigh;
    if (iLow == iHigh) return iLow;
    if (iLow > iHigh) { iLowBound = iHigh; iHighBound = iLow; }
    if (iHighBound == (iLowBound + 1)) { if (coin_toss()) return iLowBound; else return iHighBound; }
    integer iMidPoint = ((iHighBound - iLowBound) / 2) + iLowBound;
    if (coin_toss()) return selectOne(iLowBound, iMidPoint);
    return selectOne(iMidPoint, iHighBound);
}

printPhrases(key kID) {
    
    llRegionSayTo(kID, 0, "kbprogrammer sayings set:");
    integer i;
    integer length = llGetListLength(g_lTempLines);
    for(i = 0; i < length; i++)  {
        llRegionSayTo(kID, 0, (string) i + "-" + llList2String(g_lTempLines, i));
    }
}

UserCommand(integer iNum, string sStr, key kID)
{
    list lParams = llParseString2List(sStr, [" "], []);
    string sCommand = llToLower(llList2String(lParams, 0));
    string sButton = llList2String(lParams, 0);
    string sValue = llToLower(llList2String(lParams, 1));
    string sMenuName = llToLower(g_sSubMenu);
    integer iChange = FALSE;
    if (sCommand == "programsmenu" 
    || (sCommand == "menu" && sValue =="programs")
    || (sCommand == "menu" && sValue =="Programs")) {
      if (kID!=g_kWearer && iNum!=CMD_OWNER) {
        llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS%",kID);
        llMessageLinked(LINK_SET, iNum, "menu " + g_sParentMenu, kID);
      } else DoMenu(kID, iNum);
    }
    else if (sCommand == "reset") {
      if (kID!=g_kWearer && iNum!=CMD_OWNER) {
        llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS%",kID);
        llMessageLinked(LINK_SET, iNum, "menu " + g_sParentMenu, kID);
      } else llResetScript();
    }
    else if (iNum == CMD_OWNER) {
      if (sButton == PROGRAM_ON) { 
//          iChange = setSetting(PROGRUN_SETTING, "y");
          g_iProgramming = TRUE; 
          llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sProgToken + PROGRUN_SETTING + "=y", "");
          setTimer();
          llMessageLinked(LINK_SET,NOTIFY,"0"+"Programming active",kID);
          DoMenu(kID, iNum);
      } else if (sButton == PROGRAM_OFF) { 
//          iChange = setSetting(PROGRUN_SETTING, "n");
          g_iProgramming = FALSE; 
          llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sProgToken + PROGRUN_SETTING + "=n", "");
          unsetTimer();
          llMessageLinked(LINK_SET,NOTIFY,"0"+"Programming inactive",kID);
          DoMenu(kID, iNum);
      } else if (sButton == PROGRAM_CONSTANT) { 
//          iChange = setSetting(PROGLOOP_SETTING, "y");
          g_iAutoLoop = TRUE; 
          g_iAutoCount = 0;
          llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sProgToken + PROGLOOP_SETTING + "=y", "");
          llMessageLinked(LINK_SET,NOTIFY,"0"+"No time limit",kID);
          DoMenu(kID, iNum);
      } else if (sButton == PROGRAM_TIMER) { 
//          iChange = setSetting(PROGLOOP_SETTING, "n");
          g_iAutoLoop = FALSE; 
          g_iAutoCount = 0;
          llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sProgToken + PROGLOOP_SETTING + "=n", "");
          llMessageLinked(LINK_SET,NOTIFY,"0"+"Auto off enabled",kID);
          DoMenu(kID, iNum);
      } else if (sButton == ADDSAYING) { 
          Dialog(kID, g_sAddPhrasePrompt, [], [], 0, iNum, "AddMenu");
      } else if (sButton == DELSAYING) { 
          Dialog(kID, "Select a saying to be removed...", g_lTempLines, [UPMENU], 0, iNum, "DelMenu");
      } else if (sButton == LISTSAYINGS) { 
          printPhrases(kID);
          DoMenu(kID, iNum);
      } else if (sButton == RELOAD) { 
          ReadIndex(g_sWearer);
          DoMenu(kID, iNum);
      }
//      if (iChange) {
//        UpdateSettings();
//        SaveSettings();
//      }
    }
}

ReadIndex(string sName)
{
    string sURL;
    key kAv;
    integer iExists = 0;
    iExists = llGetInventoryType(sName);
    if (iExists != INVENTORY_NONE) {
      g_sIndName = sName;
      g_lTempLines = ["No sayings set"];
      g_iCount = llGetListLength(g_lTempLines);
      g_lIndex = [];
      g_iIndex = 0;
      g_iLine = 0;
      if (!g_iKBarOptions) g_kQuery = llGetNotecardLine(g_sNoteCardName, g_iLine);  
    }
}

AddLine(string sLine) {
  integer iCount = llGetListLength(g_lTempLines);
  if (iCount == 0) {
    g_lTempLines = [sLine];
    g_iCount = 1;
  } else if (iCount == 1) {
      if (llList2String(g_lTempLines, 0) == "No sayings set") {
        g_lTempLines = [sLine];
      } else if (llList2String(g_lTempLines, 0) != sLine) {
          g_lTempLines += [sLine];
      }
  } else if (llListFindList(g_lTempLines, [sLine]) < 0) {
      g_lTempLines += [sLine];
  }
  g_iCount = llGetListLength(g_lTempLines);
}

SetKBarOn() {
  llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
  g_iKBarOptions = 1;
}

SetKBarOff() {
  llMessageLinked(LINK_SET, MENUNAME_REMOVE , g_sParentMenu + "|" + g_sSubMenu, "");
  g_iKBarOptions = 0;
}

default
{
    state_entry() {
        g_kWearer = llGetOwner();
        g_sWearer = llKey2Name(g_kWearer);
        list lName = llParseString2List(g_sWearer, [" "], [""]);
        g_sWearer = llList2String(lName, 0) + llList2String(lName, 1);
        if (g_iGirlStatus == 0) ReadIndex(g_sWearer);
    }

    on_rez(integer iParam) {
        if (llGetOwner()!=g_kWearer) {
            // Reset if wearer changed
            llResetScript();
        }
        if (g_iProgramming) {
            setTimer();
        }
    }

    link_message(integer iSender, integer iNum, string sStr, key kID)
    {
        if (g_iKBarOptions) {
          if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
            llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
          else if (iNum >= CMD_OWNER && iNum <= CMD_WEARER)
            UserCommand( iNum, sStr, kID);
          else if (iNum == DIALOG_RESPONSE) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (iMenuIndex != -1) {
              list lMenuParams = llParseString2List(sStr, ["|"], []);
              key kAv = (key)llList2String(lMenuParams, 0);
              string sMessage = llList2String(lMenuParams, 1);
              integer iPage = (integer)llList2String(lMenuParams, 2);
              integer iAuth = (integer)llList2String(lMenuParams, 3);
              string sMenuType = llList2String(g_lMenuIDs, iMenuIndex + 1);
              //remove stride from g_lMenuIDs
              //we have to subtract from the index because the dialog id comes in the middle of the stride
              g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
              if (sMenuType == "ProgMenu") {
                if (sMessage == UPMENU)
                  llMessageLinked(LINK_SET, iAuth, "menu " + g_sParentMenu, kAv);
                else
                  UserCommand(iAuth, sMessage, kAv);
              } else if (sMenuType == "AddMenu") {
                  list lMenuParams = llParseString2List(sStr, ["|"], []);
                  key kAv = (key)llList2String(lMenuParams, 0);
                  string sMessage = llList2String(lMenuParams, 1);
                  integer iPage = (integer)llList2String(lMenuParams, 2);
                  integer iAuth = (integer)llList2String(lMenuParams, 3); // auth level of avatar
                  if ((sMessage != "") && (iAuth = CMD_OWNER)) {
                    if(llListFindList(g_lTempLines, [sMessage]) >= 0) {
                      llMessageLinked(LINK_SET,NOTIFY,"0"+"This phrase already exists",kAv);
                    } else {
                      g_lTempLines += [sMessage];
                      g_iCount = llGetListLength(g_lTempLines);
//                      SaveSettings();
//                      llMessageLinked(LINK_SET,NOTIFY,"0"+"Added",kAv);
                      DoMenu(kAv, iAuth);
                    } 
                  }
              } else if (sMenuType == "DelMenu") {
                  list lMenuParams = llParseString2List(sStr, ["|"], []);
                  key kAv = (key)llList2String(lMenuParams, 0);
                  string sMessage = llList2String(lMenuParams, 1);
                  integer iPage = (integer)llList2String(lMenuParams, 2);
                  integer iAuth = (integer)llList2String(lMenuParams, 3); // auth level of avatar
                  if(sMessage == UPMENU) {
                    DoMenu(kAv, iAuth);
                  } else {
                    if (llListFindList(g_lTempLines, [sMessage]) < 0) {
                      llMessageLinked(LINK_SET,NOTIFY,"0"+"Can't find " + sMessage + " to delete",kAv);
                    } else {
                      integer iIndex;
                      iIndex = llListFindList(g_lTempLines, [sMessage]);
                      g_lTempLines = llDeleteSubList(g_lTempLines, iIndex, iIndex);
                      g_iCount = llGetListLength(g_lTempLines);
//                      SaveSettings();
                      llMessageLinked(LINK_SET,NOTIFY,"0"+"Removed",kAv);
                    }
                    DoMenu(kAv, iAuth);
                  }
              }
            }
          }
        }
        if (iNum == DIALOG_TIMEOUT) {
          integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
          if (iMenuIndex != -1) {
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
          }
        }
        else if (iNum == LM_SETTING_RESPONSE) {
          //this is tricky since our db value contains equals signs
          //split string on both comma and equals sign
          //first see if this is the token we care about
          list lParams = llParseString2List(sStr, ["="], []);
          string sToken = llList2String(lParams, 0);
          string sValue = llList2String(lParams, 1);
//          string sTest1 = g_sProgToken+ "List";
//          string sTest2 = g_sProgToken+ "list";
//          llOwnerSay("kb_programmer link_message " + sToken + " " + sValue + " " + sTest1 + " " + sTest2);
          if (llToLower(sToken) == "kbprograms_list") {
            llMessageLinked(LINK_SET, LM_SETTING_DELETE, sToken, "");
          }
//          if ((sToken == sTest1) || (sToken == sTest2)) {
//            g_lSettings = llParseString2List(sValue, [","], []);
//            llOwnerSay("kb_programmer link_message g_lSettings 13 " + llDumpList2String(g_lSettings, "---"));
//            UpdateSettings();
//          }
          else if (llToLower(sToken) == llToLower(g_sProgToken+PROGRUN_SETTING)) {
            if (llToLower(sValue) == "y") g_iProgramming = TRUE; else g_iProgramming = FALSE;
          }
          else if (llToLower(sToken) == llToLower(g_sProgToken+PROGLOOP_SETTING)) {
            if (llToLower(sValue) == "y") g_iAutoLoop = TRUE; else g_iAutoLoop = FALSE;
          }
          else if (llToLower(sToken) == llToLower(g_sGlobalToken+"kbar")) {
            if ((g_iKBarOptions != 0) && (0 == (integer) sValue)) SetKBarOff();
            else if ((g_iKBarOptions != 1) && (1 == (integer) sValue)) SetKBarOn();
            else g_iKBarOptions = (integer) sValue;
          }
          else if (llToLower(sToken) == llToLower(g_sGlobalToken+"kbarstat")) g_iGirlStatus = (integer) sValue;
          else if (llToLower(sToken) == llToLower(g_sProgToken+"prog")) { AddLine(sValue); llMessageLinked(LINK_SET, LM_SETTING_DELETE, sToken, ""); }
//          else if (llToLower(sToken) == llToLower(g_sProgToken+"list")) AddLine(sValue);
        }

        else if (iNum == LINK_KB_VERS_REQ) {
          llMessageLinked(LINK_SET,LINK_KB_VERS_RESP,llGetScriptName()+"|"+KB_VERSION+KB_DEVSTAGE,"");
        }
    }
    timer()
    {
        unsetTimer();
        integer iIdx = g_iCount;
        while (iIdx > g_iCount-1) { iIdx = selectOne(0, g_iCount - 1); }
        string sTmpName = llGetObjectName();
        llSetObjectName("in the back of your mind a tiny voice says");
        llOwnerSay(llList2String(g_lTempLines, iIdx));
        llSetObjectName(sTmpName);

        if (!g_iAutoLoop) ++g_iAutoCount;

        if ((!g_iAutoLoop) && (g_iAutoCount > 30)) {
            g_iAutoCount = 0;
            g_iProgramming = FALSE; 
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sProgToken + PROGRUN_SETTING + "=n", "");
        } else {
            setTimer();
        }
    }    
    dataserver(key kQueryId, string sData) 
    {
      if (g_iGirlStatus == 0) {
        if (kQueryId == g_kQuery) 
        {
          if ((sData != EOF) && (sData != "")) {
            string sWork = llStringTrim(sData, STRING_TRIM);
            AddLine(sWork);
    
//          g_lTempLines += [sWork];
//          g_iCount = llGetListLength(g_lTempLines);
            g_iLine++;
            g_kQuery = llGetNotecardLine(g_sNoteCardName, g_iLine);
          }
        }
      }
    }

    changed(integer iChg) 
    {
      if (iChg & CHANGED_INVENTORY ) 
      {
  //            Debug2(STATE_NAME, LOC_NAME, "Change " + (string) iChg);
        llResetScript();
      }
    }
}

//K-Bar kb_programmer
