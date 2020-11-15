
//K-Bar clock

string  g_sModule = "clock";
list    g_lInterrupts;
integer INTERRUPTSTRIDE = 4;
integer ALARM_ID = 2;
integer ALARM_TYPE = 1;
integer ALARM_TIME = 0;

string  KB_VERSIONMAJOR      = "8";
string  KB_VERSIONMINOR      = "0";
string  KB_DEVSTAGE          = "1a105";
string  g_sCollarVersion = "not set";

integer NOTIFY              = 1002;

//integer LINK_CMD_DEBUG=1999;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved
//str must be in form of "token=value"
integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the settings script sends responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from settings
integer LM_SETTING_EMPTY = 2004;//sent when a token has no value

integer KB_DEBUG_CLOCK_ON		   = -36001;
integer KB_DEBUG_CLOCK_OFF		   = -36002;
integer KB_COLLAR_VERSION		   = -34847;
integer KB_REQUEST_VERSION         = -34591;
integer REBOOT                     = -1000;

string g_sMajor = "kbclock";
string g_sMinor = "alarm";

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

integer g_bDebugOn = FALSE;
integer g_iDebugLevel = 10;
integer KB_DEBUG_CHANNEL           = -617783;
integer g_iDebugCounter = 0;

SetDebugOn() {
    g_bDebugOn = TRUE;
    g_iDebugLevel = 0;
    g_iDebugCounter = 0;
}

SetDebugOff() {
    g_bDebugOn = FALSE;
    g_iDebugLevel = 10;
}

//integer g_iRLVOn         = FALSE; //Assume RLV is off until we hear otherwise

key     g_kWearer = NULL_KEY;       // key of the current wearer to reset only on owner changes

list    g_lPairs = [];

integer KB_CLOCK_SET			   = -34843;
integer KB_CLOCK_ALARM			   = -34844;

integer SECONDS_PER_DAY      = 86400;
integer SECONDS_PER_HOUR     = 3600;
integer SECONDS_PER_MINUTE   = 60;

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
//    string PST_PDT = " PST";                  // start by assuming Pacific Standard Time
    // Up to 2006, PDT is from the first Sunday in April to the last Sunday in October
    // After 2006, PDT is from the 2nd Sunday in March to the first Sunday in November
    if (years > 2006 && month == 3  && LastSunday >  7)     bPST = FALSE;
    if (month > 3)                                          bPST = FALSE;
    if (month > 10)                                         bPST = TRUE;
    if (years < 2007 && month == 10 && LastSunday > 24)     bPST = TRUE;
    return bPST;
}

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

string formatDate(list lDate) {
    string sDate = llList2String(lDate, 0) + "-"
                 + llList2String(lDate, 1) + "-"
                 + llList2String(lDate, 2) + " "
                 + llList2String(lDate, 3) + ":"
                 + llList2String(lDate, 4) + ":"
                 + llList2String(lDate, 5);
    return sDate;
}

string xJSONstring(string JSONcluster, string sElement) {
    string sWork = llJsonGetValue(JSONcluster, [sElement]);
    if (sWork != JSON_INVALID && sWork != JSON_NULL) return sWork;
    return "";
}

//string xJSONkey(string JSONcluster, string sElement) {
//    string sWork = llJsonGetValue(JSONcluster, [sElement]);
//    if (g_bDebugOn) DebugOutput(3, ["xJSONkey", JSONcluster, sElement, sWork]);
//    if (sWork != JSON_INVALID && sWork != JSON_NULL) return sWork;
//    return NULL_KEY;
//}

integer xJSONint(string JSONcluster, string sElement) {
    string sWork = llJsonGetValue(JSONcluster, [sElement]);
    if (sWork != JSON_INVALID && sWork != JSON_NULL) return (integer) sWork;
    return 0;
}

setAlarm(string sStr) {
    string sAlarmID = xJSONstring(sStr, "alarm_id");
    string sAlarmType = xJSONstring(sStr, "alarm_type");
    integer iAlarmTime = xJSONint(sStr, "alarm_time");
    setAlarmNoJSon(sAlarmID, sAlarmType, iAlarmTime);
}

setAlarmNoJSon(string sAlarmID, string sAlarmType, integer iAlarmTime) {
    integer iInterruptIndex = llListFindList(g_lInterrupts, [sAlarmID])  - ALARM_ID; // adjust to start of entry
    if (g_bDebugOn) { DebugOutput(["setAlarm", sAlarmID, sAlarmType, formatDate(Unix2DateTime(iAlarmTime)), iInterruptIndex, llGetListLength(g_lInterrupts)]); }
    if (iInterruptIndex >= 0) {
        g_lInterrupts = llListReplaceList(g_lInterrupts, [iAlarmTime, sAlarmType, sAlarmID], iInterruptIndex, iInterruptIndex + INTERRUPTSTRIDE - 1);
    } else {
        g_lInterrupts += [iAlarmTime, sAlarmType, sAlarmID];
    }
    
//    llList2Json(JSON_OBJECT, ["alarm_id", CURFEW_ALARM, "alarm_type", "**", "alarm_time", iAlarm])

//
//    Or: list llListSort( list src, integer stride, integer ascending );
//        llListSort([1, "C", 3, "A", 2, "B"], 2, TRUE) // returns [1, "C", 2, "B", 3, "A"]
//
    if (llGetListLength(g_lInterrupts) > INTERRUPTSTRIDE)
        g_lInterrupts = llListSort(g_lInterrupts, INTERRUPTSTRIDE, TRUE);
//
    saveAlarms();
    checkAlarms();
}

saveAlarms() {
    string sToken = g_sMajor + "_" + g_sMinor;
    integer iLen = llGetListLength(g_lInterrupts);
    if (g_bDebugOn) { DebugOutput(["saveAlarms-1", sToken, iLen]); }
    if (iLen == 0) {
        llMessageLinked(LINK_SET, LM_SETTING_DELETE, sToken, "");
        return;        
    }
    integer iIdx = 0;
    string sAlarms = "";
    while (iIdx < iLen) {
        if (sAlarms != "") sAlarms += ",";
        string sAlarm_Id = llList2String(g_lInterrupts, (iIdx * INTERRUPTSTRIDE) + ALARM_ID);
        string sAlarm_Type = llList2String(g_lInterrupts, (iIdx * INTERRUPTSTRIDE) + ALARM_TYPE);
        integer iAlarm = llList2Integer(g_lInterrupts, (iIdx * INTERRUPTSTRIDE) + ALARM_TIME);
        string sAlarmJson = llList2Json(JSON_OBJECT, ["alarm_id", sAlarm_Id, "alarm_type", sAlarm_Type, "alarm_time", iAlarm]);
        sAlarms += sAlarmJson;
        iIdx += INTERRUPTSTRIDE;
        if (g_bDebugOn) { DebugOutput(["saveAlarms-2", sAlarmJson, formatDate(Unix2DateTime(iAlarm)), sAlarms, iIdx, iLen]); }
    }
    llMessageLinked(LINK_SET, LM_SETTING_SAVE, sToken + "=" + sAlarms, "");
    if (g_bDebugOn) { DebugOutput(["saveAlarms-3", sToken + "=" + sAlarms]); }
}
setTimer(integer iNow) {
    llSetTimerEvent(0.0);  // disable timers to start
    if (g_bDebugOn) { DebugOutput(["setTimer-1", llGetListLength(g_lInterrupts)]); }
    if (llGetListLength(g_lInterrupts) == 0) { // no pending alarms --> no timer
        return;
    }
    integer iLowest = llList2Integer(g_lInterrupts, ALARM_TIME); // time from first element in list
//    integer iIndex = 0;
//    while (iIndex < llGetListLength(g_lInterrupts)) {
//        if (g_bDebugOn) { DebugOutput(["setTimer-2", iIndex, llGetListLength(g_lInterrupts), iLowest,llList2Integer(g_lInterrupts, iIndex + ALARM_TIME)]); }
//        if (iLowest > llList2Integer(g_lInterrupts, iIndex + ALARM_TIME)) iLowest = llList2Integer(g_lInterrupts, iIndex + ALARM_TIME);
//        iIndex += INTERRUPTSTRIDE;
//    }
//    integer iNow = Unix2PST_PDT(llGetUnixTime());
    if (g_bDebugOn) { DebugOutput(["setTimer-3 lowest, now, delay", iLowest, iNow, iLowest - iNow, formatDate(Unix2DateTime(iLowest)), formatDate(Unix2DateTime(iNow))]); }
    integer iDelay = iLowest - iNow;
    if (iDelay > 0) {
        float fDelay = (float) iDelay;
        if (g_bDebugOn) { DebugOutput(["setTimer-5", iDelay, fDelay]); }
        llSetTimerEvent(fDelay);
    } else {
        if (g_bDebugOn) { DebugOutput(["setTimer-6"]); }
        llSetTimerEvent(2.0); // something odd happened, cause a trigger and alarm check in a few seconds
    }
}
//
//    If the list is sorted by ascending order of alarm times, the first element always is the lowest; process it,
//        delete it, and the new first element now is the lowest. As soon as the lowest element is greater than
//        the current time, you're done.
//
checkAlarms() {
    llSetTimerEvent(0.0);
    while (checkAlarm(Unix2PST_PDT(llGetUnixTime())));
    setTimer(Unix2PST_PDT(llGetUnixTime()));
}

integer checkAlarm(integer iTime) {
    if (llGetListLength(g_lInterrupts) == 0) return FALSE;
//
//    check first and go
//
    integer iTest = llList2Integer(g_lInterrupts, ALARM_TIME); // no index offset because we're looking at the first entry
//    integer iIndex = llGetListLength(g_lInterrupts) - INTERRUPTSTRIDE;
//    if (g_bDebugOn) { DebugOutput(["checkAlarms - 1 now, index, length", formatDate(Unix2DateTime(iTime)), iIndex, llGetListLength(g_lInterrupts)]); }
//    while (llGetListLength(g_lInterrupts) > 0 && iIndex >= 0) {
//        integer iTest = llList2Integer(g_lInterrupts, iIndex + INTERRUPTSTRIDE - 1);
        if (g_bDebugOn) { DebugOutput(["checkAlarm - 2 now, test", formatDate(Unix2DateTime(iTime)), formatDate(Unix2DateTime(iTest))]); }
        if (iTime > iTest) { // found an expired timer
            if (g_bDebugOn) { DebugOutput(["checkAlarm - 3", "iTime > iTest"]); }
            llMessageLinked(LINK_SET, KB_CLOCK_ALARM, llList2String(g_lInterrupts, ALARM_ID), "");
            g_lInterrupts = llDeleteSubList(g_lInterrupts, 0, INTERRUPTSTRIDE - 1);
            return TRUE;
        } else {
//            iIndex -= INTERRUPTSTRIDE;
            return FALSE;
        }
//    }
//    setTimer();
}

integer ALIVE = -55;
integer READY = -56;
integer STARTUP = -57;

// TODO: Persistent storage of alarms

default {
    on_rez(integer iNum){
        llResetScript();
    }

    state_entry(){
        llMessageLinked(LINK_SET, ALIVE, llGetScriptName(),"");
    }
    
    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if(iNum == REBOOT) {
            if(sStr == "reboot") {
                llResetScript();
            }
        } else if(iNum == READY) {
            llMessageLinked(LINK_SET, ALIVE, llGetScriptName(), "");
        } else if(iNum == STARTUP) {
            state active;
        }
    }

    state_exit()
    {
        // if (g_bDebugOn) DebugOutput(5, ["default", "state_exit", llGetFreeMemory(), "bytes free"]);
    }
}
   
state active  {
    changed(integer iChange) {
        if(iChange & CHANGED_OWNER) { 
            llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sMajor + "_" + g_sMinor, "");
        }
    }

    state_entry() {
        if (g_bDebugOn) { DebugOutput(["state_entry", formatVersion(), llGetListLength(g_lInterrupts)]); }
        g_kWearer = llGetOwner();
        llOwnerSay("kb_clock " + formatVersion() + " starting");
        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, g_sMajor + "_" + g_sMinor, "");
        llSetTimerEvent(60.0); // on startup, wait for this setting request, then check alarms, in case startup timing caused us to miss it first time around
        checkAlarms();
    }

    on_rez(integer iParam) {
        if (g_bDebugOn) { DebugOutput(["on_rez ", formatVersion(), "wearer ",  g_kWearer]); }
        llResetScript();
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum == KB_CLOCK_SET) {
            if (g_bDebugOn) { DebugOutput(["link_message", "KB_CLOCK_SET", KB_CLOCK_SET]); }
            setAlarm(sStr);
        } 
        else if (iNum == KB_DEBUG_CLOCK_ON) SetDebugOn();
        else if (iNum == KB_DEBUG_CLOCK_OFF) SetDebugOff();
        else if (iNum == LM_SETTING_RESPONSE) {
            // if (g_bDebugOn) DebugOutput(5, ["link_message", "setting_response", iSender, iNum, sStr, kID]);
            // KBCLOCK_ALARM=alarm,alarm,...,alarm
            list lTmp = llParseString2List(sStr, ["="], []);
            string sTok = llList2String(lTmp, 0);
            string sVal = llList2String(lTmp, 1);
            list lMajMin = llParseString2List(sTok, ["="], []);
            string sMajor = llToLower(llList2String(lMajMin, 0));
            string sMinor = llToLower(llList2String(lMajMin, 1));
            if (sMajor == g_sMajor) {
                if (sMinor == g_sMinor) {
                    list lAlarms = llParseString2List(sVal, [","], []);
                    integer iLen = llGetListLength(lAlarms);
                    integer iIdx = 0;
                    while (iIdx < iLen) {
                        setAlarm(llList2String(lAlarms, iIdx));
                        ++iIdx;
                    }
                }
            }
        } else if (iNum == KB_COLLAR_VERSION) g_sCollarVersion = sStr;
        else if (iNum == KB_REQUEST_VERSION)
            llMessageLinked(LINK_SET,NOTIFY,"0"+llGetScriptName() + " version " + formatVersion(),kID);
    }
    
    timer() {
        checkAlarms();
    }
}

// kb_clock
