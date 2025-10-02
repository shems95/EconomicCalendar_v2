//+------------------------------------------------------------------+
//|                                             EconomicCalendar.mqh |
//|                                                      shems95     |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, shems95"
#property version   "1.02"

#include <Generic\ArrayList.mqh>
#include <Generic\HashSet.mqh>
#include "IEconomicCalendar.mqh"

//+------------------------------------------------------------------+
//| Enum for news importance                                        |
//+------------------------------------------------------------------+
enum NewsImportance {
   IMPORTANCE_HIGH,
   IMPORTANCE_MEDIUM,
   IMPORTANCE_LOW,
   IMPORTANCE_UNKNOWN
};

//+------------------------------------------------------------------+
//| Updated News struct                                             |
//+------------------------------------------------------------------+
struct News {
   string          title;
   string          country;
   datetime        dateTime;
   NewsImportance  importance;
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class EconomicCalendar : public IEconomicCalendar {
private:
   // Singleton instance
   static EconomicCalendar* s_instance;
   
   uint   minuteBeforeNews;
   uint   minuteAfterNews;
   bool   checkHighImportance;
   bool   checkMediumImportance;
   bool   checkLowImportance;

   // Daily cache for events
   struct DailyCacheEntry {
      string currency;
      datetime cacheDate;  // Day date (without time)
      MqlCalendarValue events[];  // All events of the day
   };
   DailyCacheEntry m_dailyCache[];
   
   // Private constructor for singleton
   EconomicCalendar(uint minuteBeforeAfterNews, bool checkHighImportance = true, bool checkMediumImportance = false, bool checkLowImportance = false);
   EconomicCalendar(uint minuteBeforeNews, uint minuteAfterNews, bool checkHighImportance = true, bool checkMediumImportance = false, bool checkLowImportance = false);
   
   // Private destructor
   ~EconomicCalendar();

public:
   // Singleton access methods
   static EconomicCalendar* GetInstance(uint minuteBeforeAfterNews = 30, bool checkHighImportance = true, bool checkMediumImportance = false, bool checkLowImportance = false);
   static EconomicCalendar* GetInstance(uint minuteBeforeNews, uint minuteAfterNews, bool checkHighImportance = true, bool checkMediumImportance = false, bool checkLowImportance = false);
   static void DestroyInstance();
   
   // Interface implementation
   bool GetNewsInTimeWindow(string symbol, MqlCalendarValue &events[], string &eventNames[]);
   bool IsNewsTime(string symbol, bool &result);
   void DebugPrintNextEvents(string symbol, int maxEvents = 5);
   void DebugPrintTodayNews();

private:
   // Maps a calendar value to a News struct
   void MapNews(MqlCalendarValue &value, News &news);

   // Filters by importance according to configuration
   void FilterByImportance(MqlCalendarValue &sourceValues[], MqlCalendarValue &filteredValues[]);

   // Retrieves current news for specified currencies
   bool GetActualNews(string &currencies[], News &newsListResult[]);
   
   // Gets the day date (midnight)
   datetime GetDayStartTime(datetime time);
   
   // Loads all daily events for a currency
   bool LoadDailyEvents(string currency);
   
   // Cleans cache from previous days
   void CleanOldCache();
};

//+------------------------------------------------------------------+
//| Static member initialization                                     |
//+------------------------------------------------------------------+
EconomicCalendar* EconomicCalendar::s_instance = NULL;

//+------------------------------------------------------------------+
//| Singleton GetInstance methods                                    |
//+------------------------------------------------------------------+
static EconomicCalendar* EconomicCalendar::GetInstance(uint minuteBeforeAfterNews = 30, bool checkHighImportance = true, bool checkMediumImportance = false, bool checkLowImportance = false) {
   if(s_instance == NULL) {
      s_instance = new EconomicCalendar(minuteBeforeAfterNews, checkHighImportance, checkMediumImportance, checkLowImportance);
   }
   return s_instance;
}

static EconomicCalendar* EconomicCalendar::GetInstance(uint minuteBeforeNews, uint minuteAfterNews, bool checkHighImportance = true, bool checkMediumImportance = false, bool checkLowImportance = false) {
   if(s_instance == NULL) {
      s_instance = new EconomicCalendar(minuteBeforeNews, minuteAfterNews, checkHighImportance, checkMediumImportance, checkLowImportance);
   }
   return s_instance;
}

static void EconomicCalendar::DestroyInstance() {
   if(s_instance != NULL) {
      delete s_instance;
      s_instance = NULL;
   }
}

//+------------------------------------------------------------------+
//| Constructors                                                     |
//+------------------------------------------------------------------+
EconomicCalendar::EconomicCalendar(uint minuteBeforeAfterNews, bool checkHighImportance, bool checkMediumImportance, bool checkLowImportance) {
   this.minuteBeforeNews = minuteBeforeAfterNews;
   this.minuteAfterNews = minuteBeforeAfterNews;
   this.checkHighImportance = checkHighImportance;
   this.checkMediumImportance = checkMediumImportance;
   this.checkLowImportance = checkLowImportance;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
EconomicCalendar::EconomicCalendar(uint minuteBeforeNews, uint minuteAfterNews, bool checkHighImportance, bool checkMediumImportance, bool checkLowImportance) {
   this.minuteBeforeNews = minuteBeforeNews;
   this.minuteAfterNews = minuteAfterNews;
   this.checkHighImportance = checkHighImportance;
   this.checkMediumImportance = checkMediumImportance;
   this.checkLowImportance = checkLowImportance;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
EconomicCalendar::~EconomicCalendar() {
}

//+------------------------------------------------------------------+
//| Gets the day date (midnight)                                    |
//+------------------------------------------------------------------+
datetime EconomicCalendar::GetDayStartTime(datetime time) {
   MqlDateTime dt;
   TimeToStruct(time, dt);
   dt.hour = 0;
   dt.min = 0;
   dt.sec = 0;
   return StructToTime(dt);
}

//+------------------------------------------------------------------+
//| Loads all daily events for a currency                           |
//+------------------------------------------------------------------+
bool EconomicCalendar::LoadDailyEvents(string currency) {
   datetime currentDay = GetDayStartTime(TimeCurrent());
   
   // Check if we already have the cache for today
   for(int i = 0; i < ArraySize(m_dailyCache); i++) {
      if(m_dailyCache[i].currency == currency && m_dailyCache[i].cacheDate == currentDay) {
         return true; // Already in cache
      }
   }
   
   // Load events for the entire day
   datetime dayStart = currentDay;
   datetime dayEnd = dayStart + 86400; // +24 hours
   
   MqlCalendarValue allEvents[];
   if(!CalendarValueHistory(allEvents, dayStart, dayEnd, "", currency)) {
      Print("[WARNING] EconomicCalendar::LoadDailyEvents: No events for ", currency, " today");
      // Add empty entry to avoid repeated requests
      int cacheIdx = ArraySize(m_dailyCache);
      ArrayResize(m_dailyCache, cacheIdx + 1);
      m_dailyCache[cacheIdx].currency = currency;
      m_dailyCache[cacheIdx].cacheDate = currentDay;
      ArrayResize(m_dailyCache[cacheIdx].events, 0);
      return true;
   }
   
   // Add to cache
   int cacheIdx = ArraySize(m_dailyCache);
   ArrayResize(m_dailyCache, cacheIdx + 1);
   m_dailyCache[cacheIdx].currency = currency;
   m_dailyCache[cacheIdx].cacheDate = currentDay;
   
   // Copy events
   int eventCount = ArraySize(allEvents);
   ArrayResize(m_dailyCache[cacheIdx].events, eventCount);
   ArrayCopy(m_dailyCache[cacheIdx].events, allEvents);
   
   Print("[INFO] Loaded ", eventCount, " events for ", currency, " today");
   return true;
}

//+------------------------------------------------------------------+
//| Checks if there's relevant news for the symbol                  |
//+------------------------------------------------------------------+
bool EconomicCalendar::IsNewsTime(string symbol, bool &result) {
   string baseCurrency = SymbolInfoString(symbol, SYMBOL_CURRENCY_BASE);
   string profitCurrency = SymbolInfoString(symbol, SYMBOL_CURRENCY_PROFIT);
   
   // Error handling if symbol is not valid
   if(baseCurrency == "" || profitCurrency == "") {
      Print("[ERROR] EconomicCalendar::IsNewsTime: Invalid symbol: ", symbol);
      return false;
   }

   string currencies[];
   ArrayResize(currencies, 2);
   currencies[0] = baseCurrency;
   currencies[1] = profitCurrency;

   News newsList[];
   
   if(!GetActualNews(currencies, newsList)) {
      Print("[ERROR] EconomicCalendar::IsNewsTime: GetActualNews failed");
      return false;
   }

   result = ArraySize(newsList) > 0;
   return true;
}

//+------------------------------------------------------------------+
//| Retrieves news in time window for the symbol                    |
//+------------------------------------------------------------------+
bool EconomicCalendar::GetNewsInTimeWindow(string symbol, MqlCalendarValue &events[], string &eventNames[]) {
   string baseCurrency = SymbolInfoString(symbol, SYMBOL_CURRENCY_BASE);
   string profitCurrency = SymbolInfoString(symbol, SYMBOL_CURRENCY_PROFIT);
   
   if(baseCurrency == "" || profitCurrency == "") {
      Print("[ERROR] EconomicCalendar::GetNewsInTimeWindow: Invalid symbol: ", symbol);
      return false;
   }
   
   // Load daily events for both currencies
   string currencies[] = {baseCurrency, profitCurrency};
   for(int i = 0; i < 2; i++) {
      LoadDailyEvents(currencies[i]);
   }
   
   datetime currentTime = TimeCurrent();
   datetime fromDateTime = currentTime - (minuteBeforeNews * 60);
   datetime toDateTime = currentTime + (minuteAfterNews * 60);
   
   // Retrieve events from daily cache
   MqlCalendarValue tempEvents[];
   int totalEvents = 0;
   
   for(int i = 0; i < 2; i++) {
      // Find cache for this currency
      int cacheIndex = -1;
      for(int c = 0; c < ArraySize(m_dailyCache); c++) {
         if(m_dailyCache[c].currency == currencies[i] && 
            m_dailyCache[c].cacheDate == GetDayStartTime(currentTime)) {
            cacheIndex = c;
            break;
         }
      }
      
      if(cacheIndex != -1 && ArraySize(m_dailyCache[cacheIndex].events) > 0) {
         // Filter events in time window
         for(int j = 0; j < ArraySize(m_dailyCache[cacheIndex].events); j++) {
            if(m_dailyCache[cacheIndex].events[j].time >= fromDateTime && 
               m_dailyCache[cacheIndex].events[j].time <= toDateTime) {
               int idx = totalEvents++;
               ArrayResize(tempEvents, totalEvents);
               tempEvents[idx] = m_dailyCache[cacheIndex].events[j];
            }
         }
      }
   }
   
   // Filter by importance
   FilterByImportance(tempEvents, events);
   
   // Retrieve event names
   int eventCount = ArraySize(events);
   ArrayResize(eventNames, eventCount);
   
   for(int i = 0; i < eventCount; i++) {
      MqlCalendarEvent event;
      if(CalendarEventById(events[i].event_id, event)) {
         eventNames[i] = event.name;
      } else {
         eventNames[i] = "Unknown Event";
      }
   }
   
   return eventCount > 0;
}

//+------------------------------------------------------------------+
//| Prints next events for debugging                                |
//+------------------------------------------------------------------+
void EconomicCalendar::DebugPrintNextEvents(string symbol, int maxEvents) {
   MqlCalendarValue events[];
   string eventNames[];
   
   if(GetNewsInTimeWindow(symbol, events, eventNames)) {
      Print("=== Next events for ", symbol, " ===");
      int count = MathMin(maxEvents, ArraySize(events));
      
      for(int i = 0; i < count; i++) {
         MqlCalendarEvent event;
         MqlCalendarCountry country;
         if(CalendarEventById(events[i].event_id, event)) {
            string importance = "";
            switch(event.importance) {
               case CALENDAR_IMPORTANCE_HIGH: importance = "HIGH"; break;
               case CALENDAR_IMPORTANCE_MODERATE: importance = "MEDIUM"; break;
               case CALENDAR_IMPORTANCE_LOW: importance = "LOW"; break;
               default: importance = "NONE"; break;
            }
            
            string currencyCode = "";
            if(CalendarCountryById(event.country_id, country)) {
               currencyCode = country.currency;
            }
            
            Print(TimeToString(events[i].time), " - ", eventNames[i], 
                  " [", importance, "] - ", currencyCode);
         }
      }
      Print("========================");
   } else {
      Print("No events found for ", symbol);
   }
}

//+------------------------------------------------------------------+
//| Cleans cache from previous days                                 |
//+------------------------------------------------------------------+
void EconomicCalendar::CleanOldCache() {
   datetime currentDay = GetDayStartTime(TimeCurrent());
   int validEntries = 0;
   
   // Count entries for current day
   for(int i = 0; i < ArraySize(m_dailyCache); i++) {
      if(m_dailyCache[i].cacheDate == currentDay) {
         validEntries++;
      }
   }
   
   // If all are valid, do nothing
   if(validEntries == ArraySize(m_dailyCache)) return;
   
   // Create new array with only current day entries
   DailyCacheEntry tempCache[];
   ArrayResize(tempCache, validEntries);
   int j = 0;
   
   for(int i = 0; i < ArraySize(m_dailyCache); i++) {
      if(m_dailyCache[i].cacheDate == currentDay) {
         tempCache[j] = m_dailyCache[i];
         j++;
      }
   }
   
   // Replace cache
   ArrayResize(m_dailyCache, validEntries);
   for(int i = 0; i < validEntries; i++) {
      m_dailyCache[i] = tempCache[i];
   }
}

//+------------------------------------------------------------------+
//| Filters by importance                                            |
//+------------------------------------------------------------------+
void EconomicCalendar::FilterByImportance(MqlCalendarValue &sourceValues[], MqlCalendarValue &filteredValues[]) {
   // Pre-allocate maximum space
   ArrayResize(filteredValues, ArraySize(sourceValues));
   int filteredIndex = 0;
   
   // Optimization: retrieve all events in batch if possible
   for(int i = 0; i < ArraySize(sourceValues); i++) {
      MqlCalendarEvent event;
      if(!CalendarEventById(sourceValues[i].event_id, event)) {
         continue; // Skip if unable to retrieve event
      }
      
      bool shouldInclude = false;
      switch(event.importance) {
         case CALENDAR_IMPORTANCE_HIGH:
            shouldInclude = checkHighImportance;
            break;
         case CALENDAR_IMPORTANCE_MODERATE:
            shouldInclude = checkMediumImportance;
            break;
         case CALENDAR_IMPORTANCE_LOW:
            shouldInclude = checkLowImportance;
            break;
         default:
            shouldInclude = false;
            break;
      }
      
      if(shouldInclude) {
         filteredValues[filteredIndex++] = sourceValues[i];
      }
   }
   
   // Resize to actual number of elements
   if(filteredIndex < ArraySize(sourceValues)) {
      ArrayResize(filteredValues, filteredIndex);
   }
}

//+------------------------------------------------------------------+
//| Retrieves current news for specified currencies                 |
//+------------------------------------------------------------------+
bool EconomicCalendar::GetActualNews(string &currencies[], News &newsListResult[]) {
   // Clean old cache (previous days)
   CleanOldCache();
   
   datetime currentTime = TimeCurrent();
   datetime fromDateTime = currentTime - (minuteBeforeNews * 60);
   datetime toDateTime = currentTime + (minuteAfterNews * 60);
   
   ArrayResize(newsListResult, 0);
   
   for(int i = 0; i < ArraySize(currencies); i++) {
      string currency = currencies[i];
      
      // Load daily events if not already in cache
      if(!LoadDailyEvents(currency)) {
         continue;
      }
      
      // Find cache for this currency
      int cacheIndex = -1;
      for(int c = 0; c < ArraySize(m_dailyCache); c++) {
         if(m_dailyCache[c].currency == currency && 
            m_dailyCache[c].cacheDate == GetDayStartTime(currentTime)) {
            cacheIndex = c;
            break;
         }
      }
      
      if(cacheIndex == -1 || ArraySize(m_dailyCache[cacheIndex].events) == 0) {
         continue;
      }
      
      // Filter events in time window
      MqlCalendarValue eventsInWindow[];
      int windowCount = 0;
      ArrayResize(eventsInWindow, ArraySize(m_dailyCache[cacheIndex].events));
      
      for(int j = 0; j < ArraySize(m_dailyCache[cacheIndex].events); j++) {
         if(m_dailyCache[cacheIndex].events[j].time >= fromDateTime && 
            m_dailyCache[cacheIndex].events[j].time <= toDateTime) {
            eventsInWindow[windowCount++] = m_dailyCache[cacheIndex].events[j];
         }
      }
      
      if(windowCount == 0) continue;
      
      ArrayResize(eventsInWindow, windowCount);
      
      // Filter by importance
      MqlCalendarValue filteredValues[];
      FilterByImportance(eventsInWindow, filteredValues);
      
      int filteredSize = ArraySize(filteredValues);
      if(filteredSize == 0) continue;
      
      // Add to results
      int oldSize = ArraySize(newsListResult);
      ArrayResize(newsListResult, oldSize + filteredSize);
      
      for(int j = 0; j < filteredSize; j++) {
         News news;
         MapNews(filteredValues[j], news);
         newsListResult[oldSize + j] = news;
      }
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Maps a calendar value to a News struct                          |
//+------------------------------------------------------------------+
void EconomicCalendar::MapNews(MqlCalendarValue &value, News &news) {
   MqlCalendarEvent event;
   MqlCalendarCountry country;

   if(!CalendarEventById(value.event_id, event)) {
      news.title = "Unknown Event";
      news.country = "Unknown";
      news.dateTime = value.time;
      news.importance = IMPORTANCE_UNKNOWN;
      return;
   }
   
   if(!CalendarCountryById(event.country_id, country)) {
      news.country = "Unknown Country";
   } else {
      news.country = country.name;
   }

   NewsImportance importance = IMPORTANCE_UNKNOWN;
   switch(event.importance) {
      case CALENDAR_IMPORTANCE_HIGH :
         importance = IMPORTANCE_HIGH;
         break;
      case CALENDAR_IMPORTANCE_MODERATE :
         importance = IMPORTANCE_MEDIUM;
         break;
      case CALENDAR_IMPORTANCE_LOW :
         importance = IMPORTANCE_LOW;
         break;
      default:
         importance = IMPORTANCE_UNKNOWN;
         break;
   }

   news.title = event.name;
   news.dateTime = value.time;
   news.importance = importance;
}

//+------------------------------------------------------------------+
//| Prints today's news for debugging                               |
//+------------------------------------------------------------------+
void EconomicCalendar::DebugPrintTodayNews() {
   datetime currentDay = GetDayStartTime(TimeCurrent());
   
   Print("=== [EconomicCalendar] Today's News ===");
   Print("Date: ", TimeToString(currentDay, TIME_DATE));
   Print("Cache entries: ", ArraySize(m_dailyCache));
   
   bool foundEvents = false;
   
   for(int i = 0; i < ArraySize(m_dailyCache); i++) {
      if(m_dailyCache[i].cacheDate == currentDay && ArraySize(m_dailyCache[i].events) > 0) {
         foundEvents = true;
         Print("\nCurrency: ", m_dailyCache[i].currency, " - Events: ", ArraySize(m_dailyCache[i].events));
         
         for(int j = 0; j < ArraySize(m_dailyCache[i].events); j++) {
            MqlCalendarEvent event;
            if(CalendarEventById(m_dailyCache[i].events[j].event_id, event)) {
               string importance = "";
               switch(event.importance) {
                  case CALENDAR_IMPORTANCE_HIGH: importance = "HIGH"; break;
                  case CALENDAR_IMPORTANCE_MODERATE: importance = "MEDIUM"; break;
                  case CALENDAR_IMPORTANCE_LOW: importance = "LOW"; break;
                  default: importance = "NONE"; break;
               }
               
               Print("  ", TimeToString(m_dailyCache[i].events[j].time, TIME_MINUTES), 
                     " - ", event.name, " [", importance, "]");
            } else {
               Print("  ", TimeToString(m_dailyCache[i].events[j].time, TIME_MINUTES), 
                     " - Unknown Event");
            }
         }
      }
   }
   
   if(!foundEvents) {
      Print("No events found for today");
   }
   
   Print("=====================================");
}

//+------------------------------------------------------------------+
//| Test function for the class                                     |
//+------------------------------------------------------------------+
void TestEconomicCalendar() {
   Print("=== Starting EconomicCalendar Test ===");
   
   // Test 1: Create singleton instance and verify news
   EconomicCalendar* calendar = EconomicCalendar::GetInstance(30, 30, true, true, false);
   bool hasNews1;
   
   Print("Test 1: Check news for EURUSD");
   if(calendar.IsNewsTime("EURUSD", hasNews1)) {
      Print("- Result: ", hasNews1 ? "THERE ARE news" : "NO news");
   } else {
      Print("- ERROR in news retrieval");
   }
   
   // Test 2: Verify daily cache (second call should use cache)
   bool hasNews2;
   Print("\nTest 2: Second call (daily cache test)");
   ulong startTime = GetMicrosecondCount();
   calendar.IsNewsTime("EURUSD", hasNews2);
   ulong elapsed = GetMicrosecondCount() - startTime;
   Print("- Execution time: ", elapsed, " microseconds");
   Print("- Result: ", hasNews2 ? "THERE ARE news" : "NO news");
   
   // Test 3: Invalid symbol
   bool hasNews3;
   Print("\nTest 3: Invalid symbol");
   bool result = calendar.IsNewsTime("INVALID", hasNews3);
   Print("- Expected result: false, Obtained result: ", result);
   
   // Test 4: Debug print events
   Print("\nTest 4: Debug print next events");
   calendar.DebugPrintNextEvents("EURUSD", 5);
   
   // Test 5: GetNewsInTimeWindow
   Print("\nTest 5: GetNewsInTimeWindow");
   MqlCalendarValue events[];
   string eventNames[];
   if(calendar.GetNewsInTimeWindow("GBPUSD", events, eventNames)) {
      Print("- Found ", ArraySize(events), " events");
      for(int i = 0; i < MathMin(3, ArraySize(events)); i++) {
         Print("  ", TimeToString(events[i].time), " - ", eventNames[i]);
      }
   } else {
      Print("- No events found");
   }
   
   // Test 6: Verify singleton (second instance should be the same)
   Print("\nTest 6: Verify singleton");
   EconomicCalendar* calendar2 = EconomicCalendar::GetInstance(60, 60, false, false, true);
   
   // Test 7: Cleanup
   Print("\nTest 7: Cleanup singleton");
   EconomicCalendar::DestroyInstance();
   Print("- Singleton destroyed");
   
   Print("\n=== End EconomicCalendar Test ===");
}
//+------------------------------------------------------------------+