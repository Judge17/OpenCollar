
/*
This file is a part of OpenCollar.
Copyright ©2020
: Contributors :
Aria (Tashia Redrose)
	*June 2020       -       Created oc_api
	  * This implements some auth features, and acts as a API Bridge for addons and plugins
	
	
et al.
Licensed under the GPLv2. See LICENSE for full details.
https://github.com/OpenCollarTeam/OpenCollar
*/
string g_sVersionId = "20200720 2300";

integer API_CHANNEL = 0x60b97b5e;

//integer    g_bAuthModsAreLive = FALSE;

//MESSAGE MAP
integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
integer CMD_TRUSTED = 501;
integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
integer CMD_EVERYONE = 504;
integer CMD_RLV_RELAY = 507;
integer CMD_SAFEWORD = 510;
integer CMD_RELAY_SAFEWORD = 511;
integer CMD_NOACCESS=599;


integer REBOOT = -1000;
/*
string UPMENU = "BACK";
integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;
*/
integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved
//str must be in form of "token=value"
integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the settings script sends responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from settings
integer LM_SETTING_EMPTY = 2004;//sent when a token has no value

integer KB_ADDON_MESSAGE = -34851;

/*
Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
	key kMenuID = llGenerateKey();
	llMessageLinked(LINK_SET, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

	integer iIndex = llListFindList(g_lMenuIDs, [kID]);
	if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
	else g_lMenuIDs += [kID, kMenuID, sName];
}
string SLURL(key kID){
	return "secondlife:///app/agent/"+(string)kID+"/about";
}

key g_kGroup;
*/

key g_kWearer;

key g_kThisKey = "f03fba89-80e8-6d03-4071-109d85252c72";
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
/*
key g_kTry;
integer g_iCurrentAuth;
key g_kMenuUser;

integer CalcAuth(key kID){
	string sID = (string)kID;
	// First check
	if(llGetListLength(g_lOwner) == 0 && kID==g_kWearer)
		return CMD_OWNER;
	else{
		if(llListFindList(g_lBlock,[sID])!=-1)return CMD_NOACCESS;
		if(llListFindList(g_lOwner, [sID])!=-1)return CMD_OWNER;
		if(llListFindList(g_lTrust,[sID])!=-1)return CMD_TRUSTED;
		if(kID==g_kWearer)return CMD_WEARER;
		if(in_range(kID)){
			if(g_kGroup!=""){
				if(llSameGroup(kID))return CMD_GROUP;
			}
		
			if(g_iPublic)return CMD_EVERYONE;
		} else {
			llMessageLinked(LINK_SET, NOTIFY, "0%NOACCESS% because you are out of range", kID);
		}
	}
	return CMD_NOACCESS;
}

list g_lMenuIDs;
integer g_iMenuStride;

integer NOTIFY = 1002;
integer NOTIFY_OWNERS=1003;
integer g_iPublic;
*/
string g_sPrefix;

integer g_iLimitRange=TRUE;
integer in_range(key kID){
	if(!g_iLimitRange)return TRUE;
	if(kID == g_kWearer)return TRUE;
	else{
		vector pos = llList2Vector(llGetObjectDetails(kID, [OBJECT_POS]),0);
		if(llVecDist(llGetPos(),pos) <=20.0)return TRUE;
		else return FALSE;
	}
}

HandleSettings(string sStr) {
	if (g_bDebugOn) DebugOutput(["HandleSettings", sStr]);
	list lParams = llParseString2List(sStr, ["="], []); // now [0] = "major_minor" and [1] = "value"
	string sToken = llList2String(lParams, 0); // now SToken = "major_minor"
	string sValue = llList2String(lParams, 1); // now sValue = "value"
	integer i = llSubStringIndex(sToken, "_");
	string sTokenMajor = llToLower(llGetSubString(sToken, 0, i - 1));
	string sTokenMinor = llToLower(llGetSubString(sToken, i + 1, -1));
	if (g_bDebugOn) DebugOutput(["HandleSettings", sTokenMajor, sTokenMinor, sValue]);
	if (sTokenMajor == "leash") {
//        if (g_bDebugOn) DebugOutput([sStr, sToken]);
		if (sTokenMinor == "leashedto") {
			list lLeashed = llParseString2List(sValue, [","], []);
			if (g_bDebugOn) DebugOutput(lLeashed);
			if (llGetListLength(lLeashed) > 2) {
				if (g_kLeashedTo == NULL_KEY) {
					g_kLeashedTo = llList2Key(lLeashed, 0); 
					g_iLeashedRank = llList2Integer(lLeashed, 1);
					g_iLeashedTime = llGetUnixTime();
					AddOnMessage(llList2Json(JSON_OBJECT, ["msgid", "leashed", 
						"addon_name", "OpenCollar", 
						"leashedto", g_kLeashedTo, 
						"leashedrank", g_iLeashedRank, 
						"leashedtime", g_iLeashedTime,
						"victim", g_kWearer]));
				}
//	[19:38:22] OpenCollar Minimal2: kb_api AddOnMessage {"msgid":"leashed","addon_name":"OpenCollar","leashedto":"f03fba89-80e8-6d03-4071-109d85252c72","leashedrank":503,"leashedtime":1595731103} 
//	[19:38:32] OpenCollar Minimal2: kb_api AddOnMessage {"msgid":"leashed","addon_name":"OpenCollar","leashedto":"f03fba89-80e8-6d03-4071-109d85252c72","leashedrank":503,"leashedtime":1595731113} 
//	[19:38:42] OpenCollar Minimal2: kb_api AddOnMessage {"msgid":"leashed","addon_name":"OpenCollar","leashedto":"f03fba89-80e8-6d03-4071-109d85252c72","leashedrank":503,"leashedtime":1595731123} 
//	[19:38:45] OpenCollar Minimal2: kb_api AddOnMessage {"msgid":"leashed","addon_name":"OpenCollar","leashedto":"f03fba89-80e8-6d03-4071-109d85252c72","leashedrank":503,"leashedtime":1595731126} 
			}
		}
	} else if (sTokenMajor == "addons") {
		if (sTokenMinor == "name") {
			g_lAddons = [];
			list lNames = llParseString2List(sValue, [","], []);
			integer ii = 0;
			integer il = llGetListLength(lNames);
			while (ii < il) {
				string sName = llList2String(lNames, ii);
				if (llListFindList(g_lAddons, [sName]) < 0) g_lAddons += [sName];
				++ii;
			}
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
	if (sTokenMajor == "leash") {
		if (sTokenMinor == "leashedto") {
			g_kLeashedTo = NULL_KEY; 
			g_iLeashedRank = 0;
			AddOnMessage(llList2Json(JSON_OBJECT, ["msgid", "unleashed", 
					"addon_name", "OpenCollar", "victim", g_kWearer]));
		}
	}
}

/*
UserCommand(integer iAuth, string sCmd, key kID){
	if(iAuth == CMD_OWNER){
		if(sCmd == "safeword-disable")g_iSafewordDisable=TRUE;
		else if(sCmd == "safeword-enable")g_iSafewordDisable=FALSE;
	}
	if (iAuth <CMD_OWNER || iAuth>CMD_EVERYONE) return;
	if (iAuth == CMD_OWNER && sCmd == "runaway") {
		
		return;
	}
	
	if(llToLower(sCmd) == "menu addons" || llToLower(sCmd)=="addons"){
		AddonsMenu(kID, iAuth);
	}
}
 
list StrideOfList(list src, integer stride, integer start, integer end)
{
	list l = [];
	integer ll = llGetListLength(src);
	if(start < 0)start += ll;
	if(end < 0)end += ll;
	if(end < start) return llList2List(src, start, start);
	while(start <= end)
	{
		l += llList2List(src, start, start);
		start += stride;
	}
	return l;
}

AddonsMenu(key kID, integer iAuth){
	Dialog(kID, "[Addons]\n\nThese are addons you have worn, or rezzed that are compatible with OpenCollar and have requested collar access", StrideOfList(g_lAddons,2,1,llGetListLength(g_lAddons)), [UPMENU],0,iAuth,"addons");
}

SW(){
	llRegionSayTo(g_kWearer,g_iInterfaceChannel,"%53%41%46%45%57%4F%52%44"); // okay what the fuck is this? How can we make this more readable??!
	llMessageLinked(LINK_SET, NOTIFY,"0You used the safeword, your owners have been notified", g_kWearer);
	llMessageLinked(LINK_SET, NOTIFY_OWNERS, "%WEARERNAME% had to use the safeword. Please check on %WEARERNAME%.","");
}
*/
list g_lAddons;
key g_kAddonPending;
string g_sAddonName;
integer g_iInterfaceChannel;
integer g_iLMCounter=0;

AddOnMessage(string sMessage) {
	if(llGetTime()>30){
		llResetTime();
		g_iLMCounter=0;
	}
	g_iLMCounter++;
	if(g_iLMCounter < 50){
	
	// Max of 50 LMs to send out in a 30 second period, after that ignore
		if(llGetListLength(g_lAddons)>0) {
			llRegionSay(API_CHANNEL, sMessage);
			if (g_bDebugOn) DebugOutput(["AddOnMessage", sMessage, API_CHANNEL]);
		}
	}

}

default
{
	state_entry(){
		g_kWearer = llGetOwner();
		g_sPrefix = llToLower(llGetSubString(llKey2Name(llGetOwner()),0,1));
//        DoListeners();
		// make the API Channel be per user
		API_CHANNEL = ((integer)("0x"+llGetSubString((string)llGetOwner(),0,8)))+0xf6eb-0xd2;
		if (g_bDebugOn) DebugOutput(["state_entry", "API_CHANNEL", API_CHANNEL]);
		llListen(API_CHANNEL, "", "", "");
		if (g_bDebugOn) { DebugOutput([g_sVersionId]); }
	}
	
	on_rez(integer i) {
		if (g_bDebugOn) { DebugOutput([g_sVersionId]); }		
	}
	
	listen(integer c,string n,key i,string m){
		if (g_bDebugOn) DebugOutput(["listen", c, n, i, m]);
		if(c==API_CHANNEL) {
			string sAddon = llJsonGetValue(m,["addon_name"]);
			if (sAddon != JSON_INVALID && sAddon != JSON_NULL) {
//            integer isAddonBridge = (integer)llJsonGetValue(m,["bridge"]);
//            if(isAddonBridge && llGetOwnerKey(i) != g_kWearer)return; // flat out deny API access to bridges not owned by the wearer because they will not include a addon name, therefore can't be controlled
			// begin to pass stuff to link messages!

				// Add the addon and be done with
//                g_lAddons += [i, llJsonGetValue(m,["addon_name"])];
//            }
// kb_api listen -446871756 Simulated Grabby Post 4dc18106-6d48-8ed5-3e39-7157bb1cc1a1 {"msgid":"leashinquiry","addon_name":"grabby","leashkey":"e55c511b-bcd7-4103-bc95-1ccef72ea021"} 
				string sMsgid = llJsonGetValue(m,["msgid"]);
				if (sMsgid == "leashinquiry") {
					AddOnMessage(llList2Json(JSON_OBJECT, ["msgid", "leashed", 
						"addon_name", "OpenCollar", 
						"leashedto", g_kLeashedTo, 
						"leashedrank", g_iLeashedRank, 
						"leashedtime", g_iLeashedTime,
						"victim", g_kWearer]));
					return;
				}
				if (llListFindList(g_lAddons, [sAddon]) >= 0) {
					integer iNum = (integer)llJsonGetValue(m,["iNum"]);
					string sMsg = llJsonGetValue(m,["sMsg"]);
					key kID = llJsonGetValue(m,["kID"]);
				}         
			}
		return;
		}
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
*/
	}
	link_message(integer iSender, integer iNum, string sStr, key kID){
//        if (g_bDebugOn) DebugOutput(["link_message", iSender, iNum, sStr, kID]);
		if (iNum == KB_ADDON_MESSAGE) {
			AddOnMessage(llList2Json(JSON_OBJECT, ["msgid", "link_message", "addon_name", "OpenCollar", "iNum", iNum, "sMsg", sStr, "kID", kID]));
		} else if (iNum == LM_SETTING_RESPONSE) {
			HandleSettings(sStr);
		} else if( iNum == LM_SETTING_DELETE) {
			HandleDeletes(sStr);

				
//        if(iNum>=CMD_OWNER && iNum <= CMD_NOACCESS) { llOwnerSay(llDumpList2String([iSender, iNum, sStr, kID], " ^ "));
		} else if(iNum == REBOOT){
			if(sStr=="reboot"){
				llResetScript();
			}
		}
/*
		else if(iNum == DIALOG_RESPONSE){
			integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
			if(iMenuIndex!=-1){
				string sMenu = llList2String(g_lMenuIDs, iMenuIndex+1);
				g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex-1, iMenuIndex-2+g_iMenuStride);
				list lMenuParams = llParseString2List(sStr, ["|"],[]);
				key kAv = llList2Key(lMenuParams,0);
				string sMsg = llList2String(lMenuParams,1);
				integer iAuth = llList2Integer(lMenuParams,3);
				integer iRespring=TRUE;
				
				if(g_bAuthModsAreLive && sMenu == "scan~add"){
					if(sMsg == UPMENU){
						llMessageLinked(LINK_SET, iAuth, "menu Access", kAv);
						return;
					} else if(sMsg == ">Wearer<"){
						UpdateLists(llGetOwner());
						llMessageLinked(LINK_SET, 0, "menu Access", kAv);
					}else {
						//UpdateLists((key)sMsg);
						g_kTry = (key)sMsg;
						if(!(g_iMode&ACTION_BLOCK))
							Dialog(g_kTry, "OpenCollar\n\n"+SLURL(g_kTry)+" is trying to add you to an access list, do you agree?", ["Yes", "No"], [], 0, CMD_NOACCESS, "scan~confirm");
						else UpdateLists((key)sMsg);
					}
				} else if(g_bAuthModsAreLive && sMenu == "scan~confirm"){
					if(sMsg == "No"){
						g_iMode = 0;
						llMessageLinked(LINK_SET, 0, "menu Access", kAv);
					} else if(sMsg == "Yes"){
						UpdateLists(g_kTry);
						llSleep(1);
						llMessageLinked(LINK_SET, 0, "menu Access", kAv);
					}
				} else if(g_bAuthModsAreLive && sMenu == "removeUser"){
					if(sMsg == UPMENU){
						llMessageLinked(LINK_SET,0, "menu Access", kAv);
					}else{
						UpdateLists(sMsg);
					}
				} else if(sMenu == "addons"){
					if(sMsg == UPMENU){
						llMessageLinked(LINK_SET,0,"menu",kAv);
					} else {
						// Call this addon
						llMessageLinked(LINK_SET, iAuth, "menu "+sMsg, kAv);
					}
				}
			}
		}
*/
	}
/*    
	sensor(integer iNum){
		if (!g_bAuthModsAreLive) return;
		if(!(g_iMode&ACTION_SCANNER))return;
		list lPeople = [];
		integer i=0;
		for(i=0;i<iNum;i++){
			if(llGetListLength(lPeople)<10){
				//llSay(0, "scan: "+(string)i+";"+(string)llGetListLength(lPeople)+";"+(string)g_iMode);
				if(llDetectedKey(i)!=llGetOwner())
					lPeople += llDetectedKey(i);
				
			} else {
				//llSay(0, "scan: invalid list length: "+(string)llGetListLength(lPeople)+";"+(string)g_iMode);
			}
		}
		
		Dialog(g_kMenuUser, "OpenCollar\nAdd Menu", lPeople, [">Wearer<",UPMENU], 0, g_iCurrentAuth, "scan~add");
	}
*/
}
