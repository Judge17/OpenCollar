
//K-Bar Settings Host 802 00 a
    
string  KB_VERSIONMAJOR      = "8";
string  KB_VERSIONMINOR      = "0";
string  KB_DEVSTAGE          = "200026";
// LEGEND: Major.Minor.ijklmm i=Build j=RC k=Beta l=Alpha mm=KBar Version
string  g_sScriptVersion = "";

string formatVersion() {
//    if (g_bDebugOn) llOwnerSay("formatVersion; " + KB_VERSIONMAJOR + "; " + KB_VERSIONMINOR + "; " + KB_DEVSTAGE + ";. " );
    return KB_VERSIONMAJOR + "." + KB_VERSIONMINOR + "." + KB_DEVSTAGE;
}

DebugOutput(integer iLevel, list ITEMS) {
    if (iLevel > g_iDebugLevel) {
        ++g_iDebugCounter;
        integer i=0;
        integer end=llGetListLength(ITEMS);
        string final;
        for(i=0;i<end;i++){
            final+=llList2String(ITEMS,i)+" ";
        }
        llSay(KB_DEBUG_CHANNEL, llGetScriptName() + " " + formatVersion() + " " + (string) g_iDebugCounter + " " + final);
//        llOwnerSay(llGetScriptName() + " " + formatVersion() + " " + (string) g_iDebugCounter + " " + final);
        if (g_iDebugCounter > 9999) SetDebugOff(); // safety check
    }
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

integer g_bDebugOn = TRUE;
integer g_iDebugLevel = 0;
integer KB_DEBUG_CHANNEL           = -617783;
integer g_iDebugCounter = 0;

list g_lNoteCards = [];
list g_lNameList = [];
//  Table of recognized names and associated integer abbreviations
list g_lPersonDict = [];
//  Table of recognized major setting categories and associated integer abbreviations
list g_lMajorDict = [];
//  Pending unprocessed collar requests
list g_lRequests = [];
//  "Request being processed" indicator
integer g_bRequestInProgress = FALSE;
//  index of next setting to be sent
integer g_iNextSetting = 0;
//  last request sequence sent
integer g_iLastSequenceSent = 0;
integer g_iCurrentNoteCard = 0;
integer g_iNoteCardLength = 0;
integer g_iCurrentLineNr = 0;
integer g_iCurrentName = 0;
string g_sCurrentName = "";
key g_kCurrentOwner;
key g_kCurrentKey;
key g_kCardRequest;
string g_sCombinedCard;
string g_sIntermediateCard;

key g_kOwner;
integer KB_HAIL_CHANNEL00 = -317784;
integer g_iListenHandle = 0;

//integer compare(string s1, string s2)
//{
//    if (s1 == s2)
//        return FALSE;
//    
//    if (s1 == llList2String(llListSort([s1, s2], 1, TRUE), 0))
//        return -1;
//    
//    return TRUE;
//}

//  g_lNoteCards is a 3-stride list that stores the contents of the "setings00" notecards in the storage device
//  An entry consists of:
//      1-normalized name, e.g. "John Resident" becomes "johnresident"
//      2-setting, or parameter name, e.g. "INTERN", "AUTH", "BOOKMARKS"
//      3-tilde-delimited keyword-value pair, e.g. "~norun~1~owner~UUID..."
//

string FormatInteger(integer iIn) {
    if (iIn > 999) return "xxx";
    if (iIn < 0) return "yyy";
    string w1 = (string) iIn;
    w1 = llStringTrim(w1, STRING_TRIM);
    while (llStringLength(w1) < 3) w1 = "0" + w1;
    return w1;
}

integer PersonDictionary(string sPerson) {
    string sPersonWork = llStringTrim(sPerson, STRING_TRIM);
    //. if (g_bDebugOn) DebugOutput(9, ["PersonDictionary-1 ", llGetFreeMemory(), sPerson, sPersonWork] + g_lPersonDict);
    integer iPDLen = llGetListLength(g_lPersonDict);
    integer iPDidx = 0;
    while (iPDidx < iPDLen) {
        //. if (g_bDebugOn) DebugOutput(5, ["PersonDictionary-2 ", llGetFreeMemory(), sPersonWork, iPDidx, llList2String(g_lPersonDict, iPDidx)]);
        if (sPersonWork == llList2String(g_lPersonDict, iPDidx)) return iPDidx;
        ++iPDidx;
    }
    g_lPersonDict += [sPersonWork];
    return iPDidx;
}

//string DecodePersonDictionary(integer iIndex) {
//    if ((iIndex >= 0) && (iIndex < llGetListLength(g_lPersonDict))) return llList2String(g_lPersonDict, iIndex);
//    return "unknown";
//}

integer MajorDictionary(string sMajor) {
    string sMajorWork = llStringTrim(sMajor, STRING_TRIM);
    //. if (g_bDebugOn) DebugOutput(5, ["MajorDictionary-1 ", llGetFreeMemory(), sMajorWork] + g_lMajorDict);
    integer iMDLen = llGetListLength(g_lMajorDict);
    integer iMDidx = 0;
    while (iMDidx < iMDLen) {
        //. if (g_bDebugOn) DebugOutput(5, ["MajorDictionary-2 ", llGetFreeMemory(), sMajorWork, iMDidx, llList2String(g_lMajorDict, iMDidx)]);
        if (sMajorWork == llList2String(g_lMajorDict, iMDidx)) return iMDidx;
        ++iMDidx;
    }
    g_lMajorDict += [sMajorWork];
    return iMDidx;
}

string DecodeMajorDictionary(integer iIndex) {
    if ((iIndex >= 0) && (iIndex < llGetListLength(g_lMajorDict))) return llList2String(g_lMajorDict, iIndex);
    return "unknown";
}

GenerateUpdateCall(string sPerson, string sParmID, string sParmValue) {
    //. if (g_bDebugOn) DebugOutput(5, ["GenerateUpdateCall-1", sPerson, sParmID, sParmValue]);
    string sPersonID = FormatInteger(PersonDictionary(sPerson));
    string sMajorID = FormatInteger(MajorDictionary(sParmID));
    list lBreakOut = llParseString2List(sParmValue, ["~"], []);
    integer iBOLen = llGetListLength(lBreakOut);
    integer iBOidx = 0;
    while (iBOidx < iBOLen) {
        string sParm = llList2String(lBreakOut, iBOidx);
        string sValue = llList2String(lBreakOut, iBOidx + 1);
        iBOidx += 2;
        string sWorkEntry = sPersonID + "~" + sMajorID + "~" + sParm + "~" + sValue;
        UpdateNoteCardList(sWorkEntry);
    }
    //. if (g_bDebugOn) DebugOutput(5, ["GenerateUpdateCall-2", sPerson, sParmID, sParmValue]);
}

UpdateNoteCardList(string sWorkEntry) {
    //. if (g_bDebugOn) DebugOutput(5, ["UpdateNoteCardList-1", llGetFreeMemory(), sWorkEntry]);
    integer iLen = llGetListLength(g_lNoteCards);
    integer iIdx = 0;
    integer iPtr = -1;
    while (iIdx < iLen) {
        if (sWorkEntry == llList2String(g_lNoteCards, iIdx)) return;
        ++iIdx;
    }
    g_lNoteCards += [sWorkEntry];
//            if (sPerson == llList2String(g_lNoteCards, iIdx)) {
//                if (g_bDebugOn) DebugOutput(5, ["UpdateNoteCardList-2a", sPerson, llList2String(g_lNoteCards, iIdx + 1)]);
//                if (sParm == llList2String(g_lNoteCards, iIdx + 1)) {
//    //                if (g_bDebugOn) DebugOutput(5, ["UpdateNoteCardList-2b", sParmID]);
//                    if (sValue == )
//                    string sWork = llList2String(g_lNoteCards, iIdx + 2) + "~" + sParmValue;
//                    g_lNoteCards = llListReplaceList(g_lNoteCards, [sWork], iIdx + 2, iIdx + 2);
//                    if (g_bDebugOn) DebugOutput(5, ["UpdateNoteCardList-2c"] + g_lNoteCards);
//                }
//            }
//            iIdx += 3;
//        }
//    g_lNoteCards += [sPerson, sParmID, sParmValue];
    //. if (g_bDebugOn) DebugOutput(5, ["UpdateNoteCardList-3", llGetFreeMemory()] + g_lNoteCards);
}

Kickoff() {
    g_lNoteCards = [];
    
    integer iTotalItems = llGetInventoryNumber(INVENTORY_ALL);
    integer iIndex;

    while (iIndex < iTotalItems) {
        //. if (g_bDebugOn) DebugOutput(5, ["Kickoff", "iIndex", iIndex]);
        
        string sItemName = llGetInventoryName(INVENTORY_ALL, iIndex);
        integer iType = llGetInventoryType(sItemName);
        if (iType == INVENTORY_NOTECARD) { 
            //. if (g_bDebugOn) DebugOutput(5, ["Kickoff", iIndex, "found"]);
            integer iLen = llStringLength(sItemName);
            string sWork = llGetSubString(sItemName, iLen - 2, iLen);
            if (sWork == "00") {
                sWork = llToLower(llGetSubString(sItemName, 0, iLen - 3));
                g_lNameList += [iIndex, sWork];
            }
        }
        ++iIndex;
    }
    //. if (g_bDebugOn) DebugOutput(5, ["Kickoff"] + g_lNameList);
    g_iNoteCardLength = llGetListLength(g_lNameList);
    if (g_iNoteCardLength > 0) {
        g_iCurrentName = 0;
        g_iCurrentNoteCard = llList2Integer(g_lNameList, g_iCurrentName);
        g_sCurrentName = llList2String(g_lNameList, g_iCurrentName + 1);
        g_iCurrentLineNr = 0;
        g_kCardRequest = llGetNotecardLine(g_sCurrentName + "00", g_iCurrentLineNr);
    }
}

InitListen() {
    //. if (g_bDebugOn) DebugOutput(5, ["InitListen Entry", g_iListenHandle]);
    if (g_iListenHandle != 0) { 
        llListenRemove(g_iListenHandle); 
        g_iListenHandle = 0; 
        g_iListenHandle = llListen(KB_HAIL_CHANNEL00, "", "", ""); 
    } else g_iListenHandle = llListen(KB_HAIL_CHANNEL00, "", "", "");
    //. if (g_bDebugOn) DebugOutput(5, ["InitListen Exit", g_iListenHandle]);
}

CloseListen() {
    if (g_iListenHandle == 0) return;
    llListenRemove(g_iListenHandle);
    g_iListenHandle = 0;
}

integer MessageTo(key kTarget, integer iSequence, string sMessage) {
    //. if (g_bDebugOn) DebugOutput(9, ["MessageTo", llGetFreeMemory(), kTarget, iSequence, sMessage]);
    llRegionSayTo(kTarget, KB_HAIL_CHANNEL00, FormatInteger(iSequence) + "<>" + sMessage);
    return iSequence + 1;
}

StartRun() {
    llSetTimerEvent(0.0);
    //. if (g_bDebugOn) DebugOutput(9, ["StartRun-1", llGetFreeMemory(), g_bRequestInProgress] + g_lRequests);
    if (!g_bRequestInProgress) {
        integer iLen = llGetListLength(g_lRequests);
        //. if (g_bDebugOn) DebugOutput(9, ["StartRun-2", llGetFreeMemory(), g_bRequestInProgress, iLen]);
        if (iLen > 0) {
            g_bRequestInProgress = TRUE;
            g_kCurrentKey = llList2Key(g_lRequests, iLen - 1);
            g_kCurrentOwner = llGetOwnerKey(g_kCurrentKey);
            g_lRequests = llDeleteSubList(g_lRequests, iLen - 1, iLen - 1);
            g_sCurrentName = NormalizeName(llKey2Name(g_kCurrentOwner));
            g_iCurrentName = PersonDictionary(g_sCurrentName);
            //. if (g_bDebugOn) DebugOutput(9, ["StartRun-3", llGetFreeMemory(), g_bRequestInProgress, g_kCurrentKey, g_kCurrentOwner, g_sCurrentName, g_iCurrentName]);
            if (g_iCurrentName >= 0) {
                g_iNextSetting = 0;
                g_bRequestInProgress = TRUE;
                MessageTo(g_kCurrentKey, 0, "go");
                llSetTimerEvent(60.0);  //  Allow a minute for requesting collar to respond
            } else {
                EndRun();
//                MessageTo(g_kCurrentKey, 999, "quit");
//                g_bRequestInProgress = FALSE;
                llSetTimerEvent(5.0);   //  Allow requesting collar a few seconds to shut up before trying another
            }
        } else {
            EndRun();
        }
    }
}

EndRun() {
    //. if (g_bDebugOn) DebugOutput(6, ["EndRun-1", "Final Request"]);
    if (g_bRequestInProgress) {
        g_bRequestInProgress = FALSE;
        MessageTo(g_kCurrentKey, 999, "quit");
        g_iLastSequenceSent = 0;
        g_kCurrentKey = NULL_KEY;
        g_kCurrentOwner = NULL_KEY;
        g_sCurrentName = "";
        g_iCurrentName = -1;
    }
}

integer CheckBatchLength(string sMessage, string sAddition) {
    integer iMessageLength = llStringLength(sMessage);
    integer iAdditionLength = llStringLength(sAddition);
    integer iNewLength = iMessageLength + iAdditionLength + 2;
    //. if (g_bDebugOn) DebugOutput(5, ["CheckBatchLength-1", llGetFreeMemory(), sMessage, iMessageLength, sAddition, iAdditionLength, iNewLength]);
    if (iNewLength > 500) return FALSE;
    return TRUE;
}

integer ExtractPersonCode(integer iIndex) {
    if (g_iNextSetting >= llGetListLength(g_lNoteCards)) return -1;
    list lWork = llParseString2List(llList2String(g_lNoteCards, g_iNextSetting), ["~"], []);
    if (llGetListLength(lWork) < 1) return -1;
    integer iPerson = llList2Integer(lWork, 0);
    return iPerson;
}

//
//SendBatch(iBatchNr) where iBatcnNr is the sequence number of the requested batch
//
//
//    Starting with the  most recent index (the most recently sent subscript in g_lNoteCards), build a message by adding one 
//    after another entry in g_lNoteCards until the aggregate length is just uner 500; then save the index and the 
//    sequence/batch number associated with this message and send it along.
//
//    If this batch winds up being the final batch for this person, return TRUE for the end; otherwise return FALSE
//
//    If a batch/sequence number gets requested a second time, ignore it (maybe one of these days figure out how to restart it - 
//    maybe save a table of previous batch starting numbers?)
//

integer SendBatch(integer iBatchNr, key kId) {
//  000~003~ParticleMode~Classic
    //. if (g_bDebugOn) DebugOutput(5, ["SendBatch-1", llGetFreeMemory(), g_bRequestInProgress, iBatchNr, g_iLastSequenceSent, g_iNextSetting, kId] + g_lRequests);
    if (g_iLastSequenceSent > iBatchNr) return TRUE;
    integer iMessageLength = 0;
    string sMessage = "";
    string sAddition = "";
    integer iSettingsEnd = llGetListLength(g_lNoteCards);
    
    while (g_iNextSetting < iSettingsEnd) {
        if (g_iCurrentName == ExtractPersonCode(g_iNextSetting)) {
            sAddition = DecodeNotecardEntry(llList2String(g_lNoteCards, g_iNextSetting));
            integer iMinor = llSubStringIndex(sAddition, "=");
            string sMajor = llGetSubString(sAddition, 0, iMinor - 1);
            if (llToLower(sMajor) != "bookmarks") { // skip bookmarks, we'll deal with them elsewhere
                //. if (g_bDebugOn) DebugOutput(5, ["SendBatch-2", llGetFreeMemory(), sAddition, g_iNextSetting]);
                if (CheckBatchLength(sMessage, sAddition)) {
                    //. if (g_bDebugOn) DebugOutput(5, ["SendBatch-3", llGetFreeMemory(), "!!", sMessage, "!!"]);
                    if (llStringLength(sMessage) == 0) {
                        sMessage = sAddition;
                    } else {
                        sMessage += ("<>" + sAddition);
                    }
                    ++g_iNextSetting;
                } else {
                    //. if (g_bDebugOn) DebugOutput(5, ["SendBatch-4", llGetFreeMemory(), g_iLastSequenceSent, sMessage]);
                    MessageTo(kId, ++g_iLastSequenceSent, sMessage);
                    //                g_iLastSequenceSent = MessageTo(kId, g_iLastSequenceSent, sMessage);
                    //            ++g_iLastSequenceSent;
                    return FALSE;
                }
            } else {
                ++g_iNextSetting;
            }
        } else {
            ++g_iNextSetting;
        }
    }
    if (llStringLength(sMessage) > 0) {
        //. if (g_bDebugOn) DebugOutput(5, ["SendBatch-5", llGetFreeMemory(), g_iLastSequenceSent, sMessage]);
        MessageTo(kId, ++g_iLastSequenceSent, sMessage);
//                g_iLastSequenceSent = MessageTo(kId, g_iLastSequenceSent, sMessage);
//        if (g_bDebugOn) DebugOutput(5, ["SendBatch-5", llGetFreeMemory(), sMessage]);
//        g_iLastSequenceSent = MessageTo(kId, g_iLastSequenceSent, sMessage);
        return FALSE;
    }
    return TRUE;
}

//
//    Break input into component parts (separated by tilde)
//    Decode the second entry into a major setting category
//    Construct a message payload with the decoded major entry
//

string DecodeNotecardEntry(string sInput) {
    list lWork = llParseString2List(sInput, ["~"], []);
    lWork += ["*", "*", "*"]; // safety padding
    //. if (g_bDebugOn) DebugOutput(5, ["DecodeNotecardEntry-1", llGetFreeMemory()] + lWork);
    integer iMajorCode = llList2Integer(lWork, 1);
    string sMajor = DecodeMajorDictionary(iMajorCode);
        
    //. if (g_bDebugOn) DebugOutput(5, ["DecodeNotecardEntry-2", llGetFreeMemory(), iMajorCode, sMajor]);
    string sEntry = sMajor + "=" + llList2String(lWork, 2) + "~" + llList2String(lWork, 3);
    return sEntry;
}

//
//    Get the collar owner's name, smush it to all lowercase, eliminate spaces, append "00" for basic settings
//
string NormalizeName(string sName) {
    list lName = llParseString2List(sName, [" "], [""]);
    string sTargetName = llStringTrim(llList2String(lName, 0), STRING_TRIM) + llStringTrim(llList2String(lName, 1), STRING_TRIM);
    sTargetName = llToLower(sTargetName);
    return sTargetName;
}

integer AddRequest(key kId) {
    if(llListFindList(g_lRequests, [kId]) == -1) {
        g_lRequests += [kId];
        return TRUE;
    }
    return FALSE;
}

default {
    state_entry() {
        g_kOwner = llGetOwner();
        //  if (g_bDebugOn) DebugOutput(5, ["state_entry", g_kOwner]);
        Kickoff();
    }

    on_rez(integer iParam) {
        //  if (g_bDebugOn) DebugOutput(5, ["on_rez"]);
        if (g_kOwner != llGetOwner()) llResetScript();
        Kickoff();
    }

    dataserver(key kID, string sData) {
        //. if (g_bDebugOn) DebugOutput(5, ["dataserver", sData, g_iCurrentLineNr]);

        if (kID == g_kCardRequest) {
            if (sData != EOF) {
                g_sIntermediateCard = llStringTrim(sData, STRING_TRIM);
                integer i1 = llStringLength(g_sIntermediateCard);
                if (i1 > 0) {
                    integer i2 = llStringLength(g_sCombinedCard);
                    if (g_sIntermediateCard != "" && llStringLength(g_sIntermediateCard) > 0) {
                        list lWork = llParseString2List(g_sIntermediateCard, ["="], []);
                        GenerateUpdateCall(g_sCurrentName, llList2String(lWork, 0), llList2String(lWork, 1));
                    }
                }
                ++g_iCurrentLineNr;
                g_kCardRequest = llGetNotecardLine(g_sCurrentName + "00", g_iCurrentLineNr);
//                LoadSetting(sData,++g_iLineNr);
//                g_kSettingsID = llGetNotecardLine(g_sTargetCard, g_iLineNr);
//
            } else {
                g_iCurrentName += 2;
                if (g_iNoteCardLength > g_iCurrentName) {
                    g_iCurrentNoteCard = llList2Integer(g_lNameList, g_iCurrentName);
                    g_sCurrentName = llList2String(g_lNameList, g_iCurrentName + 1);
                    g_iCurrentLineNr = 0;
                    g_kCardRequest = llGetNotecardLine(g_sCurrentName + "00", g_iCurrentLineNr);
                } else {
                    //. if (g_bDebugOn) DebugOutput(8, ["dataserver-eof", llGetFreeMemory()] + g_lNoteCards);
                    state init_version;
                }
                
                
                
                //                LoadSetting(sData,g_iLineNr);
//                SendValues();
//                EndRun();
            }
        }
    }

    changed(integer iChange) {
        if (iChange & (CHANGED_OWNER || CHANGED_INVENTORY)) llResetScript();
    }
}

state init_version {
//
//    Listen for a ping from the collar
//
//        The key will be the collar's UID
//        Add it to the request list for processing in due time
//
    listen(integer iChannel, string sName, key kId, string sMessage) {
        //  if (g_bDebugOn) DebugOutput(6, ["init_version", "listen-1", iChannel, sName, kId, sMessage]);
        llOwnerSay(formatVersion() + " " + sName + " " + sMessage);
        list lMessage = llParseString2List(sMessage, ["<>"], [""]);
        string sParm1 = llList2String(lMessage, 0);
        if (sParm1 == "ping803") {  // only look at new style requests
            if (llGetListLength(lMessage) > 1) {    // only look at properly formated requests (must have ping803<>something)
                llSetTimerEvent(0.0);
                llSetTimerEvent(60.0); // failsafe to reset if incoming traffic freezes
                integer iParm2 = llList2Integer(lMessage, 1);   // the "something" should be an integer
                if (iParm2 == 0) {  // a "zero" is a startup attempt
                    if (AddRequest(kId)) {
                        StartRun();
                    }
                    //        if (sMessage == "ping801") { // ignore requests not meant for us
                    //            g_sPing = sMessage;
                    //            string sNotify = sMessage + " " + (string) llGetOwnerKey(kId) + " " + llKey2Name(llGetOwnerKey(kId));
                    //            llOwnerSay(sNotify);
                    //            g_lRequests += [kId];
                    //            if (g_bDebugOn) DebugOutput(5, ["init_version", "listen-2", llGetListLength(g_lRequests), g_kActiveKey, kId, iChannel, llList2Key(g_lRequests, 1)]);
                    //            StartWork();
                    //        }
                    //        if (g_kActiveKey == NULL_KEY)
                    //            StartWork(llList2Key(g_lRequests, 0)); 
                } else {
                    if (SendBatch(iParm2, kId)) {
                        EndRun();
                        //  if (g_bDebugOn) DebugOutput(6, ["init_version", "listen-2", "Final Request"]);
                    }
                }
            }
        }
    }
    
    timer() {
        //  if (g_bDebugOn) DebugOutput(9, ["init_version", "timer", llGetFreeMemory()]);
        llSetTimerEvent(0.0);
        if (g_bRequestInProgress) {
            EndRun();
        }
        StartRun();
    }

    state_entry() {
        g_kOwner = llGetOwner();
        //  if (g_bDebugOn) DebugOutput(9, ["init_version", "state_entry", llGetFreeMemory(), g_kOwner]);
        g_bRequestInProgress = FALSE;
        InitListen();
    }
        
    on_rez(integer iParam) {
        //  if (g_bDebugOn) DebugOutput(5, ["init_version", "on_rez"]);
        if (g_kOwner != llGetOwner()) llResetScript();
        llResetScript();
    }
    
    changed(integer iChange) {
        if (iChange & (CHANGED_OWNER || CHANGED_INVENTORY)) llResetScript();
    }

    state_exit() {
        //  if (g_bDebugOn) DebugOutput(5, ["init_version", "state_exit", g_kOwner]);
        CloseListen();
    }
}
//K-Bar Settings Host 802 00 a end
