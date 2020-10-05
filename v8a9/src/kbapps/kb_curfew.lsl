//K-Bar curfew

//
//    "Curfew" is a period each day when an avatar must be at a specified home point (initially, home sim, to be
//        made more specific when proximity is implemented
//
//    The period has a start and stop time specified as HH mm, where HH is the 24-hour start or stop time, with mm being the
//        minutes. The start time (HHmm-s) and the end time (HHmm-e) are entered and stored separately, in the tplimits menu
//
//    If HHmm-s is lower than HHmm-e, they are assumed to be in the same 24-hour day. Curfew is enforced during the period
//        from HHmm-s to HHmm-e (case 1)
//
//    If HHmm-s is larger than HHMM-e, HHmm-s is assumed to occur in 24-hour period 1 (D1) and HHmm-e is assumed to occur 
//        in the following 24-hour period (D2). Curfew is enforced from HHmm-s through 2359 on D1, and from 0000 through 
//        HHmm-2 on D2 (case 2)
//
//    At state_entry or on_rez, the correct HHmm-s and HHmm-e for the current day are calculated. (InitCalcs, via a
//        CURFEW_SETUP alarm)
//    Then, the current date/time is checked against either case 1 or case 2, whichever is appropriate. (inCurfewNow)
//    If the current date/time is within the curfew enforcement period, final checks are made (CheckStatus)
//    If no exemption exists, removal to the home point is started. (case 3)
//
//    On region change, the same test is run, but the initial calculations are not, having been done already at state_entry
//        or on_rez
//
//    Upon receipt of curfew times via SETTINGS_RESPONSE, the same test is run, but the initial calculations are as well;
//        state_entry and on_rez will already have passsed, and the curfew times may not have been set at that point
//
//    If the above test fails, a link message is sent to kb_clock setting an alarm for HHmm-s
//
//    If an alarm is received from kb_clock, the test described in case 3 is tried
//

string  g_sModule = "curfew";
string  KB_VERSIONMAJOR      = "7";
string  KB_VERSIONMINOR      = "5";
string  KB_DEVSTAGE          = "14";
string  g_sScriptVersion = "";

string formatVersion() {
    return KB_VERSIONMAJOR + "." + KB_VERSIONMINOR + "." + KB_DEVSTAGE;
}

DebugOutput(list ITEMS) {
    ++g_iDebugCounter;
    integer i=0;
    integer end=llGetListLength(ITEMS);
    string final;
    for(i=0;i<end;i++){
        final+=llList2String(ITEMS,i)+" ";
    }
    llSay(KB_DEBUG_CHANNEL, llGetScriptName() + " " + formatVersion() + " " + (string) g_iDebugCounter + " " + final);
    if (g_iDebugCounter > 9999) SetDebugOff(); // safety check
}

SetDebugOn() {
    g_bDebugOn = TRUE;
    g_iDebugLevel = 0;
    g_iDebugCounter = 0;
}

SetDebugOff() {
    g_bDebugOn = FALSE;
    g_iDebugLevel = 10;
}

integer g_bDebugOn = FALSE;
integer g_iDebugLevel = 10;
integer KB_DEBUG_CHANNEL           = -617783;
integer g_iDebugCounter = 0;

integer g_iRLVOn         = FALSE; //Assume RLV is off until we hear otherwise

key     g_kWearer = NULL_KEY;       // key of the current wearer to reset only on owner changes

string  g_sScript;                  // part of script name used for settings

list    g_lPairs = [];

integer CMD_OWNER = 500;
integer CMD_TRUSTED = 501;

integer NOTIFY              = 1002;

integer LM_SETTING_SAVE     = 2000;
integer LM_SETTING_REQUEST  = 2001;
integer LM_SETTING_RESPONSE = 2002;
integer LM_SETTING_DELETE   = 2003;

integer RLV_OFF      = 6100;
integer RLV_ON       = 6101;

integer KB_CLOCK_SET			   = -34843;
integer KB_CLOCK_ALARM			   = -34844;
integer KB_CURFEW_ACTIVE		   = -34845;
integer KB_CURFEW_INACTIVE		   = -34846;
integer KB_DEBUG_CURFEW_ON		   = -36003;
integer KB_DEBUG_CURFEW_OFF		   = -36004;

string	KB_CLOCK_NODUP			   = "nodup";

string  CURFEW_SETUP = "curfew_setup";
string  CURFEW_ALARM = "curfew_alarm";

//
//    Start of common block
//

integer g_iCurfewActive = FALSE;
integer g_iLeashedRank = 0;
key     g_kLeashedTo   = NULL_KEY;
list    g_lCurfew = [0, 0, 0, 0];
integer g_bRemovalInProgress = FALSE;
integer g_iTimerService = 0;
//        1 = removal;
//        2 = status check
//
//    End of common block
//
integer g_iSecondsBeforeBoot = 0;
list    g_lCurfewPeriods = [];    // start and stop times of curfew, list of pairs
integer CURFEW_START = 0;
integer CURFEW_STOP = 1;
integer CURFEW_STRIDE = 2;

integer bool(integer a){
    if(a)return TRUE;
    else return FALSE;
}

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
 
    integer LastSunday = days - DayOfWeek;

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
    if (g_bDebugOn) { DebugOutput(["deleteOccurrence ", sName]); }
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
    if (g_bDebugOn) { DebugOutput(["findRegion", sName]); }
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

integer timeNow() {
    integer iTimeNow = Unix2PST_PDT(llGetUnixTime());
    return iTimeNow;
}

alarmFired(integer iSender, integer iNum, string sStr, key kID) {
    if (g_bDebugOn) { DebugOutput(["alarmFired"]); }
    integer iTimeNow = timeNow();
    if (sStr == CURFEW_SETUP) { InitCalcs(iTimeNow); checkStatus(iTimeNow); }
    else if (sStr == CURFEW_ALARM) { checkStatus(iTimeNow); }
}
//
//    Perform initial calculation of the curfew start and stop times. This is triggered by a CURFEW_SETUP alarm.
//        That alarm is set in state_entry and in on_rez. When the alarm goes off, InitCalcs is invoked (see alarmFired).
//        InitCalcs will set a CURFEW_ALARM alarm to trigger curfew checks at the start of the next curfew period.
//
InitCalcs(integer iTimeNow) {
    if (g_bDebugOn) { DebugOutput(["InitCalcs", "stopping timer events-1"]); }
    llSetTimerEvent(0.0);
    list lTimeNow = Unix2DateTime(iTimeNow);
    if (g_bDebugOn) { list lTemp = ["InitCalcs 0"] + lTimeNow; DebugOutput(lTemp); }
    
    list lStart = [llList2Integer(lTimeNow, 0), llList2Integer(lTimeNow, 1), llList2Integer(lTimeNow, 2), 
        llList2Integer(g_lCurfew, 0), llList2Integer(g_lCurfew, 1) ,0];
    list lStop = [llList2Integer(lTimeNow, 0), llList2Integer(lTimeNow, 1), llList2Integer(lTimeNow, 2), 
        llList2Integer(g_lCurfew, 2), llList2Integer(g_lCurfew, 3) ,0];
        
    if (g_bDebugOn) { list lTemp = ["InitCalcs 1"] + lStart; DebugOutput(lTemp); }
    if (g_bDebugOn) { list lTemp = ["InitCalcs 2"] + lStop; DebugOutput(lTemp); }
    
    integer iCurfewStart = DateTime2Unix(llList2Integer(lTimeNow, 0), llList2Integer(lTimeNow, 1), llList2Integer(lTimeNow, 2), 
        llList2Integer(g_lCurfew, 0), llList2Integer(g_lCurfew, 1) ,0);
    integer iCurfewStop = DateTime2Unix(llList2Integer(lTimeNow, 0), llList2Integer(lTimeNow, 1), llList2Integer(lTimeNow, 2), 
        llList2Integer(g_lCurfew, 2), llList2Integer(g_lCurfew, 3) ,0);
        
    if (g_bDebugOn) { DebugOutput(["InitCalcs 3", iCurfewStart, iTimeNow, iCurfewStop]); }
    
    g_lCurfewPeriods = [];
    
    if (iCurfewStart < iCurfewStop) g_lCurfewPeriods = [iCurfewStart, iCurfewStop];    // Curfew times already in SL time
    else {
        integer iStop = DateTime2Unix(llList2Integer(lTimeNow, 0), llList2Integer(lTimeNow, 1), llList2Integer(lTimeNow, 2), 
            23, 59, 59);
        g_lCurfewPeriods = [0, iCurfewStop, iCurfewStop, iStop];
    }
    
    integer iAlarm = 0;
//    if length = stride -> only one entry and (0) is the next start time
//    Otherwise -> two entries, first one already passed or inCurfewNow would have been TRUE, so (2) is next
    if (llGetListLength(g_lCurfewPeriods) == CURFEW_STRIDE) iAlarm = llList2Integer(g_lCurfewPeriods, 0);
    else iAlarm = llList2Integer(g_lCurfewPeriods, 2);
        
    llMessageLinked(LINK_SET, KB_CURFEW_INACTIVE, "", "");
    llMessageLinked(LINK_SET, KB_CLOCK_SET, llList2Json(JSON_OBJECT, ["alarm_id", CURFEW_ALARM, "alarm_type", "**", "alarm_time", iAlarm]), "");
}

integer inCurfewNow(integer iTimeNow) {
    integer iIndex = 0;
    while (iIndex < llGetListLength(g_lCurfewPeriods)) {
        integer iCurfewStart = llList2Integer(g_lCurfewPeriods, iIndex + CURFEW_START);
        integer iCurfewStop = llList2Integer(g_lCurfewPeriods, iIndex + CURFEW_STOP);
        if (iCurfewStart < iTimeNow && iTimeNow < iCurfewStop) return TRUE;
        iIndex += CURFEW_STRIDE;
    }
    return FALSE;
}

parseSettings(integer iSender, integer iNum, string sStr, key kID) {
//
//    parse out settings and deletions
//
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
                    integer iCheckTime = timeNow() + 20;
                    llMessageLinked(LINK_SET, KB_CLOCK_SET, llList2Json(JSON_OBJECT, ["alarm_id", CURFEW_SETUP, "alarm_type", KB_CLOCK_NODUP, "alarm_time", iCheckTime]), "");
                } else {
                    g_iCurfewActive = FALSE;
                    if (g_bDebugOn) { DebugOutput(["parseSettings", "stopping timer events-1"]); }
                    llSetTimerEvent(0.0);
                    llMessageLinked(LINK_SET, KB_CURFEW_INACTIVE, "", "");
                }
            } else if (sTokenMinor == "curfewtimes") {
                g_lCurfew = llCSV2List(sValue);
                integer iCheckTime = timeNow() + 20;
                llMessageLinked(LINK_SET, KB_CLOCK_SET, llList2Json(JSON_OBJECT, ["alarm_id", CURFEW_SETUP, "alarm_type", KB_CLOCK_NODUP, "alarm_time", iCheckTime]), "");
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
                if (g_bDebugOn) { DebugOutput(["parseSettings", "stopping timer events-2"]); }
                llSetTimerEvent(0.0);
                llMessageLinked(LINK_SET, KB_CURFEW_INACTIVE, "", "");
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
//    
//    If curfew is not active, there's nothing to do.
//    If the person is leashed by someone with the proper authority, there's nothing to do
//    If the person is in the home region, there's nothing to do (this may change when proximity works)
//    
//    If all of those exceptions fail, meaning curfew is active, the person is loose, and not at home
//    If the home bookmark exixts, trigger kickoff for the final check
//

integer checkStatus(integer iTimeNow) {
    if (g_bDebugOn) { DebugOutput(["checkStatus - 1 stopping timer events"]); }
    llSetTimerEvent(0.0);
//    g_iSecondsBeforeBoot = 0;

    if (!g_iCurfewActive) return TRUE; // curfew not active, done.
    if (!inCurfewNow(iTimeNow)) return TRUE; // not in curfew now, done
    if (LeashOK()) return TRUE; // leashed, done
    if (RegOK(llGetRegionName())) return TRUE; // if region OK (meaning the home region) done
    if ((findOccurrence("Home") >= 0) ||
        (findOccurrence("home") >= 0) ||
        (findOccurrence("DefaultHome") >= 0) ||
        (findOccurrence("defaulthome") >= 0)) {
        StartHome();
        return FALSE;
    } else {
        llMessageLinked(LINK_SET,NOTIFY,"0"+"DefaultHome and Home bookmarks both missing.", g_kWearer);
        return TRUE;
    }
}

//checkMemory(integer iForce) {;
//    if (g_bDebugOn) { DebugOutput(["checkMemory", iForce]); }
//    if (iForce) {
//        llMessageLinked(LINK_SET,NOTIFY,"0"+"kbtplim is resetting due to forced input.", g_kWearer);
//        llResetScript();
//    } else {
//        if (llGetFreeMemory() < 6000) {
//            llMessageLinked(LINK_SET,NOTIFY,"0"+"kbtplim is resetting due to minimum available memory.", g_kWearer);
//            llResetScript();
//        }
//    }
//}

StartHome() {
    if (g_bDebugOn) { DebugOutput(["StartHome-1", g_iSecondsBeforeBoot, g_bRemovalInProgress]); }
    llMessageLinked(LINK_SET, KB_CURFEW_ACTIVE, "", "");

    if (!g_bRemovalInProgress) {
        g_bRemovalInProgress = TRUE;
        g_iSecondsBeforeBoot = 30;
        if (g_bDebugOn) { DebugOutput(["StartHome-2", g_iSecondsBeforeBoot, g_bRemovalInProgress]); }
        llSetTimerEvent(2.0);
    } else {
        if (g_bDebugOn) { DebugOutput(["StartHome-3", g_iSecondsBeforeBoot, g_bRemovalInProgress]); }
        llSetTimerEvent(5.0);
    }
}

default  {
    changed(integer iChange) {
        if (g_bDebugOn) { DebugOutput(["changed", iChange]); }

        if(iChange & CHANGED_OWNER) { llResetScript(); }
        
        if (iChange & CHANGED_REGION) 
        { 
            if (g_bDebugOn) { DebugOutput(["changed", llGetRegionName(), "invoking checkStatus"]); }
            integer iTimeNow = timeNow(); 
            checkStatus(iTimeNow);
        }
    }

    state_entry() {
        if (g_bDebugOn) { DebugOutput(["state_entry"]); }
        llOwnerSay("kb_curfew version " + formatVersion() + " active");
        g_sScript = llStringTrim(llList2String(llParseString2List(llGetScriptName(), ["-"], []), 1), STRING_TRIM) + "_";
        g_sScriptVersion = KB_VERSIONMAJOR + "." + KB_VERSIONMINOR + "." + KB_DEVSTAGE;
        // store key of wearer
        g_kWearer = llGetOwner();
        g_iSecondsBeforeBoot = 0;
        g_bRemovalInProgress = FALSE;
        if (g_bDebugOn) { DebugOutput(["state_entry ", "seconds left " + (string) g_iSecondsBeforeBoot]); } 
        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "bookmarks", "");
        integer iCheckTime = timeNow() + 20;
        llMessageLinked(LINK_SET, KB_CLOCK_SET, llList2Json(JSON_OBJECT, ["alarm_id", CURFEW_SETUP, "alarm_type", KB_CLOCK_NODUP, "alarm_time", iCheckTime]), "");
    }

    on_rez(integer iParam) {
        if (g_bDebugOn) { DebugOutput(["on_rez ", iParam, "wearer ",  g_kWearer]); }
        if(llGetOwner() != g_kWearer) {
        // Reset if wearer changed
            llResetScript();
        }
        g_iSecondsBeforeBoot = 0;
        g_bRemovalInProgress = FALSE;
        if (g_bDebugOn) { DebugOutput(["on_rez ", "seconds left " + (string) g_iSecondsBeforeBoot]); }
        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "bookmarks", "");
        integer iCheckTime = timeNow() + 20;
        
        llMessageLinked(LINK_SET, KB_CLOCK_SET, llList2Json(JSON_OBJECT, ["alarm_id", CURFEW_SETUP, "alarm_type", KB_CLOCK_NODUP, "alarm_time", iCheckTime]), "");
    }

    // listen for linked messages from OC scripts
    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if(iNum == RLV_OFF) { // rlvoff -> we have to turn the menu off too
            g_iRLVOn = FALSE;
        }
        else if(iNum == RLV_ON) { // rlvon -> we have to turn the menu on again
            g_iRLVOn = TRUE;
        }
        else if(iNum == LM_SETTING_RESPONSE) parseSettings(iSender, iNum, sStr, kID);
        else if(iNum == LM_SETTING_DELETE) parseSettings(iSender, iNum, sStr, kID);
        else if(iNum == KB_CLOCK_ALARM) alarmFired(iSender, iNum, sStr, kID);
        else if (iNum == KB_DEBUG_CURFEW_ON) SetDebugOn();
        else if (iNum == KB_DEBUG_CURFEW_OFF) SetDebugOff();

    }
    
    timer() {
        if (g_bDebugOn) { DebugOutput(["timer"]); }
        llSetTimerEvent(0.0);
        if (g_bDebugOn) { DebugOutput(["timer-1 ", "seconds left " + (string) g_iSecondsBeforeBoot, "invoking checkStatus"]); }
        string sMsg = "";

        integer iTimeNow = timeNow();
        if (checkStatus(iTimeNow)) {
            llMessageLinked(LINK_SET, KB_CURFEW_INACTIVE, "", "");
            if (g_bRemovalInProgress)
                llMessageLinked(LINK_SET,NOTIFY,"0"+"removal has been stopped.", g_kWearer);
            g_iSecondsBeforeBoot = 0;
            g_bRemovalInProgress = FALSE;
            if (g_bDebugOn) { DebugOutput(["timer-2 ", "seconds left " + (string) g_iSecondsBeforeBoot]); }
        } else {
            if (g_bRemovalInProgress) {
                if (g_iSecondsBeforeBoot > 0) {
                    sMsg = "you are not allowed out after curfew. you have " + (string) g_iSecondsBeforeBoot + " seconds left.";
                    g_iSecondsBeforeBoot -= 5;
                    llMessageLinked(LINK_SET,NOTIFY,"0"+sMsg, g_kWearer);
//                llSetTimerEvent(5.0);
                    if (g_bDebugOn) { DebugOutput(["timer-3 ", "seconds left " + (string) g_iSecondsBeforeBoot]); }
                } else {
                    llSetTimerEvent(0.0);
                    g_iSecondsBeforeBoot = 0;
                    g_bRemovalInProgress = FALSE;
                    if (g_bDebugOn) { DebugOutput(["timer-4 ", "seconds left " + (string) g_iSecondsBeforeBoot]); }
                    llMessageLinked(LINK_SET, KB_CURFEW_INACTIVE, "", "");
                    if (findOccurrence("Home") >= 0) {
                        llMessageLinked(LINK_SET, CMD_OWNER, "tp Home", g_kWearer);
                    } else if (findOccurrence("home") >= 0) {
                        llMessageLinked(LINK_SET, CMD_OWNER, "tp home", g_kWearer);
                    } else if (findOccurrence("DefaultHome") >= 0) {
                        llMessageLinked(LINK_SET, CMD_OWNER, "tp DefaultHome", g_kWearer);
                    } else if (findOccurrence("defaulthome") >= 0) {
                        llMessageLinked(LINK_SET, CMD_OWNER, "tp defaulthome", g_kWearer);
                    } else { 
                        llMessageLinked(LINK_SET,NOTIFY,"0"+"TP home failed.", g_kWearer);
                    }
                }
            }
        }
    }
}

// kb_curfew
