//+------------------------------------------------------------------+
//|                                                       Tester.mq5 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#include "News.mqh"
#include "..\EconomicCalendarBacktesting.mqh"
#include "..\EconomicCalendar.mqh"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
IEconomicCalendar *calendar;
datetime lastDay = 0;  // Track current day to detect day changes
bool lastNewsTimeState = false;  // Track previous news time state

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   
   if(MQL_TESTER) {
      calendar = EconomicCalendarBacktesting::GetInstance(15, 15, true, false, false);
   } else {
      calendar = EconomicCalendar::GetInstance(15, 15, true, false, false);
   }
   
   lastNewsTimeState = false;
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {

}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
   // Check if a new day has started
   datetime currentDay = GetDayStartTime(TimeCurrent());
   if(currentDay != lastDay) {
      lastDay = currentDay;
      lastNewsTimeState = false;  // Reset state for new day
      Print("\n[Tester] New day started: ", TimeToString(currentDay, TIME_DATE));
      calendar.DebugPrintTodayNews();
   }

   bool isNewsTime;
   if(calendar.IsNewsTime(_Symbol, isNewsTime)) {
      // Print only when ENTERING the news time window
      if(isNewsTime && !lastNewsTimeState) {
         Print("[", TimeToString(TimeCurrent(), TIME_MINUTES), "] Entering news time window for ", _Symbol);
         
         //CloseAllPositions()
         
         // Get events in current time window
         MqlCalendarValue events[];
         string eventNames[];
         
         if(calendar.GetNewsInTimeWindow(_Symbol, events, eventNames)) {
            Print("Active events:");
            
            for(int i = 0; i < ArraySize(events); i++) {
               Print("  - ", TimeToString(events[i].time, TIME_MINUTES), ": ", eventNames[i]);
            }
         } else {
            Print("  No specific events found in window");
         }
      }
      // Optional: print when EXITING the news time window
      else if(!isNewsTime && lastNewsTimeState) {
         Print("[", TimeToString(TimeCurrent(), TIME_MINUTES), "] Exited news time window for ", _Symbol);
      }
      
      // Update state
      lastNewsTimeState = isNewsTime;
   } else {
      Print("[ERROR] Failed to check news time for ", _Symbol);
   }
}

//+------------------------------------------------------------------+
//| Helper function to get day start time                           |
//+------------------------------------------------------------------+
datetime GetDayStartTime(datetime time) {
   MqlDateTime dt;
   TimeToStruct(time, dt);
   dt.hour = 0;
   dt.min = 0;
   dt.sec = 0;
   return StructToTime(dt);
}
//+------------------------------------------------------------------+