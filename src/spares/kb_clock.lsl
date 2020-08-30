
//K-Bar clock

string  g_sModule = "clock";
list    g_lInterrupts;
integer INTERRUPTSTRIDE = 3;
integer ALARM_ID = 0;
integer ALARM_TYPE = 1;
integer ALARM_TIME = 2;

string  KB_VERSIONMAJOR      = "7";
string  KB_VERSIONMINOR      = "5";
string  KB_DEVSTAGE          = "1";
string  g_sScriptVersion = "";

integer NOTIFY              = 1002;

integer LINK_CMD_DEBUG=1999;

//integer g_bDebugOn = FALSE;
//key     g_kDebugKey = NULL_KEY;
key KURT_KEY   = "4986014c-2eaa-4c39-a423-04e1819b0fbf";
key SILKIE_KEY = "1a828b4e-6345-4bb3-8d41-f93e6621ba25";

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

integer g_bDebugOn = TRUE;
integer g_iDebugLevel = 0;
integer KB_DEBUG_CHANNEL           = -617783;
integer g_iDebugCounter = 0;

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

integer g_iRLVOn         = FALSE; //Assume RLV is off until we hear otherwise

key     g_kWearer = NULL_KEY;       // key of the current wearer to reset only on owner changes

string  g_sScript;                  // part of script name used for settings

list    g_lPairs = [];

integer KB_CLOCK_SET			   = -34843;
integer KB_CLOCK_ALARM			   = -34844;

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
    integer iInterruptIndex = llListFindList(g_lInterrupts, [sAlarmID]);
    if (iInterruptIndex != -1) {
        g_lInterrupts = llListReplaceList(g_lInterrupts, [sAlarmID, sAlarmType, iAlarmTime], iInterruptIndex, iInterruptIndex + INTERRUPTSTRIDE - 1);
    } else {
        g_lInterrupts += [sAlarmID, sAlarmType, iAlarmTime];
    }
    checkAlarms();
}

setTimer(integer iTime) {
    if (g_bDebugOn) { DebugOutput(["setTimer", iTime]); }
    integer iLowest = 0;
    if (llGetListLength(g_lInterrupts) > 0) iLowest = llList2Integer(g_lInterrupts, INTERRUPTSTRIDE - 1);
    else return;
    integer iIndex = 0;
    while (iIndex < llGetListLength(g_lInterrupts)) {
        if (iLowest == 0 || iLowest > llList2Integer(g_lInterrupts, iIndex + ALARM_TIME)) iLowest = llList2Integer(g_lInterrupts, iIndex + ALARM_TIME);
        iIndex += INTERRUPTSTRIDE;
    }
    if (iLowest != 0) {
        integer iDelay = iLowest - iTime;
        float fDelay = (float) iDelay;
        llSetTimerEvent(fDelay);
    }
}

checkAlarms() {
    llSetTimerEvent(0.0);
    integer iTime = Unix2PST_PDT(llGetUnixTime());
    integer iIndex = llGetListLength(g_lInterrupts) - INTERRUPTSTRIDE;
    if (g_bDebugOn) { DebugOutput(["checkAlarms", iTime, iIndex, llGetListLength(g_lInterrupts)]); }
    while (llGetListLength(g_lInterrupts) > 0) {
        integer iTest = llList2Integer(g_lInterrupts, iIndex + INTERRUPTSTRIDE - 1);
        if (iTime < iTest) {
            if (g_bDebugOn) { DebugOutput(["checkAlarmsComparison", iTime, iTest]); }
            llMessageLinked(LINK_SET, KB_CLOCK_ALARM, llList2String(g_lInterrupts, iIndex), "");
            g_lInterrupts = llDeleteSubList(g_lInterrupts, iIndex, iIndex + INTERRUPTSTRIDE - 1);
            iIndex = llGetListLength(g_lInterrupts) - INTERRUPTSTRIDE;
        } else {
            iIndex -= INTERRUPTSTRIDE;
        }
    }
    setTimer(iTime);
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
        checkAlarms();
    }

    on_rez(integer iParam) {
        if (g_bDebugOn) { DebugOutput(["on_rez ", "wearer ",  g_kWearer]); }
        if(llGetOwner() != g_kWearer) {
            llResetScript();
        }
        checkAlarms();
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if(iNum == KB_CLOCK_SET) {
            setAlarm(sStr);
        }
    }
    
    timer() {
        checkAlarms();
    }
}

// kb_clock
