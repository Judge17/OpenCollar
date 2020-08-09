
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
string g_sVersionId = "20200806 1645";

integer API_CHANNEL = 0x60b97b5e;

string  g_sSubMenu              = "KBAPI"; // Name of the submenu
string  g_sParentMenu          	= "Apps"; // name of the menu, where the menu plugs in, should be usually Addons. Please do not use the mainmenu anymore
string  PLUGIN_CHAT_CMD         = "KBAPI"; // every menu should have a chat command, so the user can easily access it by type for instance *plugin

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

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

string UPMENU = "BACK";
integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved
//str must be in form of "token=value"
integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the settings script sends responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from settings
integer LM_SETTING_EMPTY = 2004;//sent when a token has no value

integer KB_ADDON_MESSAGE = -34851;

Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sMenuType) {
	key kMenuID = llGenerateKey();
	llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);
	integer iIndex = llListFindList(g_lMenuIDs, [kRCPT]);
	if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kRCPT, kMenuID, sMenuType], iIndex, iIndex + g_iMenuStride - 1);
	else g_lMenuIDs += [kRCPT, kMenuID, sMenuType];
}

DoMenu(key keyID, integer iAuth) {
	string sPrompt = "\n[KB Api Debug Level (less is more)] "+g_sVersionId + ", " + (string) llGetFreeMemory() + " bytes free.\nCurrent debug level: " + (string) g_iDebugLevel;
	list lMyButtons = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10"];
	Dialog(keyID, sPrompt, lMyButtons, [UPMENU], 0, iAuth, "debug");
}

key g_kWearer;

key g_kThisKey = "f03fba89-80e8-6d03-4071-109d85252c72";
key g_kLeashedTo = NULL_KEY; 
integer g_iLeashedRank = 0;
integer g_iLeashedTime = 0;

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
integer g_iDebugCounter = 0;
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
*/
list g_lMenuIDs;
integer g_iMenuStride;

integer NOTIFY = 1002;
integer NOTIFY_OWNERS=1003;
//integer g_iPublic;

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
	if (g_bDebugOn) DebugOutput(3, ["HandleSettings", sStr]);
	list lParams = llParseString2List(sStr, ["="], []); // now [0] = "major_minor" and [1] = "value"
	string sToken = llList2String(lParams, 0); // now SToken = "major_minor"
	string sValue = llList2String(lParams, 1); // now sValue = "value"
	integer i = llSubStringIndex(sToken, "_");
	string sTokenMajor = llToLower(llGetSubString(sToken, 0, i - 1));
	string sTokenMinor = llToLower(llGetSubString(sToken, i + 1, -1));
	if (g_bDebugOn) DebugOutput(3, ["HandleSettings", sTokenMajor, sTokenMinor, sValue]);
	if (sTokenMajor == "leash") {
//        if (g_bDebugOn) DebugOutput([sStr, sToken]);
		if (sTokenMinor == "leashedto") {
			list lLeashed = llParseString2List(sValue, [","], []);
			if (g_bDebugOn) DebugOutput(3, lLeashed);
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

HandleMenus(string sStr, key kID) {
	integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
	if (~iMenuIndex) {
		list lMenuParams = llParseString2List(sStr, ["|"], []);
		key kAv = (key)llList2String(lMenuParams, 0);
		string sMessage = llList2String(lMenuParams, 1);
		integer iAuth = (integer)llList2String(lMenuParams, 3);
		string sMenu=llList2String(g_lMenuIDs, iMenuIndex + 1);
		g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
		if (sMenu == "debug") {
			if (sMessage == UPMENU) {
				llMessageLinked(LINK_SET, iAuth, "menu " + g_sParentMenu, kAv);
			} else {
				SetDebugLevel(sMessage);
				DoMenu(kAv, iAuth);
			}
		}
	}
}

SetDebugLevel(string sLevel) {
	integer iNew = (integer) sLevel;
	g_iDebugLevel = iNew;
	if (g_iDebugLevel > 9) g_bDebugOn = FALSE;
	else g_bDebugOn = TRUE;
	if (g_bDebugOn) {DebugOutput(0, ["Debug Level", g_iDebugLevel, "Debug Status", g_bDebugOn]); }
}

UserCommand(integer iAuth, string sCmd, key kID){
	if (sCmd == "menu "+g_sSubMenu) {
		DoMenu(kID, iAuth);
	}
}
/*
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
			if (g_bDebugOn) DebugOutput(3, ["AddOnMessage", sMessage, API_CHANNEL]);
		}
	}

}

string xJSONstring(string JSONcluster, string sElement) {
	string sWork = llJsonGetValue(JSONcluster, [sElement]);
	if (sWork != JSON_INVALID && sWork != JSON_NULL) return sWork;
	return "";
}

string xJSONkey(string JSONcluster, string sElement) {
	string sWork = llJsonGetValue(JSONcluster, [sElement]);
	if (g_bDebugOn) DebugOutput(3, ["xJSONkey", JSONcluster, sElement, sWork]);
	if (sWork != JSON_INVALID && sWork != JSON_NULL) return sWork;
	return NULL_KEY;
}

integer xJSONint(string JSONcluster, string sElement) {
	string sWork = llJsonGetValue(JSONcluster, [sElement]);
	if (sWork != JSON_INVALID && sWork != JSON_NULL) return (integer) sWork;
	return 0;
}

default
{
	state_entry(){
		g_kWearer = llGetOwner();
		g_sPrefix = llToLower(llGetSubString(llKey2Name(llGetOwner()),0,1));
//        DoListeners();
		// make the API Channel be per user
		API_CHANNEL = ((integer)("0x"+llGetSubString((string)llGetOwner(),0,8)))+0xf6eb-0xd2;
		if (g_bDebugOn) DebugOutput(3, ["state_entry", "API_CHANNEL", API_CHANNEL]);
		llListen(API_CHANNEL, "", "", "");
		if (g_bDebugOn) { DebugOutput(3, [g_sVersionId, API_CHANNEL]); }
	}
	
	on_rez(integer i) {
		g_iDebugCounter = 0;
		if (g_bDebugOn) { DebugOutput(3, [g_sVersionId]); }		
	}
	
	listen(integer c,string n,key i,string m){
		if (g_bDebugOn) DebugOutput(3, ["listen", c, n, i, m]);
		if(c==API_CHANNEL) {
			string sAddon = xJSONstring(m, "addon_name");
			if (llListFindList(g_lAddons, [sAddon]) >= 0) {
				string sMsgid = llJsonGetValue(m,["msgid"]);
				if (sMsgid == "leashinquiry") {
					if (g_kLeashedTo != NULL_KEY) {
						AddOnMessage(llList2Json(JSON_OBJECT, ["msgid", "leashed", 
							"addon_name", "OpenCollar", 
							"leashedto", g_kLeashedTo, 
							"leashedrank", g_iLeashedRank, 
							"leashedtime", g_iLeashedTime,
							"victim", g_kWearer]));
						return;
					} else {
						AddOnMessage(llList2Json(JSON_OBJECT, ["msgid", "notleashed", 
							"addon_name", "OpenCollar", 
							"victim", g_kWearer]));
						return;
					}
				} else if (sMsgid == "launch") {
					integer iNum = xJSONint(m, "iNum");
					string sMsg = xJSONstring(m, "sMsg");
					key kID = xJSONkey(m,"kID");
					if (g_bDebugOn) DebugOutput(3, ["listen", "llMessageLinked", LINK_SET, iNum, sMsg, kID]);
					llMessageLinked(LINK_SET, iNum, sMsg, kID);
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
		if(iNum == MENUNAME_REQUEST && sStr == g_sParentMenu) {
			llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
		} else if (iNum == KB_ADDON_MESSAGE) {
			AddOnMessage(llList2Json(JSON_OBJECT, ["msgid", "link_message", "addon_name", "OpenCollar", "iNum", iNum, "sMsg", sStr, "kID", kID]));
		} else if (iNum == LM_SETTING_RESPONSE) {
			HandleSettings(sStr);
		} else if( iNum == LM_SETTING_DELETE) {
			HandleDeletes(sStr);
		} else if (iNum >= CMD_OWNER && iNum <= CMD_WEARER) { 
			UserCommand(iNum, sStr, kID); // This is intentionally not available to public access.
		} else if (iNum == DIALOG_RESPONSE) {
			HandleMenus(sStr, kID);
		} else if(iNum == REBOOT){
			if(sStr=="reboot"){
				llResetScript();
			}
		}
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
