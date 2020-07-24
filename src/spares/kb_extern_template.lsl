

key g_kWearer;
string g_sPrefix;
integer API_CHANNEL = 0x60b97b5e;
string     g_sCard = ".externsettings";
integer g_iLineNr = 0;
key g_kLineID = NULL_KEY;
list g_lTargets = [];
list g_lVictims = [];

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

StartVictims() {
	integer iDx = 0;
	integer iLen = llGetListLength(g_lVictims);
	if (iLen == 0) return;
	for (iDx = 0; iDx < iLen; ++iDx) {
		key kWork = llList2Key(g_lVictims, iDx);
		string sStat = llList2String(g_lVictims, iDx+1);
		if (sStat == "try") {
			
		}
	}
}

CheckVictims() {
	
}

default
{
	state_entry(){
		g_kWearer = llGetOwner();
		g_sPrefix = llToLower(llGetSubString(llKey2Name(llGetOwner()),0,1));
//        DoListeners();
		// make the API Channel be per user
		API_CHANNEL = ((integer)("0x"+llGetSubString((string)llGetOwner(),0,8)))+0xf6eb-0xd2;
//        llListen(API_CHANNEL, "", "", "");
		if (llGetInventoryKey(g_sCard)) {
			g_iLineNr = 0;
			g_kLineID = llGetNotecardLine(g_sCard, g_iLineNr);
		}
	}
/*    
	listen(integer c,string n,key i,string m){
		if(c==API_CHANNEL){
			integer isAddonBridge = (integer)llJsonGetValue(m,["bridge"]);
			if(isAddonBridge && llGetOwnerKey(i) != g_kWearer)return; // flat out deny API access to bridges not owned by the wearer because they will not include a addon name, therefore can't be controlled
			// begin to pass stuff to link messages!
			// first- Check if a pairing was done with this addon, if not ask the user for confirmation, add it to Addons, and then move on
			if(llListFindList(g_lAddons, [i])==-1 && llGetOwnerKey(i)!=g_kWearer){
				g_kAddonPending = i;
				g_sAddonName = llJsonGetValue(m,["addon_name"]);
//                Dialog(g_kWearer, "[ADDON]\n\nAn object named: "+n+"\nAddon Name: "+g_sAddonName+"\nOwned by: secondlife:///app/agent/"+(string)llGetOwnerKey(i)+"/about\n\nHas requested internal collar access. Grant it?", ["Yes", "No"],[],0,CMD_WEARER,"addon~add");
				return;
			}else if(llListFindList(g_lAddons, [i])==-1 && llGetOwnerKey(i) == g_kWearer){
				// Add the addon and be done with
				g_lAddons += [i, llJsonGetValue(m,["addon_name"])];
			}
			
			integer iNum = (integer)llJsonGetValue(m,["iNum"]);
			string sMsg = llJsonGetValue(m,["sMsg"]);
			key kID = llJsonGetValue(m,["kID"]);            
			return;
		}
*/
/*
		if(llToLower(llGetSubString(m,0,1))==g_sPrefix){
			string CMD=llGetSubString(m,2,-1);
			if(llGetSubString(CMD,0,0)==" ")CMD=llDumpList2String(llParseString2List(CMD,[" "],[]), " ");
			llMessageLinked(LINK_SET, CMD_ZERO, CMD, i);
		} else {
			if(m == g_sSafeword && !g_iSafewordDisable && i == g_kWearer){
				llMessageLinked(LINK_SET, CMD_SAFEWORD, "","");
				SW();
			} else {
				// check for OOC quotes and the safeword
				if(llSubStringIndex(m,"((")!=-1 && llSubStringIndex(m,g_sSafeword) !=-1 && llSubStringIndex(m,"))")!=-1 && !g_iSafewordDisable && i==g_kWearer){
					// okay!
					llMessageLinked(LINK_SET, CMD_SAFEWORD, "" , "");
					SW();
				}
			}
		}

	}
*/

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
				if (llList2Key(g_lTargets, ji) == llDetectedKey(i)) {
					if (g_bDebugOn) { DebugOutput(["sensor", llDetectedKey(i)]); DebugOutput(g_lVictims); }
					g_lVictims += [llDetectedKey(i), "try"];
				}
				++ji;
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
	
	dataserver(key kID, string sData) {
		if (kID == g_kLineID) {
			if (g_bDebugOn) DebugOutput(["dataserver", sData, g_iLineNr]);
			if (sData != EOF) {
				string sTarget = llStringTrim(sData, STRING_TRIM);
				if (sTarget != "") { 
					key kTarget = (key) sTarget; 
					g_lTargets += [kTarget]; 
					g_lTargets += ["idle"];
					if (g_bDebugOn) DebugOutput(g_lTargets);
				}
				g_kLineID = llGetNotecardLine(g_sCard, ++g_iLineNr);
			} else {
				g_iLineNr = 0;
				StartSensor();
			}
		}
	}
	
	changed(integer iChange) {
		if (iChange & (CHANGED_OWNER || CHANGED_INVENTORY)) llResetScript();
	}

}
