//+------------------------------------------------------------------+
//|                                                         News.mqh |
//|                                                 username Chris70 |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright  "username Chris70"
#property link       "https://www.mql5.com"

#include             "Time.mqh"  // use this line if the file is in the same folder
// #include             <Time.mqh>  // use this line if the file is in the shared include folder

enum ENUM_COUNTRY_ID
  {
   World=0,
   EU=999,////
   USA=840,
   Canada=124,//////
   Australia=36,/////
   NewZealand=554,////
   Japan=392,////
   China=156,/////
   UK=826,
   Switzerland=756,
   Germany=276,
   France=250,
   Italy=380,///////
   Spain=724,
   Brazil=76,
   SouthKorea=410
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CNews
  {
private:
   struct            EventStruct
     {
      ulong          value_id;
      ulong          event_id;
      datetime       time;
      datetime       period;
      int            revision;
      long           actual_value;
      long           prev_value;
      long           revised_prev_value;
      long           forecast_value;
      ENUM_CALENDAR_EVENT_IMPACT impact_type;
      ENUM_CALENDAR_EVENT_TYPE event_type;
      ENUM_CALENDAR_EVENT_SECTOR sector;
      ENUM_CALENDAR_EVENT_FREQUENCY frequency;
      ENUM_CALENDAR_EVENT_TIMEMODE timemode;
      ENUM_CALENDAR_EVENT_IMPORTANCE importance;
      ENUM_CALENDAR_EVENT_MULTIPLIER multiplier;
      ENUM_CALENDAR_EVENT_UNIT unit;
      uint           digits;
      ulong          country_id; // ISO 3166-1
     };
   CTime             time;
   string            future_eventname[];
public:
   EventStruct       event[];
   string            eventname[];
   int               SaveHistory(bool printlog_info=false);
   int               LoadHistory(bool printlog_info=false);
   int               update(int interval_seconds,bool printlog_info=false);
   int               next(int pointer_start,string currency,bool show_on_chart,long chart_id);
   string            CountryIdToCurrency(ENUM_COUNTRY_ID c);
   int               CurrencyToCountryId(string currency);
   datetime          last_update;
   ushort            GMT_offset_winter;
   ushort            GMT_offset_summer;
                     CNews(void)
     {
      ArrayResize(event,200000,0);
      ZeroMemory(event);
      ArrayResize(eventname,200000,0);
      ZeroMemory(eventname);
      ArrayResize(future_eventname,200000,0);
      ZeroMemory(future_eventname);
      GMT_offset_winter=2;
      GMT_offset_summer=3;
      last_update=0;
      SaveHistory(true);
      LoadHistory(true);
     }
                    ~CNews(void) {};
  };

//+------------------------------------------------------------------+
//| update news events (file and buffer arrays)                      |
//+------------------------------------------------------------------+
int CNews::update(int interval_seconds=60,bool printlog_info=false)
  {
   static datetime last_time=TimeCurrent();
   static int total_events=0;
   if(TimeCurrent()<last_time+interval_seconds)
     {
      return total_events;
     }
   SaveHistory();
   total_events=LoadHistory();
   return total_events;
  }

//+------------------------------------------------------------------+
//| grab news history and save it to disk                            |
//+------------------------------------------------------------------+
int CNews::SaveHistory(bool printlog_info=false)
  {
   datetime tm_gmt=time.GMT(GMT_offset_winter,GMT_offset_summer);
   int filehandle;

// create or open history file
   if(!FileIsExist("news\\newshistory.bin",FILE_COMMON))
     {
      filehandle=FileOpen("news\\newshistory.bin",FILE_READ|FILE_WRITE|FILE_SHARE_READ|FILE_SHARE_WRITE|FILE_COMMON|FILE_BIN);
      if(filehandle!=INVALID_HANDLE)
        {
         if(printlog_info)
           {
            Print(__FUNCTION__,": creating new file common/files/news/newshistory.bin");
           }
        }
      else
        {
         if(printlog_info)
           {
            Print(__FUNCTION__,"invalid filehandle, can't create news history file");
           }
         return 0;
        }
      FileSeek(filehandle,0,SEEK_SET);
      FileWriteLong(filehandle,(long)last_update);
     }
   else
     {
      filehandle=FileOpen("news\\newshistory.bin",FILE_READ|FILE_WRITE|FILE_SHARE_READ|FILE_SHARE_WRITE|FILE_COMMON|FILE_BIN);
      FileSeek(filehandle,0,SEEK_SET);
      last_update=(datetime)FileReadLong(filehandle);
      if(filehandle!=INVALID_HANDLE)
        {
         if(printlog_info)
           {
            Print(__FUNCTION__,": previous newshistory file found in common/files; history update starts from ",last_update," GMT");
           }
        }
      else
        {
         if(printlog_info)
           {
            Print(__FUNCTION__,": invalid filehandle; can't open previous news history file");
           };
         return 0;
        }
      bool from_beginning=FileSeek(filehandle,0,SEEK_END);
      if(!from_beginning)
        {
         Print(__FUNCTION__": unable to go to the file's beginning");
        }
     }
   if(last_update>tm_gmt)
     {
      if(printlog_info)
        {
         Print(__FUNCTION__,": time of last news update is in the future relative to timestamp of request; the existing data won't be overwritten/replaced,",
               "\nexecution of function therefore prohibited; only future events relative to this timestamp will be loaded");
        }
      return 0; //= number of new events since last update
     }

// get entire event history from last update until now
   MqlCalendarValue eventvaluebuffer[];
   ZeroMemory(eventvaluebuffer);
   MqlCalendarEvent eventbuffer;
   ZeroMemory(eventbuffer);
   
   ResetLastError();
   
   bool result = CalendarValueHistory(eventvaluebuffer,last_update); //If returns 0 events check Tools -> Options -> Community -> Put your Account a check is Calendar is selected
   
   if(!result)
     {
      Print("An error occured during loading news event: Error: " + GetLastError());
     }

   int number_of_events=ArraySize(eventvaluebuffer);
   int saved_elements=0;
   if(number_of_events>=ArraySize(event))
     {
      ArrayResize(event,number_of_events,0);
     }
   for(int i=0; i<number_of_events; i++)
     {
      event[i].value_id          =  eventvaluebuffer[i].id;
      event[i].event_id          =  eventvaluebuffer[i].event_id;
      event[i].time              =  eventvaluebuffer[i].time;
      event[i].period            =  eventvaluebuffer[i].period;
      event[i].revision          =  eventvaluebuffer[i].revision;
      event[i].actual_value      =  eventvaluebuffer[i].actual_value;
      event[i].prev_value        =  eventvaluebuffer[i].prev_value;
      event[i].revised_prev_value=  eventvaluebuffer[i].revised_prev_value;
      event[i].forecast_value    =  eventvaluebuffer[i].forecast_value;
      event[i].impact_type       =  eventvaluebuffer[i].impact_type;

      CalendarEventById(eventvaluebuffer[i].event_id,eventbuffer);

      event[i].event_type        =  eventbuffer.type;
      event[i].sector            =  eventbuffer.sector;
      event[i].frequency         =  eventbuffer.frequency;
      event[i].timemode          =  eventbuffer.time_mode;
      event[i].importance        =  eventbuffer.importance;
      event[i].multiplier        =  eventbuffer.multiplier;
      event[i].unit              =  eventbuffer.unit;
      event[i].digits            =  eventbuffer.digits;
      event[i].country_id        =  eventbuffer.country_id;
      if(event[i].event_type!=CALENDAR_TYPE_HOLIDAY &&            // ignore holiday events
         event[i].timemode==CALENDAR_TIMEMODE_DATETIME)           // only events with exactly published time
        {
         uint writenByte = FileWriteStruct(filehandle,event[i]);
         uint writenByte2 = FileWriteString(filehandle,eventbuffer.name,30);
         saved_elements++;
        }
     }
// renew update time
   FileSeek(filehandle,0,SEEK_SET);
   FileWriteLong(filehandle,(long)tm_gmt);
   FileClose(filehandle);
   if(printlog_info)
     {
      Print(__FUNCTION__,": ",number_of_events," total events found, ",saved_elements,
            " events saved (holiday events and events without exact published time are ignored)");
     }
   return saved_elements; //= number of new events since last update
  }

//+------------------------------------------------------------------+
//| load history                                                     |
//+------------------------------------------------------------------+
int CNews::LoadHistory(bool printlog_info=false)
  {
   datetime dt_gmt=time.GMT(GMT_offset_winter,GMT_offset_summer);
   int filehandle;
   int number_of_events=0;
// open history file
   if(FileIsExist("news\\newshistory.bin",FILE_COMMON))
     {
      filehandle=FileOpen("news\\newshistory.bin",FILE_READ|FILE_WRITE|FILE_SHARE_READ|FILE_SHARE_WRITE|FILE_COMMON|FILE_BIN);
      FileSeek(filehandle,0,SEEK_SET);
      last_update=(datetime)FileReadLong(filehandle);
      if(filehandle!=INVALID_HANDLE)
        {
         if(printlog_info)
           {
            Print(__FUNCTION__,": previous news history file found; last update was on ",last_update," (GMT)");
           }
        }
      else
        {
         if(printlog_info)
           {
            Print(__FUNCTION__,": can't open previous news history file; invalid file handle");
           }
         return 0;
        }

      ZeroMemory(event);
      // read all stored events
      int i=0;
      while(!FileIsEnding(filehandle) && !IsStopped())
        {
         if(ArraySize(event)<i+1)
           {ArrayResize(event,i+1000);}
         FileReadStruct(filehandle,event[i]);
         eventname[i]=FileReadString(filehandle,30);
         i++;
        }
      number_of_events=i;
      // FileClose(filehandle);
      if(printlog_info)
        {Print(__FUNCTION__,": loading of event history completed (",number_of_events," events), continuing with events after ",last_update," (GMT) ...");}
     }
   else
     {
      if(printlog_info)
        {Print(__FUNCTION__,": no newshistory file found, only upcoming events will be loaded");}
      last_update=dt_gmt;
     }

// get future events
   MqlCalendarValue eventvaluebuffer[];
   ZeroMemory(eventvaluebuffer);
   MqlCalendarEvent eventbuffer;
   ZeroMemory(eventbuffer);
   CalendarValueHistory(eventvaluebuffer,last_update,0);
   int future_events=ArraySize(eventvaluebuffer);
   if(printlog_info)
     {Print(__FUNCTION__,": ",future_events," new events found (holiday events and events without published exact time will be ignored)");}
   EventStruct future[];
   ArrayResize(future,future_events,0);
   ZeroMemory(future);
   ArrayResize(event,number_of_events+future_events);
   ArrayResize(eventname,number_of_events+future_events);
   for(int i=0; i<future_events; i++)
     {

      future[i].value_id          =  eventvaluebuffer[i].id;
      future[i].event_id          =  eventvaluebuffer[i].event_id;
      future[i].time              =  eventvaluebuffer[i].time;
      future[i].period            =  eventvaluebuffer[i].period;
      future[i].revision          =  eventvaluebuffer[i].revision;
      future[i].actual_value      =  eventvaluebuffer[i].actual_value;
      future[i].prev_value        =  eventvaluebuffer[i].prev_value;
      future[i].revised_prev_value=  eventvaluebuffer[i].revised_prev_value;
      future[i].forecast_value    =  eventvaluebuffer[i].forecast_value;
      future[i].impact_type       =  eventvaluebuffer[i].impact_type;

      CalendarEventById(eventvaluebuffer[i].event_id,eventbuffer);

      future[i].event_type        =  eventbuffer.type;
      future[i].sector            =  eventbuffer.sector;
      future[i].frequency         =  eventbuffer.frequency;
      future[i].timemode          =  eventbuffer.time_mode;
      future[i].importance        =  eventbuffer.importance;
      future[i].multiplier        =  eventbuffer.multiplier;
      future[i].unit              =  eventbuffer.unit;
      future[i].digits            =  eventbuffer.digits;
      future[i].country_id        =  eventbuffer.country_id;
      future_eventname[i]         =  eventbuffer.name;
      if(future[i].event_type!=CALENDAR_TYPE_HOLIDAY &&            // ignore holiday events
         future[i].timemode==CALENDAR_TIMEMODE_DATETIME)           // only events with exactly published time
        {
         number_of_events++;
         event[number_of_events]=future[i];
         eventname[number_of_events]=future_eventname[i];
        }
     }
   if(printlog_info)
     {Print(__FUNCTION__,": loading of news history completed, ",number_of_events," events in memory");}
   last_update=dt_gmt;
   return number_of_events;
  }

// +------------------------------------------------------------------+
// | get pointer to next event for given currency                     |
// +------------------------------------------------------------------+
int CNews::next(int pointer_start,string currency,bool show_on_chart,long chart_id)
  {
   datetime dt_gmt=time.GMT(GMT_offset_winter,GMT_offset_summer);
   for(int p=pointer_start; p<ArraySize(event); p++)
     {
      if
      (
         event[p].country_id==CurrencyToCountryId(currency) &&
         event[p].time>=dt_gmt
      )
        {
         if(pointer_start!=p && show_on_chart && MQLInfoInteger(MQL_VISUAL_MODE))
           {
            ObjectCreate(chart_id,"event "+IntegerToString(p),OBJ_VLINE,0,event[p].time+TimeTradeServer()-dt_gmt,0);
            ObjectSetInteger(chart_id,"event "+IntegerToString(p),OBJPROP_WIDTH,3);
            ObjectCreate(chart_id,"label "+IntegerToString(p),OBJ_TEXT,0,event[p].time+TimeTradeServer()-dt_gmt,SymbolInfoDouble(Symbol(),SYMBOL_BID));
            ObjectSetInteger(chart_id,"label "+IntegerToString(p),OBJPROP_YOFFSET,800);
            ObjectSetInteger(chart_id,"label "+IntegerToString(p),OBJPROP_BACK,true);
            ObjectSetString(chart_id,"label "+IntegerToString(p),OBJPROP_FONT,"Arial");
            ObjectSetInteger(chart_id,"label "+IntegerToString(p),OBJPROP_FONTSIZE,10);
            ObjectSetDouble(chart_id,"label "+IntegerToString(p),OBJPROP_ANGLE,-90);
            ObjectSetString(chart_id,"label "+IntegerToString(p),OBJPROP_TEXT,eventname[p]);
           }
         return p;
        }
     }
   return pointer_start;
  }

//+------------------------------------------------------------------+
//| country id to currency                                           |
//+------------------------------------------------------------------+
string CNews::CountryIdToCurrency(ENUM_COUNTRY_ID c)
  {
   switch(c)
     {
      case 999:
         return "EUR";     // EU
      case 276:
         return "EUR";     // Germany
      case 250:
         return "EUR";     // France
      case 380:
         return "EUR";     // Italy
      case 724:
         return "EUR";     // Spain
      case 840:
         return "USD";     // USA
      case 36:
         return "AUD";     // Australia
      case 554:
         return "NZD";     // NewZealand
      case 156:
         return "CYN";     // China
      case 826:
         return "GBP";     // UK
      case 756:
         return "CHF";     // Switzerland
      case 76:
         return "BRL";     // Brazil
      case 410:
         return "KRW";     // South Korea
      case 392:
         return "JPY";     //Japan
      case 124:
         return "CAD";     //Canada
         
         default:
         return "";
     }
  }

//+------------------------------------------------------------------+
//| currency to country id                                           |
//+------------------------------------------------------------------+
int CNews::CurrencyToCountryId(string currency)
  {
   if(currency=="EUR")
     {
      return 999;
     }
   if(currency=="USD")
     {
      return 840;
     }
   if(currency=="AUD")
     {
      return 36;
     }
   if(currency=="NZD")
     {
      return 554;
     }
   if(currency=="CYN")
     {
      return 156;
     }
   if(currency=="GBP")
     {
      return 826;
     }
   if(currency=="CHF")
     {
      return 756;
     }
   if(currency=="BRL")
     {
      return 76;
     }
   if(currency=="KRW")
     {
      return 410;
     }
   return 0;
  }
//+------------------------------------------------------------------