// Message list 20200201

integer KB_NOTICE_LEASHED          = -34691;
integer KB_NOTICE_UNLEASHED        = -34692;
integer KB_SET_REGION_NAME         = -34693;
integer KB_REM_REGION_NAME         = -34694;
integer KB_REQUEST_VERSION         = -34591;
integer KB_SET_RLV_EXCEPT          = -34695;
integer KB_SET_RLV_ALLOW_SEND      = -34696;
integer KB_SET_RLV_ALLOW_READ      = -34697;
integer KB_SET_RLV_FORBID_SEND     = -34698;
integer KB_SET_RLV_FORBID_READ     = -34699;
integer KB_SET_RLV_ALLOW_START     = -34700;
integer KB_SET_RLV_FORBID_START    = -34701;
integer KB_NOTICE_GROUP_SET        = -34702;
integer KB_NOTICE_GROUP_UNSET      = -34703;
integer KB_SET_GROUP_KEY           = -34704;
integer KB_REM_GROUP_KEY           = -34705;
integer KB_LINK_UPDATE             = -34706;
integer KB_NONVOLATILE_BOOKMARK    = -34707;
integer KB_NOTICE_OWNERONLY        = -34708;
integer KB_REQUEST_LOG_LINK_NR     = -34709;
integer KB_REPORT_LOG_LINK_NR      = -34710;
integer KB_INIT_LOG_SCRIPTS        = -34711;
integer KB_INIT_LOG_SCRIPT1        = -34712;
integer KB_INIT_LOG_SCRIPT2        = -34713;
integer KB_INIT_LOG_SCRIPT3        = -34714;
integer KB_ACTIVE_LOG_FULL         = -34715;
integer KB_LOG_THIS_EVENT          = -34716;
integer KB_KBSYNC_KICKSTART 	   = -34717;
integer KB_LOG_LOG_SCRIPT1         = -34718;
integer KB_LOG_LOG_SCRIPT2         = -34719;
integer KB_LOG_LOG_SCRIPT3         = -34720;
integer KB_LOG_REPORT_STATUS       = -34721;
integer KB_LOG_DUMP_SCRIPT1        = -34722;
integer KB_LOG_DUMP_SCRIPT2        = -34723;
integer KB_LOG_DUMP_SCRIPT3        = -34724;
integer KB_DUMP_SCRIPT1_COMPLETE   = -34725;
integer KB_DUMP_SCRIPT2_COMPLETE   = -34726;
integer KB_DUMP_SCRIPT3_COMPLETE   = -34727;
integer KB_REQUEST_MANDATORY_LIST  = -34728;
integer LINK_KB_SYNC_DB 		   = -77519;
integer LINK_KB_VERS_REQ 		   = -75301;
integer LINK_KB_VERS_RESP 		   = -75302;
integer LINK_KB_TRIGGER_SETTINGS   = -75303;
integer LINK_KB_SETTINGS_COMPLETE  = -75304;
integer OC_SYS_SETTINGS_MENU       = -75305;
integer OC_SYS_MENU_RESET          = -75306;
integer OC_SYS_MAIN_MENU           = -75307;
integer OC_SYS_FIX_MENU            = -75308;
integer OC_SYS_HELP_MENU           = -75309;
integer OC_AUTH_OWNER_MENU		   = -75310;
integer OC_AUTH_TRUSTED_MENU	   = -75311;
integer OC_AUTH_BLOCK_MENU		   = -75312;
integer OC_KEY_IS_OWNER			   = -75313;
integer OC_KEY_IS_TRUSTED		   = -75314;
integer OC_KEY_IS_BLOCKED		   = -75315;
integer OC_CHECK_KEY			   = -75316;
integer OC_KEY_IS_NOT_OWNER		   = -75317;
integer OC_KEY_IS_NOT_TRUSTED	   = -75318;
integer OC_KEY_IS_NOT_BLOCKED	   = -75319;
integer OC_KEY_IS_GROUP			   = -75320;
integer OC_KEY_IS_EVERYONE		   = -75321;
integer OC_KEY_IS_WEARER		   = -75322;
integer OC_KEY_IS_NOT_GROUP		   = -75323;
integer OC_KEY_IS_NOT_EVERYONE	   = -75324;
integer OC_KEY_IS_NOT_WEARER	   = -75325;
integer OC_START_BLOCK_CHECK	   = -75326;
integer OC_AUTH_LIST_OWNERS 	   = -75327;
integer OC_AUTH_ADD_BLOCK   	   = -75328;
integer OC_AUTH_LIST SWITCHES	   = -75329;
integer OC_AUTH_ADD_OWNER   	   = -75330;
integer OC_AUTH_LIST_BLOCK  	   = -75331;
integer OC_START_OWNER_CHECK	   = -75332;
integer OC_AUTH_LIST_TRUST  	   = -75333;
integer OC_AUTH_ADD_TRUST   	   = -75334;
integer OC_START_TRUST_CHECK	   = -75335;
integer LINK_SAYING1			   = -75336;

integer KB_NOTICE_SENDCHAT         = -34801;
integer KB_NOTICE_CHATCHAN         = -34802;
integer KB_NOTICE_EMOTECHAN        = -34803;
integer KB_NOTICE_SENDCHAN         = -34804;
integer KB_JSON_MESSAGE  	  	   = -34850;
integer KB_ADDON_MESSAGE  	  	   = -34851;
integer	KB_CURFEW_NOTICE		   = -34852;
integer KB_CLOCK_SET			   = -34843;
integer KB_CLOCK_ALARM			   = -34844;
integer KB_CURFEW_ACTIVE		   = -34845;
integer KB_CURFEW_INACTIVE		   = -34846;
integer KB_COLLAR_VERSION		   = -34847;
integer KB_READY_SAYINGS		   = -34848;
integer KB_SEND_SAYINGS			   = -34849;
integer KB_SET_SAYING			   = -34850;

integer KB_DEBUG_CLOCK_ON		   = -36001;
integer KB_DEBUG_CLOCK_OFF		   = -36002;
integer KB_DEBUG_CURFEW_ON		   = -36003;
integer KB_DEBUG_CURFEW_OFF		   = -36004;

integer KB_LOG_CHANNEL			   = -317083;
integer KB_HAIL_CHANNEL			   = -317783;
integer KB_HAIL_CHANNEL00		   = -317784;
integer KB_DEBUG_CHANNEL		   = -617783;

string	KB_CLOCK_NODUP			   = "nodup";

Errors:
llMessageLinked(LINK_SET,NOTIFY,"0Error 1201",kID); 

1201	Invalid parameter count in add in UserCommand in oc_auth_block
1202	Invalid parameter count in internadd in UserCommand in oc_auth_block
1203	Attempt to block Kurt
1204	Invalid parameter count in remove in link_message in oc_auth_block
1205	Invalid parameter count in add in UserCommand in oc_auth_owner
1206	Invalid parameter count in remove in UserCommand in oc_auth_owner
1207	Invalid parameter count in internadd in UserCommand in oc_auth_owner
1208	Table error in TrackAuth in oc_auth_verify
1209	Invalid parameter count in PrintSwitches in oc_auth_main
1210	Invalid parameter count in add in UserCommand in oc_auth_trust
1211	Invalid parameter count in internadd in UserCommand in oc_auth_trust
1212	Invalid parameter count in OC_AUTH_ADD_TRUSTED in link_message in oc_auth_owner
1213	Invalid parameter count in OC_AUTH_ADD_OWNER in link_message in oc_auth_owner
1214	Invalid parameter count in OC_AUTH_ADD_BLOCK in link_message in oc_auth_block

logThis(string sStr, integer iLevel) {
	if (g_iLogLevel < iLevel) return;
	string sLog = (string) llGetUnixTime() + g_sDivider + llGetScriptName() + " " +g_sScriptVersion+g_sDevStage + g_sDivider + sStr;
	if (g_iCurrentLogScript == 1) { llMessageLinked(g_iLogLinkNumber, KB_LOG_LOG_SCRIPT1, sLog, NULL_KEY); }
	else if (g_iCurrentLogScript == 2) { llMessageLinked(g_iLogLinkNumber, KB_LOG_LOG_SCRIPT2, sLog, NULL_KEY); }
	else if (g_iCurrentLogScript == 3) { llMessageLinked(g_iLogLinkNumber, KB_LOG_LOG_SCRIPT3, sLog, NULL_KEY); }
}

SetLogLevel(integer iNew, integer iSave) {
	if ((iNew < 0) || (iNew > 9)) return;
	if (g_iLogLevel == iNew) return;
	g_iLogLevel = iNew;
	if (iSave) SaveAndResend(g_sGlobalToken + "loglevel", (string) g_iLogLevel);
}

if (llToLower(llGetSubString(sToken, 0, i)) == llToLower(g_sGlobalToken)) { // if "major_" = "global_"
	sToken = llGetSubString(sToken, i + 1, -1);
	if (sToken == "kbar") SetKBarOptions((integer) sValue, FALSE);
	else if (sToken == "slavemsg") g_sSlaveMessage = sValue;
	else if (sToken == "kbarstat") SetGirlStatus((integer) sValue, FALSE);
	else if (sToken == "loglevel") SetLogLevel((integer) sValue, FALSE);
	else if (sToken == "swactive") SetSWActive((integer) sValue, FALSE);
	else if (sToken == "kbarstatlock") {
		SetLockStatus((integer) sValue, FALSE);
	}
}

logThis(string sStr, integer iLevel) {
	if (g_iLogLevel < iLevel) return;
	llMessageLinked(LINK_SET, KB_LOG_THIS_EVENT, sStr + "|" + (string) iLevel, "");
}

DebugOutput(list ITEMS) {
	if (!g_bDebugOn) return;
	list lMsg = DebugList(ITEMS);
	integer iLen = llGetListLength(lMsg);
	if (iLen > 0) {
		integer iIdx = 0;
		while (iIdx < iLen) {
			llRegionSay(KB_LOG_CHANNEL, llList2String(lMsg, iIdx));
			++iIdx;
		}
	}
}

list DebugList(list ITEMS) {
	list lWork = [];
	if (llGetListLength(ITEMS) == 0) return lWork;
	string sWork = DebugParse(ITEMS);
	if (llStringLength(sWork) == 0) return lWork;
	if (llStringLength(sWork) < 513) return [sWork];
	while (llStringLength(sWork) > 512) {
		string s1 = llGetSubString(sWork, 0, 511);
		string s2 = llGetSubString(sWork, 512, -1);
		lWork += [s1];
		sWork = s2;
	}
	lWork += sWork;
	return lWork;
}

string DebugParse(list ITEMS) {
	integer i=0;
	integer end=llGetListLength(ITEMS);
	string final;
	for(i = 0; i < end; i++) {
		final += llList2String(ITEMS,i)+" ";
	}
	return llGetScriptName()+" "+KB_VERSION+KB_DEVSTAGE+" " +final;
}

	integer ALIVE = -55;
	integer READY = -56;
	integer STARTUP = -57;
	default
	{
		on_rez(integer iNum){
			llResetScript();
		}
		state_entry(){
			llMessageLinked(LINK_SET, ALIVE, llGetScriptName(),"");
		}
		link_message(integer iSender, integer iNum, string sStr, key kID){
			if(iNum == REBOOT){
				if(sStr == "reboot"){
					llResetScript();
				}
			} else if(iNum == READY){
				llMessageLinked(LINK_SET, ALIVE, llGetScriptName(), "");
			} else if(iNum == STARTUP){
				state active;
			}
		}
	}
	state active
	{
		state_entry()
		{
			g_kWearer = llGetOwner();
			llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "global_locked","");
		}
		on_rez(integer i) {
			if(llGetOwner()!=g_kWearer) llResetScript();
			if (Source) {
				llOwnerSay("@detach=n"); // no escaping before we are sure the former source really is not active anymore
				g_iResit_status = 0;
				llSetTimerEvent(30);
				llRegionSayTo(Source, RLV_RELAY_CHANNEL, "ping,"+(string)Source+",ping,ping");
				
			}else llResetScript();
		}



/*
---------------KBar Modification ----------------------------------------
| 

*/

code

/*
---------------KBar Modification End-------------------------------------
*/

key KURT_KEY   = "4986014c-2eaa-4c39-a423-04e1819b0fbf";
key SILKIE_KEY = "1a828b4e-6345-4bb3-8d41-f93e6621ba25";
