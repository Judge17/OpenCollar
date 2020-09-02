key     g_kLineID;
integer g_iLineNr;

string  SECRET = "Put your passphrase here.";
integer PASSES = 6;
 
list ASCII_TABLE = [    "",  "",  "",  "",  "",  "",  "",  "",
                        "",  "",  "",  "",  "", "\n", "",  "",
                        "",  "",  "",  "",  "",  "",  "",  "",
                        "",  "",  "",  "",  "",  "",  "",  "",
                        " ", "!","\"", "#", "$", "%", "&", "'",
                        "(", ")", "*", "+", ",", "-", ".", "/",
                        "0", "1", "2", "3", "4", "5", "6", "7",
                        "8", "9", ":", ";", "<", "=", ">", "?",
                        "@", "A", "B", "C", "D", "E", "F", "G",
                        "H", "I", "J", "K", "L", "M", "N", "O",
                        "P", "Q", "R", "S", "T", "U", "V", "W",
                        "X", "Y", "Z", "[","\\", "]", "^", "_", /*"/**/
                        "`", "a", "b", "c", "d", "e", "f", "g", 
                        "h", "i", "j", "k", "l", "m", "n", "o", 
                        "p", "q", "r", "s", "t", "u", "v", "w", 
                        "x", "y", "z", "{", "|", "}", "~", ""  ];

string XTEAEncryptBase64( string clear, integer nonce )
{
    string  md5 = llMD5String( SECRET, nonce );
    list    k = [   (integer)("0x"+llGetSubString(md5,0,7)),
                    (integer)("0x"+llGetSubString(md5,8,15)),
                    (integer)("0x"+llGetSubString(md5,16,23)),
                    (integer)("0x"+llGetSubString(md5,24,31)) ];
    integer w1;
    integer w2;
    string  cipher;
    integer len = llStringLength( clear ); 
    integer i;
    integer n;
    integer sum;
    for( i=0; i<len; i+=8 )
    {
        w1 =
            (llListFindList(ASCII_TABLE,[llGetSubString(clear,i,i)])) |
            (llListFindList(ASCII_TABLE,[llGetSubString(clear,i+1,i+1)])<<8) |
            (llListFindList(ASCII_TABLE,[llGetSubString(clear,i+2,i+2)])<<16) |
            (llListFindList(ASCII_TABLE,[llGetSubString(clear,i+3,i+3)])<<24);
        w2 =
            (llListFindList(ASCII_TABLE,[llGetSubString(clear,i+4,i+4)])) |
            (llListFindList(ASCII_TABLE,[llGetSubString(clear,i+5,i+5)])<<8) |
            (llListFindList(ASCII_TABLE,[llGetSubString(clear,i+6,i+6)])<<16) |
            (llListFindList(ASCII_TABLE,[llGetSubString(clear,i+7,i+7)])<<24);
        n = PASSES;
        sum = 0;
        do
        {
            w1 = w1+((w2<<4^w2>>5)+w2^sum+llList2Integer(k,(sum&3)));
            w2 = w2+((w1<<4^w1>>5)+w1^sum+llList2Integer(k,((sum+=0x9E3779B9)>>11&3)));
        } while( n = ~-n );
        cipher = cipher + llGetSubString(llIntegerToBase64(w1),0,5) + llGetSubString(llIntegerToBase64(w2),0,5);
    }  
    return cipher;        
}
 
string XTEADecryptBase64( string cipher, integer nonce )
{
    string  md5 = llMD5String( SECRET, nonce );
    list    k = [   (integer)("0x"+llGetSubString(md5,0,7)),
                    (integer)("0x"+llGetSubString(md5,8,15)),
                    (integer)("0x"+llGetSubString(md5,16,23)),
                    (integer)("0x"+llGetSubString(md5,24,31)) ];
    integer w1;
    integer w2;
    string  clear;
    integer i;
    integer len = llStringLength(cipher);
    integer n;
    integer sum;
    integer dc = 0x9E3779B9*PASSES;
    integer ind;
    for( i=0; i<len; i+=12 )
    {
        w1 = llBase64ToInteger(llGetSubString(cipher,i,i+5));
        w2 = llBase64ToInteger(llGetSubString(cipher,i+6,i+11));
        n = PASSES;
        sum = dc;
        do
        {
            w2 = w2-((w1<<4^w1>>5)+w1^sum+llList2Integer(k,(sum>>11&3)));
            w1 = w1-((w2<<4^w2>>5)+w2^sum+llList2Integer(k,((sum-=0x9E3779B9)&3)));
        } while( n = ~-n );
        clear +=    llList2String(ASCII_TABLE,w1&0x7f) +
                    llList2String(ASCII_TABLE,(w1&0x7f00)>>8) +
                    llList2String(ASCII_TABLE,(w1&0x7f0000)>>16) +
                    llList2String(ASCII_TABLE,(w1&0x7f000000)>>24) +
                    llList2String(ASCII_TABLE,w2&0x7f) +
                    llList2String(ASCII_TABLE,(w2&0x7f00)>>8) +
                    llList2String(ASCII_TABLE,(w2&0x7f0000)>>16) +
                    llList2String(ASCII_TABLE,(w2&0x7f000000)>>24);
    }
    return clear;        
}

default
{
    on_rez(integer iParam) {
        g_iLineNr = 1;
        g_kLineID = llGetNotecardLine("testcard", g_iLineNr);
    }

    dataserver(key kID, string sData) {
        if (kID == g_kLineID) {
            if (sData != EOF) {
                string e=XTEAEncryptBase64( sData, 20656 );
                string s=XTEADecryptBase64( e, 20656 );
                llOwnerSay(sData + " = " + e + " | " + s);
                g_kLineID = llGetNotecardLine("testcard", ++g_iLineNr);
            } 
        }
    }
}
