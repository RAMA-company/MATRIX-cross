//+------------------------------------------------------------------+
//|                                            RamaEmpire_EA.mq5     |
//|                                  Copyright 2026, Rama Empire     |
//+------------------------------------------------------------------+
#property copyright "Rama Empire"
#property version   "1.20"
#property strict

#include <Trade\Trade.mqh>

input group "=== Signal Source ==="
input string   InpIndicatorName   = "MATRIX-cross-V3-Signal";
input int      InpMagicNumber     = 20260101;
input double   InpLotSize         = 0.01;
input int      InpSlippage        = 50;
input int      InpSignalBar       = 1;

input group "=== Timeframe Selection ==="
input bool   InpUse_M1  = true;
input bool   InpUse_M5  = true;
input bool   InpUse_M15 = true;
input bool   InpUse_M30 = true;
input bool   InpUse_H1  = true;
input bool   InpUse_H4  = true;
input bool   InpUse_D1  = true;

input group "=== Day Filter ==="
input bool   InpTrade_Sunday    = false;
input bool   InpTrade_Monday    = true;
input bool   InpTrade_Tuesday   = true;
input bool   InpTrade_Wednesday = true;
input bool   InpTrade_Thursday  = true;
input bool   InpTrade_Friday    = true;
input bool   InpTrade_Saturday  = false;

input group "=== Trading Time Filter ==="
input bool   InpUse_TimeFilter = false;
input int    InpStart_Hour     = 0;
input int    InpStart_Minute   = 0;
input int    InpEnd_Hour       = 23;
input int    InpEnd_Minute     = 59;

input group "=== Daily Blocked Hours (GMT+3:30) ==="
input bool   InpUse_DailyBlocked      = true;
input bool   InpBlocked_UseServerTime = false;
input int    InpBlocked_Start_Hour    = 4;
input int    InpBlocked_Start_Minute  = 0;
input int    InpBlocked_End_Hour      = 6;
input int    InpBlocked_End_Minute    = 0;
input int    InpBlocked_GMT_Offset    = 210;

input group "=== News Filter ==="
input bool   InpUse_NewsFilter      = false;
input int    InpNews_Minutes_Before = 30;
input int    InpNews_Minutes_After  = 30;

CTrade trade;
int    indicatorHandle = INVALID_HANDLE;
double tfStates[7];

#define BUF_STATE_CURRENT 5
#define BUF_STATE_M5      6
#define BUF_STATE_M15     7
#define BUF_STATE_M30     8
#define BUF_STATE_H1      9
#define BUF_STATE_H4      10
#define BUF_STATE_D1      11

//+------------------------------------------------------------------+
int OnInit()
  {
   trade.SetExpertMagicNumber(InpMagicNumber);
   trade.SetDeviationInPoints(InpSlippage);

   indicatorHandle = iCustom(_Symbol, _Period, InpIndicatorName);
   if(indicatorHandle == INVALID_HANDLE)
     {
      Print("Error: Could not load indicator: ", InpIndicatorName);
      return INIT_FAILED;
     }

   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(indicatorHandle != INVALID_HANDLE) IndicatorRelease(indicatorHandle);
  }

//+------------------------------------------------------------------+
void OnTick()
  {
   if(!ReadStates()) return;

   int  posType  = GetPositionType();
   bool canTrade = IsTradeAllowed();

   //--- در Buy هستیم: فقط وقتی همه سبز نبودند ببند، بدون معکوس فوری
   if(posType == 1)
     {
      if(!AreAllGreen()) ClosePositions(1);
      return;
     }

   //--- در Sell هستیم: فقط وقتی همه قرمز نبودند ببند، بدون معکوس فوری
   if(posType == -1)
     {
      if(!AreAllRed()) ClosePositions(-1);
      return;
     }

   //--- بدون پوزیشن: صبر تا هماهنگی کامل
   if(canTrade)
     {
      if(AreAllGreen())     OpenBuy();
      else if(AreAllRed())  OpenSell();
     }
  }

//+------------------------------------------------------------------+
bool ReadStates()
  {
   double buf[];
   ArraySetAsSeries(buf, true);

   if(CopyBuffer(indicatorHandle, BUF_STATE_CURRENT, InpSignalBar, 1, buf) <= 0) return false;
   tfStates[0] = buf[0];
   if(CopyBuffer(indicatorHandle, BUF_STATE_M5, InpSignalBar, 1, buf) <= 0) return false;
   tfStates[1] = buf[0];
   if(CopyBuffer(indicatorHandle, BUF_STATE_M15, InpSignalBar, 1, buf) <= 0) return false;
   tfStates[2] = buf[0];
   if(CopyBuffer(indicatorHandle, BUF_STATE_M30, InpSignalBar, 1, buf) <= 0) return false;
   tfStates[3] = buf[0];
   if(CopyBuffer(indicatorHandle, BUF_STATE_H1, InpSignalBar, 1, buf) <= 0) return false;
   tfStates[4] = buf[0];
   if(CopyBuffer(indicatorHandle, BUF_STATE_H4, InpSignalBar, 1, buf) <= 0) return false;
   tfStates[5] = buf[0];
   if(CopyBuffer(indicatorHandle, BUF_STATE_D1, InpSignalBar, 1, buf) <= 0) return false;
   tfStates[6] = buf[0];

   return true;
  }

//+------------------------------------------------------------------+
bool AreAllGreen()
  {
   int count = 0, green = 0;
   if(InpUse_M1)  { count++; if(tfStates[0] ==  1) green++; }
   if(InpUse_M5)  { count++; if(tfStates[1] ==  1) green++; }
   if(InpUse_M15) { count++; if(tfStates[2] ==  1) green++; }
   if(InpUse_M30) { count++; if(tfStates[3] ==  1) green++; }
   if(InpUse_H1)  { count++; if(tfStates[4] ==  1) green++; }
   if(InpUse_H4)  { count++; if(tfStates[5] ==  1) green++; }
   if(InpUse_D1)  { count++; if(tfStates[6] ==  1) green++; }
   return (count > 0 && green == count);
  }

//+------------------------------------------------------------------+
bool AreAllRed()
  {
   int count = 0, red = 0;
   if(InpUse_M1)  { count++; if(tfStates[0] == -1) red++; }
   if(InpUse_M5)  { count++; if(tfStates[1] == -1) red++; }
   if(InpUse_M15) { count++; if(tfStates[2] == -1) red++; }
   if(InpUse_M30) { count++; if(tfStates[3] == -1) red++; }
   if(InpUse_H1)  { count++; if(tfStates[4] == -1) red++; }
   if(InpUse_H4)  { count++; if(tfStates[5] == -1) red++; }
   if(InpUse_D1)  { count++; if(tfStates[6] == -1) red++; }
   return (count > 0 && red == count);
  }

//+------------------------------------------------------------------+
int GetPositionType()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0)
        {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
            PositionGetInteger(POSITION_MAGIC) == InpMagicNumber)
           {
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)  return  1;
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) return -1;
           }
        }
     }
   return 0;
  }

//+------------------------------------------------------------------+
void ClosePositions(int type)
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0)
        {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
            PositionGetInteger(POSITION_MAGIC) == InpMagicNumber)
           {
            if((type ==  1 && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ||
               (type == -1 && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL))
               trade.PositionClose(ticket);
           }
        }
     }
  }

//+------------------------------------------------------------------+
void OpenBuy()
  {
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   if(!trade.Buy(InpLotSize, _Symbol, ask, 0, 0, "Rama Empire Buy"))
      Print("Buy failed. Error: ", GetLastError());
  }

//+------------------------------------------------------------------+
void OpenSell()
  {
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(!trade.Sell(InpLotSize, _Symbol, bid, 0, 0, "Rama Empire Sell"))
      Print("Sell failed. Error: ", GetLastError());
  }

//+------------------------------------------------------------------+
bool IsTradeAllowed()
  {
   if(!IsDayAllowed())  return false;
   if(!IsTimeAllowed()) return false;
   if(IsDailyBlocked()) return false;
   if(IsNewsBlocked())  return false;
   return true;
  }

//+------------------------------------------------------------------+
bool IsDayAllowed()
  {
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   switch(dt.day_of_week)
     {
      case 0: return InpTrade_Sunday;
      case 1: return InpTrade_Monday;
      case 2: return InpTrade_Tuesday;
      case 3: return InpTrade_Wednesday;
      case 4: return InpTrade_Thursday;
      case 5: return InpTrade_Friday;
      case 6: return InpTrade_Saturday;
     }
   return false;
  }

//+------------------------------------------------------------------+
bool IsTimeAllowed()
  {
   if(!InpUse_TimeFilter) return true;
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   int cur   = dt.hour * 60 + dt.min;
   int start = InpStart_Hour * 60 + InpStart_Minute;
   int end   = InpEnd_Hour * 60 + InpEnd_Minute;
   if(start <= end) return (cur >= start && cur <= end);
   return (cur >= start || cur <= end);
  }

//+------------------------------------------------------------------+
bool IsDailyBlocked()
  {
   if(!InpUse_DailyBlocked) return false;

   datetime baseTime;
   if(InpBlocked_UseServerTime)
      baseTime = TimeCurrent();
   else
     {
      baseTime = TimeGMT();
      if(baseTime <= 0) baseTime = TimeCurrent();
      else baseTime = baseTime + (datetime)(InpBlocked_GMT_Offset * 60);
     }

   MqlDateTime dt;
   TimeToStruct(baseTime, dt);
   int cur   = dt.hour * 60 + dt.min;
   int start = InpBlocked_Start_Hour * 60 + InpBlocked_Start_Minute;
   int end   = InpBlocked_End_Hour * 60 + InpBlocked_End_Minute;

   if(start <= end) return (cur >= start && cur <= end);
   return (cur >= start || cur <= end);
  }

//+------------------------------------------------------------------+
//| فیلتر خبری (اصلاح‌شده با امضای درست CalendarValueHistory)         |
//+------------------------------------------------------------------+
bool HasHighImpactNews(datetime from, datetime to, string currency)
  {
   MqlCalendarValue values[];
   int count = CalendarValueHistory(values, from, to, NULL, currency);
   if(count <= 0) return false;

   for(int i = 0; i < count; i++)
     {
      MqlCalendarEvent ev;
      if(CalendarEventById(values[i].event_id, ev))
         if(ev.importance == CALENDAR_IMPORTANCE_HIGH)
            return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
bool IsNewsBlocked()
  {
   if(!InpUse_NewsFilter) return false;

   datetime now  = TimeCurrent();
   datetime from = now - (datetime)(InpNews_Minutes_Before * 60);
   datetime to   = now + (datetime)(InpNews_Minutes_After * 60);

   string base  = StringSubstr(_Symbol, 0, 3);
   string quote = StringSubstr(_Symbol, 3, 3);

   if(HasHighImpactNews(from, to, base))  return true;
   if(HasHighImpactNews(from, to, quote)) return true;

   return false;
  }
//+------------------------------------------------------------------+