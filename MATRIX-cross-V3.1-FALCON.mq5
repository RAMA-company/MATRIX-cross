//+------------------------------------------------------------------+
//|                                            RamaEmpire_EA.mq5     |
//|                                  Copyright 2026, Rama Empire     |
//+------------------------------------------------------------------+
#property copyright "Rama Empire"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>

//--- ورودی‌ها
input group "=== منبع سیگنال ==="
input string   InpIndicatorName   = "MATRIX-cross-V3-Signal"; // نام فایل اندیکاتور
input int      InpMagicNumber     = 20260101;                 // مجیک نامبر
input double   InpLotSize         = 0.01;                     // حجم معامله
input int      InpSlippage        = 50;                       // اسلیپیج
input int      InpSignalBar       = 1;                        // کندل خواندن سیگنال (1=آخرین بسته)

input group "=== انتخاب تایم‌فریم‌ها ==="
input bool   InpUse_M1  = true;
input bool   InpUse_M5  = true;
input bool   InpUse_M15 = true;
input bool   InpUse_M30 = true;
input bool   InpUse_H1  = true;
input bool   InpUse_H4  = true;
input bool   InpUse_D1  = true;

input group "=== حالت معاملاتی ==="
input bool   InpImmediateReverse = true;   // معکوس فوری

input group "=== فیلتر روزهای هفته ==="
input bool   InpTrade_Sunday    = false;
input bool   InpTrade_Monday    = true;
input bool   InpTrade_Tuesday   = true;
input bool   InpTrade_Wednesday = true;
input bool   InpTrade_Thursday  = true;
input bool   InpTrade_Friday    = true;
input bool   InpTrade_Saturday  = false;

input group "=== فیلتر ساعت معاملاتی ==="
input bool   InpUse_TimeFilter = false;
input int    InpStart_Hour     = 0;
input int    InpStart_Minute   = 0;
input int    InpEnd_Hour       = 23;
input int    InpEnd_Minute     = 59;

input group "=== ساعت ممنوعه روزانه (GMT+3:30) ==="
input bool   InpUse_DailyBlocked    = true;
input int    InpBlocked_Start_Hour  = 4;
input int    InpBlocked_Start_Min   = 0;
input int    InpBlocked_End_Hour    = 6;
input int    InpBlocked_End_Min     = 0;
input int    InpBlocked_GMT_Offset  = 210; // +3:30 = 210 دقیقه

input group "=== فیلتر خبری ==="
input bool   InpUse_NewsFilter      = false;
input int    InpNews_Minutes_Before = 30;
input int    InpNews_Minutes_After  = 30;

//--- متغیرهای سراسری
CTrade trade;
int    indicatorHandle = INVALID_HANDLE;
double tfStates[7]; // 0=M1, 1=M5, 2=M15, 3=M30, 4=H1, 5=H4, 6=D1

//--- ایندکس بافرهای وضعیت در اندیکاتور
#define BUF_STATE_CURRENT 5
#define BUF_STATE_M5      6
#define BUF_STATE_M15     7
#define BUF_STATE_M30     8
#define BUF_STATE_H1      9
#define BUF_STATE_H4      10
#define BUF_STATE_D1      11

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   trade.SetExpertMagicNumber(InpMagicNumber);
   trade.SetDeviationInPoints(InpSlippage);
   
   indicatorHandle = iCustom(_Symbol, _Period, InpIndicatorName);
   if(indicatorHandle == INVALID_HANDLE)
   {
      Print("خطا: اندیکاتور ", InpIndicatorName, " بارگذاری نشد");
      return INIT_FAILED;
   }
   
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(indicatorHandle != INVALID_HANDLE)
      IndicatorRelease(indicatorHandle);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   if(!ReadStates()) return;
   
   int  posType   = GetPositionType();
   bool allGreen  = AreAllGreen();
   bool allRed    = AreAllRed();
   bool anyRed    = IsAnyRed();
   bool anyGreen  = IsAnyGreen();
   bool canTrade  = IsTradeAllowed();
   
   //--- منطق معاملاتی با معکوس فوری
   if(posType == 1) // در Buy هستیم
   {
      if(anyRed)
      {
         ClosePositions(1);
         if(canTrade && InpImmediateReverse) OpenSell();
      }
   }
   else if(posType == -1) // در Sell هستیم
   {
      if(anyGreen)
      {
         ClosePositions(-1);
         if(canTrade && InpImmediateReverse) OpenBuy();
      }
   }
   else // پوزیشن باز نداریم
   {
      if(canTrade)
      {
         if(allGreen)     OpenBuy();
         else if(allRed)  OpenSell();
      }
   }
}

//+------------------------------------------------------------------+
//| خواندن وضعیت تایم‌فریم‌ها از اندیکاتور                            |
//+------------------------------------------------------------------+
bool ReadStates()
{
   double buf[];
   ArraySetAsSeries(buf, true);
   
   // M1 / Current
   if(CopyBuffer(indicatorHandle, BUF_STATE_CURRENT, InpSignalBar, 1, buf) <= 0) return false;
   tfStates[0] = buf[0];
   
   // M5
   if(CopyBuffer(indicatorHandle, BUF_STATE_M5, InpSignalBar, 1, buf) <= 0) return false;
   tfStates[1] = buf[0];
   
   // M15
   if(CopyBuffer(indicatorHandle, BUF_STATE_M15, InpSignalBar, 1, buf) <= 0) return false;
   tfStates[2] = buf[0];
   
   // M30
   if(CopyBuffer(indicatorHandle, BUF_STATE_M30, InpSignalBar, 1, buf) <= 0) return false;
   tfStates[3] = buf[0];
   
   // H1
   if(CopyBuffer(indicatorHandle, BUF_STATE_H1, InpSignalBar, 1, buf) <= 0) return false;
   tfStates[4] = buf[0];
   
   // H4
   if(CopyBuffer(indicatorHandle, BUF_STATE_H4, InpSignalBar, 1, buf) <= 0) return false;
   tfStates[5] = buf[0];
   
   // D1
   if(CopyBuffer(indicatorHandle, BUF_STATE_D1, InpSignalBar, 1, buf) <= 0) return false;
   tfStates[6] = buf[0];
   
   return true;
}

//+------------------------------------------------------------------+
//| آیا همه تایم‌فریم‌های انتخابی سبز هستند؟                         |
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
//| آیا همه تایم‌فریم‌های انتخابی قرمز هستند؟                        |
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
//| آیا حتی یک تایم‌فریم قرمز شده؟                                   |
//+------------------------------------------------------------------+
bool IsAnyRed()
{
   if(InpUse_M1  && tfStates[0] == -1) return true;
   if(InpUse_M5  && tfStates[1] == -1) return true;
   if(InpUse_M15 && tfStates[2] == -1) return true;
   if(InpUse_M30 && tfStates[3] == -1) return true;
   if(InpUse_H1  && tfStates[4] == -1) return true;
   if(InpUse_H4  && tfStates[5] == -1) return true;
   if(InpUse_D1  && tfStates[6] == -1) return true;
   return false;
}

//+------------------------------------------------------------------+
//| آیا حتی یک تایم‌فریم سبز شده؟                                    |
//+------------------------------------------------------------------+
bool IsAnyGreen()
{
   if(InpUse_M1  && tfStates[0] ==  1) return true;
   if(InpUse_M5  && tfStates[1] ==  1) return true;
   if(InpUse_M15 && tfStates[2] ==  1) return true;
   if(InpUse_M30 && tfStates[3] ==  1) return true;
   if(InpUse_H1  && tfStates[4] ==  1) return true;
   if(InpUse_H4  && tfStates[5] ==  1) return true;
   if(InpUse_D1  && tfStates[6] ==  1) return true;
   return false;
}

//+------------------------------------------------------------------+
//| نوع پوزیشن باز فعلی                                              |
//| خروجی: 0=هیچ، 1=Buy، -1=Sell                                    |
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
//| بستن پوزیشن‌های باز از نوع مشخص                                  |
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
            {
               trade.PositionClose(ticket);
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| باز کردن Buy                                                     |
//+------------------------------------------------------------------+
void OpenBuy()
{
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   trade.Buy(InpLotSize, _Symbol, ask, 0, 0, "Rama Empire Buy");
}

//+------------------------------------------------------------------+
//| باز کردن Sell                                                    |
//+------------------------------------------------------------------+
void OpenSell()
{
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   trade.Sell(InpLotSize, _Symbol, bid, 0, 0, "Rama Empire Sell");
}

//+------------------------------------------------------------------+
//| آیا اجازه معامله هست؟                                            |
//+------------------------------------------------------------------+
bool IsTradeAllowed()
{
   if(!IsDayAllowed())       return false;
   if(!IsTimeAllowed())      return false;
   if(IsDailyBlocked())      return false;
   if(IsNewsBlocked())       return false;
   return true;
}

//+------------------------------------------------------------------+
//| فیلتر روز هفته                                                   |
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
//| فیلتر ساعت معاملاتی                                              |
//+------------------------------------------------------------------+
bool IsTimeAllowed()
{
   if(!InpUse_TimeFilter) return true;
   
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   int cur   = dt.hour * 60 + dt.min;
   int start = InpStart_Hour * 60 + InpStart_Minute;
   int end   = InpEnd_Hour * 60 + InpEnd_Minute;
   
   if(start <= end)
      return (cur >= start && cur <= end);
   else
      return (cur >= start || cur <= end);
}

//+------------------------------------------------------------------+
//| ساعت ممنوعه روزانه بر اساس GMT+3:30                              |
//+------------------------------------------------------------------+
bool IsDailyBlocked()
{
   if(!InpUse_DailyBlocked) return false;
   
   datetime gmtTime  = TimeGMT();
   datetime zoneTime = gmtTime + (datetime)(InpBlocked_GMT_Offset * 60);
   
   MqlDateTime dt;
   TimeToStruct(zoneTime, dt);
   int cur   = dt.hour * 60 + dt.min;
   int start = InpBlocked_Start_Hour * 60 + InpBlocked_Start_Min;
   int end   = InpBlocked_End_Hour * 60 + InpBlocked_End_Min;
   
   if(start <= end)
      return (cur >= start && cur <= end);
   else
      return (cur >= start || cur <= end);
}

//+------------------------------------------------------------------+
//| فیلتر خبری                                                       |
//+------------------------------------------------------------------+
bool IsNewsBlocked()
{
   if(!InpUse_NewsFilter) return false;
   
   datetime now  = TimeCurrent();
   datetime from = now - (datetime)(InpNews_Minutes_Before * 60);
   datetime to   = now + (datetime)(InpNews_Minutes_After * 60);
   
   MqlCalendarValue values[];
   ArraySetAsSeries(values, true);
   
   int count = CalendarValueHistory(values, from, to, NULL, NULL);
   if(count > 0) return true;
   
   return false;
}
//+------------------------------------------------------------------+