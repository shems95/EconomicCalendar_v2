//+------------------------------------------------------------------+
//|                                                         Time.mqh |
//|                                                 username Chris70 |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "username Chris70"
#property link      "https://www.mql5.com"

class CTime
  {
private:
   MqlDateTime tm;
   datetime servertime;
   bool initialized;
public:
   bool summertime;
   datetime GMT(ushort server_offset_winter,ushort server_offset_summer);
  };
  
//+------------------------------------------------------------------+
//| convert server time to GMT                                       |
//| (=for correct GMT time during both testing and live trading)     |
//+------------------------------------------------------------------+
datetime CTime::GMT(ushort server_offset_winter,ushort server_offset_summer)
  {
   // CASE 1: LIVE ACCOUNT
   if (!MQLInfoInteger(MQL_OPTIMIZATION) && !MQLInfoInteger(MQL_TESTER)){return TimeGMT();}
   
   // CASE 2: TESTER or OPTIMIZER
   servertime=TimeCurrent(); //=should be the same as TimeTradeServer() in tester mode, however, the latter sometimes leads to performance issues
   TimeToStruct(servertime,tm);
   // make a rough guess
   if (!initialized)
     {
      summertime=true;
      if (tm.mon<=2 || (tm.mon==3 && tm.day<=7)) {summertime=false;}
      if ((tm.mon==11 && tm.day>=8) || tm.mon==12) {summertime=false;}
      initialized=true;
     }
   // switch to summertime
   if (tm.mon==3 && tm.day>7 && tm.day_of_week==0 && tm.hour==7+server_offset_winter) // second sunday in march, 7h UTC New York=2h local winter time
     {
      summertime=true;
     }
   // switch to wintertime
   if (tm.mon==11 && tm.day<=7 && tm.day_of_week==0 && tm.hour==7+server_offset_summer) // first sunday in november, 7h UTC New York=2h local summer time
     {
      summertime=false;
     }
   if (summertime){return servertime-server_offset_summer*3600;}
   else {return servertime-server_offset_winter*3600;}
  }
