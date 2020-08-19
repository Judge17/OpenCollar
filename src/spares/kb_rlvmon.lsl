
key         g_kWearer;
string      g_sWearerName;
string      g_sWearer;
key         KURT_KEY   = "4986014c-2eaa-4c39-a423-04e1819b0fbf";
integer     g_iRLVChan = 22;
integer     g_iRLVListen = 0;

integer LINK_AUTH             = 2;
integer LINK_DIALOG         = 3;
integer LINK_RLV             = 4;
integer LINK_SAVE             = 5;
integer LINK_UPDATE         = -10;
integer NOTIFY              = 1002;


integer LM_SETTING_RESPONSE = 2002;

/*
string SplitToken(string sIn, integer iSlot) {
    integer i = llSubStringIndex(sIn, "_");
    if (!iSlot) return llGetSubString(sIn, 0, i - 1);
    return llGetSubString(sIn, i + 1, -1);
}


integer GroupIndex(list lCache, string sToken) {
    string sGroup = SplitToken(sToken, 0);
    integer i = llGetListLength(lCache) - 1;
    
    for (; ~i ; i -= 2) {
        if (SplitToken(llList2String(lCache, i - 1), 0) == sGroup) return i + 1;
    }
    return -1;
}

list SetSetting(list lCache, string sToken, string sValue) {
    integer idx = llListFindList(lCache, [sToken]);
    if (~idx) return llListReplaceList(lCache, [sValue], idx + 1, idx + 1);
    idx = GroupIndex(lCache, sToken);
    if (~idx) return llListInsertList(lCache, [sToken, sValue], idx);
    return lCache + [sToken, sValue];
}

SendValues() {
    
    

    integer n = 0;
    string sToken = "";
    list lOut = [];
    for (; n < llGetListLength(g_lSettings); n += 2) {
        sToken = llList2String(g_lSettings, n) + "=";
        sToken += llList2String(g_lSettings, n + 1);
        if (llListFindList(lOut, [sToken]) == -1) lOut += [sToken];
    }
    n = 0;
    for (; n < llGetListLength(lOut); n++) {
        llMessageLinked(LINK_ALL_OTHERS, LM_SETTING_RESPONSE, llList2String(lOut, n), "");

    }
}



ReadLimits(string sName, key kID) {
    string sURL;
    key kAv;
    sURL = g_sURL1 + sName + "40" + g_sURL2;
    g_sWearer = sName;


    g_kURLLoadRequest = kID;
    g_kLoadFromWeb = llHTTPRequest(sURL, [HTTP_METHOD, "GET", HTTP_VERBOSE_THROTTLE, FALSE], "");

}

 $touchme$detach$detach$detach$detach$detach$detach

[08:46:09] OpenCollar: kb_rlvmon received  $touchme$detach$detach$detach$detach$detach$startim$startim:e55c511b-bcd7-4103-bc95-1ccef72ea021$sendchat$redirchat:3$rediremote:3$detach$detach

16:56:05] OpenCollar: kb_rlvmon received  
[16:56:40] OpenCollar: kb_rlvmon received  /detach=n
[16:56:40] Stealth Gag: You are gagged: Incoherent
[16:56:40] OpenCollar: kb_rlvmon received  /unsit=y
[16:56:40] OpenCollar: kb_rlvmon received  /tplure=y
[16:56:40] OpenCollar: kb_rlvmon received  /tploc=y
[16:56:41] OpenCollar: kb_rlvmon received  /tplm=y
[16:56:41] OpenCollar: kb_rlvmon received  /showworldmap=y
[16:56:41] OpenCollar: kb_rlvmon received  /showminimap=y
[16:56:41] OpenCollar: kb_rlvmon received  /showinv=y
[16:56:42] OpenCollar: kb_rlvmon received  /rez=y
[16:56:42] OpenCollar: kb_rlvmon received  /edit=y
[16:56:42] OpenCollar: kb_rlvmon received  /viewnote=y
[16:56:42] OpenCollar: kb_rlvmon received  /addoutfit=y
[16:56:42] OpenCollar: kb_rlvmon received  /remoutfit=y
[16:56:43] OpenCollar: kb_rlvmon received  /sit=y
[16:56:43] OpenCollar: kb_rlvmon received  /fartouch=y
[16:56:43] OpenCollar: kb_rlvmon received  /tplm=y
[16:56:43] OpenCollar: kb_rlvmon received  /tplur=y
[16:56:44] OpenCollar: kb_rlvmon received  /tploc=y
[16:56:44] OpenCollar: kb_rlvmon received  /sendim=y
[16:56:44] OpenCollar: kb_rlvmon received  /sendim:e55c511b-bcd7-4103-bc95-1ccef72ea021=rem
[16:56:44] OpenCollar: kb_rlvmon received  /recvim=y
[16:56:45] OpenCollar: kb_rlvmon received  /recvim:e55c511b-bcd7-4103-bc95-1ccef72ea021=rem
[16:56:45] OpenCollar: kb_rlvmon received  /startim=n
[16:56:45] OpenCollar: kb_rlvmon received  /startim:e55c511b-bcd7-4103-bc95-1ccef72ea021=add
[16:56:46] OpenCollar: kb_rlvmon received  /sendchat=n   <----------------------------------------------------
[16:56:46] OpenCollar: kb_rlvmon received  /redirchat:3=add   <-----------------------------------------------
[16:56:46] OpenCollar: kb_rlvmon received  /emote=rem   <-----------------------------------------------------
[16:56:46] OpenCollar: kb_rlvmon received  /rediremote:3=add   <----------------------------------------------
[16:56:46] OpenCollar: kb_rlvmon received  /rediremote:102050607=rem   <--------------------------------------
[16:56:47] OpenCollar: kb_rlvmon received  /recvchat=y
[16:56:47] OpenCollar: kb_rlvmon received  /showhovertextall=y
[16:56:47] OpenCollar: kb_rlvmon received  /showworldmap=y
[16:56:47] OpenCollar: kb_rlvmon received  /showminimap=y
[16:56:47] OpenCollar: kb_rlvmon received  /showloc=y
[16:56:48] OpenCollar: kb_rlvmon received  /unsit=y
[16:56:48] OpenCollar: kb_rlvmon received  /tplure=y
[16:56:48] OpenCollar: kb_rlvmon received  /tploc=y
[16:56:48] OpenCollar: kb_rlvmon received  /tplm=y
[16:56:48] OpenCollar: kb_rlvmon received  /showworldmap=y
[16:56:48] OpenCollar: kb_rlvmon received  /showminimap=y
[16:56:49] OpenCollar: kb_rlvmon received  /showinv=y
[16:56:49] OpenCollar: kb_rlvmon received  /rez=y
[16:56:49] OpenCollar: kb_rlvmon received  /edit=y
[16:56:50] OpenCollar: kb_rlvmon received  /viewnote=y
[16:56:50] OpenCollar: kb_rlvmon received  /addoutfit=y
[16:56:50] OpenCollar: kb_rlvmon received  /remoutfit=y
[16:56:50] OpenCollar: kb_rlvmon received  /sit=y
[16:56:50] OpenCollar: kb_rlvmon received  /fartouch=y
[16:56:50] OpenCollar: kb_rlvmon received  /sendim=y
[16:56:50] OpenCollar: kb_rlvmon received  /sendim:e55c511b-bcd7-4103-bc95-1ccef72ea021=rem
[16:56:51] OpenCollar: kb_rlvmon received  /recvim=y
[16:56:51] OpenCollar: kb_rlvmon received  /recvim:e55c511b-bcd7-4103-bc95-1ccef72ea021=rem
[16:56:51] OpenCollar: kb_rlvmon received  /startim=n
[16:56:51] OpenCollar: kb_rlvmon received  /startim:e55c511b-bcd7-4103-bc95-1ccef72ea021=add
[16:56:51] OpenCollar: kb_rlvmon received  /sendchat=n
[16:56:51] OpenCollar: kb_rlvmon received  /redirchat:3=add
[16:56:51] OpenCollar: kb_rlvmon received  /emote=rem
[16:56:52] OpenCollar: kb_rlvmon received  /rediremote:3=add
[16:56:52] OpenCollar: kb_rlvmon received  /rediremote:102050607=rem
[16:56:52] OpenCollar: kb_rlvmon received  /recvchat=y
[16:56:52] OpenCollar: kb_rlvmon received  /showhovertextall=y
[16:56:52] OpenCollar: kb_rlvmon received  /showworldmap=y
[16:56:52] OpenCollar: kb_rlvmon received  /showminimap=y
[16:56:52] OpenCollar: kb_rlvmon received  /showloc=y
[16:56:53] OpenCollar: kb_rlvmon received  /sendim=y
[16:56:53] OpenCollar: kb_rlvmon received  /sendim:e55c511b-bcd7-4103-bc95-1ccef72ea021=rem
[16:56:53] OpenCollar: kb_rlvmon received  /recvim=y
[16:56:53] OpenCollar: kb_rlvmon received  /recvim:e55c511b-bcd7-4103-bc95-1ccef72ea021=rem
[16:56:53] OpenCollar: kb_rlvmon received  /startim=n
[16:56:53] OpenCollar: kb_rlvmon received  /startim:e55c511b-bcd7-4103-bc95-1ccef72ea021=add
[16:56:53] OpenCollar: kb_rlvmon received  /sendchat=n
[16:56:54] OpenCollar: kb_rlvmon received  /redirchat:3=add
[16:56:54] OpenCollar: kb_rlvmon received  /emote=rem
[16:56:54] OpenCollar: kb_rlvmon received  /rediremote:3=add
[16:56:54] OpenCollar: kb_rlvmon received  /rediremote:102050607=rem
[16:56:54] OpenCollar: kb_rlvmon received  /recvchat=y
[16:56:54] OpenCollar: kb_rlvmon received  /showhovertextall=y
[16:56:54] OpenCollar: kb_rlvmon received  /showworldmap=y
[16:56:55] OpenCollar: kb_rlvmon received  /showminimap=y
[16:56:55] OpenCollar: kb_rlvmon received  /showloc=y
[16:57:01] Stealth Gag: Your gag is removed
[16:57:01] OpenCollar: kb_rlvmon received  /clear
[16:57:01] OpenCollar: kb_rlvmon received  /unsit=y
[16:57:01] OpenCollar: kb_rlvmon received  /tplure=y
[16:57:02] OpenCollar: kb_rlvmon received  /tploc=y
[16:57:02] OpenCollar: kb_rlvmon received  /tplm=y
[16:57:02] OpenCollar: kb_rlvmon received  /showworldmap=y
[16:57:02] OpenCollar: kb_rlvmon received  /showminimap=y
[16:57:02] OpenCollar: kb_rlvmon received  /showinv=y
[16:57:03] OpenCollar: kb_rlvmon received  /rez=y
[16:57:03] OpenCollar: kb_rlvmon received  /edit=y
[16:57:03] OpenCollar: kb_rlvmon received  /viewnote=y
[16:57:03] OpenCollar: kb_rlvmon received  /addoutfit=y
[16:57:03] OpenCollar: kb_rlvmon received  /remoutfit=y
[16:57:04] OpenCollar: kb_rlvmon received  /sit=y
[16:57:04] OpenCollar: kb_rlvmon received  /fartouch=y
[16:57:04] OpenCollar: kb_rlvmon received  /unsit=y
[16:57:04] OpenCollar: kb_rlvmon received  /tplure=y
[16:57:04] OpenCollar: kb_rlvmon received  /tploc=y
[16:57:05] OpenCollar: kb_rlvmon received  /tplm=y
[16:57:05] OpenCollar: kb_rlvmon received  /showworldmap=y
[16:57:05] OpenCollar: kb_rlvmon received  /showminimap=y
[16:57:05] OpenCollar: kb_rlvmon received  /showinv=y
[16:57:05] OpenCollar: kb_rlvmon received  /rez=y
[16:57:07] OpenCollar: kb_rlvmon received  /edit=y
[16:57:08] OpenCollar: kb_rlvmon received  /viewnote=y
[16:57:08] OpenCollar: kb_rlvmon received  /addoutfit=y
[16:57:08] OpenCollar: kb_rlvmon received  /remoutfit=y
[16:57:08] OpenCollar: kb_rlvmon received  /sit=y
[16:57:08] OpenCollar: kb_rlvmon received  /fartouch=y
[16:57:08] OpenCollar: kb_rlvmon received  /tplm=y
[16:57:09] OpenCollar: kb_rlvmon received  /tplur=y
[16:57:09] OpenCollar: kb_rlvmon received  /tploc=y
[16:57:09] OpenCollar: kb_rlvmon received  /unsit=y
[16:57:09] OpenCollar: kb_rlvmon received  /tplure=y
[16:57:09] OpenCollar: kb_rlvmon received  /tploc=y
[16:57:10] OpenCollar: kb_rlvmon received  /tplm=y
[16:57:10] OpenCollar: kb_rlvmon received  /showworldmap=y
[16:57:11] OpenCollar: kb_rlvmon received  /showminimap=y
[16:57:11] OpenCollar: kb_rlvmon received  /showinv=y
[16:57:11] OpenCollar: kb_rlvmon received  /rez=y
[16:57:11] OpenCollar: kb_rlvmon received  /edit=y
[16:57:11] OpenCollar: kb_rlvmon received  /viewnote=y
[16:57:11] OpenCollar: kb_rlvmon received  /addoutfit=y
[16:57:12] OpenCollar: kb_rlvmon received  /remoutfit=y
[16:57:12] OpenCollar: kb_rlvmon received  /sit=y
[16:57:12] OpenCollar: kb_rlvmon received  /fartouch=y
[16:57:12] OpenCollar: kb_rlvmon received  /clear
[16:57:12] OpenCollar: kb_rlvmon received  /clear
*/

list ParseRestr(string sRestr) {
    list lRestr = llParseString2List(sRestr, ["$"], []);
    list lChat = [];
    integer i = 0;
    integer j = llGetListLength(lRestr);
    integer k = 0;
    for (i = 0; i < j; ++i) {
        string sWork = llList2String(lRestr, i);
        integer l = llSubStringIndex(sWork,":");
        if (l >= 0) {
            string sLeft = llGetSubString(sWork, 0, l - 1);
            string sRight = llGetSubString(sWork, l + 1, -1);
            if (sLeft == "redirchat" || sLeft == "rediremote") {
                lChat += [llGetSubString(sWork, 0, l - 1)];
                lChat += [llGetSubString(sWork, l + 1, -1)];
            }
        }
    }
    return lChat;
}
default
{
    on_rez(integer iT) {
        llOwnerSay(llGetScriptName()+" on_rez");
        llResetScript();
    }
    
    state_entry() {
        llSay(0, llGetScriptName()+" "+(string)llGetFreeMemory()+" bytes free");
        g_kWearer = llGetOwner();
        g_sWearerName = llToLower(llKey2Name(g_kWearer));
        list lName = llParseString2List(g_sWearerName, [" "], [""]);
        g_sWearerName = llList2String(lName, 0) + llList2String(lName, 1);
        g_iRLVListen = llListen(g_iRLVChan, "", "", "");
        llSleep(30.0);
        llOwnerSay("@versionnew=" + (string) g_iRLVChan);
        string sCmd = "getstatus:;#=" + (string) g_iRLVChan;
        llOwnerSay(llGetScriptName()+" "+sCmd);
        llOwnerSay("@"+sCmd);
        sCmd = "getstatusall:;$=" + (string) g_iRLVChan;
        llOwnerSay(llGetScriptName()+" "+sCmd);
        llOwnerSay("@"+sCmd);
        sCmd = "getinv:=" + (string) g_iRLVChan;
        llOwnerSay(llGetScriptName()+" "+sCmd);
        llOwnerSay("@"+sCmd);
        sCmd = "notify:" + (string) g_iRLVChan + "=add";
        llOwnerSay(llGetScriptName()+" "+sCmd);
        llOwnerSay("@"+sCmd);
    }
    
    listen(integer iChannel, string sWho, key kID, string sMsg) {
        llOwnerSay(llGetScriptName() + " received  " + sMsg);
        string sInd = llGetSubString(sMsg, 0, 0);
        if (sInd == "$") {
            llOwnerSay("current restriction string " + sMsg);
            list lRestr = ParseRestr(sMsg);
            if (llGetListLength(lRestr) > 0) llOwnerSay("chat restrictions"); else llOwnerSay("no chat restrictions");
        }
        else if (sInd == "/") {
            llOwnerSay("changed restriction");
            string sChg = llGetSubString(sMsg, 1, -1);
            list lParts = llParseString2List(sChg,[":="],[""]);
        }
    }
    
    link_message(integer iSender,integer iNum,string sStr,key kID) {
        
        if(iNum == LINK_UPDATE) {
            if(sStr == "LINK_AUTH") LINK_AUTH=iSender;
            if(sStr == "LINK_DIALOG") LINK_DIALOG=iSender;
            if(sStr == "LINK_RLV") LINK_RLV=iSender;
            if(sStr == "LINK_SAVE") LINK_SAVE = iSender;
        }
    }    
}

