
//K-Bar Settings Host01

//TODO - high level control routine that cycles through the avatar requests
//	Convert "StartWork" into step one of two
//	More or less duplicate it for the sayings
//	Figure out g_kActiveKey timing issue
	
string  KB_VERSIONMAJOR      = "8";
string  KB_VERSIONMINOR      = "0";
string  KB_DEVSTAGE          = "1a906";
string  g_sScriptVersion = "";

string formatVersion() {
//	if (g_bDebugOn) llOwnerSay("formatVersion; " + KB_VERSIONMAJOR + "; " + KB_VERSIONMINOR + "; " + KB_DEVSTAGE + ";. " );
	return KB_VERSIONMAJOR + "." + KB_VERSIONMINOR + "." + KB_DEVSTAGE;
}

DebugOutput(list ITEMS) {
	++g_iDebugCounter;
	integer i=0;
	integer end=llGetListLength(ITEMS);
	string final;
	for(i=0;i<end;i++){
		final+=llList2String(ITEMS,i)+" ";
	}
//	llSay(KB_DEBUG_CHANNEL, llGetScriptName() + " " + formatVersion() + " " + (string) g_iDebugCounter + " " + final);
	llOwnerSay(llGetScriptName() + " " + formatVersion() + " " + (string) g_iDebugCounter + " " + final);
	if (g_iDebugCounter > 9999) SetDebugOff(); // safety check
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

key 	g_kOwner = NULL_KEY;
integer g_iListenHandle = 0;
integer KB_HAIL_CHANNEL = -317783;
integer KB_HAIL_CHANNEL01 = -317785;

string 	g_sSplitLine; // to parse lines that were split due to lsl constraints
integer g_iLineNr = 0;
key 	g_kSayingsID;
string 	g_sTargetName = "";
string	g_sTargetCard = "";
integer g_bBlock = FALSE;

string g_sDelimiter = "\\";
//list g_lSayings;

list g_lRequests;

key g_kActiveKey = NULL_KEY;

key g_kActiveOwner = NULL_KEY;
string  g_sMsgPackage = "";
list g_lMsgPackage = [];

string g_sPing = "";

LoadSaying(string sData, integer iLine) {
	string sID;
	string sToken;
	string sValue;
	integer i;
//	if (g_bDebugOn) DebugOutput(["LoadSaying entry sData ", sData, iLine]);
	if (iLine == 0 && g_sSplitLine != "" ) {
		sData = g_sSplitLine ;
		g_sSplitLine = "" ;
	}
	if (iLine) {
		// first we can filter out & skip blank lines & remarks
		sData = llStringTrim(sData, STRING_TRIM_HEAD);
//		if (g_bDebugOn) DebugOutput(["LoadSaying sData trimmed " + sData]);
		if (sData == "" || llGetSubString(sData, 0, 0) == "#") return;
		// check for "continued" line pieces
		if (llStringLength(g_sSplitLine)) {
			sData = g_sSplitLine + sData ;
			g_sSplitLine = "" ;
		}
		if (llGetSubString(sData,-1,-1) == g_sDelimiter) {
			g_sSplitLine = llDeleteSubString(sData,-1,-1) ;
			return;
		}
		if (sData) g_lMsgPackage += [sData];
	}
//	if (g_bDebugOn) DebugOutput(["LoadSaying exit sData ", sData, iLine]);
}

/*
integer GroupIndex(list lCache, string sToken) {
	string sGroup = SplitToken(sToken, 0);
	integer i = llGetListLength(lCache) - 1;
	// start from the end to find last instance, +2 to get behind the value
	for (; ~i ; i -= 2) {
		if (SplitToken(llList2String(lCache, i - 1), 0) == sGroup) return i + 1;
	}
	return -1;
}
*/
string SplitToken(string sIn, integer iSlot) {
	integer i = llSubStringIndex(sIn, "_");
	if (!iSlot) return llGetSubString(sIn, 0, i - 1);
	return llGetSubString(sIn, i + 1, -1);
}

/*
string SuffixTrans(integer iIn) {
	if (iIn == 0) return "00";
	if (iIn == 1) return "01";
	if (iIn == 2) return "02";
	if (iIn == 3) return "03";
	return "99";
}
*/
//
//	Get the collar owner's name, smush it to all lowercase, eliminate spaces, append "00" for basic settings
//
CardBaseName() {
	g_sTargetName = llToLower(llKey2Name(g_kActiveOwner));
	list lName = llParseString2List(g_sTargetName, [" "], [""]);
	string sTargetName = llStringTrim(llList2String(lName, 0), STRING_TRIM) + llStringTrim(llList2String(lName, 1), STRING_TRIM);
	g_sTargetCard = sTargetName + "01";	
	if (g_bDebugOn) DebugOutput(["CardBaseName", g_sTargetCard, g_kActiveKey]);
}

StartRun() {
	CardBaseName();
	g_sMsgPackage = "";
	g_lMsgPackage = [];
	if (g_bDebugOn) DebugOutput(["StartRun - a", llGetListLength(g_lRequests), g_kActiveKey, g_sTargetName, g_sTargetCard]);
	if (g_bDebugOn) DebugOutput(["StartRun - b", g_kActiveKey, g_sTargetName, g_kActiveKey]);
	if (g_sTargetCard != "") {
		key kKey = llGetInventoryKey(g_sTargetCard);
		if (g_bDebugOn) DebugOutput(["StartRun - c", kKey]);
		if (kKey != NULL_KEY) {
			if (g_bDebugOn) DebugOutput(["StartRun - d", g_kActiveKey, g_sTargetCard, g_kActiveKey]);
			g_iLineNr = 0;
			g_kSayingsID = llGetNotecardLine(g_sTargetCard, g_iLineNr);
//			return;
		} else {
			llRegionSayTo(g_kActiveKey, KB_HAIL_CHANNEL01, "Notify=No 01 Card");
			if (g_bDebugOn) DebugOutput(["StartRun - e", g_kActiveKey, KB_HAIL_CHANNEL01, "Notify=No 01 Card"]);
			DeleteKey(g_kActiveKey);
			g_kActiveKey = NULL_KEY;
			EndRun();
		}
	} else {
		llRegionSayTo(g_kActiveKey, KB_HAIL_CHANNEL01, "Notify=No 01 Card");
		if (g_bDebugOn) DebugOutput(["StartRun - f", g_kActiveKey, KB_HAIL_CHANNEL01, "Notify=No 01 Card"]);
		DeleteKey(g_kActiveKey);
		g_kActiveKey = NULL_KEY;
		EndRun();
	}
}

EndRun() {
	g_iLineNr = 0;
//	++g_iProcessingPhase;
	if (g_bDebugOn) DebugOutput(["EndRun - a", llGetListLength(g_lRequests), g_kActiveKey, g_sTargetName, g_sTargetCard]);
	StartWork();
}

//
//	StartWork
//
//		Identify collar's owner
//		Clear and initialize work areas
//		Process collar owner name to locate appropriate settings card
//		If there is one, start the read process and exit
//		If there isn't, clear out the work areas, abandon that collar key, and try again
//
StartWork() {
	if (g_bDebugOn) DebugOutput(["StartWork - a", llGetListLength(g_lRequests), g_kActiveKey, g_sTargetName]);
	if (llGetListLength(g_lRequests) > 0) {
		g_kActiveKey = llList2Key(g_lRequests, 0);
		g_kActiveOwner = llGetOwnerKey(g_kActiveKey);
		if (g_bDebugOn) DebugOutput(["StartWork - b", llGetListLength(g_lRequests), g_kActiveKey, g_sTargetName]);
		StartRun();
	}
}

DeleteKey(key kTarget) {
//	g_iProcessingPhase = 0;
	g_bBlock = FALSE;
	integer iDx = llListFindList(g_lRequests, [kTarget]);
	if (g_bDebugOn) DebugOutput(["DeleteKey-1", llGetListLength(g_lRequests), kTarget, iDx]);
	if (iDx < 0) return;
	if (g_bDebugOn) { list lTmp = ["DeleteKey-2"] + g_lRequests; DebugOutput(lTmp); }
	g_lRequests = llDeleteSubList(g_lRequests, iDx, iDx);	
	if (g_bDebugOn) { list lTmp = ["DeleteKey-3"] + g_lRequests; DebugOutput(lTmp); }
}

SendSayings() {
//	if (g_bDebugOn) DebugOutput(["SendSayings Start", llGetListLength(g_lRequests), g_kActiveKey]);
//	if (g_bDebugOn) DebugOutput(g_lMsgPackage);
	integer iLineCount = 1;
	integer iDx = 0;
	integer iLimit = llGetListLength(g_lMsgPackage);
	if (g_sPing == "ping801") {
		if (iLimit == 0) {
			g_sMsgPackage = "kbnosayings";
			if (g_bDebugOn) DebugOutput(["SendSayings-1 sending", g_kActiveKey, KB_HAIL_CHANNEL01, g_sMsgPackage]);
			llRegionSayTo(g_kActiveKey, KB_HAIL_CHANNEL01, g_sMsgPackage);
			return;
		}
	}
//	if (g_iProcessingPhase == 0)
	string sEndFlag = "kbhostaction=done";
	g_sMsgPackage = "kbhostline=" + (string) iLineCount;
	for (iDx = 0; iDx < iLimit; ++iDx) {
		string sWork = llList2String(g_lMsgPackage, iDx);
		integer iCalcLength = llStringLength(g_sMsgPackage) + llStringLength("%%") + llStringLength(sWork);
		iCalcLength += llStringLength("%%");
		iCalcLength += llStringLength(sEndFlag);
		if (iCalcLength < 768) {
			g_sMsgPackage += "%%";
			g_sMsgPackage += sWork;
		} else {
			if (g_bDebugOn) DebugOutput(["SendSayings-2 sending", g_kActiveKey, KB_HAIL_CHANNEL01, g_sMsgPackage]);
			llRegionSayTo(g_kActiveKey, KB_HAIL_CHANNEL01, g_sMsgPackage);
			g_sMsgPackage = "kbhostline=" + (string) iLineCount;
			++iLineCount;
			g_sMsgPackage = sWork;
		}
	}
	g_sMsgPackage += "%%";
	g_sMsgPackage += sEndFlag;
	if (g_bDebugOn) DebugOutput(["SendSayings-3 sending", g_kActiveKey, KB_HAIL_CHANNEL01, g_sMsgPackage]);
	llRegionSayTo(g_kActiveKey, KB_HAIL_CHANNEL01, g_sMsgPackage);

	DeleteKey(g_kActiveKey);
	g_kActiveKey = NULL_KEY;
	g_sMsgPackage = "";
	g_lMsgPackage = [];
	if (g_bDebugOn) DebugOutput(["SendSayings Exit", llGetListLength(g_lRequests), g_kActiveKey]);
	if (g_bDebugOn) DebugOutput(g_lMsgPackage);
}
/*
SendSayings() {
	//	if (g_bDebugOn) DebugOutput(["SendSayings Start", llGetListLength(g_lRequests), g_kActiveKey]);
	//	if (g_bDebugOn) DebugOutput(g_lMsgPackage);
		integer iLineCount = 1;
		integer iDx = 0;
		integer iLimit = llGetListLength(g_lMsgPackage);
		if (g_sPing == "ping801") {
			if (iLimit == 0) {
				g_sMsgPackage = "kbnosayings";
				if (g_bDebugOn) DebugOutput(["SendSayings sending", g_kActiveKey, KB_HAIL_CHANNEL, g_sMsgPackage]);
				llRegionSayTo(g_kActiveKey, KB_HAIL_CHANNEL, g_sMsgPackage);
				return;
			}
		}
	//	if (g_iProcessingPhase == 0)
		string sEndFlag = "kbsayings1action=done";
		g_sMsgPackage = "kbsayings1line=" + (string) iLineCount;
		for (iDx = 0; iDx < iLimit; ++iDx) {
			string sWork = llList2String(g_lMsgPackage, iDx);
			integer iCalcLength = llStringLength(g_sMsgPackage) + llStringLength("%%") + llStringLength(sWork);
//			iCalcLength += llStringLength("%%");
//			iCalcLength += llStringLength(sEndFlag);
			if (iCalcLength < 1024) {
				g_sMsgPackage += "%%";
				g_sMsgPackage += sWork;
			} else {
				if (g_bDebugOn) DebugOutput(["SendSayings sending", g_kActiveKey, KB_HAIL_CHANNEL, g_sMsgPackage]);
				llRegionSayTo(g_kActiveKey, KB_HAIL_CHANNEL, g_sMsgPackage);
				g_sMsgPackage = "kbsayings1line=" + (string) iLineCount;
				++iLineCount;
				g_sMsgPackage += sWork;
			}
		}
//		g_sMsgPackage += "%%";
//		g_sMsgPackage += sEndFlag;
		if (llStringLength(g_sMsgPackage) > 0) {
			if (g_bDebugOn) DebugOutput(["SendSayings sending", g_kActiveKey, KB_HAIL_CHANNEL, g_sMsgPackage]);
			llRegionSayTo(g_kActiveKey, KB_HAIL_CHANNEL, g_sMsgPackage);
		}

	//	DeleteKey(g_kActiveKey);
	//	g_kActiveKey = NULL_KEY;
		g_sMsgPackage = "";
		g_lMsgPackage = [];
		if (g_bDebugOn) DebugOutput(["SendSayings Exit", llGetListLength(g_lRequests), g_kActiveKey]);
		if (g_bDebugOn) DebugOutput(g_lMsgPackage);
		llRegionSayTo(g_kActiveKey, KB_HAIL_CHANNEL, sEndFlag);
}
*/
InitListen() {
	if (g_bDebugOn) DebugOutput(["InitListen Entry", g_iListenHandle]);
	if (g_iListenHandle != 0) { 
		llListenRemove(g_iListenHandle); 
		g_iListenHandle = 0; 
		g_iListenHandle = llListen(KB_HAIL_CHANNEL01, "", "", ""); 
	} else g_iListenHandle = llListen(KB_HAIL_CHANNEL01, "", "", "");
	if (g_bDebugOn) DebugOutput(["InitListen Exit", g_iListenHandle]);
}

default {
	state_entry() {
		llOwnerSay(llGetScriptName() + " " + formatVersion() + " starting, debug = " + (string) g_bDebugOn);
		if (g_bDebugOn) DebugOutput(["state_entry"]);
		g_lRequests = [];
		g_kActiveKey = NULL_KEY;
		InitListen();
//		g_sVersion = g_sScriptVersion;
//		g_sVersion += g_sDevStage;
// if (g_kWearer == NULL_KEY) {
// g_kWearer = llGetOwner();
// g_sWearer = (string) g_kWearer;
// g_sTargetName = llToLower(llKey2Name(g_kWearer));
// list lName = llParseString2List(g_sTargetName, [" "], [""]);
// g_sTargetName = llList2String(lName, 0) + llList2String(lName, 1);
// } else {
// if (g_kWearer != llGetOwner()) llResetScript();
// }
		g_kOwner = llGetOwner();
		if (g_bDebugOn) DebugOutput(["state_entry", g_kOwner, g_iListenHandle]);
	}

	on_rez(integer iParam) {
		if (g_bDebugOn) DebugOutput(["on_rez"]);
		if (g_kOwner != llGetOwner()) llResetScript();
		InitListen();
	}

//	link_message(integer iSender, integer iNum, string sStr, key kID) {
//	}
	
//
//	Listen for a ping from the collar
//
//		The key will be the collar's UID
//		Add it to the request list for processing in due time
//	
	listen(integer iChannel, string sName, key kId, string sMessage) {
		if (g_bDebugOn) DebugOutput(["listen-1", iChannel, sName, kId, sMessage]);
		if (sMessage == "ping801") { // ignore requests not meant for us
			g_sPing = sMessage;
			string sNotify = sMessage + " " + (string) llGetOwnerKey(kId) + " " + llKey2Name(llGetOwnerKey(kId));
			llOwnerSay(sNotify);
			g_lRequests += [kId];
			if (g_bDebugOn) DebugOutput(["listen-2", llGetListLength(g_lRequests), g_kActiveKey, kId, iChannel, llList2Key(g_lRequests, 1)]);
			StartWork();
		}
//		if (g_kActiveKey == NULL_KEY)
//			StartWork(llList2Key(g_lRequests, 0)); 
	}

	dataserver(key kID, string sData) {
		if (g_bDebugOn) DebugOutput(["dataserver-1", sData]);
		if (kID == g_kSayingsID) {
			if (sData != EOF) {
				LoadSaying(sData,++g_iLineNr);
				if (g_bDebugOn) DebugOutput(["dataserver-2", sData, g_iLineNr]);
//				else LoadSaying(sData,++g_iLineNr);
				g_kSayingsID = llGetNotecardLine(g_sTargetCard, g_iLineNr);
			} else {
				if (g_bDebugOn) DebugOutput(["dataserver-3", g_iLineNr]);
				LoadSaying(sData,g_iLineNr);
				SendSayings();
				EndRun();
//				else LoadSaying(sData,g_iLineNr);
//				llSetTimerEvent(1.0);
//				if (g_iProcessingPhase == 1) SendSayings();
//				else (SendSayings());
			}
		}
	}

	changed(integer iChange) {
		if (iChange & (CHANGED_OWNER || CHANGED_INVENTORY)) llResetScript();
	}
}

// kb_settings_host01
