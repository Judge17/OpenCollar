
//K-Bar curfew

string  g_sModule = "curfew";
list    g_lMenuIDs;
integer g_iMenuStride = 3;

//string  g_sSubMenu           = "TPLimits"; // Name of the submenu
//string  g_sParentMenu        = "Apps";     // name of the menu, where the menu plugs in
//string  g_sChatCommand       = "tplim";    // every menu should have a chat command
//string  BUTTON_PARENTMENU    = g_sParentMenu;
//key     g_kWebLookup;
string  KB_VERSIONMAJOR      = "7";
string  KB_VERSIONMINOR      = "5";
string  KB_DEVSTAGE          = "1";
string  g_sScriptVersion = "";
//integer LINK_CMD_DEBUG=1999;

//integer g_bDebugOn = FALSE;
//key     g_kDebugKey = NULL_KEY;
//key KURT_KEY   = "4986014c-2eaa-4c39-a423-04e1819b0fbf";
//key SILKIE_KEY = "1a828b4e-6345-4bb3-8d41-f93e6621ba25";

//DebugOutput(integer iLevel, list ITEMS) {
//    if (g_iDebugLevel > iLevel) return;
DebugOutput(list ITEMS) {
    ++g_iDebugCounter;
    integer i=0;
    integer end=llGetListLength(ITEMS);
    string final;
    for(i=0;i<end;i++){
        final+=llList2String(ITEMS,i)+" ";
    }
    llSay(KB_DEBUG_CHANNEL, llGetScriptName() + " " + (string) g_iDebugCounter + " " + final);
//    llOwnerSay(llGetScriptName() + " " + (string) g_iDebugCounter + " " + final);
}

integer g_bDebugOn = FALSE;
integer g_iDebugLevel = 10;
integer KB_DEBUG_CHANNEL           = -617783;
integer g_iDebugCounter = 0;
/*
SetDebugOn(key kID) {
    g_bDebugOn = TRUE;
    g_iDebugLevel = 0;
    g_iDebugCounter = 0;
    llMessageLinked(LINK_SET,NOTIFY,"0"+"TP debug active.", kID);
}

SetDebugOff(key kID) {
    g_bDebugOn = FALSE;
    g_iDebugLevel = 10;
    llMessageLinked(LINK_SET,NOTIFY,"0"+"TP debug inactive.", kID);
}
*/
integer g_iRLVOn         = FALSE; //Assume RLV is off until we hear otherwise

key     g_kWearer = NULL_KEY;       // key of the current wearer to reset only on owner changes

string  g_sScript;                  // part of script name used for settings
//integer g_iKBarOptions=0;
//integer g_iGirlStatus=0; // 0=guest, 1=protected, 2=slave
list    g_lPairs = [];

integer CMD_OWNER = 500;
integer CMD_TRUSTED = 501;
//integer CMD_WEARER = 503;

integer NOTIFY              = 1002;

integer LM_SETTING_SAVE     = 2000;
integer LM_SETTING_REQUEST  = 2001;
integer LM_SETTING_RESPONSE = 2002;
integer LM_SETTING_DELETE   = 2003;

//integer MENUNAME_REQUEST    = 3000;
//integer MENUNAME_RESPONSE   = 3001;

//integer DIALOG = -9000;
//integer DIALOG_RESPONSE = -9001;
//integer DIALOG_TIMEOUT = -9002;

integer RLV_OFF      = 6100;
integer RLV_ON       = 6101;
/*
integer KB_NOTICE_LEASHED          = -34691;
integer KB_NOTICE_UNLEASHED        = -34692;
integer KB_SET_REGION_NAME         = -34693;
integer KB_REM_REGION_NAME         = -34694;
integer KB_REQUEST_VERSION         = -34591;
integer    KB_CURFEW_NOTICE           = -34852;

string UPMENU = "BACK";

string  ACTIVATE   = "Activate";
string  DEACTIVATE = "Deactivate";
string  FORCERESET = "ForceReset";
string  DEBUGON = "DebugOn";
string  DEBUGOFF = "DebugOff";
string  CURFEWON = "CurfewOn";
string  CURFEWOFF = "CurfewOff";
string  SETSTART = "Start Time";
string  SETSTOP = " End Time";
*/
//
//    Start of common block
//

integer g_iCurfewActive = FALSE;
integer g_iLeashedRank = 0;
key     g_kLeashedTo   = NULL_KEY;
//integer g_iChecking = 0;
list    g_lCurfew = [0, 0, 0, 0];
//integer g_iCurfewStart = 0; // hour * 100 + minute
//integer g_iCurfewEnd = 0; // as above
//
//    End of common block
//
integer g_iSecondsBeforeBoot = 0;

integer bool(integer a){
    if(a)return TRUE;
    else return FALSE;
}
/*
integer CurfewHour(list lCurfew) {
    integer i = llList2Integer(lCurfew, 0);
    return i;
}

integer CurfewMinute(list lCurfew) {
    integer i = llList2Integer(lCurfew, 1);
    return i;
}

string FormatCurfew(list lCurfew, integer bStart) {
    list lTemp = ["FormatCurfew", "***"];
    lTemp += lCurfew;
    lTemp += ["***", bStart];
    if (g_bDebugOn) DebugOutput(lTemp);
    integer i = 0;
    if (!bStart) i = 2;
    string s1 = llList2String(g_lCurfew, i);
    string s2 = llList2String(g_lCurfew, i + 1);
    s1 = llStringTrim(s1, STRING_TRIM);
    while (llStringLength(s1) < 2) {
        s1 = "0" + s1;
    }
    s2 = llStringTrim(s2, STRING_TRIM);
    while (llStringLength(s2) < 2) {
        s2 = "0" + s2;
    }
    return s1 + s2;
}
*/

/////////////////////////////////////////////////////////////////////
// Script Library Contribution by Flennan Roffo
// Logic Scripted Products & Script Services
// Peacock Park (183,226,69)
// (c) 2007 - Flennan Roffo
//
// Distributed as GPL, donated to wiki.secondlife.com on 19 sep 2007
//
// SCRIPT:  Unix2DateTimev1.0.lsl
//
// FUNCTION: 
// Perform conversion from return value of llGetUnixTime() to
// date and time strings and vice versa.
//
// USAGE:
// list timelist=Unix2DateTime(llGetUnixTime());
// llSay(PUBLIC_CHANNEL, "Date: " +  DateString(timelist); // displays date as DD-MON-YYYY
// llSay(PUBLIC_CHANNEL, "Time: " +  TimeString(timelist); // displays time as HH24:MI:SS
/////////////////////////////////////////////////////////////////////
 
///////////////////////////// Unix Time conversion //////////////////
 
integer DAYS_PER_YEAR        = 365;           // Non leap year
integer SECONDS_PER_YEAR     = 31536000;      // Non leap year
integer SECONDS_PER_DAY      = 86400;
integer SECONDS_PER_HOUR     = 3600;
integer SECONDS_PER_MINUTE   = 60;
 
list MonthNameList = [  "JAN", "FEB", "MAR", "APR", "MAY", "JUN", 
                        "JUL", "AUG", "SEP", "OCT", "NOV", "DEC" ];
 
// This leap year test works for all years from 1901 to 2099 (yes, including 2000)
// Which is more than enough for UnixTime computations, which only operate over the range [1970, 2038].  (Omei Qunhua)
integer LeapYear( integer year)
{
    return !(year & 3);
}
 
integer DaysPerMonth(integer year, integer month)
{
    // Compact Days-Per-Month algorithm. Omei Qunhua.
    if (month == 2)      return 28 + LeapYear(year);
    return 30 + ( (month + (month > 7) ) & 1);           // Odd months up to July, and even months after July, have 31 days
}
 
integer DaysPerYear(integer year)
{
    return 365 + LeapYear(year);
}
 
///////////////////////////////////////////////////////////////////////////////////////
// Convert Unix time (integer) to a Date and Time string
///////////////////////////////////////////////////////////////////////////////////////
 
/////////////////////////////// Unix2DataTime() ///////////////////////////////////////
 
list Unix2DateTime(integer unixtime)
{
    integer days_since_1_1_1970     = unixtime / SECONDS_PER_DAY;
    integer day = days_since_1_1_1970 + 1;
    integer year  = 1970;
    integer days_per_year = DaysPerYear(year);
 
    while (day > days_per_year)
    {
        day -= days_per_year;
        ++year;
        days_per_year = DaysPerYear(year);
    }
 
    integer month = 1;
    integer days_per_month = DaysPerMonth(year, month);
 
    while (day > days_per_month)
    {
        day -= days_per_month;
 
        if (++month > 12)
        {    
            ++year;
            month = 1;
        }
 
        days_per_month = DaysPerMonth(year, month);
    }
 
    integer seconds_since_midnight  = unixtime % SECONDS_PER_DAY;
    integer hour        = seconds_since_midnight / SECONDS_PER_HOUR;
    integer second      = seconds_since_midnight % SECONDS_PER_HOUR;
    integer minute      = second / SECONDS_PER_MINUTE;
    second              = second % SECONDS_PER_MINUTE;
 
    return [ year, month, day, hour, minute, second ];
}
 
///////////////////////////////// MonthName() ////////////////////////////
 
string MonthName(integer month)
{
    if (month >= 0 && month < 12)
        return llList2String(MonthNameList, month);
    else
        return "";
}
 
///////////////////////////////// DateString() ///////////////////////////
 
string DateString(list timelist)
{
    integer year       = llList2Integer(timelist,0);
    integer month      = llList2Integer(timelist,1);
    integer day        = llList2Integer(timelist,2);
 
    return (string)day + "-" + MonthName(month - 1) + "-" + (string)year;
}
 
///////////////////////////////// TimeString() ////////////////////////////
 
string TimeString(list timelist)
{
    string  hourstr     = llGetSubString ( (string) (100 + llList2Integer(timelist, 3) ), -2, -1);
    string  minutestr   = llGetSubString ( (string) (100 + llList2Integer(timelist, 4) ), -2, -1);
    string  secondstr   = llGetSubString ( (string) (100 + llList2Integer(timelist, 5) ), -2, -1);
    return  hourstr + ":" + minutestr + ":" + secondstr;
}
 
///////////////////////////////////////////////////////////////////////////////
// Convert a date and time to a Unix time integer
///////////////////////////////////////////////////////////////////////////////
 
////////////////////////// DateTime2Unix() ////////////////////////////////////
 
integer DateTime2Unix(integer year, integer month, integer day, integer hour, integer minute, integer second)
{
    integer time = 0;
    integer yr = 1970;
    integer mt = 1;
    integer days;
 
    while(yr < year)
    {
        days = DaysPerYear(yr++);
        time += days * SECONDS_PER_DAY;
    }
 
    while (mt < month)
    {
        days = DaysPerMonth(year, mt++);
        time += days * SECONDS_PER_DAY;
    }
 
    days = day - 1;
    time += days * SECONDS_PER_DAY;
    time += hour * SECONDS_PER_HOUR;
    time += minute * SECONDS_PER_MINUTE;
    time += second;
 
    return time;
}

integer Unix2PST_PDT(integer insecs)
{
    if (Convert(insecs - (3600 * 8))) return insecs - (3600 * 8);
    return insecs - (3600 * 7);
}

integer Convert(integer insecs)
{
    integer bPST = TRUE;
    integer w; integer month; integer daysinyear;
    integer mins = insecs / 60;
    integer secs = insecs % 60;
    integer hours = mins / 60;
    mins = mins % 60;
    integer days = hours / 24;
    hours = hours % 24;
    integer DayOfWeek = (days + 4) % 7;    // 0=Sun thru 6=Sat
 
    integer years = 1970 +  4 * (days / 1461);
    days = days % 1461;                  // number of days into a 4-year cycle
 
    @loop;
    daysinyear = 365 + LeapYear(years);
    if (days >= daysinyear)
    {
        days -= daysinyear;
        ++years;
        jump loop;
    }
    ++days;
 
    for (w = month = 0; days > w; )
    {
        days -= w;
        w = DaysPerMonth(years, ++month);
    }
//    string str =  ((string) years + "-" + llGetSubString ("0" + (string) month, -2, -1) + "-" + llGetSubString ("0" + (string) days, -2, -1) + " " +
//    llGetSubString ("0" + (string) hours, -2, -1) + ":" + llGetSubString ("0" + (string) mins, -2, -1) );
 
    integer LastSunday = days - DayOfWeek;
    string PST_PDT = " PST";                  // start by assuming Pacific Standard Time
    // Up to 2006, PDT is from the first Sunday in April to the last Sunday in October
    // After 2006, PDT is from the 2nd Sunday in March to the first Sunday in November
    if (years > 2006 && month == 3  && LastSunday >  7)     bPST = FALSE;
    if (month > 3)                                          bPST = FALSE;
    if (month > 10)                                         bPST = TRUE;
    if (years < 2007 && month == 10 && LastSunday > 24)     bPST = TRUE;
    return bPST;
}

//////////////////////////////////////////////
// End Unix2DateTimev1.0.lsl
//////////////////////////////////////////////

/*
// Returns a list that is a Unix time code converted to the format [Y, M, D, h, m, s]

list uUnix2StampLst( integer vIntDat ){
    if (vIntDat / 2145916800){
        vIntDat = 2145916800 * (1 | vIntDat >> 31);
    }
    integer vIntYrs = 1970 + ((((vIntDat %= 126230400) >> 31) + vIntDat / 126230400) << 2);
    vIntDat -= 126230400 * (vIntDat >> 31);
    integer vIntDys = vIntDat / 86400;
    list vLstRtn = [vIntDat % 86400 / 3600, vIntDat % 3600 / 60, vIntDat % 60];
 
    if (789 == vIntDys){
        vIntYrs += 2;
        vIntDat = 2;
        vIntDys = 29;
    }else{
        vIntYrs += (vIntDys -= (vIntDys > 789)) / 365;
        vIntDys %= 365;
        vIntDys += vIntDat = 1;
        integer vIntTmp;
        while (vIntDys > (vIntTmp = (30 | (vIntDat & 1) ^ (vIntDat > 7)) - ((vIntDat == 2) << 1))){
            ++vIntDat;
            vIntDys -= vIntTmp;
        }
    }
    return [vIntYrs, vIntDat, vIntDys] + vLstRtn;
}
///--                       Anti-License Text                         --///
///     Contributed Freely to the Public Domain without limitation.     ///
///   2009 (CC0) [ http://creativecommons.org/publicdomain/zero/1.0 ]   ///
///  Void Singer [ https://wiki.secondlife.com/wiki/User:Void_Singer ]  ///
///--
*/
/*
list g_lCheckboxes=["⬜","⬛"];
string Checkbox(integer iValue, string sLabel) {
    return llList2String(g_lCheckboxes, bool(iValue))+" "+sLabel;
}

list    PLUGIN_BUTTONS = [];

list    g_lButtons;

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) //we've alread given a menu to this user.  overwrite their entry
        g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
    else //we've not already given this user a menu. append to list
        g_lMenuIDs += [kID, kMenuID, sName];
}

InitPluginButtons() {
    PLUGIN_BUTTONS = [ACTIVATE, DEACTIVATE, DEBUGON, DEBUGOFF];
    string sWork = Checkbox(FALSE,"Active");
    PLUGIN_BUTTONS += [sWork];
    sWork = Checkbox(TRUE,"Active");
    PLUGIN_BUTTONS += [sWork];
}

DoCurfewMenu(key keyID, integer iAuth, integer iOption) {
    if (keyID == NULL_KEY) { return; }
    if (iOption == 1)
        Dialog(keyID, FormatMenuMessage(2), [], [], 0, iAuth, "Textbox~Start");
    else if (iOption == 2)
        Dialog(keyID, FormatMenuMessage(3), [], [], 0, iAuth, "Textbox~Stop");
}

string FormatMenuMessage(integer iOption) {
    string s1;
    string s2;
    string s3;
    string s4;
    string s5;
    
    string sPrompt = "";

    if (g_iActive) {
        s2 = "Restrictions engaged; ";
    } else {
        s2 = "No restrictions; ";
    }
    
    if (g_iCurfewActive) {
        s2 += "Curfew active, start:" + FormatCurfew(g_lCurfew, TRUE) + "; end:" + FormatCurfew(g_lCurfew, FALSE) + "\n";
    } else {
        s2 += "No curfew set\n";
    }
    
    s3 = "Leashed level: " + (string) g_iLeashedRank + "\n"; 
    s4 = llGetScriptName() + " " + (string) llGetFreeMemory() + " bytes free\n";
    s1 = "Approved regions:" + llList2CSV(dumpRegions()) + "\n";
    s5 = "Version " + KB_VERSIONMAJOR + "." + KB_VERSIONMINOR + "." + KB_DEVSTAGE + "\n";

    sPrompt += "\nThis is a K-Bar plugin; for support, wire roan (Silkie Sabra), K-Bar Ranch.\n";

    if (iOption == 1) sPrompt += s1 + s2 + s3 + s4 + s5 + "\nPick an option.";
    else if (iOption == 2) sPrompt += s1 + s2 + s3 + s4 + s5 + "\nSet curfew start (24-hour SL time).";
    else if (iOption == 3) sPrompt += s1 + s2 + s3 + s4 + s5 + "\nSet curfew end (24-hour SL time).";

    return sPrompt;
}

DoMenu(key keyID, integer iAuth) {
    if (keyID == NULL_KEY) { return; }

    list lButtons = [];

    lButtons += Checkbox(g_iActive, "Active");
    
    lButtons += Checkbox(g_iCurfewActive, "Curfew");
    
    if (g_iCurfewActive) lButtons += [SETSTART, SETSTOP];
    
    if ((keyID == KURT_KEY) || ((keyID == SILKIE_KEY) && (g_kWearer != keyID))) {
        lButtons += Checkbox(g_bDebugOn, "Debug");
    }

    Dialog(keyID, FormatMenuMessage(1), lButtons, [UPMENU], 0, iAuth, "mainmenu");
}

UserCommand(integer iNum, string sStr, key kID) {
    if (g_bDebugOn) { DebugOutput(["UserCommand", iNum, sStr, kID]); }
    if(!(iNum >= CMD_OWNER && iNum <= CMD_WEARER)) return;
    // a validated command from a owner, secowner, groupmember or the wearer has been received
    list lParams = llParseString2List(sStr, [" "], []);
    //string sCommand = llToLower(llList2String(lParams, 0));
    //string sValue = llToLower(llList2String(lParams, 1));
    // So commands can accept a value
    if(sStr == g_sChatCommand || sStr == "menu " + g_sSubMenu) {
        // an authorized user requested the plugin menu by typing the menus chat command
        DoMenu(kID, iNum);
    }
    else if ((llGetSubString(sStr, 0, llStringLength(g_sChatCommand + " " + ACTIVATE) - 1) == g_sChatCommand + " " + ACTIVATE) || (sStr == Checkbox(TRUE, "Active"))) {
        if (iNum==CMD_OWNER) {
            g_iActive = TRUE;
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, "KBTP_engaged=y", "");
            llMessageLinked(LINK_SET,NOTIFY,"0"+"TP restrictions active.", kID);
        } else {
            llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS% to activate limits",kID);
        }
        DoMenu(kID, iNum);
    }
    else if ((llGetSubString(sStr, 0, llStringLength(g_sChatCommand + " " + DEACTIVATE) - 1) == g_sChatCommand + " " + DEACTIVATE) || (sStr == Checkbox(FALSE, "Active"))) {
        if (iNum == CMD_OWNER) {
            g_iActive = FALSE;
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, "KBTP_engaged=n", "");
            llMessageLinked(LINK_SET,NOTIFY,"0"+"TP restrictions inactive.", kID);
        } else {
            llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS% to deactivate limits", kID);
        }
        DoMenu(kID, iNum);
    }
    else if ((llGetSubString(sStr, 0, llStringLength(g_sChatCommand + " " + CURFEWON) - 1) == g_sChatCommand + " " + CURFEWON) || (sStr == Checkbox(TRUE, "Curfew"))) {
        if (iNum==CMD_OWNER) {
            g_iCurfewActive = TRUE;
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, "KBTP_curfew=y", "");
            llMessageLinked(LINK_SET,NOTIFY,"0"+"Curfew active.", kID);
        } else {
            llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS% to activate curfew",kID);
        }
        DoMenu(kID, iNum);
    }
    else if ((llGetSubString(sStr, 0, llStringLength(g_sChatCommand + " " + CURFEWOFF) - 1) == g_sChatCommand + " " + CURFEWOFF) || (sStr == Checkbox(FALSE, "Curfew"))) {
        if (iNum == CMD_OWNER) {
            g_iCurfewActive = FALSE;
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, "KBTP_curfew=n", "");
            llMessageLinked(LINK_SET,NOTIFY,"0"+"Curfew inactive.", kID);
        } else {
            llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS% to deactivate curfew", kID);
        }
        DoMenu(kID, iNum);
    }
    else if ((llGetSubString(sStr, 0, llStringLength(g_sChatCommand + " " + DEBUGON) - 1) == g_sChatCommand + " " + DEBUGON) || (sStr == Checkbox(TRUE, "Debug"))) {
        if ((kID == KURT_KEY) || ((kID == SILKIE_KEY) && (g_kWearer != kID))) {
            SetDebugOn(kID);
        } else {
            llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS% to activate TP debug",kID);
        }
        DoMenu(kID, iNum);
    }
    else if ((llGetSubString(sStr, 0, llStringLength(g_sChatCommand + " " + DEBUGOFF) - 1) == g_sChatCommand + " " + DEBUGOFF) || (sStr == Checkbox(FALSE, "Debug"))) {
        if ((kID == KURT_KEY) || ((kID == SILKIE_KEY) && (g_kWearer != kID))) {
            SetDebugOff(kID);
        } else {
            llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS% to deactivate TP debug", kID);
        }
        DoMenu(kID, iNum);
    } else if ((llGetSubString(sStr, 0, llStringLength(g_sChatCommand + " " + SETSTART) - 1) == g_sChatCommand + " " + SETSTART) || (sStr == SETSTART)) {
        if (iNum == CMD_OWNER) {
            DoCurfewMenu(kID, iNum, 1);
        } else {
            llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS% to deactivate TP debug", kID);
            DoMenu(kID, iNum);
        }
    }

    else if(llGetSubString(sStr, 0, llStringLength(g_sChatCommand + " " + FORCERESET) - 1) == g_sChatCommand + " " + FORCERESET) {
        checkMemory(TRUE);

}
*/
/*
list dumpRegions() {
    integer iIdx = 0;
    integer iLen = llGetListLength(g_lPairs);
    list lRet = [];
    for (iIdx = 0; iIdx < iLen; ++iIdx) {
        string sEntry = llList2String(g_lPairs, iIdx);
        list lEntry = llParseString2List(sEntry, ["~"], []);
        string sEntryName = llList2String(lEntry, 1);
        if (llListFindList(lRet, [sEntryName]) < 0) {
            lRet += [sEntryName];
        }
    }
    return lRet;
}
*/
addOccurrence(string sName, string sRegion) {
    if (g_bDebugOn) { DebugOutput(["addOccurrence ", sName, sRegion]); }
    string sWork = llToLower(sName);
    if ((sName == "home") || (sName == "defaulthome")) {
        string sEntry = sName + "~" + sRegion;
        integer iIdx = llListFindList(g_lPairs, [sEntry]);
        if (iIdx < 0) {
            g_lPairs += [sEntry];
        }
    }
}

deleteOccurence(string sName) {
    integer iIdx = findOccurrence(sName);
    if (iIdx >= 0) {
        g_lPairs = llDeleteSubList(g_lPairs, iIdx, iIdx);
    }
}

integer findOccurrence(string sName) {
    if (g_bDebugOn) { DebugOutput(["findOccurrence ", sName]); }
    integer iIdx = 0;
    integer iLen = llGetListLength(g_lPairs);
    for (iIdx = 0; iIdx < iLen; ++iIdx) {
        string sEntry = llList2String(g_lPairs, iIdx);
        if (g_bDebugOn) { DebugOutput(["findOccurrence entry ", sEntry]); }
        list lEntry = llParseString2List(sEntry, ["~"], []);
        string sEntryName = llList2String(lEntry, 0);
        if (sEntryName == sName) {
            if (g_bDebugOn) { DebugOutput(["findOccurrence returned ", iIdx]); }
            return iIdx;
        }
    }
    if (g_bDebugOn) { DebugOutput(["findOccurrence returned -1"]); }
    return -1;
}

integer findRegion(string sName) {
    integer iIdx = 0;
    integer iLen = llGetListLength(g_lPairs);
    for (iIdx = 0; iIdx < iLen; ++iIdx) {
        string sEntry = llList2String(g_lPairs, iIdx);
        list lEntry = llParseString2List(sEntry, ["~"], []);
        string sEntryName = llList2String(lEntry, 1);
        if (sEntryName == sName) { if (g_bDebugOn) { DebugOutput(["findRegion returning TRUE"]); } return TRUE; }
    }
    if (g_bDebugOn) { DebugOutput(["findRegion returning FALSE"]); }
    return FALSE;
}

parseSettings(integer iSender, integer iNum, string sStr, key kID) {
    // response from setting store have been received
    // parse the answer
    
    list lParams = llParseString2List(sStr, ["="], []); // now [0] = "major_minor" and [1] = "value"
    string sToken = llList2String(lParams, 0); // now SToken = "major_minor"
    string sValue = llList2String(lParams, 1); // now sValue = "value"
    integer i = llSubStringIndex(sToken, "_");
    string sTokenMajor = llToLower(llGetSubString(sToken, 0, i - 1));  // now sTokenMajor = "major"
    string sTokenMinor = "";
    if (i > 0 ) sTokenMinor = llToLower(llGetSubString(sToken, i + 1, -1));  // now sTokenMinor = "minor"
    if (g_bDebugOn) { DebugOutput(["parseSettings", iNum, sStr, sTokenMajor, sTokenMinor, sValue]); }
    if (iNum == LM_SETTING_RESPONSE) {
        if (sTokenMajor == "bookmarks") {
            if (g_bDebugOn) { DebugOutput([sTokenMajor, " ", sValue]); }
            list lparts = llParseString2List(sValue, ["("], [""]);
            string sRegion = llStringTrim(llList2String(lparts, 0), STRING_TRIM);
            addOccurrence(sTokenMinor, sRegion);
        }
        else if(sTokenMajor == "kbtp") {
            if (sTokenMinor == "curfew")  {
//                if (g_bDebugOn) { DebugOutput([sToken, " ", sValue]); }
                if ((sValue == "y") || (sValue == "Y")) {
                    g_iCurfewActive = TRUE;
                    KickOff();
                } else {
                    g_iCurfewActive = FALSE;
                    llSetTimerEvent(0.0);
                }
            } else if (sTokenMinor == "curfewtimes") {
                g_lCurfew = llCSV2List(sValue);
                KickOff();
            }
        } 
        else if (sTokenMajor == "leash") {
            if (sTokenMinor = "leashedto") {
                list lLeashed = llParseString2List(sValue, [","], []);
                if (g_bDebugOn) { list lTemp = ["saving settings", sTokenMajor, sTokenMinor] + lLeashed; DebugOutput(lTemp); }
                if (llList2Integer(lLeashed, 1) > 0) {
                    g_kLeashedTo = llList2Key(lLeashed, 0); 
                    g_iLeashedRank = llList2Integer(lLeashed, 1);
//                    checkStatus(TRUE);
                }
            }
        }
    }
    else if (iNum == LM_SETTING_DELETE) {
        if (sTokenMajor == "leash") {
            if (sTokenMinor = "leashedto") {
            if (g_bDebugOn) { DebugOutput(["Delete ", sToken]); }
                g_kLeashedTo = NULL_KEY; 
                g_iLeashedRank = 0; 
//                checkStatus(TRUE);
            }
        } else if (sTokenMajor == "kbtp") {
            if (sTokenMinor == "curfew")  {
                g_iCurfewActive = FALSE;
                llSetTimerEvent(0.0);
            } else if (sTokenMinor == "curfewtimes"){
                g_lCurfew = llCSV2List(sValue);
            }
        } else if (sTokenMajor == "bookmarks") { 
            list lparts = llParseString2List(sValue, ["_"], [""]);
            string sRegion = llStringTrim(llList2String(lparts, 1), STRING_TRIM);
            deleteOccurence(sRegion);
        }
    }
}

integer RegOK(string sRegion) {
    return findRegion(sRegion);
}

integer LeashOK() {
    if (g_bDebugOn) { DebugOutput(["LeashOK ", "g_kLeashedTo " + (string) g_kLeashedTo]); }
    if (g_kLeashedTo != NULL_KEY) {
        if (g_bDebugOn) { DebugOutput(["LeashOK ", "g_iLeashedRank " + (string) g_iLeashedRank]); }
        if ((g_iLeashedRank == CMD_OWNER) || (g_iLeashedRank == CMD_TRUSTED)) {  return TRUE; }
    }
    return FALSE;
}

integer checkOK(integer bFirstTime, string sRegion) {

/*
    checkOK is an extension of checkStatus. It handles the actual logic to decide whether the wearer is
        allowed in the region currently occupied
*/

    llSetTimerEvent(0.0);
    if (g_bDebugOn) { DebugOutput(["checkOK ", "g_iCurfewActive " + (string) g_iCurfewActive]); }
    if (!g_iCurfewActive) return TRUE;
    if (LeashOK()) return TRUE;
    if (RegOK(sRegion)) return TRUE;
    if ((findOccurrence("Home") >= 0) ||
        (findOccurrence("home") >= 0) ||
        (findOccurrence("DefaultHome") >= 0) ||
        (findOccurrence("defaulthome") >= 0)) {
            if (g_bDebugOn) { 
                DebugOutput(["checkOK ", 
                "g_iSecondsBeforeBoot " + (string) g_iSecondsBeforeBoot,
                "bFirstTime " + (string) bFirstTime]); 
            }
            if (bFirstTime) {
                g_iSecondsBeforeBoot = 30;
                llSetTimerEvent(5.0);
            }
    } else {
        llMessageLinked(LINK_SET,NOTIFY,"0"+"DefaultHome and Home bookmarks both missing.", g_kWearer);
    }
    return FALSE;
/*    
    llMessageLinked(LINK_SET,NOTIFY,"0"+"you are not allowed in this region unless you are leashed.", g_kWearer);
    if (findOccurrence("Home") >= 0) {
        llMessageLinked(LINK_THIS, CMD_OWNER, "tp Home", g_kWearer);
    } 
    else if (findOccurrence("home") >= 0) {
        llMessageLinked(LINK_THIS, CMD_OWNER, "tp home", g_kWearer);
    }
    else if (findOccurrence("DefaultHome") >= 0) {
        llMessageLinked(LINK_THIS, CMD_OWNER, "tp DefaultHome", g_kWearer);
    }
    else if (findOccurrence("defaulthome") >= 0) {
        llMessageLinked(LINK_THIS, CMD_OWNER, "tp defaulthome", g_kWearer);
    } else {
        llMessageLinked(LINK_SET,NOTIFY,"0"+"DefaultHome and Home bookmarks both missing.", g_kWearer);
    }
*/
}

checkMemory(integer iForce) {
    if (iForce) {
        llMessageLinked(LINK_SET,NOTIFY,"0"+"kbtplim is resetting due to forced input.", g_kWearer);
        llResetScript();
    } else {
        if (llGetFreeMemory() < 6000) {
            llMessageLinked(LINK_SET,NOTIFY,"0"+"kbtplim is resetting due to minimum available memory.", g_kWearer);
            llResetScript();
        }
    }
}

integer checkStatus(integer bFirstTime) {
/*
    checkOK is an extension of checkStatus. It handles the actual logic to decide whether the wearer is
        allowed in the region currently occupied
*/
//    g_iChecking = 1;
    
    if (bFirstTime) {
        g_iSecondsBeforeBoot = 0;
        llSetTimerEvent(0.0);
    }
    if (checkOK(bFirstTime, llGetRegionName())) {
        if (g_bDebugOn) { DebugOutput(["checkStatus returning TRUE"]); }
        return TRUE;
    } else {
        if (g_bDebugOn) { DebugOutput(["checkStatus returning FALSE"]); }
        return FALSE;
    }
}

/*
NotifyCurfew() {
    string sPackage = llList2Json(JSON_OBJECT, ["msgid", "curfew_data", 
            "start_hour", llList2Integer(g_lCurfew, 0),
            "start_minute", llList2Integer(g_lCurfew, 1),
            "stop_hour", llList2Integer(g_lCurfew, 2),
            "stop_minute", llList2Integer(g_lCurfew, 3),
            "curfew_active", g_iCurfewActive]);
    llMessageLinked(LINK_ALL_OTHERS, KB_CURFEW_NOTICE, sPackage, "");
}
*/
/*
HandleMenus(key kID, string sStr, integer iNum) {
    integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
    if (iMenuIndex != -1) {
        list lMenuParams = llParseStringKeepNulls(sStr, ["|"], []);
        key kAv = (key)llList2String(lMenuParams, 0); // avatar using the menu
        string sMessage = llList2String(lMenuParams, 1); // button la
        integer iPage = (integer)llList2String(lMenuParams, 2); // menu page
        integer iAuth = (integer)llList2String(lMenuParams, 3); // auth level of avatar
        list lParams =  llParseStringKeepNulls(sStr, ["|"], []);
        string sMenuType = llList2String(g_lMenuIDs, iMenuIndex + 1);
        g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
        if (g_bDebugOn) { DebugOutput(["HandleMenus", iNum, sStr, kID, kAv, sMessage, iPage, iAuth, sMenuType]); }
        if (sMenuType == "mainmenu") {
            if (sMessage == UPMENU)
                llMessageLinked(LINK_ROOT, iAuth, "menu "+BUTTON_PARENTMENU, kAv);
            else if (sMessage == ACTIVATE) {
                UserCommand(iAuth, g_sChatCommand + " " + ACTIVATE, kAv);
            } else if(sMessage == DEACTIVATE) {
                UserCommand(iAuth, g_sChatCommand + " " + DEACTIVATE, kAv);
            } else if(sMessage == FORCERESET) {
                UserCommand(iAuth, g_sChatCommand + " " + FORCERESET, kAv);
            } else if(sMessage == DEBUGON) {
                UserCommand(iAuth, g_sChatCommand + " " + DEBUGON, kAv);
            } else if(sMessage == DEBUGOFF) {
                UserCommand(iAuth, g_sChatCommand + " " + DEBUGOFF, kAv);
            } else if(sMessage == Checkbox(FALSE,"Active")) {
                UserCommand(iAuth, g_sChatCommand + " " + ACTIVATE, kAv);
            } else if(sMessage == Checkbox(TRUE,"Active")) {
                UserCommand(iAuth, g_sChatCommand + " " + DEACTIVATE, kAv);
            } else if(sMessage == Checkbox(FALSE,"Debug")) {
                UserCommand(iAuth, g_sChatCommand + " " + DEBUGON, kAv);
            } else if(sMessage == Checkbox(TRUE,"Debug")) {
                UserCommand(iAuth, g_sChatCommand + " " + DEBUGOFF, kAv);
            } else if(sMessage == Checkbox(FALSE,"Curfew")) {
                UserCommand(iAuth, g_sChatCommand + " " + CURFEWON, kAv);
            } else if(sMessage == Checkbox(TRUE,"Curfew")) {
                UserCommand(iAuth, g_sChatCommand + " " + CURFEWOFF, kAv);
            } else if(sMessage == SETSTART) {
                UserCommand(iAuth, g_sChatCommand + " " + SETSTART, kAv);
            } else if(sMessage == SETSTOP) {
                UserCommand(iAuth, g_sChatCommand + " " + SETSTOP, kAv);
            }
        } else if (sMenuType == "Textbox~Start") {
            integer i = (integer) sMessage;
            integer j = i / 100;
            integer k = i % 100;
            g_lCurfew = llListReplaceList(g_lCurfew, [j, k], 0, 1);
            if (g_bDebugOn) { list lList = ["Textbox~Start", i, j, k, "***"] + g_lCurfew; DebugOutput(lList); }
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, "KBTP_curfewtimes=" + llList2CSV(g_lCurfew), "");
            DoCurfewMenu(kAv, iAuth, 2);
        } else if (sMenuType == "Textbox~Stop") {
            integer i = (integer) sMessage;
            integer j = i / 100;
            integer k = i % 100;
            g_lCurfew = llListReplaceList(g_lCurfew, [j, k], 2, 3);
            if (g_bDebugOn) { list lList = ["Textbox~Start", i, j, k, "***"] + g_lCurfew; DebugOutput(lList); }
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, "KBTP_curfewtimes=" + llList2CSV(g_lCurfew), "");
            DoMenu(kAv, iAuth);
        }
    }
}
*/

KickOff() {
    llSetTimerEvent(0.0);
    integer iTimeNow = Unix2PST_PDT(llGetUnixTime());
    list lTimeNow = Unix2DateTime(iTimeNow);
    if (g_bDebugOn) { list lTemp = ["Kickoff 0"] + lTimeNow; DebugOutput(lTemp); }
    list lStart = [llList2Integer(lTimeNow, 0), llList2Integer(lTimeNow, 1), llList2Integer(lTimeNow, 2), 
        llList2Integer(g_lCurfew, 0), llList2Integer(g_lCurfew, 1) ,0];
    list lStop = [llList2Integer(lTimeNow, 0), llList2Integer(lTimeNow, 1), llList2Integer(lTimeNow, 2), 
        llList2Integer(g_lCurfew, 2), llList2Integer(g_lCurfew, 3) ,0];
    if (g_bDebugOn) { list lTemp = ["Kickoff 1"] + lStart; DebugOutput(lTemp); }
    if (g_bDebugOn) { list lTemp = ["Kickoff 2"] + lStop; DebugOutput(lTemp); }
    
    integer iCurfewStart = DateTime2Unix(llList2Integer(lTimeNow, 0), llList2Integer(lTimeNow, 1), llList2Integer(lTimeNow, 2), 
        llList2Integer(g_lCurfew, 0), llList2Integer(g_lCurfew, 1) ,0);
    integer iCurfewStop = DateTime2Unix(llList2Integer(lTimeNow, 0), llList2Integer(lTimeNow, 1), llList2Integer(lTimeNow, 2), 
        llList2Integer(g_lCurfew, 2), llList2Integer(g_lCurfew, 3) ,0);
    if (g_bDebugOn) { DebugOutput(["Kickoff3", iCurfewStart, iTimeNow, iCurfewStop]); }
    if (iCurfewStop < iCurfewStart) iCurfewStop += 86400;
    if (g_bDebugOn) { DebugOutput(["Kickoff4", iCurfewStart, iTimeNow, iCurfewStop]); }
    if (iTimeNow >= iCurfewStart && iTimeNow <= iCurfewStop) {
        llSetTimerEvent(5.0);
        return;
    } else {
        integer iDelay = iCurfewStop - iTimeNow;
        if (iDelay <= 0) {
            llSetTimerEvent(5.0);
            return;
        } else {
            float fDelay = (float) iDelay;
            llSetTimerEvent(fDelay);
        }
    }
}

default  {
    changed(integer iChange) {
        if(iChange & CHANGED_OWNER) { llResetScript(); }
    }

    state_entry() {
        g_sScript = llStringTrim(llList2String(llParseString2List(llGetScriptName(), ["-"], []), 1), STRING_TRIM) + "_";
        g_sScriptVersion = KB_VERSIONMAJOR + "." + KB_VERSIONMINOR + "." + KB_DEVSTAGE;
        // store key of wearer
        g_kWearer = llGetOwner();
        // sleep a second to allow all scripts to be initialized
        llSleep(1.5);
        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "bookmarks", "");
        if (g_iCurfewActive) KickOff();
    }

    on_rez(integer iParam) {
        if (g_bDebugOn) { DebugOutput(["on_rez ", "wearer ",  g_kWearer]); }
        if(llGetOwner() != g_kWearer) {
        // Reset if wearer changed
            llResetScript();
        }
        if (g_iCurfewActive) KickOff();
    }

    // listen for linked messages from OC scripts
    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if(iNum == RLV_OFF) { // rlvoff -> we have to turn the menu off too
            g_iRLVOn = FALSE;
        }
        else if(iNum == RLV_ON) { // rlvon -> we have to turn the menu on again
            g_iRLVOn = TRUE;
        }
        else if(iNum == LM_SETTING_RESPONSE) {
            parseSettings(iSender, iNum, sStr, kID);
        }
        else if(iNum == LM_SETTING_DELETE) {
            parseSettings(iSender, iNum, sStr, kID);
        }
    }
    
    timer() {
        llSetTimerEvent(0.0);
        if (g_bDebugOn) { DebugOutput(["timer ", "seconds left " + (string) g_iSecondsBeforeBoot]); }
        string sMsg = "";
        if (checkStatus(FALSE)) {
            llMessageLinked(LINK_SET,NOTIFY,"0"+"removal aborted.", g_kWearer);
            g_iSecondsBeforeBoot = 0;
        } else {
            if (g_iSecondsBeforeBoot > 0) {
//                if (g_iChecking == 1)
//                    sMsg = "you are not allowed in this region unless you are leashed. you have " + (string) g_iSecondsBeforeBoot + " seconds left.";
//                if (g_iChecking == 2)
                sMsg = "you are not allowed out after curfew. you have " + (string) g_iSecondsBeforeBoot + " seconds left.";
                g_iSecondsBeforeBoot -= 5;
                llMessageLinked(LINK_SET,NOTIFY,"0"+sMsg, g_kWearer);
                llSetTimerEvent(5.0);
            } else {
                llSetTimerEvent(0.0);
//                g_iChecking = 0;
                if (findOccurrence("Home") >= 0) {
                    llMessageLinked(LINK_THIS, CMD_OWNER, "tp Home", g_kWearer);
                } else if (findOccurrence("home") >= 0) {
                    llMessageLinked(LINK_THIS, CMD_OWNER, "tp home", g_kWearer);
                } else if (findOccurrence("DefaultHome") >= 0) {
                    llMessageLinked(LINK_THIS, CMD_OWNER, "tp DefaultHome", g_kWearer);
                } else if (findOccurrence("defaulthome") >= 0) {
                    llMessageLinked(LINK_THIS, CMD_OWNER, "tp defaulthome", g_kWearer);
                } else { llMessageLinked(LINK_SET,NOTIFY,"0"+"TP home failed.", g_kWearer);
                }
            }
        }
    }
}

// kb_curfew
