//+------------------------------------------------------------------+
//|                                            IEconomicCalendar.mqh |
//|                                                      shems95     |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, shems95"
#property version   "1.00"
interface IEconomicCalendar {
   bool  IsNewsTime(string symbol, bool &result);

   bool GetNewsInTimeWindow(string symbol,
                            MqlCalendarValue &events[],
                            string &eventNames[]);

   void                 DebugPrintTodayNews();
};
//+------------------------------------------------------------------+
