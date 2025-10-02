# MQL5 Economic Calendar Library

A robust and optimized library for managing economic news events in MetaTrader 5 Expert Advisors, with support for both live trading and backtesting environments.

## Overview

This library provides a unified interface for accessing and filtering economic calendar events in MT5, helping traders avoid or manage positions during high-impact news releases. It features intelligent caching, optimized performance, and seamless switching between live and backtesting modes.

## Features

- **Dual Mode Support**: Automatically switches between live trading (`EconomicCalendar`) and backtesting (`EconomicCalendarBacktesting`) implementations
- **Singleton Pattern**: Ensures single instance throughout the application lifecycle
- **Smart Caching**: Daily event caching to minimize API calls and improve performance
- **Flexible Filtering**: Configure importance levels (High/Medium/Low) and time windows around events
- **Multi-Symbol Support**: Efficiently handles multiple currency pairs from Market Watch
- **Optimized Performance**: Sub-millisecond response times through intelligent caching strategies

## Architecture

### Core Components

- **IEconomicCalendar** - Abstract interface defining the contract for all implementations
- **EconomicCalendar** - Live trading implementation using MT5's native Calendar API
- **EconomicCalendarBacktesting** - Backtesting implementation using pre-loaded historical data
- **News** - Helper class for managing historical news data in backtesting mode

### Class Hierarchy
```
IEconomicCalendar (Interface)
    ├── EconomicCalendar (Live Trading)
    └── EconomicCalendarBacktesting (Strategy Tester)
```

## Usage

### Basic Implementation

```mql5
#include "EconomicCalendar.mqh"
#include "EconomicCalendarBacktesting.mqh"

IEconomicCalendar *calendar;

int OnInit() {
    // Automatic mode selection
    if(MQL_TESTER) {
        calendar = EconomicCalendarBacktesting::GetInstance(15, 15, true, false, false);
    } else {
        calendar = EconomicCalendar::GetInstance(15, 15, true, false, false);
    }
    return(INIT_SUCCEEDED);
}

void OnTick() {
    bool isNewsTime;
    if(calendar.IsNewsTime(_Symbol, isNewsTime)) {
        if(isNewsTime) {
            // Handle news time - e.g., close positions, pause trading
            Print("News event active for ", _Symbol);
        }
    }
}
```

### Configuration Parameters

- **minuteBeforeNews**: Minutes before event to start the protection window (default: 15)
- **minuteAfterNews**: Minutes after event to end the protection window (default: 15)
- **checkHighImpact**: Include high importance events (default: true)
- **checkMediumImpact**: Include medium importance events (default: false)
- **checkLowImpact**: Include low importance events (default: false)

## Key Methods

### IsNewsTime()
Checks if current time falls within a news event window for the specified symbol.

```mql5
bool isNewsTime;
if(calendar.IsNewsTime("EURUSD", isNewsTime)) {
    if(isNewsTime) {
        // Trading restricted due to news
    }
}
```

### GetNewsInTimeWindow()
Retrieves all events within the current time window for a symbol.

```mql5
MqlCalendarValue events[];
string eventNames[];
if(calendar.GetNewsInTimeWindow("GBPUSD", events, eventNames)) {
    for(int i = 0; i < ArraySize(events); i++) {
        Print(eventNames[i], " at ", TimeToString(events[i].time));
    }
}
```

### DebugPrintTodayNews()
Prints all windows scheduled for the current day (debugging).

```mql5
calendar.DebugPrintTodayNews();
```

### EconomicCalendar (Live)

- **Daily Cache**: Events loaded once per day per currency
- **Smart Filtering**: Events filtered by importance at retrieval
- **Automatic Cache Cleanup**: Removes outdated entries automatically

### EconomicCalendarBacktesting

- **Pre-computed Windows**: News windows calculated once at day start
- **Window Merging**: Overlapping events merged into single windows
- **O(1) Lookups**: Same-second queries return cached results instantly
- **Optimized Symbol Handling**: All Market Watch symbols processed in batch

## Testing

The included `Tester.mq5` demonstrates proper usage:

- Day change detection and cache refresh
- State tracking to avoid repeated notifications
- Event window entry/exit handling
- Clean output formatting

## Requirements

- MetaTrader 5 Build 2361 or higher
- For backtesting: Historical news data file (News.mqh format)
- Active internet connection for live trading mode

## File Structure

```
├── IEconomicCalendar.mqh          # Interface definition
├── EconomicCalendar.mqh           # Live implementation
├── EconomicCalendarBacktesting.mqh # Backtest implementation
├── Backtesting/
│   └── News.mqh                   # Historical data handler
└── Tester.mq5                     # Usage example
```


## Limitations

- Backtesting requires pre-loaded historical data
- Live mode depends on MT5's Calendar API availability
- Cache refreshes at midnight (server time)
- Maximum one day of events cached in memory

## License

Copyright 2025, shems95. All rights reserved.

## Support

For issues, questions, or contributions, please open an issue on the GitHub repository.