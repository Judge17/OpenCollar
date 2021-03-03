
//K-Bar programmer

string  KB_VERSIONMAJOR      = "8";
string  KB_VERSIONMINOR      = "0";
string  KB_DEVSTAGE          = "030001";
// LEGEND: Major.Minor.ijklmm i=Build j=RC k=Beta l=Alpha mm=KBar Version
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
	g_bDebugOn = FALSE;
	g_iDebugLevel = 10;
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

key KURT_KEY   = "4986014c-2eaa-4c39-a423-04e1819b0fbf";
key SILKIE_KEY = "1a828b4e-6345-4bb3-8d41-f93e6621ba25";

string g_sModule = "programmer";

integer g_iCount = 28;
list            g_lSayings = [];    // The resulting data pushed into a list
integer         g_iLine;              // The line count for the card reader
key             g_kQuery;             // The key of the card being read
string          g_sNoteCardName = "kbprograms"; // The name of the card being read

string g_sSubMenu = "Programs";      // Name of the submenu
string g_sParentMenu = "Apps";       // name of the menu, where the menu plugs in
string g_sChatCommand = ".kbprogram"; // every menu should have a chat command

integer LINK_KB_VERS_REQ 	= -75301;
integer LINK_KB_VERS_RESP 	= -75302;
integer KB_READY_SAYINGS	= -34848;
integer KB_SEND_SAYINGS		= -34849;
integer KB_SET_SAYING		= -34850;
integer KB_COLLAR_VERSION	= -34847;
integer KB_REQUEST_VERSION  = -34591;

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

integer REBOOT              = -1000;

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

integer LINK_SAYING1        = -75336;

string UPMENU               = "BACK";
string g_sGlobalToken       = "global";
string g_sProgToken         = "kbwhisper";

list g_lIndex = [];
integer g_iIndex = 0;
integer g_iIndCount = 0;
string g_sIndName = "";
integer bool(integer a){
		if(a)return TRUE;
		else return FALSE;
}

list g_lCheckboxes=["⬜","⬛"];

string Checkbox(integer iValue, string sLabel) {
		return llList2String(g_lCheckboxes, bool(iValue))+" "+sLabel;
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
		string sPrompt ="\n" + llGetScriptName() + " version " + formatVersion();
		
		list lButtons = g_lLocalbuttons + g_lButtons + [ADDSAYING, DELSAYING, LISTSAYINGS];

		s1 = "\nCurrent delay " + (string) g_iMsgDelay + " seconds; iteration " + (string) g_iAutoCount + "\n";

		if (g_iProgramming) {
				s2 = "Whispers enabled "; 
				lButtons += [Checkbox(TRUE, "Active")];
		} else {
				s2 = "Whispers disabled ";
				lButtons += [Checkbox(FALSE, "Active")];
				
		}
		if (g_iAutoLoop) {   
				s2 += "endless loop\n";
		lButtons += [Checkbox(TRUE, "Endless")];
//        lButtons += [PROGRAM_TIMER];
		} else {
				s2 += "on timer\n";
//        lButtons += [PROGRAM_CONSTANT];
		lButtons += [Checkbox(FALSE, "Endless")];
		}
		s4 = llGetScriptName() + " " + (string) llGetFreeMemory() + " bytes free\n";
		s5 = (string) g_iCount + " sayings ready\n";

		sPrompt += "\n" + s1 + s2 + s4 +s5 + "Pick an option.\n";
		if (keyID == NULL_KEY) { return; }
		
		lButtons = llListSort(lButtons, 1, TRUE); // resort menu buttons alphabetical
		// and display the menu
		Dialog(keyID, sPrompt, lButtons, [UPMENU], 0, iAuth, "ProgMenu");
}

SetDebugLevel(string sLevel) {
	integer iNew = (integer) sLevel;
	g_iDebugLevel = iNew;
	if (g_iDebugLevel > 9) g_bDebugOn = FALSE;
	else g_bDebugOn = TRUE;
	if (g_bDebugOn) {DebugOutput(0, ["Debug Level", g_iDebugLevel, "Debug Status", g_bDebugOn]); }
}

setTimer() {
		llSetTimerEvent(0.0);
		g_iMsgDelay = randIntBetween(1, 600) + 1;
		llSetTimerEvent((float) g_iMsgDelay);
		if (g_bDebugOn) {DebugOutput(0, ["Timer delay", g_iMsgDelay]); }
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
		integer length = llGetListLength(g_lSayings);
		for(i = 0; i < length; i++)  {
				llRegionSayTo(kID, 0, (string) i + "-" + llList2String(g_lSayings, i));
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
		if (g_bDebugOn) DebugOutput(3, ["UserCommand", iNum, sStr, kID, sCommand, sButton, sValue, Checkbox(TRUE, "Active"), sMenuName]);    
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
		else if (sStr == Checkbox(FALSE, "Active")) { // I get it, seems backards, but there you are; it does work
			if (iNum == CMD_OWNER) {
				g_iProgramming = TRUE; 
				llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sProgToken + "_" + PROGRUN_SETTING + "=y", "");
				setTimer();
				llMessageLinked(LINK_SET,NOTIFY,"0"+"Programming active",kID);
			} else {
				llMessageLinked(LINK_SET,NOTIFY,"0%NOACCESS%"+" to change programming",kID);
			}
			DoMenu(kID, iNum);
		}
		else if (sStr == Checkbox(TRUE, "Active")) { // I get it, seems backards, but there you are; it does work
			if (iNum == CMD_OWNER) {
				g_iProgramming = FALSE; 
				llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sProgToken + "_" + PROGRUN_SETTING + "=n", "");
				unsetTimer();
				llMessageLinked(LINK_SET,NOTIFY,"0"+"Programming inactive",kID);
			} else {
				llMessageLinked(LINK_SET,NOTIFY,"0%NOACCESS%"+" to change programming",kID);
			}
			DoMenu(kID, iNum);
		} 
		else if ((sButton == PROGRAM_CONSTANT) || (sStr == Checkbox(FALSE, "Endless"))) { // I get it, seems backards, but there you are; it does work
			if (iNum == CMD_OWNER) {
				g_iAutoLoop = TRUE; 
				g_iAutoCount = 0;
				llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sProgToken + "_" + PROGLOOP_SETTING + "=y", "");
				llMessageLinked(LINK_SET,NOTIFY,"0"+"No time limit",kID);
			} else {
				llMessageLinked(LINK_SET,NOTIFY,"0%NOACCESS%"+" to change timer",kID);
			}
			DoMenu(kID, iNum);
		} 
		else if ((sButton == PROGRAM_TIMER) || (sStr == Checkbox(TRUE, "Endless"))) { // I get it, seems backards, but there you are; it does work
			if (iNum == CMD_OWNER) {
				g_iAutoLoop = FALSE; 
				g_iAutoCount = 0;
				llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sProgToken + "_" + PROGLOOP_SETTING + "=n", "");
				llMessageLinked(LINK_SET,NOTIFY,"0"+"Auto off enabled",kID);
			} else {
				llMessageLinked(LINK_SET,NOTIFY,"0%NOACCESS%"+" to change timer",kID);
			}
			DoMenu(kID, iNum);
		} 
		else if (sButton == ADDSAYING) { 
			if (iNum == CMD_OWNER) {
				Dialog(kID, g_sAddPhrasePrompt, [], [], 0, iNum, "AddMenu");
			} else {
				llMessageLinked(LINK_SET,NOTIFY,"0%NOACCESS%"+" to change sayings",kID);
			}
			DoMenu(kID, iNum);
		}
		else if (sButton == DELSAYING) { 
			if (iNum == CMD_OWNER) {
				Dialog(kID, "Select a saying to be removed...", g_lSayings, [UPMENU], 0, iNum, "DelMenu");
			} else {
				llMessageLinked(LINK_SET,NOTIFY,"0%NOACCESS%"+" to change sayings",kID);
			}
			DoMenu(kID, iNum);
		} 
		else if (sButton == LISTSAYINGS) { 
			if (iNum == CMD_OWNER) {
				printPhrases(kID);
			} else {
				llMessageLinked(LINK_SET,NOTIFY,"0%NOACCESS%"+" to list sayings",kID);
			}
			DoMenu(kID, iNum);
		} 
}

HandleMenus(string sStr, key kID) {
	integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
	if (~iMenuIndex) {
		list lMenuParams = llParseString2List(sStr, ["|"], []);
		key kAv = (key)llList2String(lMenuParams, 0);
		string sMessage = llList2String(lMenuParams, 1);
		integer iPage = (integer)llList2String(lMenuParams, 2);
		integer iAuth = (integer)llList2String(lMenuParams, 3);
		string sMenu=llList2String(g_lMenuIDs, iMenuIndex + 1);
		g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
		if (sMenu == "ProgMenu") {
			if (sMessage == UPMENU)
				llMessageLinked(LINK_SET, iAuth, "menu " + g_sParentMenu, kAv);
			else
				UserCommand(iAuth, sMessage, kAv);
			} else if (sMenu == "AddMenu") {
				if ((sMessage != "") && (iAuth = CMD_OWNER)) {
					if(llListFindList(g_lSayings, [sMessage]) >= 0) {
						llMessageLinked(LINK_SET,NOTIFY,"0"+"This phrase already exists",kAv);
					} else {
						g_lSayings += [sMessage];
						g_iCount = llGetListLength(g_lSayings);
						DoMenu(kAv, iAuth);
					} 
				}
			} else if (sMenu == "DelMenu") {
				if(sMessage == UPMENU) {
					DoMenu(kAv, iAuth);
				} else {
					if (llListFindList(g_lSayings, [sMessage]) < 0) {
						llMessageLinked(LINK_SET,NOTIFY,"0"+"Can't find " + sMessage + " to delete",kAv);
					} else {
						integer iIndex;
						iIndex = llListFindList(g_lSayings, [sMessage]);
						g_lSayings = llDeleteSubList(g_lSayings, iIndex, iIndex);
						g_iCount = llGetListLength(g_lSayings);
						llMessageLinked(LINK_SET,NOTIFY,"0"+"Removed",kAv);
					}
					DoMenu(kAv, iAuth);
				}
			} else if (sMenu == "debug") {
				if (sMessage == UPMENU) {
					llMessageLinked(LINK_SET, iAuth, "menu " + g_sParentMenu, kAv);
				} else {
					SetDebugLevel(sMessage);
					DoMenu(kAv, iAuth);
				}
			}
	}
}

HandleSettings(string sStr) {
	if (g_bDebugOn) DebugOutput(3, ["HandleSettings", sStr]);
	list lParams = llParseString2List(sStr, ["="], []); // now [0] = "major_minor" and [1] = "value"
	string sToken = llList2String(lParams, 0); // now SToken = "major_minor"
	string sValue = llList2String(lParams, 1); // now sValue = "value"
	integer i = llSubStringIndex(sToken, "_");
	string sTokenMajor = llToLower(llGetSubString(sToken, 0, i - 1));
	string sTokenMinor = llToLower(llGetSubString(sToken, i + 1, -1));
	if (g_bDebugOn) DebugOutput(3, ["HandleSettings", sTokenMajor, sTokenMinor, sValue]);
	if (sTokenMajor == g_sProgToken) {
		if (sTokenMinor == PROGRUN_SETTING) {
			if (llToLower(sValue) == "y") { g_iProgramming = TRUE; setTimer(); } else g_iProgramming = FALSE;
		} else if (sTokenMinor == PROGLOOP_SETTING) {
			if (llToLower(sValue) == "y") g_iAutoLoop = TRUE; else g_iAutoLoop = FALSE;
		}
	} else if (sTokenMajor == g_sGlobalToken) {
			if (sTokenMinor == "checkboxes") {
			g_lCheckboxes = llCSV2List(sValue);
		}
	}
}

HandleDeletes(string sStr) {
	list lParams = llParseString2List(sStr, ["="], []); // now [0] = "major_minor" and [1] = "value"
	string sToken = llList2String(lParams, 0); // now SToken = "major_minor"
	string sValue = llList2String(lParams, 1); // now sValue = "value"
	integer i = llSubStringIndex(sToken, "_");
	string sTokenMajor = llToLower(llGetSubString(sToken, 0, i - 1));
	string sTokenMinor = llToLower(llGetSubString(sToken, i + 1, -1));
	if (sTokenMajor == g_sProgToken) {
		if (sTokenMinor == PROGRUN_SETTING) {
			g_iProgramming = FALSE;
		} else if (sTokenMinor == PROGLOOP_SETTING) {
			g_iAutoLoop = FALSE;
		}
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
		g_lSayings = ["No sayings set"];
		g_iCount = llGetListLength(g_lSayings);
		g_lIndex = [];
		g_iIndex = 0;
		g_iLine = 0;
		g_kQuery = llGetNotecardLine(g_sNoteCardName, g_iLine);  
	}
}

AddLine(string sLine) {
	integer iCount = llGetListLength(g_lSayings);
	if (iCount == 0) {
		g_lSayings = [sLine];
		g_iCount = 1;
	} else if (iCount == 1) {
		if (llList2String(g_lSayings, 0) == "No sayings set") {
			g_lSayings = [sLine];
		} else if (llList2String(g_lSayings, 0) != sLine) {
				g_lSayings += [sLine];
		}
	} else if (llListFindList(g_lSayings, [sLine]) < 0) {
		g_lSayings += [sLine];
	}
	g_iCount = llGetListLength(g_lSayings);
	if (g_bDebugOn) { DebugOutput(0, ["AddLine", sLine, iCount]); }
}

InternalLoad(string sMessage) {
	list lTemp = llParseString2List(sMessage, ["%%"], [""]);
	if (g_bDebugOn) { list lX = ["InternalLoad"] + lTemp; DebugOutput(0, lX); }
	integer iHostIdx = 0;
	integer iHostLen = llGetListLength(lTemp);
	while (iHostIdx < iHostLen) {
		AddLine(llStringTrim(llList2String(lTemp, iHostIdx), STRING_TRIM));
		++iHostIdx;
	}
}

//SetKBarOn() {
//  llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
//  g_iKBarOptions = 1;
//}

//SetKBarOff() {
//  llMessageLinked(LINK_SET, MENUNAME_REMOVE , g_sParentMenu + "|" + g_sSubMenu, "");
//  g_iKBarOptions = 0;
//}
integer ALIVE = -55;
integer READY = -56;
integer STARTUP = -57;

default {
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

	state_exit()
	{
		// if (g_bDebugOn) DebugOutput(5, ["default", "state_exit", llGetFreeMemory(), "bytes free"]);
	}
}

state active {

	state_entry() {
		g_kWearer = llGetOwner();
		g_sWearer = llKey2Name(g_kWearer);
		list lName = llParseString2List(g_sWearer, [" "], [""]);
		g_sWearer = llList2String(lName, 0) + llList2String(lName, 1);
		ReadIndex(g_sWearer);
	}

	on_rez(integer iParam) {
		llResetScript();
	}

	link_message(integer iSender, integer iNum, string sStr, key kID) {
		if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
			llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
		else if (iNum >= CMD_OWNER && iNum <= CMD_WEARER)
			UserCommand( iNum, sStr, kID);
		else if (iNum == DIALOG_RESPONSE)
			HandleMenus(sStr, kID);
		else if (iNum == LINK_SAYING1) {
			if (g_bDebugOn) DebugOutput(0, ["LINK_SAYING1", sStr]);
		InternalLoad(sStr);
		} else if (iNum == DIALOG_TIMEOUT) {
			integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
			if (iMenuIndex != -1) {
				g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
			}
		} else if (iNum == LM_SETTING_RESPONSE) HandleSettings(sStr);
		else if (iNum == LM_SETTING_DELETE) HandleDeletes(sStr);
		else if (iNum == KB_READY_SAYINGS) {
			g_lSayings = [];
			llMessageLinked(LINK_SET, KB_SEND_SAYINGS, "", "");
		} else if (iNum == KB_SET_SAYING) AddLine(sStr);
		else if (iNum == KB_COLLAR_VERSION) g_sCollarVersion = sStr;
		else if (iNum == KB_REQUEST_VERSION)
			llMessageLinked(LINK_SET,NOTIFY,"0"+llGetScriptName() + " version " + formatVersion(),kID);
	}
		
	timer() {
		if (g_bDebugOn) {DebugOutput(0, ["Timer fired"]); }
		unsetTimer();
		integer iIdx = g_iCount;
		while (iIdx > g_iCount-1) { iIdx = selectOne(0, g_iCount - 1); }
		string sTmpName = llGetObjectName();
		llSetObjectName("in the back of your mind a tiny voice says");
		llOwnerSay(llList2String(g_lSayings, iIdx));
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
		
	dataserver(key kQueryId, string sData) {
		if (kQueryId == g_kQuery) 
		{
			if ((sData != EOF) && (sData != "")) {
				string sWork = llStringTrim(sData, STRING_TRIM);
				AddLine(sWork);
				g_iLine++;
				g_kQuery = llGetNotecardLine(g_sNoteCardName, g_iLine);
			}
		}
	}

	changed(integer iChg) {
		if (iChg & CHANGED_INVENTORY ) 
		{
			llResetScript();
		}
	}
}

//K-Bar kb_programmer
