// This file is part of OpenCollar.
// Copyright (c) 2018 - 2019 Tashia Redrose, Silkie Sabra, lillith xue                            
// Licensed under the GPLv2.  See LICENSE for full details. 

string g_sParentMenu = "Apps";
string g_sSubMenu = "Attachments";

string g_sDevStage = "beta 1";
string 	g_sScriptVersion = "7.5";

//MESSAGE MAP
//integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
integer CMD_TRUSTED = 501;
//integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
integer CMD_EVERYONE = 504;
integer CMD_RLV_RELAY = 507;
integer CMD_SAFEWORD = 510;
integer CMD_RELAY_SAFEWORD = 511;

integer NOTIFY = 1002;

integer REBOOT = -1000;

integer LINK_CMD_RESTRICTIONS = -2576;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved
//str must be in form of "token=value"
integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the settings script sends responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from settings
integer LM_SETTING_EMPTY = 2004;//sent when a token has no value
//integer LM_SETTING_REQUEST_EXTENSION = 2200;
//integer LM_SETTING_RESPONSE_EXTENSION = 2201;

integer AUTH_REQUEST = 600;
integer AUTH_REPLY = 601;

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

integer RLV_CMD = 6000;
integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.
integer RLV_CLEAR = 6002;//RLV plugins should clear their restriction lists upon receiving this message.

integer RLV_OFF = 6100; // send to inform plugins that RLV is disabled now, no message or key needed
integer RLV_ON = 6101; // send to inform plugins that RLV is enabled now, no message or key needed

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;
string UPMENU = "BACK";
string ALL = "ALL";
string g_sChecked = "☑";
string g_sUnChecked = "☐";

integer g_iNCLine;
key g_kNCQuery;
string g_sNCName = "Collar Pose";

string g_sLockSound="dec9fb53-0fef-29ae-a21d-b3047525d312";
string g_sUnlockSound="82fa6d06-b494-f97c-2908-84009380c8d1";

key g_kChainTexture = "4cde01ac-4279-2742-71e1-47ff81cc3529";
key g_kRopeTexture = "9a342cda-d62a-ae1f-fc32-a77a24a85d73";

// Chain Style
key g_kTexture = "4cde01ac-4279-2742-71e1-47ff81cc3529";
float g_fSize = 0.04;
float g_fGravity = 0.01;
float g_fRed = 1;
float g_fGreen = 1;
float g_fBlue = 1;
integer g_bRibbon = TRUE;

integer g_bMoveLock = FALSE;

integer g_iChan_ocCmd = -1;
integer g_iChan_OCChain = -9889;
list g_lCollarPoses = [];
list g_lPoses = [];
list g_lActivePoses = [];
list g_lSelectedPose = [];
integer g_bRLV = FALSE;
string g_sCurrentCollarPose = "";

integer g_bCollarLocked = FALSE;
integer g_bLocked = FALSE;
integer g_bSyncLock = FALSE;
integer g_bHidden = FALSE;
integer g_bPingInProgress = FALSE;

string g_sGlobalToken = "global"; 
key g_kWearer;
list g_lMenuIDs;
integer g_iMenuStride;

list g_lDeviceMenu = [];
/*
integer g_bDebugOn = FALSE;
DebugOutput(list ITEMS){
    integer i=0;
    integer end=llGetListLength(ITEMS);
    string final;
    for(i=0;i<end;i++){
        final+=llList2String(ITEMS,i)+" ";
    }
// llInstantMessage(kID, llGetScriptName() +final);
    llOwnerSay(llGetScriptName() + " " + final);
}
*/

integer bool(integer a){
    if(a)return TRUE;
    else return FALSE;
}

list g_lCheckboxes=["⬜","⬛"];
string Checkbox(integer iValue, string sLabel) {
    return llList2String(g_lCheckboxes, bool(iValue))+" "+sLabel;
}


Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_THIS, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kID, kMenuID, sName];
}

Menu(key kID, integer iAuth) {
    string sPrompt = "\n[Cuff Menu] " + g_sScriptVersion + " " + g_sDevStage;
    
    list lButtons = ["Poses"];
    
    if (g_bLocked) lButtons += [g_sChecked+"Locked"];
    else lButtons += [g_sUnChecked+"Locked"];
    if (iAuth == CMD_OWNER || iAuth == CMD_WEARER) lButtons += ["Settings"];
    if (iAuth != CMD_WEARER) lButtons += ["Clear All"];
    
    lButtons += ["Devices"];
    
    Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth, "Menu~Cuffs");
}

DeviceMenu(key kID, integer iAuth, string sDevice){
    string sPrompt = "\n [Devices] " + g_sScriptVersion + " " + g_sDevStage;
    list lButtons = [];
    if (llGetListLength(g_lDeviceMenu) < 1) sPrompt += "\n \nNo Device worn";
    else {
        integer i;
        for (i=0; i<llGetListLength(g_lDeviceMenu);++i){
            list lMenu = llParseString2List(llList2String(g_lDeviceMenu,i),["|"],[]);
            string sDeviceMenu = llList2String(lMenu,0);
            if (sDevice == "" && llListFindList(lButtons,[sDeviceMenu]) == -1) lButtons += [sDeviceMenu];
            else if (sDevice == sDeviceMenu) lButtons += [llList2String(lMenu,1)];
        }
    }
    string sMenuName = "Menu~DeviceList";
    if (sDevice != "") sMenuName = "Menu~"+sDevice; 
    Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth, sMenuName);
}

PosesMenu(key kID, integer iAuth){
    string sPrompt = "\n[Cuff Poses] " + g_sScriptVersion + " " + g_sDevStage;
    list lButtons = [];
    integer i;
    for (i=0; i<llGetListLength(g_lPoses);++i) {
        list lPose = llParseString2List(llList2String(g_lPoses,i),["|"],[]);
        if (llListFindList(lButtons,[llList2String(lPose,0)]) == -1) lButtons+=[llList2String(lPose,0)];
    }
    
    if (iAuth == CMD_WEARER) sPrompt += "\n \n!! WARNING !! \n \n You will not be able to stop Poses by yourself!";
    
    Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth, "Menu~CuffPoses");
}

SettingsMenu(key kID, integer iAuth, string sTarget)
{
    string sPrompt = "\n[Cuff-Settings] " + g_sScriptVersion + " " + g_sDevStage;
    list lButtons =  [];
    if (sTarget == "Settings") {
        lButtons = ["Chains","Sync"];
        if (g_bHidden) lButtons += [g_sChecked+"Hide"];
        else lButtons += [g_sUnChecked+"Hide"];
    } else if (sTarget == "Chains") {
        if (g_kTexture == g_kChainTexture) lButtons = [g_sChecked+"Chain",g_sUnChecked+"Rope"];
        else lButtons = [g_sUnChecked+"Chain",g_sChecked+"Rope"];
        
    } else if (sTarget == "Sync") {
        if (g_bSyncLock) lButtons = [g_sChecked+"Sync Lock"];
        else lButtons = [g_sUnChecked+"Sync Lock"];
        lButtons += "ReSync Now";
    }
    
    Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth, "Menu~CuffSettings");
}


AnimMenu(key kID, integer iAuth, string sTarget){
    string sPrompt = "\n["+sTarget+ "Poses ]" + g_sScriptVersion + " " + g_sDevStage;
    list lButtons = [];
    list lUtility = [UPMENU];
    integer i;
    for (i=0;i<llGetListLength(g_lPoses);++i) {
        list lPose = llParseString2List(llList2String(g_lPoses,i),["|"],[]);
        if (llList2String(lPose,0) == sTarget) {
            if (llListFindList(g_lActivePoses,[llList2String(g_lPoses,i)]) > -1) lButtons += [g_sChecked+llList2String(lPose,1)];
            else lButtons += [g_sUnChecked+llList2String(lPose,1)];
        }
    }
    
    Dialog(kID, sPrompt, lButtons, lUtility, 0, iAuth, "Menu~"+sTarget);
}

UserCommand(integer iNum, string sStr, key kID) {
    if (iNum<CMD_OWNER || iNum>CMD_EVERYONE) return;
    if (sStr=="attachment" || sStr == "menu "+g_sSubMenu) Menu(kID, iNum);
    list lUCmd = llParseString2List(sStr,[" "],[]);
    string sPrefix = llList2String(lUCmd,0);
    if (sPrefix == "attachment" || sPrefix == "attach" || sPrefix == "a"){
        string sCmd = llList2String(lUCmd,1);
        if (sCmd == "pose") {
            string sParam = llList2String(lUCmd,2);
            if (sParam == "") PosesMenu(kID,iNum);
            else {
                string sRealPoseName = "";
                integer i;
                for (i=0; i<llGetListLength(g_lPoses);++i){
                    list lPose = llParseString2List(llList2String(g_lPoses,i),["|"],[]);
                    if (llList2String(lUCmd,3) != ""){
                        if (llToLower(llList2String(lPose,1)) == llToLower(sParam)+" "+llToLower(llList2String(lUCmd,3))) sRealPoseName = llList2String(g_lPoses,i);
                    } else if (llToLower(llList2String(lPose,1)) == llToLower(sParam)) sRealPoseName = llList2String(g_lPoses,i);
                }
                if (sRealPoseName) doPose(sRealPoseName,iNum,kID);
                else llMessageLinked(LINK_SET, NOTIFY, "0"+"Pose '"+sParam+"' is not registered!", kID);
            }
        } else if (sCmd == "clear") doClearAllPoses();
        else if (sCmd == "hide"){
            g_bHidden = TRUE;
            llMessageLinked(LINK_THIS, LM_SETTING_SAVE, "cuffs_hide="+(string)g_bHidden, NULL_KEY);
        } else if (sCmd == "show"){
            g_bHidden = FALSE;
            llMessageLinked(LINK_THIS, LM_SETTING_SAVE, "cuffs_hide="+(string)g_bHidden, NULL_KEY);
        } else if (sCmd == "lock"){
            if (CheckLock(TRUE, kID)) {
                llMessageLinked(LINK_SET, NOTIFY, "0"+"Attachments are now Locked", kID);
                if (kID != g_kWearer) llMessageLinked(LINK_SET, NOTIFY, "0"+"Your Attachments are now Locked", g_kWearer);
            }
        } else if (sCmd == "unlock"){
            if (iNum != CMD_WEARER) {
                if (!CheckLock(FALSE, kID)) {
                    llMessageLinked(LINK_SET, NOTIFY, "0"+"Attachments are now Unlocked", kID);
                if (    kID != g_kWearer) llMessageLinked(LINK_SET, NOTIFY, "0"+"Your Attachments are now Unlocked", g_kWearer);
                }
            } else llMessageLinked(LINK_SET, NOTIFY, "0"+"%NOACCESS%", kID);
        } else if (sCmd != "") {
            string sRealPoseName = "";
            integer i;
            for (i=0; i<llGetListLength(g_lPoses);++i){
                list lPose = llParseString2List(llList2String(g_lPoses,i),["|"],[]);
                if (llList2String(lUCmd,2) != ""){
                    if (llToLower(llList2String(lPose,1)) == llToLower(sCmd)+" "+llToLower(llList2String(lUCmd,2))) sRealPoseName = llList2String(g_lPoses,i);
                } else if (llToLower(llList2String(lPose,1)) == llToLower(sCmd)) sRealPoseName = llList2String(g_lPoses,i);
            }
            if (sRealPoseName) doPose(sRealPoseName,iNum,kID);
            else llMessageLinked(LINK_SET, NOTIFY, "0"+"Pose '"+sCmd+"' is not registered!", kID);
        } else Menu(kID,iNum);
    }
}

integer IsTrue(string sInput) {
    if ((llToLower(sInput) == "y") || (llToLower(sInput) == "yes") || (llToLower(sInput) == "true") || (integer) sInput == 1) return TRUE;
    return FALSE;
}
//
//    ConfirmSync(global lock, cuff lock, synchronize indicator)
//
//    If synchronization is not active, do nothing (return immediately)
//    Otherwise, if the global (collar) lock matches the cuff lock, do nothing
//    Otherwise, if the global lock is set but the cuff lock is not, then:
//        RegionSay the message to tell the cuffs to lock themselves
//        Play the lock sound
//        Set the cuff lock indicator
//    Otherwise, if the global lock is not set, but the cuff lock is, then:
//        RegionSay the message to tell the cuffs to unlock themselves
//        Play the unlock sound
//        Unset the cuff lock indicator
//        
ConfirmSync(integer iGlobal, integer iCuffs, integer iSync) {
    if (!iSync) return;
    if (iGlobal && iCuffs) return;
    if (!iGlobal && !iCuffs) return;
    if (iGlobal) {
        llRegionSayTo(g_kWearer,g_iChan_ocCmd,(string)g_kWearer + ":lock"); //Lock our attachments**
        llPlaySound(g_sLockSound, 1.0);
    } else {
        llRegionSayTo(g_kWearer,g_iChan_ocCmd,(string)g_kWearer + ":unlock"); //Unlock our attachments**
        llPlaySound(g_sUnlockSound, 1.0);
    }
    g_bLocked = iGlobal;
    llMessageLinked(LINK_THIS, LM_SETTING_SAVE, "cuffs_lock=" + (string)iGlobal, NULL_KEY);
}

//
//    CheckSync(new sync status, requesting user)
//
//    if new sync status is same as old sync status, do nothing (return immediately)
//    otherwise (the new sync status differs from old sync status):
//        if the new sync status if "off":
//            set the sync status to "off"
//            update oc_settings sync status via LM_SETTING_SAVE
//        otherwise
//            if the collar lock status differs from the cuff lock status, issue error and return
//            otherwise,
//                set the sync status to "on"
//                update oc_settings sync status via LM_SETTING_SAVE
//
integer CheckSync(integer bEnable, key kUser) {
//    if (g_bDebugOn) DebugOutput(["CheckSync", g_bCollarLocked, g_bSyncLock, bEnable]);
    if (bEnable == g_bSyncLock) return g_bLocked;
    if (!bEnable) {
        g_bSyncLock = FALSE;
        llMessageLinked(LINK_THIS, LM_SETTING_SAVE, "cuffs_synclock=0", NULL_KEY);
        return FALSE;
    } else {
        if (g_bCollarLocked != g_bLocked) {
            llMessageLinked(LINK_SET, NOTIFY, "0"+"Attempt to change cuff synchronization but collar and cuffs locks do not match;.", g_kWearer);
            if (kUser != g_kWearer) llMessageLinked(LINK_SET, NOTIFY, "0"+"Attempt to change cuff synchronization but collar and cuffs locks do not match;.", kUser);
            return g_bSyncLock;
        } else {
            g_bSyncLock = TRUE;
            llMessageLinked(LINK_THIS, LM_SETTING_SAVE, "cuffs_synclock=1", NULL_KEY);
            return TRUE;
        }
    }
//    return g_bSyncLock;
}

//
//    CheckLock(new lock status, requesting user)
//
//    if new lock status is same as old lock status, do nothing (return immediately)
//    otherwise (the new lock status differs from old lock status):
//        if g_bSyncLock is set:
//            if the new lock status matches the global lock status:
//                set the old lock status to match the new lock status
//                update oc_settings cuff lock status via LM_SETTING_SAVE
//            otherwise, do nothing (global lock status overrides)
//        otherwise,
//            set the old lock status to match the new lock status
//            update oc_settings cuff lock status via LM_SETTING_SAVE
//
integer CheckLock(integer bEnable, key kUser) {
//    if (g_bDebugOn) DebugOutput(["CheckLock", g_bCollarLocked, g_bSyncLock, g_bLocked, bEnable]);
    if (bEnable == g_bLocked) return g_bLocked;
    if (g_bSyncLock) {
        if (bEnable == g_bCollarLocked) { 
            SetLock(bEnable);
            return g_bLocked;
        } else {
            string sMessage = "Attempt to change cuff lock but sync lock is set; try ";
            if (g_bCollarLocked) sMessage += "un";
            sMessage += "locking collar.";
            llMessageLinked(LINK_SET, NOTIFY, "0"+sMessage, g_kWearer);
            if (kUser != g_kWearer) llMessageLinked(LINK_SET, NOTIFY, "0"+"sMessage", kUser);
            return g_bLocked;
        }
    }
//    To reach here, new value differs from old value, and synclock is not set
    SetLock(bEnable);
    return g_bLocked;
}
//
//    SetLock(new lock status)
//
//    Not a lot of logic here - sets the cuff locks, plays the appropriate sound, saves the setting
//    Any "should I, shouldn't I" logic already happened somewhere else
//
SetLock(integer bStatus) {
    g_bLocked = bStatus;
    if (g_bLocked) {
        llRegionSayTo(g_kWearer,g_iChan_ocCmd,(string)g_kWearer + ":lock"); //Lock our attachments**
        llPlaySound(g_sLockSound, 1.0);
    } else {
        llRegionSayTo(g_kWearer,g_iChan_ocCmd,(string)g_kWearer + ":unlock"); //Unlock our attachments**
        llPlaySound(g_sUnlockSound, 1.0);
    }
    llMessageLinked(LINK_THIS, LM_SETTING_SAVE, "cuffs_lock=" + (string) bStatus, NULL_KEY);
}
//
//    InitSync()
//
//    Kill any existing timer event
//    Set the "ping in progress" flag
//    Set a 5 second timer (may need to increase this later, wait and see how bad chat lag is
//
InitSync() {
    llSetTimerEvent(0.0);
    g_bPingInProgress = TRUE;
    llSetTimerEvent(5.0);
}

BulkRequest() {
    if (g_bPingInProgress) {
        llSetTimerEvent(0.0);
        llSetTimerEvent(5.0);
        
    } else {
        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "cuffs_chaintex",g_kWearer);
        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "cuffs_synclock",g_kWearer);
        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "global_locked",g_kWearer);
        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "cuffs_poses",g_kWearer);
        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "cuffs_lock",g_kWearer);
        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "cuffs_hide",g_kWearer);
    }
}

HandleSettings(string sStr) {
    list lParams = llParseString2List(sStr, ["="], []); // now [0] = "major_minor" and [1] = "value"
    string sToken = llList2String(lParams, 0); // now SToken = "major_minor"
    string sValue = llList2String(lParams, 1); // now sValue = "value"
    integer i = llSubStringIndex(sToken, "_");
    string sTokenMajor = llToLower(llGetSubString(sToken, 0, i - 1));  // now sTokenMajor = "major"
    string sTokenMinor = llToLower(llGetSubString(sToken, i + 1, -1));  // now sTokenMinor = "minor"
    
    if (sTokenMajor == llToLower(g_sGlobalToken)) { // if "major_" = "global_"
        if (sTokenMinor == "locked") { 
            g_bCollarLocked = IsTrue(sValue);
            ConfirmSync(g_bCollarLocked, g_bLocked, g_bSyncLock);
        } else if (sTokenMinor == "checkboxes") {
                g_lCheckboxes=llCSV2List(sValue);
        }
    } else if (sTokenMajor == "cuffs") {
        if (sTokenMinor == "locked") {
            g_bLocked = IsTrue(sValue);
            ConfirmSync(g_bCollarLocked, g_bLocked, g_bSyncLock);
        } else if (sTokenMinor == "synclock") {
            g_bSyncLock = IsTrue(sValue);
            ConfirmSync(g_bCollarLocked, g_bLocked, g_bSyncLock);
        } else if (sTokenMinor == "poses") {
            llRegionSayTo(g_kWearer, g_iChan_ocCmd, (string)g_kWearer+":activeposes:"+sValue);
            g_lActivePoses = llParseString2List(sValue,[","],[]);
        } else if (sTokenMinor == "chaintex") {
            g_kTexture = sValue;
            llRegionSayTo(g_kWearer, g_iChan_OCChain, (string)g_kWearer+":chaintex:"+(string)g_kTexture);
            llMessageLinked(LINK_THIS,g_iChan_ocCmd,(string)g_kWearer+":chaintex:"+(string)g_kTexture,"");
        } else if (sTokenMinor == "hide") {
            g_bHidden = IsTrue(sValue);
            llRegionSayTo(g_kWearer, g_iChan_ocCmd, (string)g_kWearer+":hide:"+(string)g_bHidden);
        }
    } else {
//        integer h = llGetListLength(lParam);
//        string sMsg1a= llList2String(lParam, 0);
//        list lSettings = llParseString2List(sStr, ["_","="],[]);
        if (sToken == "anim_currentpose") {
            string sAnimName = llList2String(llParseString2List(sValue,[","],[]),0);
            integer iIndex = llListFindList(g_lCollarPoses,[sAnimName]);
            if (iIndex > -1) {
                llRegionSayTo(g_kWearer,g_iChan_OCChain,"clearchain:all");
                llMessageLinked(LINK_THIS,g_iChan_OCChain,"clearchain:all","");
                llRegionSayTo(g_kWearer,g_iChan_OCChain,"occhains:"+llList2String(g_lCollarPoses,iIndex+1));
                llMessageLinked(LINK_THIS,g_iChan_OCChain,"occhains:"+llList2String(g_lCollarPoses,iIndex+1),"");
                applyRLV(sAnimName);
                g_sCurrentCollarPose = sAnimName;
            } else {
                llRegionSayTo(g_kWearer,g_iChan_OCChain,"clearchain:all");
                applyRLV("");
                g_sCurrentCollarPose = "";
            }
        }
    }
}

HandleDeletes(string sStr) {
    list lParams = llParseString2List(sStr, ["_"], []); // now [0] = "major_minor" and [1] = "value"
    string sTokenMajor = llToLower(llList2String(lParams, 0)); // now STokenMajor = "major"
    string sTokenMinor = llToLower(llList2String(lParams, 1)); // now sTokenMinor = "minor"

    if (sTokenMajor == "global") {
        if (sTokenMinor == "locked") {
            g_bCollarLocked = FALSE;
            ConfirmSync(g_bCollarLocked, g_bLocked, g_bSyncLock);
        }
    } else if (sTokenMajor == "anim") {
        if (sTokenMinor == "currentpose") {
            llRegionSayTo(g_kWearer,g_iChan_OCChain,"clearchain:all");
            llMessageLinked(LINK_THIS,g_iChan_OCChain,"clearchain:all","");
            applyRLV("");
            g_sCurrentCollarPose = "";
        }
    }
}

string getCategoryPose(string sCategory)
{
    integer i;
    for (i=0;i<llGetListLength(g_lActivePoses);++i){
        list lPose = llParseString2List(llList2String(g_lActivePoses,i),["|"],[]);
        if (llList2String(lPose,0) == sCategory){
            return llList2String(g_lActivePoses,i);
        }
    }
    return "";
}

doClearAllPoses() {
    integer i;
    list lAPoses = g_lActivePoses;
    for (i=0;i<llGetListLength(lAPoses);++i){
        llRegionSayTo(g_kWearer, g_iChan_ocCmd, (string)g_kWearer+":clearpose:"+llList2String(lAPoses,i));
    }
    g_lActivePoses = [];
    llMessageLinked(LINK_THIS, LM_SETTING_SAVE, "cuffs_poses="+llDumpList2String(g_lActivePoses,","), NULL_KEY);
}


applyRLV(string sNewPose){
    integer iIndex = llListFindList(g_lCollarPoses,[g_sCurrentCollarPose]); // Remove old Restrictions
    if (iIndex > -1) {
            if (llList2String(g_lCollarPoses,iIndex+2) != ""){
            list lRestList = llParseString2List(llList2String(g_lCollarPoses,iIndex+2),[","],[]);
            list lRestrctions = [];
            integer i;
            for (i=0; i<llGetListLength(lRestList);++i){
                if (llList2String(lRestList,i) == "move"){
                    g_bMoveLock = FALSE;
                } else lRestrctions += [llList2String(lRestList,i)+"=y"];
            }
            llMessageLinked(LINK_SET,RLV_CMD,llDumpList2String(lRestrctions,","),"Collar Pose");
            llRequestPermissions(g_kWearer,PERMISSION_TAKE_CONTROLS);
        }
    }
    
    iIndex = llListFindList(g_lCollarPoses,[sNewPose]); // Add new restrictions
    if (iIndex > -1) {
        if (llList2String(g_lCollarPoses,iIndex+2) != ""){
            list lRestList = llParseString2List(llList2String(g_lCollarPoses,iIndex+2),[","],[]);
            list lRestrctions = [];
            integer i;
            for (i=0; i<llGetListLength(lRestList);++i){
                if (llList2String(lRestList,i) == "move"){
                    g_bMoveLock = TRUE;
                } else lRestrctions += [llList2String(lRestList,i)+"=n"];
            }
            llMessageLinked(LINK_SET,RLV_CMD,llDumpList2String(lRestrctions,","),"Collar Pose");
            llRequestPermissions(g_kWearer,PERMISSION_TAKE_CONTROLS);
        }
    }
}

doPose(string sPose, integer iAuth, key kID){
    string sCategory = llList2String(llParseString2List(sPose,["|"],[]),0);
    string sStopPose = getCategoryPose(sCategory);
    if (llGetListLength(g_lActivePoses) > 0 && iAuth == CMD_WEARER && sStopPose != "") llMessageLinked(LINK_SET, NOTIFY, "0"+"%NOACCESS%", kID);
        else {
            integer iActiveIndex = llListFindList(g_lActivePoses,[sPose]);
            if (iActiveIndex > -1) {
                llRegionSayTo(g_kWearer, g_iChan_ocCmd, (string)g_kWearer+":clearpose:"+sPose);
                g_lActivePoses = llDeleteSubList(g_lActivePoses,iActiveIndex,iActiveIndex);
                llMessageLinked(LINK_THIS, LM_SETTING_SAVE, "cuffs_poses="+llDumpList2String(g_lActivePoses,","), NULL_KEY);
            } else {
                if (sStopPose != "") {
                    llRegionSayTo(g_kWearer, g_iChan_ocCmd, (string)g_kWearer+":clearpose:"+sStopPose);
                    integer iStopPoseIndex = llListFindList(g_lActivePoses,[sStopPose]);
                    if (iStopPoseIndex > -1) g_lActivePoses = llDeleteSubList(g_lActivePoses,iStopPoseIndex,iStopPoseIndex);
                }
                g_lActivePoses += [sPose];
                llMessageLinked(LINK_THIS, LM_SETTING_SAVE, "cuffs_poses="+llDumpList2String(g_lActivePoses,","), NULL_KEY);
            }
            if (g_sCurrentCollarPose != "") { // Reapply current Collar pose Chains
                integer iIndex = llListFindList(g_lCollarPoses,[g_sCurrentCollarPose]);
                llRegionSayTo(g_kWearer,g_iChan_OCChain,"occhains:"+llList2String(g_lCollarPoses,iIndex+1));
                llMessageLinked(LINK_THIS,g_iChan_OCChain,"occhains:"+llList2String(g_lCollarPoses,iIndex+1),"");
            }
        }
}

default
{
    on_rez(integer t){
        llRegionSayTo(g_kWearer,g_iChan_ocCmd,(string)g_kWearer+":collarping");
        if(llGetOwner()!=g_kWearer) llResetScript();
    }
    state_entry()
    {
        if(llGetStartParameter()!=0)state inUpdate;
        integer iPrimNum = llGetNumberOfPrims();
        integer i;
        for (i=1; i<iPrimNum;++i) // turn off any existing particle systems
        {
            llLinkParticleSystem(i,[]);
        }
    
        g_kWearer = llGetOwner();
        g_iChan_ocCmd = (integer)("0x"+llGetSubString((string)g_kWearer,3,8)) + 0xCC0CC;
        if (g_iChan_ocCmd>0) g_iChan_ocCmd=g_iChan_ocCmd*(-1);
        if (g_iChan_ocCmd > -10000) g_iChan_ocCmd -= 30000;
        llListen(g_iChan_ocCmd,"",NULL_KEY,"");
        llListen(g_iChan_OCChain,"",NULL_KEY,"");
        llRegionSayTo(g_kWearer,g_iChan_ocCmd,(string)g_kWearer+":collarping");
        g_lCollarPoses = [];
        
        BulkRequest();
/*
        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "cuffs_chaintex",g_kWearer);
        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "cuffs_synclock",g_kWearer);
        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "global_locked",g_kWearer);
        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "cuffs_poses",g_kWearer);
        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "cuffs_lock",g_kWearer);
        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "cuffs_hide",g_kWearer);
*/       
        if (llGetInventoryType(g_sNCName) == INVENTORY_NOTECARD)
        {
            g_iNCLine = 0;
            g_kNCQuery = llGetNotecardLine(g_sNCName,g_iNCLine);
        } else llOwnerSay("ERROR: Notecard '"+g_sNCName+"' not found!");
    }
    
    run_time_permissions(integer iPerm){
        if (iPerm & PERMISSION_TAKE_CONTROLS){
            if (g_bMoveLock)llTakeControls(CONTROL_FWD|CONTROL_BACK|CONTROL_LEFT|CONTROL_RIGHT|CONTROL_ROT_LEFT|CONTROL_ROT_RIGHT|CONTROL_UP|CONTROL_DOWN,TRUE,FALSE);
            else llReleaseControls();
        }
    }
    
    dataserver(key kQuery, string sData){
        if (kQuery == g_kNCQuery) {
            if (sData != EOF) {
                if (llGetSubString(sData,0,0) != "#" && sData != "") {
                    list lAnim = llParseString2List(sData,[":"],[]);
                    string sCMD = llList2String(lAnim,0);
                    if (llToLower(sCMD) == "anim"){
                        if (llGetListLength(g_lSelectedPose) == 3) {
                            g_lCollarPoses += g_lSelectedPose;
                        }else if (llGetListLength(g_lSelectedPose) > 0) llOwnerSay("Error: pose '"+llList2String(lAnim,2)+"' is missing some parameters! Ignoring...");
                        g_lSelectedPose =[llList2String(lAnim,1)];
                    } else if (llToLower(sCMD) == "chains"){
                        g_lSelectedPose +=[llList2String(lAnim,1)];
                    } else if (llToLower(sCMD) == "restrictions"){
                        g_lSelectedPose +=[llList2String(lAnim,1)];
                    } else llOwnerSay("Syntax error: Unknown command '"+sCMD+"' at line "+(string)g_iNCLine);
                    
                }
                g_kNCQuery = llGetNotecardLine("Collar Pose",++g_iNCLine);
            } else {
            llOwnerSay("Finished Reading Notecard. "+(string)llGetFreeMemory()+"kb free.");
            }
        }
    }
    
    link_message(integer iSender,integer iNum,string sStr,key kID){
        if(iNum >= CMD_OWNER && iNum <= CMD_EVERYONE) UserCommand(iNum, sStr, kID);
        else if(iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
            llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu+"|"+ g_sSubMenu,"");
        else if(iNum == DIALOG_RESPONSE){
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if(iMenuIndex!=-1){
                string sMenu = llList2String(g_lMenuIDs, iMenuIndex+1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex-1, iMenuIndex-2+g_iMenuStride);
                list lMenuParams = llParseString2List(sStr, ["|"],[]);
                key kAv = llList2Key(lMenuParams,0);
                string sMsg = llList2String(lMenuParams,1);
                integer iAuth = llList2Integer(lMenuParams,3);
                
                if(sMenu == "Menu~Cuffs"){
                    if(sMsg == UPMENU) llMessageLinked(LINK_SET, iAuth, "menu "+g_sParentMenu, kAv);
                    else if (sMsg == "Settings") SettingsMenu(kAv,iAuth,sMsg);
                    else if (sMsg == g_sChecked+"Locked") { 
                        if (iAuth != CMD_WEARER) {
                            if (!CheckLock(FALSE, kAv)) {
                                llMessageLinked(LINK_SET, NOTIFY, "0"+"Attachments are now Unlocked", kAv);
                                llMessageLinked(LINK_SET, NOTIFY, "0"+"Your Attachments are now Unlocked", g_kWearer);
                            }
                        } else llMessageLinked(LINK_SET, NOTIFY, "0"+"%NOACCESS%", kAv);
                        Menu(kAv, iAuth);
                    } else if (sMsg == g_sUnChecked+"Locked") {
                        if (CheckLock(TRUE, kAv)) {
                            llMessageLinked(LINK_SET, NOTIFY, "0"+"Attachments are now Locked", kAv);
                            llMessageLinked(LINK_SET, NOTIFY, "0"+"Your Attachments are now Locked", g_kWearer);
                        }
                        Menu(kAv, iAuth);
                    } else if (sMsg == "Poses") PosesMenu(kAv,iAuth);
                    else if (sMsg == "Clear All") {
                        doClearAllPoses();
                        Menu(kAv, iAuth);
                    } else if (sMsg == "Devices") DeviceMenu(kAv,iAuth,"");
                } else if (sMenu == "Menu~DeviceList") {
                    if (sMsg == UPMENU) Menu(kAv,iAuth);
                    else DeviceMenu(kAv,iAuth,sMsg);
                } else if (sMenu == "Menu~CuffPoses") {
                    if (sMsg == UPMENU) Menu(kAv,iAuth);
                    else  AnimMenu(kAv,iAuth,sMsg);
                } else if (sMenu == "Menu~CuffSettings") {
                    if (sMsg == UPMENU) Menu(kAv,iAuth);
                    else if (sMsg == g_sChecked+"Hide") {
                        g_bHidden = FALSE;
                        llMessageLinked(LINK_THIS, LM_SETTING_SAVE, "cuffs_hide="+(string)g_bHidden, NULL_KEY);
                        SettingsMenu(kAv,iAuth,"Settings");
                    } else if (sMsg == g_sUnChecked+"Hide") {
                        g_bHidden = TRUE;
                        llMessageLinked(LINK_THIS, LM_SETTING_SAVE, "cuffs_hide="+(string)g_bHidden, NULL_KEY);
                        SettingsMenu(kAv,iAuth,"Settings");
                    } else if (sMsg == "Chains") SettingsMenu(kAv,iAuth,sMsg);
                    else if (sMsg == "Sync") SettingsMenu(kAv,iAuth,sMsg);
                    else if (sMsg == g_sChecked+"Sync Lock") {
                        CheckSync(FALSE, kAv);
                        SettingsMenu(kAv,iAuth,"Sync");
                    } else if (sMsg == g_sUnChecked+"Sync Lock") {
                        CheckSync(TRUE, kAv);
                        SettingsMenu(kAv,iAuth,"Sync");
                    } else if (sMsg == "ReSync Now"){
                        llRegionSayTo(g_kWearer,g_iChan_ocCmd,(string)g_kWearer+":collarping");
                        InitSync();
/*
                        llRegionSayTo(g_kWearer,g_iChan_ocCmd,(string)g_kWearer+":collarping");
                        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "cuffs_chaintex",g_kWearer);
                        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "cuffs_synclock",g_kWearer);
                        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "global_locked",g_kWearer);
                        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "cuffs_poses",g_kWearer);
                        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "cuffs_lock",g_kWearer);
                        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "cuffs_hide",g_kWearer);
*/
                        if (g_bRLV) llRegionSayTo(g_kWearer, g_iChan_ocCmd, (string)g_kWearer+":RLV:1");
                        else llRegionSayTo(g_kWearer, g_iChan_ocCmd, (string)g_kWearer+":RLV:0");
                         SettingsMenu(kAv,iAuth,"Sync");
                    } else if (sMsg == g_sUnChecked+"Chain") {
                        g_kTexture = g_kChainTexture;
                        llMessageLinked(LINK_THIS, LM_SETTING_SAVE, "cuffs_chaintex="+(string)g_kTexture, NULL_KEY);
                        SettingsMenu(kAv,iAuth,"Chains");
                    } else if (sMsg == g_sUnChecked+"Rope") {
                        g_kTexture = g_kRopeTexture;
                        llMessageLinked(LINK_THIS, LM_SETTING_SAVE, "cuffs_chaintex="+(string)g_kTexture, NULL_KEY);
                        SettingsMenu(kAv,iAuth,"Chains");
                    } else if (sMsg == g_sChecked+"Chain" || sMsg == g_sChecked+"Rope") SettingsMenu(kAv,iAuth,"Chains");
                } else {
                    string sMenuName = llList2String(llParseString2List(sMenu,["~"],[]),1);
                    integer iIndex = llListFindList(g_lDeviceMenu,[sMenuName+"|"+sMsg]);
                    if (iIndex > -1){
                        llRegionSayTo(g_kWearer, g_iChan_ocCmd, (string)g_kWearer+":devicemenu:"+sMenuName+"|"+sMsg);
                        DeviceMenu(kAv,iAuth,sMenuName);
                    } else {
                        if (sMsg == UPMENU) PosesMenu(kAv,iAuth);
                        else {
                            sMsg = llGetSubString(sMsg,1,-1);
                            list lMenuSplit = llParseString2List(sMenu,["~"],[]);
                            string sCategory = llList2String(lMenuSplit,1);
                            string sAnimation = sMsg;
                            doPose(sCategory+"|"+sAnimation,iAuth,kAv);
                            AnimMenu(kAv,iAuth,sCategory);
                        }
                    }
                }
            }
        } else if(iNum == -99999){
            if(sStr == "update_active")state inUpdate;
        } else if(iNum == LM_SETTING_RESPONSE){
            HandleSettings(sStr);
        } else if(iNum == LM_SETTING_DELETE){
            // This is received back from settings when a setting is deleted
            HandleDeletes(sStr);
        } else if (iNum == AUTH_REPLY){
            list lResponse = llParseString2List(sStr,["|"], []);
            if (llList2String(lResponse,0) == "AuthReply"){
                if ((string)kID =="cuffmenu" && llList2Integer(lResponse,2) <= CMD_EVERYONE) Menu(llList2Key(lResponse,1),llList2Integer(lResponse,2));
                else if (llList2Integer(lResponse,2) > CMD_EVERYONE) llMessageLinked(LINK_SET, NOTIFY, "0"+"%NOACCESS%", llList2Key(lResponse,1));
            }
        } else if (iNum == CMD_SAFEWORD || iNum == RLV_CLEAR) {
            doClearAllPoses();
        } else if (iNum == RLV_ON) {
            g_bRLV = TRUE;
             llRegionSayTo(g_kWearer, g_iChan_ocCmd, (string)g_kWearer+":RLV:1");
        } else if (iNum == RLV_OFF) {
            g_bRLV = FALSE;
             llRegionSayTo(g_kWearer, g_iChan_ocCmd, (string)g_kWearer+":RLV:0");
        } else if (iNum == LINK_CMD_RESTRICTIONS) {
            list lCMD = llParseString2List(sStr,["="],[]);
            llRegionSayTo(g_kWearer, g_iChan_ocCmd, (string)g_kWearer+":restriction:"+llList2String(lCMD,0)+"="+llList2String(lCMD,1));
        }
    }
    
    changed (integer iChange){
        if (iChange & CHANGED_INVENTORY) llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "anim_currentpose",g_kWearer); //llResetScript();
    }
    
    listen(integer iChan, string sName, key kID, string sMsg) {
        if (iChan == g_iChan_ocCmd){
            list lCMD = llParseString2List(sMsg,[":"],[]);
            key kCmdTarget = llList2Key(lCMD,0);
            if (kCmdTarget == g_kWearer) {
                string sCMD = llList2String(lCMD,1);
                string sParam = llList2String(lCMD,2);
                
                if (sCMD == "addpose") {
                    if (llListFindList(g_lPoses,[sParam]) == -1) g_lPoses += [sParam];
                } else if (sCMD == "remposes") {
                    list lPoseList = llParseString2List(sParam,[","],[]);
                    integer i;
                    for (i=0; i<llGetListLength(lPoseList);++i){
                        integer iDelIndex = llListFindList(g_lPoses,[llList2String(lPoseList,i)]);
                        if (iDelIndex > -1) g_lPoses = llDeleteSubList(g_lPoses,iDelIndex,iDelIndex);
                    }
                } else if (sCMD == "addmenu"){
                    if (llGetListLength(llParseString2List(sParam,["|"],[])) > 1) {
                        if (llListFindList(g_lDeviceMenu,[sParam]) == -1) g_lDeviceMenu += [sParam];
                    }
                } else if (sCMD == "remmenu"){
                    list lDeleteNames = [];
                    integer i;
                    for (i=0;i<llGetListLength(g_lDeviceMenu);i++){
                        list lMenu = llParseString2List(llList2String(g_lDeviceMenu,i),["|"],[]);
                        if (llList2String(lMenu,0) == sParam) {
                            lDeleteNames += [llList2String(g_lDeviceMenu,i)];
                        }
                    }
                    for (i=0; i<llGetListLength(lDeleteNames);i++){
                        integer iIndex = llListFindList(g_lDeviceMenu,[llList2String(lDeleteNames,i)]);
                        if (iIndex > -1) {
                            g_lDeviceMenu = llDeleteSubList(g_lDeviceMenu,iIndex,iIndex);
                        }
                    }
                } else if (sCMD == "rlvcmd") {
                    llMessageLinked(LINK_SET,RLV_CMD,llList2String(lCMD,3),sParam);
                } else if (sCMD == "ping") {
                    InitSync();
/*
                    llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "cuffs_synclock",g_kWearer);
                    llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "cuffs_chaintex",g_kWearer);
                    llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "global_locked",g_kWearer);
                    llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "cuffs_Poses",g_kWearer);
                    llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "cuffs_lock",g_kWearer);
                    llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "cuffs_hide",g_kWearer);
*/
                    if (g_bRLV) llRegionSayTo(g_kWearer, g_iChan_ocCmd, (string)g_kWearer+":RLV:1");
                    else llRegionSayTo(g_kWearer, g_iChan_ocCmd, (string)g_kWearer+":RLV:0");
                } else if (sCMD == "requestpose") {
                    if (llListFindList(g_lPoses,[sParam]) > -1) doPose(sParam,CMD_OWNER,NULL_KEY);
                } else if (sCMD == "menu") llMessageLinked(LINK_THIS,AUTH_REQUEST,"cuffmenu",(key)sParam); // Check auth before opening the Menu
            }
        }
    }
    
    timer() {
        llSetTimerEvent(0.0);
        g_bPingInProgress = FALSE;
        BulkRequest();
    }
}

state inUpdate{
    link_message(integer iSender, integer iNum, string sMsg, key kID){
        if(iNum == REBOOT)llResetScript();
    }
}
