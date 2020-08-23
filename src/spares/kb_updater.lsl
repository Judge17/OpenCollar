// TODO: no action if no updater or if all targets have been updated

string g_sAddOnID = "updater";
string g_sVersionId = "20200810 1300";

integer g_iLMCounter = 0;
integer g_iDebugCounter = 0;
string g_sPrefix;
integer API_CHANNEL = 0x60b97b5e;
float RELEASE_CHECK_INTERVAL = 30.0;
string     g_sCard = ".updatersettings";
key g_kMyKey = NULL_KEY;
integer g_iLineNr = 0;
key g_kLineID = NULL_KEY;
list g_lTargets = [];
string g_sCollarMajorVersion = "0.0";
string g_sCollarMinorVersion = "0";
list g_lCollarVersion = [];
list g_lUpdaterVersion = [];

key KURT_KEY   = "4986014c-2eaa-4c39-a423-04e1819b0fbf";

//
//	g_lTargets structure ( stride = 8):
//		[0] - key
//		[1] - status per addon
//		[2] - unique channel number
//		[3] - listen handle
//		[4] - major left component of this person's collar
//		[5] - major right component of this person's collar
//		[6] - minor component of this person's collar
//		[7] - last date reported
//
//	This list contains the keys specified in the input card, and information regarding their individual statuses. These keys are the people to look for for potential interaction
//
integer TARGETSTRIDE = 8;
integer TGTKEY = 0;
integer TGTSTATUS = 1;
integer TGTCHANNEL = 2;
integer TGTHANDLE = 3;
integer TGTMAJORLEFT = 4;
integer TGTMAJORRIGHT = 5;
integer TGTMINOR = 6;
integer TGTLASTDATE = 7;

list g_lVictims = [];

//
//	g_lVictims structure ( stride = 6):
//		[0] - key
//		[1] - status per addon
//			"try" - try to leash this victim
//			"oth" - other, ignore
//		[2] - unique channel number
//		[3] - listen handle
//		[4] - Collar Major Version
//		[5] - Collar Minor Version
//
//	This list contains the keys from the input card that have been sensed in range, and information regarding their individual statuses. Interaction is a stong possibility
//
integer VICTIMSTRIDE = 6;

list g_lPermanent = [];

//
//	g_lPermanent structure ( stride = 5 )
//		[0] - key
//		[1] - major left component of this person's collar
//		[2] - major right component of this person's collar
//		[3] - minor component of this person's collar
//		[4] - last date reported
//
integer PERMANENTSTRIDE = 5

//MESSAGE MAP
//integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
integer CMD_TRUSTED = 501;

//
//	DebugOutput routine mostly cribbed from aria's work; debug level and debug counter added
//		debug counter provides better message sequence information than the timestamp
//

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
//	llOwnerSay(llGetScriptName() + " " + (string) g_iDebugCounter + " " + final);
}

integer g_bDebugOn = FALSE;
integer g_iDebugLevel = 10;
integer KB_DEBUG_CHANNEL		   = -617783;

//
//	CalcChannel routing cribbed from aria's API module; should be distinguished from the one there before deploying oc_api
//

integer CalcChannel(key kIn) {
	integer iChannel = ((integer)("0x"+llGetSubString((string)llGetOwner(),0,8)))+0xf6eb-0xd2;
	return iChannel;
}

//
//	Initiate the repeating sensor scan for available victims; SCAN_RANGE and SCAN_INTERVAL constants self-explanatory
//

StartSensor() {
	float   SCAN_RANGE       = 10.0;
	float   SCAN_INTERVAL    = 60.0;
	if (g_bDebugOn) llSensor("", NULL_KEY, AGENT, SCAN_RANGE, PI);
	llSensorRepeat("", NULL_KEY, AGENT, SCAN_RANGE, PI, SCAN_INTERVAL);
	if (g_bDebugOn) { list lTemp = ["Sensor started", SCAN_RANGE, SCAN_INTERVAL, "Targets:"]; lTemp += g_lTargets; DebugOutput(9, lTemp); }
}

//
//	at this point, the victims list contains the people who are in range and targeted by this addon
//		the way someone gets on the victim list is by both being on the target list and being sensed in range; when that happens, she gets added with a status of "try"
//		the other elements added conform to the entry list in g_lVictims above: 
//

CheckVictims() {
	if (g_bDebugOn) { list lTemp = ["CheckVictims", "Victims:"]; lTemp += g_lVictims; DebugOutput(9, lTemp); }
	integer iDx = 0;
	integer iLen = llGetListLength(g_lVictims);
	if (iLen == 0) return;
	for (iDx = 0; iDx < iLen; iDx += VICTIMSTRIDE) {
		key kWork = llList2Key(g_lVictims, iDx);
		string sStat = llList2String(g_lVictims, iDx+1);
		integer iChannel = llList2Integer(g_lVictims, iDx+2);
		
		if (sStat == "try") TryVictim(iDx);
	}
}

//
//	TryVictim examines a single potential victim; it pulls victim variables as follows:
//		kWork - key of victim
//		sStat - status of victim ('try' means try this victim for leashing)
//		iChannel - unique communication channel for this victim
//		kLT - key of current leashholder if any
//		iLR - rank of current leashholder, if any
//		iLT - time current leash was first detected, or zero
//
//	If the status is 'try' send an AddOn Message to ask the collar the victim's current leash status
//		the rest of the leash logic is handled by the responst to the status message, if any
//

TryVictim(integer iDx){
	key kWork = llList2Key(g_lVictims, iDx);
	string sStat = llList2String(g_lVictims, iDx+1);
	integer iChannel = llList2Integer(g_lVictims, iDx+2);
	key kLT = llList2Key(g_lVictims, iDx + 4);
	integer iLR = llList2Integer(g_lVictims, iDx + 5);
	integer iLT = llList2Integer(g_lVictims, iDx + 6);
	string sKey = g_kMyKey;
	string sAnchor = "anchor " + sKey;
	if (sStat == "try") {
		AddOnMessage(llList2Json(JSON_OBJECT, ["msgid", "versioninquiry", 
				"addon_name", g_sAddOnID]), iChannel);
		return;
	}
/*
	if (kLT == NULL_KEY) AddOnMessage(llList2Json(JSON_OBJECT, ["msgid", "link_message", 
		"addon_name", g_sAddOnID,
		"leashkey", kWork,
		"iNum", CMD_OWNER,
		"sMsg", sAnchor,
		"kID", sKey]), iChannel);	
*/	
}

integer CheckVictimChannel(integer iInputChannel) {
	if (g_bDebugOn) { list lTemp = ["CheckVictimChannel", iInputChannel, "Victims:"]; lTemp += g_lVictims; DebugOutput(9, lTemp); }
	integer iDx = 0;
	integer iLen = llGetListLength(g_lVictims);
	if (iLen == 0) return -1;
	for (iDx = 0; iDx < iLen; iDx += VICTIMSTRIDE) {
		key kWork = llList2Key(g_lVictims, iDx);
		string sStat = llList2String(g_lVictims, iDx+1);
		integer iChannel = llList2Integer(g_lVictims, iDx+2);
		if (iChannel == iInputChannel) return iDx;
	}
	return -1;
}

//
//	Service routines to extract JSON values and return sensible alternatives to the JSON invalid codes
//

string xJSONstring(string JSONcluster, string sElement) {
	string sWork = llJsonGetValue(JSONcluster, [sElement]);
	if (sWork != JSON_INVALID && sWork != JSON_NULL) return sWork;
	return "";
}

string xJSONkey(string JSONcluster, string sElement) {
	string sWork = llJsonGetValue(JSONcluster, [sElement]);
	if (g_bDebugOn) DebugOutput(9, ["xJSONkey", JSONcluster, sElement, sWork]);
	if (sWork != JSON_INVALID && sWork != JSON_NULL) return sWork;
	return NULL_KEY;
}

integer xJSONint(string JSONcluster, string sElement) {
	string sWork = llJsonGetValue(JSONcluster, [sElement]);
	if (sWork != JSON_INVALID && sWork != JSON_NULL) return (integer) sWork;
	return 0;
}

//
//	Obvious random number generator (sort of)
//

integer random_integer(integer min, integer max)
{
	return min + (integer)(llFrand(max - min + 1));
}

//
//	if a random number between 0 and 100 is higher than the input number, return FALSE; otherwise, TRUE
//

integer odds(integer iChance) {
	integer iRand = random_integer(0, 100);
	if (g_bDebugOn) DebugOutput(9, ["odds", iRand, iChance]);
	if (iRand > iChance) return FALSE;
	return TRUE;
}

//
//	use "odds()" to return a yes/no decision; yes means leash, no means don't
//		if "yes" update the status to reflect internal leash command and send message to API to issue the anchor command
//

TryLeash(integer iVictimIndex) {
	integer iLeashOrNot = 0;
	integer iLeashOdds = 0;
	if (g_iDebugLevel == 0) {
		iLeashOdds = 110; 
	} else {
		iLeashOdds = 50;
	}
	iLeashOrNot = odds(iLeashOdds);
	if (g_bDebugOn) DebugOutput(9, ["TryLeash", iVictimIndex, iLeashOdds, iLeashOrNot]);
	if (iLeashOrNot) {
		if (iVictimIndex >= 0) {
			g_lVictims = llListReplaceList(g_lVictims, ["int"], iVictimIndex + 1, iVictimIndex + 1);
			string sWork = "anchor " + (string) g_kMyKey;
			AddOnMessage(llList2Json(JSON_OBJECT, ["msgid", "launch", 
					"addon_name", g_sAddOnID,
					"iNum", CMD_TRUSTED,
					"sMsg", sWork,
					"kID", KURT_KEY]), llList2Integer(g_lVictims, iVictimIndex + 2));
		}
	}
}

//
//	use "odds()" to return a yes/no decision; yes means leash, no means don't
//		if "yes" update the status to reflect internal leash command and send message to API to issue the anchor command
//

TryUnleash(integer iVictimIndex) {
	if (iVictimIndex < 0) return; // some kind of internal error
	integer iUnLeashOrNot = 110;
	integer iLeashOdds = 0;
	integer iTimeLeashed = llList2Integer(g_lVictims, iVictimIndex + 6);
	iTimeLeashed = MinutesSince(iTimeLeashed, llGetUnixTime()); // calculate minutes since leashed
	if (g_iDebugLevel == 0) {
		iLeashOdds = 110; 
	} else {
		iLeashOdds = 50 + iTimeLeashed;  // odds of being released increase minute by minute
	}
	iUnLeashOrNot = odds(iLeashOdds);
	if (g_bDebugOn) DebugOutput(9, ["TryUnleash", iVictimIndex, iLeashOdds, iUnLeashOrNot]);
	if (iUnLeashOrNot) {
		g_lVictims = llListReplaceList(g_lVictims, ["int"], iVictimIndex + 1, iVictimIndex + 1);
		AddOnMessage(llList2Json(JSON_OBJECT, ["msgid", "launch", 
				"addon_name", g_sAddOnID,
				"iNum", CMD_OWNER,
				"sMsg", "unleash",
				"kID", KURT_KEY]), llList2Integer(g_lVictims, iVictimIndex + 2));
	}
}

integer MinutesSince(integer iFrom, integer iTo) {
	integer iWork = iTo - iFrom;
	iWork += 30;
	iWork = iWork / 60;
	if (g_bDebugOn) DebugOutput(9, ["MinutesSince", iFrom, iTo, iWork]);
	return iWork;
}

//
//	Process an incoming addon message
//		We're only interested in messages from OpenCollar
//		We can only hand message ids "leashed", "notleashed", and "unleashed"
//			"leashed" means "currently leashed" (leashed already)
//			"notleashed" means "currently not leashed"
//			"unleashed" means "just now unleashed"
//

DecodeMessage(string sMsg) {
	if (g_bDebugOn) DebugOutput(9, ["DecodeMessage entry", sMsg]);
	string sSource = llJsonGetValue(sMsg, ["addon_name"]);
	if (sSource != "OpenCollar") return;
	string sId = xJSONstring(sMsg, "msgid");
	key kKey1 = NULL_KEY;
	integer iVictimIdx = -1;
	integer iPermIdx = -1;
	if (sId == "versionresponse") {
//
//	a "leashed" message gives details about a person's current leash status.
//		"victim" is the individual leashed (should always be the collar wearer)
//		"majver" is the collar major version (e.g. 7.5)
//		"minvwe" is the collar minor version (e.g. 1)
//			That example would be 7.5.1
//
		kKey1 = xJSONkey(sMsg, "victim");
		g_sCollarMajorVersion = xJSONstring(sMsg, "majver");
		g_sCollarMinorVersion = xJSONstring(sMsg, "minver");
		if (g_bDebugOn) DebugOutput(9, ["DecodeMessage versionresponse", kKey1, sWork, g_sCollarMajorVersion, g_sCollarMinorVersion]);
		list lParts = llParseString2List(g_sCollarMajorVersion, ["."], "");
		integer iI1 = llList2Integer(lParts, 0);
		integer iI2 = llList2Integer(lParts, 1);
		integer iI3 = (integer) g_sCollarMinorVersion;
//
//	iI integers have the current version of the target collar
//
		integer iJ1 = llList2Integer(g_lUpdaterVersion, 0);
		integer iJ2 = llList2Integer(g_lUpdaterVersion, 1);
		integer iJ3 = llList2Integer(g_lUpdaterVersion, 2);
//
//	iJ integers have version of the updater
//
		integer iK1 = 0:
		iPermIdx = llListFindList(g_lPermanent, [kKey1]);
		if (iPermIdx < 0) {
			g_lPermanent += [kKey, 0, 0, 0, 0];
			iPermIdx = llListFindList(g_lPermanent, [kKey1]);
		}
		if (llList2Integer(g_lPermanent, iPermIdx+4) == 0)
			g_lPermanent = llListReplaceList(g_lPermanent, [iI1, iI2, iI3, llGetUnixTime()]  iPermIdx+1, iPermIdx+4); // save 
		
//	Only got tthis far - need to check versions and such to decide whether to try the update
		
		
		
		iK1 = llList2Integer(g_lPermanent, iPermIdx + 4);
		iVictimIdx = llListFindList(g_lVictims, [kKey1]);
		if (iVictimIdx >= 0) {
			llListReplaceList
			g_lVictims = llListReplaceList(g_lVictims, [iI1, iI2, iI3], iVictimIdx + 4, iVictimIdx + 6); // record it and move on

			iI1 = llList2Integer(g_lVictims, )		
			integer iK2 = llGetUnixTime() - iK1; // # seconds since version last recorded
			if (sWork == "oth") return;
			
//			if (sWork == "int") { // leashed by us
//				if (llList2Key(g_lVictims, iVictimIdx + 4) == NULL_KEY) { // record doesn't reflect (i.e. first time we've received confirmation)
//					g_lVictims = llListReplaceList(g_lVictims, [kKey2, iInt1, iInt2], iVictimIdx + 4, iVictimIdx + 6); // if so, record it and move on
//				} else {
//					TryUnleash(iVictimIdx); // if not, see if this person's been leashed "long enough"
//				}
//			} else { // leashed by someone else
//				g_lVictims = llListReplaceList(g_lVictims, [kKey2, iInt1, iInt2], iVictimIdx + 4, iVictimIdx + 6); // just record it and move on
//				g_lVictims = llListReplaceList(g_lVictims, ["ext"], iVictimIdx + 1, iVictimIdx + 1);
//			}
		}
	}
}

AddOnMessage(string sMessage, integer iChannel) {
	if(llGetTime()>30){
		llResetTime();
		g_iLMCounter=0;
	}
	g_iLMCounter++;
	if(g_iLMCounter < 50) {
	// Max of 50 LMs to send out in a 30 second period, after that ignore
		llRegionSay(iChannel, sMessage);
		if (g_bDebugOn) DebugOutput(9, ["AddOnMessage", sMessage, iChannel]);
	}
}

//
//	Parse control card entries
//	Populate g_lTargets if necessary
//
//
//

ParseEntry(string sInput) {
	string sTarget = llStringTrim(sInput, STRING_TRIM);
	list lInput = [];
	key kKey = NULL_KEY;
	if (sTarget != "") lInput = llParseString2List(sTarget, ["="], []); else lInput = ["", ""];
	while (llGetListLength(lInput) < 2) lInput += [""];
	string s1 = llList2String(lInput, 0);
	string s2 = llList2String(lInput, 1);
	if (s1 == "target") {
		kKey = llList2Key(lInput, 1);
		g_lTargets += [kKey, "idle"]; 
		integer iChannel = (integer)("0x"+llGetSubString(s2,0,8))+0xf6eb-0xd2;
		integer iHandle = llListen(iChannel, "", "", "");
		g_lTargets += [iChannel, iHandle, 0, 0, 0, 0]; // channel, listen handle, 3-part version, last date
		if (g_bDebugOn) {
			list lOutput = ["ParseEntry", sInput];
			lOutput += lInput;
			lOutput += [llList2Key(lInput, 1), "idle", iChannel, iHandle];
			DebugOutput(9, lOutput);
		}
	} else if (s1 == "debug") { 
		g_iDebugLevel = llList2Integer(lInput, 1); 
		g_bDebugOn = FALSE; 
		if (g_iDebugLevel < 10) g_bDebugOn = TRUE; 
	} else if (s1 == "version") {
		list lWork = llParseString2List(s2, ["."], []);
		g_lUpdaterVersion = [llList2Integer(lWork, 0), llList2Integer(lWork, 1), llList2Integer(lWork, 2)];
	}	
}

//
//	on state_entry, do the standard setups, then start reading the control card - that will fire the dataserver event when lines are retrieved
//

default
{
	state_entry(){
		if (g_bDebugOn) { DebugOutput(9, [g_sVersionId]); }
		g_kMyKey = llGetKey();
//		g_sPrefix = llToLower(llGetSubString(llKey2Name(llGetOwner()),0,1));
//        DoListeners();
		// make the API Channel be per user
		API_CHANNEL = ((integer)("0x"+llGetSubString((string)llGetOwner(),0,8)))+0xf6eb-0xd2;
		llSetTimerEvent(0.0);
		llSetTimerEvent(RELEASE_CHECK_INTERVAL);
		if (llGetInventoryKey(g_sCard)) {
			g_iLineNr = 0;
			g_kLineID = llGetNotecardLine(g_sCard, g_iLineNr);
		}
	}
	
	on_rez(integer i) {
		llSetTimerEvent(0.0);
		llSetTimerEvent(RELEASE_CHECK_INTERVAL);
		g_lTargets = [];
		g_bDebugOn = FALSE;
		g_iDebugLevel = TRUE;
		g_iDebugCounter = 0;
		if (llGetInventoryKey(g_sCard)) {
			g_iLineNr = 0;
			g_kLineID = llGetNotecardLine(g_sCard, g_iLineNr);	
		}
	}

//
//	Don't bother dealing with messages sent on channels that aren't ours
//
//	Pass any responses to DecodeMessage for processing
//
	
	listen(integer c, string n, key i, string m) {
//		integer iDx = CheckVictimChannel(c);
		if (g_bDebugOn) { DebugOutput(9, ["listen", c, n, i, m]); }
//		if (c < 0) return;
		DecodeMessage(m);
	}
//
//	when the sensor fires:
//		check each current victim; if any of them have moved out of range,
//			if their status was "int" (meaning leashed by this addon) ignore them, otherwise remove them from the list
//			if they were leashed by this addon and are out of range, either they've logged off or been unleashed
//			if logged off, leave them along, they'll be regrabbed when they log back in
//			if unleashed, we'll get the unleash update and remove them there, but no penalty for removing them here first
//		then check the people who were in range; when someone is found who is on the target list, copy that table entry to the victims list
//		when all of the located people have been checked, then check the victims list
//

	sensor(integer iNum) {
		if (g_bDebugOn) DebugOutput(9, ["sensor", iNum]);
		list lPeople = [];
		integer i=0;
		for(i = 0; i < iNum; i++) {
			lPeople += [llDetectedKey(i)];
		}
//
//	check each key in the victim list against the people discovered in the sensor; if there is anyone in the victim list not in the people list (i.e. not in range),
//		delete that key and associated values from the victim list
//
		integer iVicLen = llGetListLength(g_lVictims);
		integer iVicIdx = iVicLen - VICTIMSTRIDE;
		while (iVicIdx >= 0) {
			if (llListFindList(lPeople, [llList2Key(g_lVictims, iVicIdx)]) < 0) {
				string sStat = llList2String(g_lVictims, iVicIdx + 1);
				if (sStat != "int") {
					g_lVictims = llDeleteSubList(g_lVictims, iVicIdx, iVicIdx + VICTIMSTRIDE-1);					
				}
			}
			iVicIdx -= VICTIMSTRIDE;
		}
//
//	check each key sensor located against the target list; ignore people not there
//	if a person is on the target list, check to see if she's already on the victim list
//		if she isn't just add her
//		if she is, check the status; if it's "int", leave it along
//
//	if someone on the list has a status of "oth" then ignore; otherwise, populate the rest of the entry and set the status to "try"
//
// TODO: put date currency checks in here - only send sufficiently non-current dates to be tried
//
		for(i = 0; i < iNum; i++) {
			if (g_bDebugOn) { list lTemp = ["sensor", "seeking", llDetectedKey(i), "Targets:"]; lTemp += g_lTargets; DebugOutput(9, lTemp); }
			integer ji = llListFindList(g_lTargets, [llDetectedKey(i)]);
			if (g_bDebugOn) { list lTemp = ["sensora", ji, llDetectedKey(i), "Targets:"]; lTemp += g_lTargets; DebugOutput(9, lTemp); }
			if (ji >= 0) {  // ignore people not on the target list
				integer ki = llListFindList(g_lVictims, [llDetectedKey(i)]);
				if (ki >= 0) {
					string sStat = llList2String(g_lVictims, ki + 1);
					if (sStat != "oth") {
						g_lVictims = llListReplaceList(g_lVictims, ["try"], ki + 1, ki + 1);
					}
					if (g_bDebugOn) { list lTemp = ["sensor1", llDetectedKey(i), "Victims:"]; lTemp += g_lVictims; DebugOutput(9, lTemp); }
				} else {
					g_lVictims += [llDetectedKey(i), "try"];  // replaces ji + 1
					g_lVictims += [llList2Integer(g_lTargets, ji + 2)];
					g_lVictims += [llList2Integer(g_lTargets, ji + 3)];
					g_lVictims += ["", ""];
					if (g_bDebugOn) { list lTemp = ["sensor2", llDetectedKey(i), "Victims:"]; lTemp += g_lVictims; DebugOutput(9, lTemp); }
				}
			}
		}
		if (g_bDebugOn)  { list lTemp = ["sensor3", "Victims:"]; lTemp += g_lVictims; DebugOutput(9, lTemp); }
		CheckVictims();
	}
	
	no_sensor() {
		if (g_bDebugOn) DebugOutput(9, ["no sensor"]);
		g_lVictims = [];
	}

//
//	dataserver wakes up on each line retrieval; each line contains the key of someone we want to look for, save the key, set state to idle, calculate the unique channel,
//		save the channel, start a listen and save the handle, allin the targets list
//
//	eventually, we hit EOF; if we've recovered any targets, start the sensors
//	
	dataserver(key kID, string sData) {
		if (kID == g_kLineID) {
			if (g_bDebugOn) DebugOutput(9, ["dataserver", sData, g_iLineNr]);
			if (sData != EOF) {
				ParseEntry(sData);
				if (g_bDebugOn) { list lTemp = ["dataserver", "Targets:"]; lTemp += g_lTargets; DebugOutput(9, lTemp); }
				g_kLineID = llGetNotecardLine(g_sCard, ++g_iLineNr);
			} else {
				g_iLineNr = 0;
				if (llGetListLength(g_lTargets) > 0)
					StartSensor();
			}
		}
	}
	
	changed(integer iChange) {
		if (iChange & (CHANGED_OWNER || CHANGED_INVENTORY)) llResetScript();
	}

	timer() {
		if (g_bDebugOn) DebugOutput(9, ["timer entry"]);
//
//	check each key in the victim list 
//
		integer iVicLen = llGetListLength(g_lVictims);
		integer iVicIdx = 0;
		while (iVicIdx < iVicLen) {
			string sStat = llList2String(g_lVictims, iVicIdx + 1);
			if (g_bDebugOn) DebugOutput(9, ["timer victim", iVicIdx, sStat]);
			if (sStat == "int") TryUnleash(iVicIdx); 
			iVicIdx += VICTIMSTRIDE;
		}	
	}
}
