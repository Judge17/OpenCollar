//TODO: random timer for unleash

string g_sAddOnID = "grabby";
string g_sVersionId = "20200720 2250";

integer g_iLMCounter = 0;
key g_kWearer;
string g_sPrefix;
integer API_CHANNEL = 0x60b97b5e;
string     g_sCard = ".externsettings";
integer g_iLineNr = 0;
key g_kLineID = NULL_KEY;
list g_lTargets = [];
list g_lVictims = [];

//
//	g_lVictims structure ( stride = 4):
//		[0] - key
//		[1] - status per addon
//		[2] - unique channel number
//		[3] - listen handle
//

list g_lManaged = [];

//
//	g_lManaged structure ( stride = 4):
//		[0] - key
//		[1] - leashed to key
//		[2] - leashed to rank
//		[3] - leashed to time
//

key g_kLeashedTo = NULL_KEY;
integer g_iLeashedRank = 0;
integer g_iLeashedTime = 0;

DebugOutput(list ITEMS){
	integer i=0;
	integer end=llGetListLength(ITEMS);
	string final;
	for(i=0;i<end;i++){
		final+=llList2String(ITEMS,i)+" ";
	}
	llOwnerSay(llGetScriptName() + " " + final);
}

integer g_bDebugOn = TRUE;

integer CalcChannel(key kIn) {
	integer iChannel = ((integer)("0x"+llGetSubString((string)llGetOwner(),0,8)))+0xf6eb-0xd2;
	return iChannel;
}

StartSensor() {
	float   SCAN_RANGE       = 10.0;
	float   SCAN_INTERVAL    = 60.0;
	if (g_bDebugOn) llSensor("", NULL_KEY, AGENT, SCAN_RANGE, PI);
	llSensorRepeat("", NULL_KEY, AGENT, SCAN_RANGE, PI, SCAN_INTERVAL);
	if (g_bDebugOn) { DebugOutput(["Sensor started", SCAN_RANGE, SCAN_INTERVAL]); DebugOutput(g_lTargets); }
}

//
//	at this point, the victims list contains the people who are in range and targeted by this addon
//		for each one, first check to see if she's already being managed (leashed)
//	TODO: the leash information has to be in a list, can't be individual static variables
//
//
//

CheckVictims() {
	integer iDx = 0;
	integer iLen = llGetListLength(g_lVictims);
	if (iLen == 0) return;
	for (iDx = 0; iDx < iLen; iDx += 4) {
		key kWork = llList2Key(g_lVictims, iDx);
		string sStat = llList2String(g_lVictims, iDx+1);
		integer iChannel = llList2Integer(g_lVictims, iDx+2);
		integer iManagedIdx = llListFindList(g_lManaged, [kWork]);
		if (iManagedIdx < 0) {
			AddOnMessage(llList2Json(JSON_OBJECT, ["msgid", "leashinquiry", 
				"addon_name", g_sAddOnID,
				"leashkey", kWork]));
		} else {
// TODO Leash and unleash logic goes here
			key kLeashedTo = llList2Key(g_lManaged, iManagedIdx+1);
			integer iLeashedRank = llList2Integer(g_lManaged, iManagedIdx+2);
			integer iLeashedTime = llList2Integer(g_lManaged, iManagedIdx+3);
		}
	}
}

integer CheckVictimChannel(integer iInputChannel) {
	integer iDx = 0;
	integer iLen = llGetListLength(g_lVictims);
	if (iLen == 0) return -1;
	for (iDx = 0; iDx < iLen; iDx += 4) {
		key kWork = llList2Key(g_lVictims, iDx);
		string sStat = llList2String(g_lVictims, iDx+1);
		integer iChannel = llList2Integer(g_lVictims, iDx+2);
		if (iChannel == iInputChannel) return iDx;
	}
	return -1;
}

DecodeMessage(string sMsg) {
/*
AddOnMessage(llList2Json(JSON_OBJECT, ["msgid", "leashed", 
	"addon_name", "OpenCollar", 
	"leashedto", g_kLeashedTo, 
	"leashedrank", g_iLeashedRank, 
	"leashedtime", g_iLeashedTime]));

kb_api AddOnMessage {"msgid":"leashed","addon_name":"OpenCollar","leashedto":"f03fba89-80e8-6d03-4071-109d85252c72","leashedrank":503,"leashedtime":1596157701,"victim":"e55c511b-bcd7-4103-bc95-1ccef72ea021"} 
	
AddOnMessage(llList2Json(JSON_OBJECT, ["msgid", "unleashed", 
	"addon_name", "OpenCollar"]));

*/
	if (g_bDebugOn) DebugOutput(["DecodeMessage entry", sMsg]);
	string sSource = llJsonGetValue(sMsg, ["addon_name"]);
	if (sSource != "OpenCollar") return;
	string sId = llJsonGetValue(sMsg, ["msgid"]);
	key kKey1 = NULL_KEY;
	key kKey2 = NULL_KEY;
	integer iInt1 = 0;
	integer iInt2 = 0;
	if (sId == "leashed") {
		string sWork = llJsonGetValue(sMsg, ["victim"]);
		if (sWork != JSON_INVALID && sWork != JSON_NULL) kKey1 = sWork;
		sWork = llJsonGetValue(sMsg, ["leashedto"]);
		if (sWork != JSON_INVALID && sWork != JSON_NULL) kKey2 = sWork;
		sWork = llJsonGetValue(sMsg, ["leashedrank"]);
		if (sWork != JSON_INVALID && sWork != JSON_NULL) iInt1 = (integer) sWork;
		sWork = llJsonGetValue(sMsg, ["leashedtime"]);
		if (sWork != JSON_INVALID && sWork != JSON_NULL) iInt2 = (integer) sWork;
		integer iManagedIdx = llListFindList(g_lManaged, [kKey1]);
		if (iManagedIdx < 0) g_lManaged += [kKey1, kKey2, iInt1, iInt2];
		else g_lManaged = llListReplaceList(g_lManaged, [kKey1, kKey2, iInt1, iInt2], iManagedIdx, iManagedIdx+3);
		if (g_bDebugOn) DebugOutput(["DecodeMessage", sId, kKey1, kKey2, iInt1, iInt2]);
	} else if (sId == "unleashed") {
		if (g_bDebugOn) DebugOutput(["DecodeMessage", sId, kKey1, kKey2, iInt1, iInt2]);
	}
}

AddOnMessage(string sMessage) {
	if(llGetTime()>30){
		llResetTime();
		g_iLMCounter=0;
	}
	g_iLMCounter++;
	if(g_iLMCounter < 50) {
	// Max of 50 LMs to send out in a 30 second period, after that ignore
		llRegionSay(API_CHANNEL, sMessage);
		if (g_bDebugOn) DebugOutput(["AddOnMessage", sMessage]);
	}
}

//
//	on state_entry, do the standard setups, then start reading the control card - that will fire the dataserver event when lines are retrieved
//

default
{
	state_entry(){
		if (g_bDebugOn) { DebugOutput([g_sVersionId]); }
		g_kWearer = llGetOwner();
		g_sPrefix = llToLower(llGetSubString(llKey2Name(llGetOwner()),0,1));
//        DoListeners();
		// make the API Channel be per user
		API_CHANNEL = ((integer)("0x"+llGetSubString((string)llGetOwner(),0,8)))+0xf6eb-0xd2;
		if (llGetInventoryKey(g_sCard)) {
			g_iLineNr = 0;
			g_kLineID = llGetNotecardLine(g_sCard, g_iLineNr);
		}
	}

//
//	Don't bother dealing with messages sent on channels that aren't ours
//
	
	listen(integer c, string n, key i, string m) {
		integer iDx = CheckVictimChannel(c);
		if (g_bDebugOn) { DebugOutput(["listen", c, n, i, m, iDx]); }
//		if (c < 0) return;
		DecodeMessage(m);
	}
//
//	when the sensor fires, go through the list of identified people; when someone is found who is on the target list, copy that table entry to the victims list
//	when all of the located people have been checked, then check the victims list
//
	sensor(integer iNum) {
		if (g_bDebugOn) DebugOutput(["sensor", iNum]);
		list lPeople = [];
		integer i=0;
		g_lVictims = [];
		for(i = 0; i < iNum; i++) {
			if (g_bDebugOn) DebugOutput(["seeking", llDetectedKey(i)]);
			if (g_bDebugOn) DebugOutput(g_lTargets);
			integer ji = 0;
			integer jl = llGetListLength(g_lTargets);
			while (ji < jl) {
				if (llList2Key(g_lTargets, ji) == llDetectedKey(i)) {  // ji + 0
					if (g_bDebugOn) { DebugOutput(["sensor", llDetectedKey(i)]); DebugOutput(g_lVictims); }
					g_lVictims += [llDetectedKey(i), "try"];  // replaces ji + 1
					g_lVictims += llList2Integer(g_lTargets, ji + 2);
					g_lVictims += llList2Integer(g_lTargets, ji + 3);
				}
				ji += 4;
			}
		}
		if (g_bDebugOn) DebugOutput(["victims"]);
		if (g_bDebugOn) DebugOutput(g_lVictims);
		CheckVictims();
	}
	
	no_sensor() {
		if (g_bDebugOn) DebugOutput(["no sensor"]);
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
			if (g_bDebugOn) DebugOutput(["dataserver", sData, g_iLineNr]);
			if (sData != EOF) {
				string sTarget = llStringTrim(sData, STRING_TRIM);
				if (sTarget != "") { 
					key kTarget = (key) sTarget; 
					g_lTargets += [kTarget]; 
					g_lTargets += ["idle"];
					integer iChannel = (integer)("0x"+llGetSubString(sTarget,0,8))+0xf6eb-0xd2;
					integer iHandle = llListen(iChannel, "", "", "");
					g_lTargets += [iChannel, iHandle]; // channel, listen handle
					if (g_bDebugOn) DebugOutput(g_lTargets);
				}
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

}
