
//K-Bar Version 2020 0722 1330

//TODO - high level control routine that cycles through the avatar requests
//	Convert "StartWork" into step one of two
//	More or less duplicate it for the sayings
//	Figure out g_kActiveKey timing issue

string g_sDevStage = "a";
string 	g_sScriptVersion = "7.5";
key 	g_kOwner = NULL_KEY;
integer 	g_iListenHandle = 0;
integer 	KB_HAIL_CHANNEL = -317783;
string 	g_sCard = ".settings";
string 	g_sSplitLine; // to parse lines that were split due to lsl constraints
integer 	g_iLineNr = 0;
key 	g_kSettingsID;
key		g_kSayings1ID;
string 	g_sTargetName = "";
string	g_sTargetCard = "";
integer 	g_bDebugOn = TRUE;
integer	g_iProcessingPhase = 0;
integer g_bBlock = FALSE;

string g_sVersion = "";
string g_sDelimiter = "\\";
list g_lExceptionTokens = ["texture","glow","shininess","color","intern"];
list g_lSettings;
list g_lRequests;
key g_kActiveKey = NULL_KEY;
key g_kActiveOwner = NULL_KEY;
string  g_sMsgPackage = "";
list g_lMsgPackage = [];

DebugOutput(list ITEMS){
	++g_iDebugCounter;
	integer i=0;
	integer end=llGetListLength(ITEMS);
	string final;
	for(i=0;i<end;i++){
		final+=llList2String(ITEMS,i)+" ";
	}
//	llSay(KB_DEBUG_CHANNEL, llGetScriptName() + " " + (string) g_iDebugCounter + " " + final);
	llOwnerSay(llGetScriptName() + " " + (string) g_iDebugCounter + " " + final);
}
integer g_iDebugCounter = 0;

LoadSaying(string sData, integer iLine) {
	
}

LoadSetting(string sData, integer iLine) {
	string sID;
	string sToken;
	string sValue;
	integer i;
//	if (g_bDebugOn) DebugOutput(["LoadSetting entry sData ", sData, iLine]);
	if (iLine == 0 && g_sSplitLine != "" ) {
		sData = g_sSplitLine ;
		g_sSplitLine = "" ;
	}
	if (iLine) {
		// first we can filter out & skip blank lines & remarks
		sData = llStringTrim(sData, STRING_TRIM_HEAD);
//		if (g_bDebugOn) DebugOutput(["LoadSetting sData trimmed " + sData]);
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
		i = llSubStringIndex(sData, "=");
		sID = llGetSubString(sData, 0, i - 1);
		sData = llGetSubString(sData, i + 1, -1);
		if (~llSubStringIndex(llToLower(sID), "_")) return;
		else if (~llListFindList(g_lExceptionTokens,[sID])) return;
		sID = llToLower(sID)+"_";
		list lData = llParseString2List(sData, ["~"], []);
		for (i = 0; i < llGetListLength(lData); i += 2) {
			sToken = llList2String(lData, i);
			sValue = llList2String(lData, i + 1);
			if (sValue) g_lSettings = SetSetting(g_lSettings, sID + sToken, sValue);
		}
	}
//	if (g_bDebugOn) DebugOutput(["LoadSetting exit sData ", sData, iLine]);
}

list SetSetting(list lCache, string sToken, string sValue) {
	 g_lMsgPackage += [sToken, sValue];
//	if (g_bDebugOn) DebugOutput(["SetSetting", sToken, sValue]);
//	if (g_bDebugOn) DebugOutput(g_lMsgPackage);
	integer idx = llListFindList(lCache, [sToken]);
	if (~idx) return llListReplaceList(lCache, [sValue], idx + 1, idx + 1);
	idx = GroupIndex(lCache, sToken);
	if (~idx) return llListInsertList(lCache, [sToken, sValue], idx);
	return lCache + [sToken, sValue];
}

integer GroupIndex(list lCache, string sToken) {
	string sGroup = SplitToken(sToken, 0);
	integer i = llGetListLength(lCache) - 1;
	// start from the end to find last instance, +2 to get behind the value
	for (; ~i ; i -= 2) {
		if (SplitToken(llList2String(lCache, i - 1), 0) == sGroup) return i + 1;
	}
	return -1;
}

string SplitToken(string sIn, integer iSlot) {
	integer i = llSubStringIndex(sIn, "_");
	if (!iSlot) return llGetSubString(sIn, 0, i - 1);
	return llGetSubString(sIn, i + 1, -1);
}

string SuffixTrans(integer iIn) {
	if (iIn == 0) return "00";
	if (iIn == 1) return "01";
	if (iIn == 2) return "02";
	if (iIn == 3) return "03";
	return "99";
}

CardBaseName() {
	g_sTargetName = llToLower(llKey2Name(g_kActiveOwner));
	list lName = llParseString2List(g_sTargetName, [" "], [""]);
	string sTargetName = llStringTrim(llList2String(lName, 0), STRING_TRIM) + llStringTrim(llList2String(lName, 1), STRING_TRIM);
	g_sTargetCard = sTargetName + SuffixTrans(g_iProcessingPhase);	
	if (g_bDebugOn) DebugOutput(["CardBaseName", g_sTargetCard, g_kActiveKey]);
}

StartRun() {
	CardBaseName();
	g_sMsgPackage = "";
	g_lMsgPackage = [];
	if (g_bDebugOn) DebugOutput(["StartRun - a", g_iProcessingPhase, llGetListLength(g_lRequests), g_kActiveKey, g_sTargetName, g_sTargetCard]);
	if (g_bDebugOn) DebugOutput(["StartRun - b", g_kActiveKey, g_sTargetName, g_kActiveKey]);
	if (g_sTargetCard != "") {
		key kKey = llGetInventoryKey(g_sTargetCard);
		if (g_bDebugOn) DebugOutput(["StartRun - c", kKey]);
		if (kKey != NULL_KEY) {
			if (g_bDebugOn) DebugOutput(["StartRun - d", g_kActiveKey, g_sTargetCard, g_kActiveKey]);
			g_iLineNr = 0;
			if (g_iProcessingPhase == 0) {
				g_kSettingsID = llGetNotecardLine(g_sTargetCard, g_iLineNr);
				return;
			} else if (g_iProcessingPhase == 1) {
				g_lMsgPackage = [];
				g_kSayings1ID = llGetNotecardLine(g_sTargetCard, g_iLineNr);
				return;
			} else {
				EndRun();
			}
		} else {
			EndRun();
		}
	} else {
		EndRun();
	}
}

EndRun() {
	g_iLineNr = 0;
	++g_iProcessingPhase;
	if (g_bDebugOn) DebugOutput(["EndRun - a", g_iProcessingPhase, llGetListLength(g_lRequests), g_kActiveKey, g_sTargetName, g_sTargetCard]);
	StartWork();
}

//
//	StartWork(key of requesting collar
//
//		Identify collar's owner
//		Clear and initialize work areas
//		Process collar owner name to locate appropriate settings card
//		If there is one, start the read process and exit
//		If there isn't, clear out the work areas, abandon that collar key, and try again
//
StartWork() {
	if (g_bDebugOn) DebugOutput(["StartWork - a", g_iProcessingPhase, llGetListLength(g_lRequests), g_kActiveKey, g_sTargetName, g_sTargetCard]);
	if (g_iProcessingPhase == 0) {
		if (llGetListLength(g_lRequests) > 0) {
			g_kActiveKey = llList2Key(g_lRequests, 0);
			g_kActiveOwner = llGetOwnerKey(g_kActiveKey);
			if (g_bDebugOn) DebugOutput(["StartWork - b", g_iProcessingPhase, llGetListLength(g_lRequests), g_kActiveKey, g_sTargetName, g_sTargetCard]);
			StartRun();
		}
		return;
	} else if (g_iProcessingPhase == 1) {
		StartRun();
		return;
	} else {
		DeleteKey(g_kActiveKey);
	}
}

DeleteKey(key kTarget) {
	g_iProcessingPhase = 0;
	g_bBlock = FALSE;
	integer iDx = llListFindList(g_lRequests, [kTarget]);
	if (g_bDebugOn) DebugOutput(["DeleteKey", llGetListLength(g_lRequests), kTarget, iDx]);
	if (iDx < 0) return;
	if (g_bDebugOn) DebugOutput(g_lRequests);
	g_lRequests = llDeleteSubList(g_lRequests, iDx, iDx);	
	if (g_bDebugOn) DebugOutput(g_lRequests);
}

SendValues() {
//	if (g_bDebugOn) DebugOutput(["SendValues Start", llGetListLength(g_lRequests), g_kActiveKey]);
//	if (g_bDebugOn) DebugOutput(g_lMsgPackage);
	integer iLineCount = 1;
	integer iDx = 0;
	integer iLimit = llGetListLength(g_lMsgPackage);
//	if (g_iProcessingPhase == 0)
	string sEndFlag = "kbhostaction=done";
	g_sMsgPackage = "kbhostline=" + (string) iLineCount;
	for (iDx = 0; iDx < iLimit; iDx += 2) {
		string sWork = llList2String(g_lMsgPackage, iDx) + "=" + llList2String(g_lMsgPackage, iDx+1);
		integer iCalcLength = llStringLength(g_sMsgPackage) + llStringLength("%%") + llStringLength(sWork);
		iCalcLength += llStringLength("%%");
		iCalcLength += llStringLength(sEndFlag);
		if (iCalcLength < 1024) {
			g_sMsgPackage += "%%";
			g_sMsgPackage += sWork;
		} else {
			if (g_bDebugOn) DebugOutput(["SendValues sending", g_kActiveKey, KB_HAIL_CHANNEL, g_sMsgPackage]);
			llRegionSayTo(g_kActiveKey, KB_HAIL_CHANNEL, g_sMsgPackage);
			g_sMsgPackage = "kbhostline=" + (string) iLineCount;
			++iLineCount;
			g_sMsgPackage = sWork;
		}
	}
	g_sMsgPackage += "%%";
	g_sMsgPackage += sEndFlag;
	if (g_bDebugOn) DebugOutput(["SendValues sending", g_kActiveKey, KB_HAIL_CHANNEL, g_sMsgPackage]);
	llRegionSayTo(g_kActiveKey, KB_HAIL_CHANNEL, g_sMsgPackage);

//	DeleteKey(g_kActiveKey);
//	g_kActiveKey = NULL_KEY;
	g_sMsgPackage = "";
	g_lMsgPackage = [];
	if (g_bDebugOn) DebugOutput(["SendValues Exit", llGetListLength(g_lRequests), g_kActiveKey]);
	if (g_bDebugOn) DebugOutput(g_lMsgPackage);
}

SendSayings() {
	//	if (g_bDebugOn) DebugOutput(["SendValues Start", llGetListLength(g_lRequests), g_kActiveKey]);
	//	if (g_bDebugOn) DebugOutput(g_lMsgPackage);
		integer iLineCount = 1;
		integer iDx = 0;
		integer iLimit = llGetListLength(g_lMsgPackage);
	//	if (g_iProcessingPhase == 0)
		string sEndFlag = "kbsayings1action=done";
		g_sMsgPackage = "kbsayings1line=" + (string) iLineCount;
		for (iDx = 0; iDx < iLimit; ++iDx) {
			string sWork = llList2String(g_lMsgPackage, iDx);
			integer iCalcLength = llStringLength(g_sMsgPackage) + llStringLength("%%") + llStringLength(sWork);
			iCalcLength += llStringLength("%%");
			iCalcLength += llStringLength(sEndFlag);
			if (iCalcLength < 1024) {
				g_sMsgPackage += "%%";
				g_sMsgPackage += sWork;
			} else {
				if (g_bDebugOn) DebugOutput(["SendSayings sending", g_kActiveKey, KB_HAIL_CHANNEL, g_sMsgPackage]);
				llRegionSayTo(g_kActiveKey, KB_HAIL_CHANNEL, g_sMsgPackage);
				g_sMsgPackage = "kbsayings1line=" + (string) iLineCount;
				++iLineCount;
				g_sMsgPackage = sWork;
			}
		}
		g_sMsgPackage += "%%";
		g_sMsgPackage += sEndFlag;
		if (g_bDebugOn) DebugOutput(["SendSayings sending", g_kActiveKey, KB_HAIL_CHANNEL, g_sMsgPackage]);
		llRegionSayTo(g_kActiveKey, KB_HAIL_CHANNEL, g_sMsgPackage);

	//	DeleteKey(g_kActiveKey);
	//	g_kActiveKey = NULL_KEY;
		g_sMsgPackage = "";
		g_lMsgPackage = [];
		if (g_bDebugOn) DebugOutput(["SendSayings Exit", llGetListLength(g_lRequests), g_kActiveKey]);
		if (g_bDebugOn) DebugOutput(g_lMsgPackage);
}

default
{
	state_entry() {
		if (g_bDebugOn) DebugOutput(["state_entry"]);
		g_lRequests = [];
		g_kActiveKey = NULL_KEY;
		if (g_iListenHandle != 0) { llListenRemove(g_iListenHandle); g_iListenHandle = 0; g_iListenHandle = llListen(KB_HAIL_CHANNEL, "", "", ""); }
		else g_iListenHandle = llListen(KB_HAIL_CHANNEL, "", "", "");
		g_sVersion = g_sScriptVersion;
		g_sVersion += g_sDevStage;
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
		if (g_iListenHandle != 0) { llListenRemove(g_iListenHandle); g_iListenHandle = 0; g_iListenHandle = llListen(KB_HAIL_CHANNEL, "", "", ""); }
		else g_iListenHandle = llListen(KB_HAIL_CHANNEL, "", "", "");
	}

	link_message(integer iSender, integer iNum, string sStr, key kID) {
	}
//
//	Listen for a ping from the collar
//
//		The key will be the collar's UID
//		Add it to the request list for processing in due time
//	
	listen(integer iChannel, string sName, key kId, string sMessage) {
		if (g_bDebugOn) DebugOutput(["listen"]);
		llOwnerSay((string) llGetOwnerKey(kId));
		llOwnerSay(llKey2Name(llGetOwnerKey(kId)));
		g_lRequests += [kId];
		if (g_bDebugOn) DebugOutput(["listen", llGetListLength(g_lRequests), g_kActiveKey, kId, iChannel, llList2Key(g_lRequests, 1)]);
		StartWork();
//		if (g_kActiveKey == NULL_KEY)
//			StartWork(llList2Key(g_lRequests, 0)); 
	}
	
	dataserver(key kID, string sData) {
		if (g_bDebugOn) DebugOutput(["dataserver", g_iProcessingPhase, sData, g_iLineNr]);
		if (kID == g_kSettingsID) {
			if (sData != EOF) {
				LoadSetting(sData,++g_iLineNr);
//				else LoadSaying(sData,++g_iLineNr);
				g_kSettingsID = llGetNotecardLine(g_sTargetCard, g_iLineNr);
			} else {
				LoadSetting(sData,g_iLineNr);
				SendValues();
				EndRun();
//				else LoadSaying(sData,g_iLineNr);
//				llSetTimerEvent(1.0);
//				if (g_iProcessingPhase == 1) SendValues();
//				else (SendSayings());
			}
		} else if (kID == g_kSayings1ID) {
			if (g_bDebugOn) DebugOutput(["dataserver", g_iProcessingPhase, sData, g_iLineNr]);
			if (sData != EOF) {
				g_lMsgPackage += [sData];
				++g_iLineNr;
				g_kSayings1ID = llGetNotecardLine(g_sTargetCard, g_iLineNr);
			} else {
				g_lMsgPackage += [sData];
				SendSayings();
				EndRun();
//				else LoadSaying(sData,g_iLineNr);
//				llSetTimerEvent(1.0);
//				if (g_iProcessingPhase == 1) SendValues();
//				else (SendSayings());
			}
		}
	}
	
	changed(integer iChange) {
		if (iChange & (CHANGED_OWNER || CHANGED_INVENTORY)) llResetScript();
	}
}

// kb_settings_host
