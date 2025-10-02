# MQL5 Economic Calendar Library

An optimized library for managing economic news events in MetaTrader 5 Expert Advisors, with support for both live trading and backtesting environments.

## Overview

This library provides a unified interface for accessing and filtering economic calendar events in MT5, helping traders avoid or manage positions during high-impact news releases. The library creates protective time windows around each news event and intelligently merges overlapping windows for optimal performance.

## Key Features

- **Dual Mode Support**: Seamlessly switches between live trading and backtesting implementations
- **Smart Time Windows**: Creates configurable protection periods around news events (e.g., 15 minutes before and after)
- **Window Optimization**: Automatically merges overlapping news windows into single, longer periods
- **Intelligent Caching**: Daily event caching with sub-millisecond response times
- **Multi-Symbol Support**: Efficiently handles all Market Watch currency pairs
- **Singleton Pattern**: Single instance throughout application lifecycle

## How It Works

The library creates protective time windows around each news event (configurable minutes before and after). When the `IsNewsTime()` method is called, it efficiently checks if the current time falls within any of these news windows.

When multiple news events have overlapping time windows, the library intelligently merges them into a single, longer window, providing:

- **Better Performance**: Fewer windows to check
- **Simplified Logic**: One continuous restriction period instead of multiple short ones  
- **Memory Efficiency**: Optimized data structures

## Architecture

### Core Components

- **IEconomicCalendar** - Abstract interface for all implementations
- **EconomicCalendar** - Live trading implementation using MT5's Calendar API
- **EconomicCalendarBacktesting** - Backtesting with pre-loaded historical data
- **News** - Historical data management for backtesting

### Class Hierarchy
```
IEconomicCalendar (Interface)
    ├── EconomicCalendar (Live Trading)
    └── EconomicCalendarBacktesting (Strategy Tester)
```

## Backtesting Setup

### Initial Data Collection
1. Run the Tester EA in **live mode**
2. Wait for complete event loading (all currencies)

### Using in Backtesting
After data collection, the `EconomicCalendarBacktesting` class provides the same interface as live trading but uses the pre-loaded historical data.

### Updating Data
Simply run the Tester EA again in live mode - it automatically appends new events from the last saved date to current date.

## Usage Example

```mql5
#include "EconomicCalendar.mqh"
#include "EconomicCalendarBacktesting.mqh"

IEconomicCalendar *calendar;

int OnInit() {
    // Automatic mode selection based on environment
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
            // Handle news period - close positions, pause trading, etc.
            Print("News protection active for ", _Symbol);
            
            // Optional: Get specific events in current window
            MqlCalendarValue events[];
            string eventNames[];
            if(calendar.GetNewsInTimeWindow(_Symbol, events, eventNames)) {
                for(int i = 0; i < ArraySize(events); i++) {
                    Print("Active: ", eventNames[i], " at ", TimeToString(events[i].time));
                }
            }
        }
    }
}

void OnDeinit(const int reason) {
    // Clean up resources
    if(MQL_TESTER) {
        EconomicCalendarBacktesting::ReleaseInstance();
    } else {
        EconomicCalendar::DestroyInstance();
    }
}
```

## Configuration

### Parameters
- **minuteBeforeNews**: Protection window start (minutes before event, default: 15)
- **minuteAfterNews**: Protection window end (minutes after event, default: 15)  
- **checkHighImpact**: Include high importance events (default: true)
- **checkMediumImpact**: Include medium importance events (default: false)
- **checkLowImpact**: Include low importance events (default: false)

### Runtime Updates
```mql5
// Update parameters dynamically
calendar.UpdateParameters(30, 30, true, true, false); // 30min before/after, high+medium impact
```

## Core Methods

### IsNewsTime()
Primary method to check if trading should be restricted.

```mql5
bool isNewsTime;
if(calendar.IsNewsTime("EURUSD", isNewsTime)) {
    if(isNewsTime) {
        // News protection active
    }
}
```

### GetNewsInTimeWindow()
Get detailed information about active news events.

```mql5
MqlCalendarValue events[];
string eventNames[];
if(calendar.GetNewsInTimeWindow("GBPUSD", events, eventNames)) {
    // Process active events
}
```

### DebugPrintTodayNews()
Development and debugging helper.

```mql5
calendar.DebugPrintTodayNews(); // Shows all windows for current day
```

## Performance Features

### Live Trading Optimizations
- **Daily Cache**: Events loaded once per day per currency
- **Smart Filtering**: Importance filtering at API level
- **Auto Cleanup**: Outdated cache entries removed automatically

### Backtesting Optimizations  
- **Pre-computed Windows**: All daily windows calculated at day start
- **Window Merging**: Overlapping events merged for efficiency
- **O(1) Lookups**: Same-second queries use cached results
- **Batch Processing**: All Market Watch symbols processed together

## Requirements & Important Notes

### Server Time Considerations
**Critical**: News events are saved with your broker's server time. When switching brokers:
1. **Delete** the existing news data file
2. **Regenerate** completely by running Tester EA in live mode
3. This ensures accurate timing alignment with the new broker's server time

## Testing & Debugging

The included `Tester.mq5` EA demonstrates:
- Automatic mode detection
- Day change handling
- News window state tracking  
- Event logging without repetition

Run it to see the library in action and understand the output format.

## Limitations

- Backtesting requires pre-loaded historical data
- News timestamps are broker-specific (server time)

## License

Copyright 2025, shems95. All rights reserved.

## Support

For issues, questions, or contributions, please open an issue on the GitHub repository.
