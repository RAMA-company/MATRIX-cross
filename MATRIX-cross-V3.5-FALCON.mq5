//+------------------------------------------------------------------+
//|                        MATRIX-cross-V3-RAPTOR-EA.mq5             |
//|                                  Copyright 2026, Rama Empire     |
//+------------------------------------------------------------------+
#property copyright "Rama Empire"
#property version   "3.00"
#property description "EA version of MATRIX-cross-V3-RAPTOR with full signal logic and auto trading"

#include <Trade\Trade.mqh>

//+------------------------------------------------------------------+
//| ENUMS برای 25 قانون Fan Trendline                                |
//+------------------------------------------------------------------+
enum ENUM_TOLERANCE_TYPE { TOL_ATR, TOL_POINTS, TOL_PERCENT };
enum ENUM_TREND_DIR      { TREND_AUTO, TREND_MANUAL, TREND_BOTH };
enum ENUM_SWING_SCALE    { SCALE_MICRO, SCALE_MINOR, SCALE_MEDIUM, SCALE_MAJOR, SCALE_CUSTOM };
enum ENUM_BREAK_RULE     { BREAK_CLOSE, BREAK_HIGHLOW, BREAK_BODY, BREAK_ATR, BREAK_TOLERANCE };
enum ENUM_RECONNECT_MODE { RECONN_LAST, RECONN_ORIGINAL, RECONN_AUTO };
enum ENUM_FAN_PRIORITY   { PRIO_NEWEST, PRIO_STRONGEST, PRIO_LONGEST, PRIO_MOST_TOUCHES };
enum ENUM_DYN_COLOR      { COLOR_TOUCHES, COLOR_AGE, COLOR_STRENGTH, COLOR_SLOPE, COLOR_DIR, COLOR_STATIC };
enum ENUM_DRAW_MODE      { DRAW_RAY, DRAW_SEGMENT, DRAW_INFINITE };

enum ENUM_PANEL_POSITION
{
   PANEL_TOP_RIGHT,
   PANEL_TOP_LEFT,
   PANEL_BOTTOM_RIGHT,
   PANEL_BOTTOM_LEFT
};

//+------------------------------------------------------------------+
//| ورودی‌های تنظیمات                                                |
//+------------------------------------------------------------------+
input group "--- تنظیمات پایه (برای همه تایم‌فریم‌ها ضرب می‌شود) ---"
input int                  InpBase_MA1_Period = 5;             // دوره مووینگ ۱
input int                  InpBase_MA1_Shift  = -4;            // شیفت مووینگ ۱
input ENUM_MA_METHOD       InpBase_MA1_Method = MODE_SMMA;     // روش محاسبه
input ENUM_APPLIED_PRICE   InpBase_MA1_Price  = PRICE_MEDIAN;  // قیمت پایه
input int                  InpBase_MA2_Period = 5;             // دوره مووینگ ۲
input int                  InpBase_MA2_Shift  = 0;             // شیفت مووینگ ۲
input int                  InpBase_BarsBefore = 14;            // X: کندل‌های قبل
input int                  InpBase_BarsAfter  = 4;             // Y: کندل‌های بعد

input group "--- قوانین FAN TRENDLINE (25 Rules) ---"
input int                  Fan_MaxFanLines        = 20;             // (R3) Maximum Fan Lines
input bool                 Fan_ExtendRight        = true;           // (R4) Infinite Extension
input int                  Fan_LineLength         = 1000;           // (R4) Line Length if Extension False (Candles)
input int                  Fan_ProjectionLength   = 1000;           // (R5) Max Projection Candles
input double               Fan_Tolerance          = 0.20;           // (R6) Tolerance Value
input ENUM_TOLERANCE_TYPE  Fan_ToleranceType      = TOL_ATR;        // (R6) Tolerance Type
input int                  Fan_MinTouches         = 3;              // (R7) Minimum Touches
input double               Fan_MinStrength        = 1.0;            // (R8) Min Strength (ATR Multiplier)
input int                  Fan_MergeNearbyCandles = 0;              // (R9) Merge Nearby Swings (Candles)
input bool                 Fan_DrawCounterTrend   = false;          // (R10) Draw Counter Trend
input ENUM_TREND_DIR       Fan_TrendDirection     = TREND_AUTO;     // (R11) Trend Direction Method
input ENUM_SWING_SCALE     Fan_SwingScale         = SCALE_MINOR;    // (R12) Swing Scale
input int                  Fan_MaxLookback        = 1000;           // (R13) Max Lookback (Candles)
input int                  Fan_CandidateRadius    = 10;             // (R14) Candidate Search Radius (Swings)
input double               Fan_MinAngle           = 5.0;            // (R15) Minimum Angle Filter (Degrees)
input double               Fan_MinPriceDist       = 10.0;           // (R16) Min Vertical Price Distance (Points)
input int                  Fan_MinCandleDist      = 5;              // (R17) Min Horizontal Candle Distance
input ENUM_BREAK_RULE      Fan_BreakRule          = BREAK_CLOSE;    // (R18) Line Break Rule
input ENUM_RECONNECT_MODE  Fan_ReconnectMode      = RECONN_AUTO;    // (R19) Reconnect Rule
input ENUM_FAN_PRIORITY    Fan_FanPriority        = PRIO_NEWEST;    // (R20) Fan Priority
input ENUM_DYN_COLOR       Fan_DynamicColoring    = COLOR_STATIC;   // (R21) Dynamic Coloring Mode
input int                  Fan_DeleteAfter        = 200;            // (R22) Remove Invalid Lines After X Candles
input int                  Fan_MaxActiveLines     = 50;             // (R23) Maximum Active Lines on Chart
input ENUM_DRAW_MODE       Fan_DrawingMode        = DRAW_RAY;       // (R24) Drawing Mode
input bool                 Fan_AutoCleanup        = true;           // (R25) Auto Cleanup Old Lines

input group "--- تنظیمات چارت جاری (Current) ---"
input bool                 InpCurr_DrawZigZag    = true;
input bool                 InpCurr_DrawFan       = true;           // رسم خط روند بادبزنی چارت فعلی؟
input color                InpCurr_FanColor      = C'0,0,0';

input group "--- تایم فریم ۵ دقیقه (M5) ---"
input bool                 InpM5_Enable       = true;
input bool                 InpM5_DrawZigZag   = true;
input bool                 InpM5_DrawFan      = true;
input color                InpM5_DotColor     = C'255,69,0';
input color                InpM5_ZigZagColor  = C'255,69,0';
input color                InpM5_FanColor     = C'255,69,0';
input int                  InpM5_ZigZagWidth  = 4;

input group "--- تایم فریم ۱۵ دقیقه (M15) ---"
input bool                 InpM15_Enable      = true;
input bool                 InpM15_DrawZigZag  = true;
input bool                 InpM15_DrawFan     = true;
input color                InpM15_DotColor    = C'255,165,0';
input color                InpM15_ZigZagColor = C'255,165,0';
input color                InpM15_FanColor    = C'255,165,0';
input int                  InpM15_ZigZagWidth = 6;

input group "--- تایم فریم ۳۰ دقیقه (M30) ---"
input bool                 InpM30_Enable      = true;
input bool                 InpM30_DrawZigZag  = true;
input bool                 InpM30_DrawFan     = true;
input color                InpM30_DotColor    = C'0,255,255';
input color                InpM30_ZigZagColor = C'0,255,255';
input color                InpM30_FanColor    = C'0,255,255';
input int                  InpM30_ZigZagWidth = 8;

input group "--- تایم فریم ۱ ساعته (H1) ---"
input bool                 InpH1_Enable       = true;
input bool                 InpH1_DrawZigZag   = true;
input bool                 InpH1_DrawFan      = true;
input color                InpH1_DotColor     = C'255,0,255';
input color                InpH1_ZigZagColor  = C'255,0,255';
input color                InpH1_FanColor     = C'255,0,255';
input int                  InpH1_ZigZagWidth  = 10;

input group "--- تایم فریم ۴ ساعته (H4) ---"
input bool                 InpH4_Enable       = false;
input bool                 InpH4_DrawZigZag   = true;
input bool                 InpH4_DrawFan      = true;
input color                InpH4_DotColor     = C'128,0,128';
input color                InpH4_ZigZagColor  = C'128,0,128';
input color                InpH4_FanColor     = C'128,0,128';
input int                  InpH4_ZigZagWidth  = 12;

input group "--- تایم فریم روزانه (D1) ---"
input bool                 InpD1_Enable       = true;
input bool                 InpD1_DrawZigZag   = true;
input bool                 InpD1_DrawFan      = true;
input color                InpD1_DotColor     = C'0,255,255';
input color                InpD1_ZigZagColor  = C'0,255,255';
input color                InpD1_FanColor     = C'0,255,255';
input int                  InpD1_ZigZagWidth  = 14;

input group "--- تایم فریم هفتگی (W1) ---"
input bool                 InpW1_Enable       = true;
input bool                 InpW1_DrawZigZag   = true;
input bool                 InpW1_DrawFan      = true;
input color                InpW1_DotColor     = C'255,215,0';
input color                InpW1_ZigZagColor  = C'255,215,0';
input color                InpW1_FanColor     = C'255,215,0';
input int                  InpW1_ZigZagWidth  = 16;

input group "--- تایم فریم ماهانه (MN1) ---"
input bool                 InpMN1_Enable      = true;
input bool                 InpMN1_DrawZigZag  = true;
input bool                 InpMN1_DrawFan     = true;
input color                InpMN1_DotColor    = C'255,0,0';
input color                InpMN1_ZigZagColor = C'255,0,0';
input color                InpMN1_FanColor    = C'255,0,0';
input int                  InpMN1_ZigZagWidth = 18;

input group "--- تنظیمات هشدارها (Alerts) ---"
input bool                 InpEnableAlert     = true;
input bool                 InpEnableSound     = false;
input bool                 InpEnablePush      = false;
input bool                 InpEnableEmail     = false;

input group "--- Calculation Timing ---"
input int                  InpCalcIntervalSeconds = 15;    // Calculate Every X Seconds
input bool                 InpForceCalcOnNewBar   = false; // Force Calculation Immediately On New Bar

input group "--- Rama Empire Panel (Last Signal Dashboard) ---"
input bool                 Panel_Enable           = true;              // Enable Rama Empire Panel
input ENUM_PANEL_POSITION  Panel_Position         = PANEL_TOP_RIGHT;   // Panel Position
input int                  Panel_X_Offset         = 12;                // Panel X Offset
input int                  Panel_Y_Offset         = 25;                // Panel Y Offset
input int                  Panel_Width            = 120;               // Panel Width
input int                  Panel_RowHeight        = 18;                // Panel Row Height
input color                Panel_BackgroundColor  = clrBlack;          // Panel Background Color
input color                Panel_BorderColor      = clrGray;           // Panel Border Color
input color                Panel_TitleColor       = clrWhite;          // Title Color
input color                Panel_TextColor        = clrWhite;          // Text Color
input color                Panel_VersionColor     = clrSilver;         // Version Color
input color                Panel_BuyDotColor      = clrLimeGreen;      // Low/Buy Dot Color
input color                Panel_SellDotColor     = clrRed;            // High/Sell Dot Color
input color                Panel_NoSignalColor    = clrDimGray;        // No Signal Dot Color
input int                  Panel_FontSize         = 9;                 // Panel Font Size
input string               Panel_FontName         = "Arial";           // Panel Font Name
input bool                 Panel_ShowLogoText     = true;              // Show Logo Text
input string               Panel_LogoText         = "RAMA EMPIRE";     // Logo Text
input color                Panel_LogoColor        = clrGold;           // Logo Text Color
input int                  Panel_LogoFontSize     = 9;                 // Logo Font Size
input string               Panel_LogoBmpFile      = "";                // Logo BMP File
input int                  Panel_LogoWidth        = 100;               // Logo BMP Width
input int                  Panel_LogoHeight       = 24;                // Logo BMP Height
input string               Panel_TitleText        = "Rama Empire";     // Title Text
input int                  Panel_TitleFontSize    = 10;                // Title Font Size
input string               Panel_VersionText      = "Version 3";       // Version Text
input int                  Panel_VersionFontSize  = 8;                 // Version Font Size
input string               Panel_CurrentLabel     = "M1";              // Current Chart Label
input string               Panel_DotSymbol        = "●";               // Dot Symbol
input bool                 Panel_Show_Current     = true;              // Show Current Chart
input bool                 Panel_Show_M5          = true;              // Show M5
input bool                 Panel_Show_M15         = true;              // Show M15
input bool                 Panel_Show_M30         = true;              // Show M30
input bool                 Panel_Show_H1          = true;              // Show H1
input bool                 Panel_Show_H4          = false;             // Show H4
input bool                 Panel_Show_D1          = true;              // Show D1
input bool                 Panel_Show_W1          = true;              // Show W1
input bool                 Panel_Show_MN1         = true;              // Show MN1

input group "--- معاملات واقعی (Auto Trading) ---"
input bool                 Trade_Enable                 = true;              // فعال‌سازی معامله خودکار
input bool                 Trade_UseCurrent             = true;              // استفاده از سیگنال چارت جاری
input bool                 Trade_UseM5                  = true;              // استفاده از M5
input bool                 Trade_UseM15                 = true;              // استفاده از M15
input bool                 Trade_UseM30                 = true;              // استفاده از M30
input bool                 Trade_UseH1                  = true;              // استفاده از H1
input bool                 Trade_UseH4                  = true;              // استفاده از H4
input bool                 Trade_UseD1                  = true;              // استفاده از D1
input bool                 Trade_UseW1                  = false;             // استفاده از W1
input bool                 Trade_UseMN1                 = false;             // استفاده از MN1
input bool                 Trade_IgnoreDisabledTF       = false;             // اگر تایم‌فریم غیرفعال بود نادیده گرفته شود
input bool                 Trade_AllowBuy               = true;              // اجازه معامله خرید
input bool                 Trade_AllowSell              = true;              // اجازه معامله فروش
input double               Trade_Lots                   = 0.01;              // حجم معامله
input int                  Trade_SlippagePoints         = 30;                // اسلیپیج (پوینت)
input ulong                Trade_Magic                  = 20260301;          // مجیک نامبر
input string               Trade_Comment                = "MATRIX_V3_ALIGN"; // کامنت معامله
input int                  Trade_MaxSpreadPoints        = 0;                 // حداکثر اسپرد - صفر یعنی بدون محدودیت
input int                  Trade_CheckIntervalSeconds   = 1;                 // فاصله بین بررسی‌های معامله
input bool                 Trade_CloseOnRemove          = false;             // بستن معاملات هنگام حذف EA

//+------------------------------------------------------------------+
//| ساختارها                                                         |
//+------------------------------------------------------------------+
struct TF_Config
{
   bool   enabled;
   int    ratio;
   string name;
   color  dotCol;
   color  zzCol;
   color  fanCol;
   int    zzWidth;
   bool   drawZZ;
   bool   drawFan;
   int    hMA1;
   int    hMA2;
};

struct SwingPoint
{
   datetime time;
   double   price;
   int      type;   // 1 = Low, 2 = High
   int      barIdx;
};

//+------------------------------------------------------------------+
//| متغیرهای عمومی                                                   |
//+------------------------------------------------------------------+
TF_Config mTFs[8];
int current_hMA1, current_hMA2;
int atrHandle;

datetime lastAlertTime;

ulong    LastCalcMs = 0;
datetime LastCalcBarTime = 0;

const string PanelPrefix   = "RAMA_PANEL_";
const string CurrentPrefix = "EA_CUR_";

datetime Panel_CurrentLastTime = 0;
int      Panel_CurrentLastType = 0;
datetime Panel_TFLastTime[8];
int      Panel_TFLastType[8];

CTrade trade;
ulong Trade_LastCheckMs = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   current_hMA1 = iMA(_Symbol, _Period, InpBase_MA1_Period, 0, InpBase_MA1_Method, InpBase_MA1_Price);
   current_hMA2 = iMA(_Symbol, _Period, InpBase_MA2_Period, 0, InpBase_MA1_Method, InpBase_MA1_Price);
   atrHandle    = iATR(_Symbol, _Period, 14);

   if(current_hMA1 == INVALID_HANDLE || current_hMA2 == INVALID_HANDLE || atrHandle == INVALID_HANDLE)
      return(INIT_FAILED);

   SetupTF(0, InpM5_Enable,  PERIOD_M5,   "M5 ",  InpM5_DotColor,  InpM5_ZigZagColor,  InpM5_FanColor,  InpM5_ZigZagWidth,  InpM5_DrawZigZag,  InpM5_DrawFan);
   SetupTF(1, InpM15_Enable, PERIOD_M15,  "M15 ", InpM15_DotColor, InpM15_ZigZagColor, InpM15_FanColor, InpM15_ZigZagWidth, InpM15_DrawZigZag, InpM15_DrawFan);
   SetupTF(2, InpM30_Enable, PERIOD_M30,  "M30 ", InpM30_DotColor, InpM30_ZigZagColor, InpM30_FanColor, InpM30_ZigZagWidth, InpM30_DrawZigZag, InpM30_DrawFan);
   SetupTF(3, InpH1_Enable,  PERIOD_H1,   "H1 ",  InpH1_DotColor,  InpH1_ZigZagColor,  InpH1_FanColor,  InpH1_ZigZagWidth,  InpH1_DrawZigZag,  InpH1_DrawFan);
   SetupTF(4, InpH4_Enable,  PERIOD_H4,   "H4 ",  InpH4_DotColor,  InpH4_ZigZagColor,  InpH4_FanColor,  InpH4_ZigZagWidth,  InpH4_DrawZigZag,  InpH4_DrawFan);
   SetupTF(5, InpD1_Enable,  PERIOD_D1,   "D1 ",  InpD1_DotColor,  InpD1_ZigZagColor,  InpD1_FanColor,  InpD1_ZigZagWidth,  InpD1_DrawZigZag,  InpD1_DrawFan);
   SetupTF(6, InpW1_Enable,  PERIOD_W1,   "W1 ",  InpW1_DotColor,  InpW1_ZigZagColor,  InpW1_FanColor,  InpW1_ZigZagWidth,  InpW1_DrawZigZag,  InpW1_DrawFan);
   SetupTF(7, InpMN1_Enable, PERIOD_MN1,  "MN1 ", InpMN1_DotColor, InpMN1_ZigZagColor, InpMN1_FanColor, InpMN1_ZigZagWidth, InpMN1_DrawZigZag, InpMN1_DrawFan);

   for(int t = 0; t < 8; t++)
   {
      if(mTFs[t].enabled && (mTFs[t].hMA1 == INVALID_HANDLE || mTFs[t].hMA2 == INVALID_HANDLE))
         return(INIT_FAILED);
   }

   lastAlertTime   = 0;
   LastCalcMs      = 0;
   LastCalcBarTime = 0;

   PanelResetSignals();
   PanelDraw();

   trade.SetExpertMagicNumber(Trade_Magic);
   trade.SetDeviationInPoints(Trade_SlippagePoints);
   trade.SetTypeFillingBySymbol(_Symbol);

   if(Trade_Enable)
   {
      if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
         Print("AutoTrading: Algo Trading در ترمینال فعال نیست.");

      if(!MQLInfoInteger(MQL_TRADE_ALLOWED))
         Print("AutoTrading: اجازه معامله برای این EA فعال نیست.");
   }

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Setup timeframe                                                  |
//+------------------------------------------------------------------+
void SetupTF(int idx, bool en, ENUM_TIMEFRAMES tf, string n, color dc, color zc, color fc, int zw, bool dz, bool df)
{
   mTFs[idx].enabled  = en;
   mTFs[idx].ratio    = 1;
   mTFs[idx].name     = n;
   mTFs[idx].dotCol   = dc;
   mTFs[idx].zzCol    = zc;
   mTFs[idx].fanCol   = fc;
   mTFs[idx].zzWidth  = zw;
   mTFs[idx].drawZZ   = dz;
   mTFs[idx].drawFan  = df;
   mTFs[idx].hMA1     = INVALID_HANDLE;
   mTFs[idx].hMA2     = INVALID_HANDLE;

   if(!en)
      return;

   int sec_curr   = PeriodSeconds(_Period);
   int sec_target = PeriodSeconds(tf);

   mTFs[idx].ratio = (sec_target > sec_curr) ? (sec_target / sec_curr) : 1;

   int scaled_P1 = InpBase_MA1_Period * mTFs[idx].ratio;
   int scaled_P2 = InpBase_MA2_Period * mTFs[idx].ratio;

   mTFs[idx].hMA1 = iMA(_Symbol, _Period, scaled_P1, 0, InpBase_MA1_Method, InpBase_MA1_Price);
   mTFs[idx].hMA2 = iMA(_Symbol, _Period, scaled_P2, 0, InpBase_MA1_Method, InpBase_MA1_Price);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(Trade_Enable && Trade_CloseOnRemove)
   {
      if(reason == REASON_REMOVE || reason == REASON_CHARTCLOSE || reason == REASON_ACCOUNT)
         Trade_ClosePositionsByMagic(Trade_Magic, -1);
   }

   ObjectsDeleteAll(0, "MTF_ZIGZAG_");
   ObjectsDeleteAll(0, "FAN_TREND_");
   ObjectsDeleteAll(0, CurrentPrefix);
   ObjectsDeleteAll(0, PanelPrefix);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   int min_bars = MathMax(InpBase_MA1_Period, InpBase_MA2_Period) + InpBase_BarsBefore + InpBase_BarsAfter + 10;
   int rates_total = Bars(_Symbol, _Period);

   if(rates_total < min_bars)
      return;

   datetime time0 = iTime(_Symbol, _Period, 0);
   if(time0 == 0)
      return;

   ulong nowMs = GetTickCount64();
   int calcInterval = MathMax(1, InpCalcIntervalSeconds);
   bool timeElapsed = true;
   bool newBar = false;

   if(LastCalcMs != 0)
   {
      timeElapsed = (nowMs - LastCalcMs >= (ulong)calcInterval * 1000);
      newBar = (time0 != LastCalcBarTime);

      if(!timeElapsed && !(InpForceCalcOnNewBar && newBar))
      {
         if(Trade_Enable)
            Trade_OnAlignment();
         return;
      }
   }

   datetime time[];
   double open[], high[], low[];
   ArraySetAsSeries(time, true);
   ArraySetAsSeries(open, true);
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);

   int copied = CopyTime(_Symbol, _Period, 0, rates_total, time);
   if(copied < min_bars)
      return;

   rates_total = copied;

   if(CopyOpen(_Symbol, _Period, 0, rates_total, open) < rates_total)  return;
   if(CopyHigh(_Symbol, _Period, 0, rates_total, high) < rates_total)  return;
   if(CopyLow(_Symbol, _Period, 0, rates_total, low)  < rates_total)  return;

   double BufferMA1[], BufferMA2[];
   ArraySetAsSeries(BufferMA1, true);
   ArraySetAsSeries(BufferMA2, true);

   if(CopyBuffer(current_hMA1, 0, 0, rates_total, BufferMA1) <= 0) return;
   if(CopyBuffer(current_hMA2, 0, 0, rates_total, BufferMA2) <= 0) return;

   LastCalcMs      = nowMs;
   LastCalcBarTime = time[0];

   PanelResetSignals();

   ObjectsDeleteAll(0, CurrentPrefix);

   SwingPoint currentSwings[];

   int rawTypes[];
   ArrayResize(rawTypes, rates_total);
   ArrayInitialize(rawTypes, 0);

   // =======================================================================
   // پردازش چارت جاری
   // =======================================================================
   for(int i = rates_total - min_bars; i >= InpBase_BarsAfter; i--)
   {
      int shift1 = i + InpBase_MA1_Shift;
      int shift2 = i + InpBase_MA2_Shift;

      if(shift1 < 0 || shift2 < 0 || shift1 + 1 >= rates_total || shift2 + 1 >= rates_total)
         continue;

      double ma1_curr = BufferMA1[shift1];
      double ma1_prev = BufferMA1[shift1 + 1];
      double ma2_curr = BufferMA2[shift2];
      double ma2_prev = BufferMA2[shift2 + 1];

      if(ma1_prev <= ma2_prev && ma1_curr > ma2_curr)
         rawTypes[i] = 1;

      if(ma1_prev >= ma2_prev && ma1_curr < ma2_curr)
         rawTypes[i] = 2;
   }

   for(int i = rates_total - min_bars; i >= InpBase_BarsAfter; i--)
   {
      if(rawTypes[i] == 0)
         continue;

      int startBar = i + InpBase_BarsBefore;
      int endBar   = i - InpBase_BarsAfter;

      if(startBar >= rates_total)
         startBar = rates_total - 1;

      if(endBar < 0)
         endBar = 0;

      if(rawTypes[i] == 1)
      {
         for(int j = i + 1; j <= startBar; j++)
         {
            if(rawTypes[j] == 2)
            {
               startBar = j - 1;
               break;
            }
         }

         for(int j = i - 1; j >= endBar; j--)
         {
            if(rawTypes[j] == 2)
            {
               endBar = j + 1;
               break;
            }
         }

         if(startBar >= endBar)
         {
            int lowestIdx = i;
            double minLow = low[i];

            for(int j = startBar; j >= endBar; j--)
            {
               if(low[j] < minLow)
               {
                  minLow = low[j];
                  lowestIdx = j;
               }
            }

            PanelUpdateCurrent(time[lowestIdx], 1);

            string buyName = CurrentPrefix + "BUY_" + IntegerToString((long)time[lowestIdx]);
            ObjectCreate(0, buyName, OBJ_ARROW, 0, time[lowestIdx], minLow);
            ObjectSetInteger(0, buyName, OBJPROP_ARROWCODE, 158);
            ObjectSetInteger(0, buyName, OBJPROP_COLOR, clrLimeGreen);
            ObjectSetInteger(0, buyName, OBJPROP_WIDTH, 3);

            if(InpCurr_DrawZigZag)
            {
               string zzName = CurrentPrefix + "ZZ_" + IntegerToString((long)time[lowestIdx]);
               ObjectCreate(0, zzName, OBJ_ARROW, 0, time[lowestIdx], minLow);
               ObjectSetInteger(0, zzName, OBJPROP_ARROWCODE, 158);
               ObjectSetInteger(0, zzName, OBJPROP_COLOR, clrGray);
               ObjectSetInteger(0, zzName, OBJPROP_WIDTH, 1);
            }

            int size = ArraySize(currentSwings);
            ArrayResize(currentSwings, size + 1);
            currentSwings[size].time   = time[lowestIdx];
            currentSwings[size].price  = minLow;
            currentSwings[size].type   = 1;
            currentSwings[size].barIdx = lowestIdx;
         }
      }

      if(rawTypes[i] == 2)
      {
         for(int j = i + 1; j <= startBar; j++)
         {
            if(rawTypes[j] == 1)
            {
               startBar = j - 1;
               break;
            }
         }

         for(int j = i - 1; j >= endBar; j--)
         {
            if(rawTypes[j] == 1)
            {
               endBar = j + 1;
               break;
            }
         }

         if(startBar >= endBar)
         {
            int highestIdx = i;
            double maxHigh = high[i];

            for(int j = startBar; j >= endBar; j--)
            {
               if(high[j] > maxHigh)
               {
                  maxHigh = high[j];
                  highestIdx = j;
               }
            }

            PanelUpdateCurrent(time[highestIdx], 2);

            string sellName = CurrentPrefix + "SELL_" + IntegerToString((long)time[highestIdx]);
            ObjectCreate(0, sellName, OBJ_ARROW, 0, time[highestIdx], maxHigh);
            ObjectSetInteger(0, sellName, OBJPROP_ARROWCODE, 158);
            ObjectSetInteger(0, sellName, OBJPROP_COLOR, clrDeepPink);
            ObjectSetInteger(0, sellName, OBJPROP_WIDTH, 3);

            if(InpCurr_DrawZigZag)
            {
               string zzName = CurrentPrefix + "ZZ_" + IntegerToString((long)time[highestIdx]);
               ObjectCreate(0, zzName, OBJ_ARROW, 0, time[highestIdx], maxHigh);
               ObjectSetInteger(0, zzName, OBJPROP_ARROWCODE, 158);
               ObjectSetInteger(0, zzName, OBJPROP_COLOR, clrGray);
               ObjectSetInteger(0, zzName, OBJPROP_WIDTH, 1);
            }

            int size = ArraySize(currentSwings);
            ArrayResize(currentSwings, size + 1);
            currentSwings[size].time   = time[highestIdx];
            currentSwings[size].price  = maxHigh;
            currentSwings[size].type   = 2;
            currentSwings[size].barIdx = highestIdx;
         }
      }
   }

   if(InpCurr_DrawFan)
      DrawFanTrendlines(currentSwings, "Current", InpCurr_FanColor);

   // =======================================================================
   // پردازش تایم‌فریم‌های بالاتر
   // =======================================================================
   for(int t = 0; t < 8; t++)
   {
      if(!mTFs[t].enabled)
         continue;

      int r = mTFs[t].ratio;

      int scaled_s1 = InpBase_MA1_Shift * r;
      int scaled_s2 = InpBase_MA2_Shift * r;
      int scaled_x  = InpBase_BarsBefore * r;
      int scaled_y  = InpBase_BarsAfter * r;

      double tMA1[], tMA2[];
      ArraySetAsSeries(tMA1, true);
      ArraySetAsSeries(tMA2, true);

      if(CopyBuffer(mTFs[t].hMA1, 0, 0, rates_total, tMA1) <= 0) continue;
      if(CopyBuffer(mTFs[t].hMA2, 0, 0, rates_total, tMA2) <= 0) continue;

      int tRawTypes[];
      ArrayResize(tRawTypes, rates_total);
      ArrayInitialize(tRawTypes, 0);

      int startCalc = rates_total - (min_bars * r);

      for(int i = startCalc; i >= scaled_y; i--)
      {
         int shift1 = i + scaled_s1;
         int shift2 = i + scaled_s2;

         if(shift1 < 0 || shift2 < 0 || shift1 + 1 >= rates_total || shift2 + 1 >= rates_total)
            continue;

         if(tMA1[shift1 + 1] <= tMA2[shift2 + 1] && tMA1[shift1] > tMA2[shift2])
            tRawTypes[i] = 1;

         if(tMA1[shift1 + 1] >= tMA2[shift2 + 1] && tMA1[shift1] < tMA2[shift2])
            tRawTypes[i] = 2;
      }

      ObjectsDeleteAll(0, "MTF_ZIGZAG_" + mTFs[t].name + "_");

      int      lastType  = 0;
      datetime lastTime  = 0;
      double   lastPrice = 0;

      SwingPoint mtfSwings[];

      for(int i = startCalc; i >= scaled_y; i--)
      {
         if(tRawTypes[i] == 0)
            continue;

         int startBar = i + scaled_x;
         int endBar   = i - scaled_y;

         if(startBar >= rates_total)
            startBar = rates_total - 1;

         if(endBar < 0)
            endBar = 0;

         if(tRawTypes[i] == 1)
         {
            for(int j = i + 1; j <= startBar; j++)
            {
               if(tRawTypes[j] == 2)
               {
                  startBar = j - 1;
                  break;
               }
            }

            for(int j = i - 1; j >= endBar; j--)
            {
               if(tRawTypes[j] == 2)
               {
                  endBar = j + 1;
                  break;
               }
            }

            if(startBar >= endBar)
            {
               int lowestIdx = i;
               double minLow = low[i];

               for(int j = startBar; j >= endBar; j--)
               {
                  if(low[j] < minLow)
                  {
                     minLow = low[j];
                     lowestIdx = j;
                  }
               }

               string dotName = "MTF_ZIGZAG_" + mTFs[t].name + "_Dot_" + IntegerToString((long)time[lowestIdx]);
               ObjectCreate(0, dotName, OBJ_ARROW, 0, time[lowestIdx], minLow);
               ObjectSetInteger(0, dotName, OBJPROP_ARROWCODE, 158);
               ObjectSetInteger(0, dotName, OBJPROP_COLOR, mTFs[t].dotCol);
               ObjectSetInteger(0, dotName, OBJPROP_WIDTH, 4);

               if(mTFs[t].drawZZ && lastTime != 0)
               {
                  string lineName = "MTF_ZIGZAG_" + mTFs[t].name + "_Line_" + IntegerToString((long)lastTime) + "_" + IntegerToString((long)time[lowestIdx]);
                  ObjectCreate(0, lineName, OBJ_TREND, 0, lastTime, lastPrice, time[lowestIdx], minLow);
                  ObjectSetInteger(0, lineName, OBJPROP_COLOR, mTFs[t].zzCol);
                  ObjectSetInteger(0, lineName, OBJPROP_WIDTH, mTFs[t].zzWidth);
                  ObjectSetInteger(0, lineName, OBJPROP_RAY_RIGHT, false);
               }

               lastTime  = time[lowestIdx];
               lastPrice = minLow;
               lastType  = 1;

               PanelUpdateTF(t, time[lowestIdx], 1);

               int size = ArraySize(mtfSwings);
               ArrayResize(mtfSwings, size + 1);
               mtfSwings[size].time   = time[lowestIdx];
               mtfSwings[size].price  = minLow;
               mtfSwings[size].type   = 1;
               mtfSwings[size].barIdx = lowestIdx;
            }
         }

         if(tRawTypes[i] == 2)
         {
            for(int j = i + 1; j <= startBar; j++)
            {
               if(tRawTypes[j] == 1)
               {
                  startBar = j - 1;
                  break;
               }
            }

            for(int j = i - 1; j >= endBar; j--)
            {
               if(tRawTypes[j] == 1)
               {
                  endBar = j + 1;
                  break;
               }
            }

            if(startBar >= endBar)
            {
               int highestIdx = i;
               double maxHigh = high[i];

               for(int j = startBar; j >= endBar; j--)
               {
                  if(high[j] > maxHigh)
                  {
                     maxHigh = high[j];
                     highestIdx = j;
                  }
               }

               string dotName = "MTF_ZIGZAG_" + mTFs[t].name + "_Dot_" + IntegerToString((long)time[highestIdx]);
               ObjectCreate(0, dotName, OBJ_ARROW, 0, time[highestIdx], maxHigh);
               ObjectSetInteger(0, dotName, OBJPROP_ARROWCODE, 158);
               ObjectSetInteger(0, dotName, OBJPROP_COLOR, mTFs[t].dotCol);
               ObjectSetInteger(0, dotName, OBJPROP_WIDTH, 4);

               if(mTFs[t].drawZZ && lastTime != 0)
               {
                  string lineName = "MTF_ZIGZAG_" + mTFs[t].name + "_Line_" + IntegerToString((long)lastTime) + "_" + IntegerToString((long)time[highestIdx]);
                  ObjectCreate(0, lineName, OBJ_TREND, 0, lastTime, lastPrice, time[highestIdx], maxHigh);
                  ObjectSetInteger(0, lineName, OBJPROP_COLOR, mTFs[t].zzCol);
                  ObjectSetInteger(0, lineName, OBJPROP_WIDTH, mTFs[t].zzWidth);
                  ObjectSetInteger(0, lineName, OBJPROP_RAY_RIGHT, false);
               }

               lastTime  = time[highestIdx];
               lastPrice = maxHigh;
               lastType  = 2;

               PanelUpdateTF(t, time[highestIdx], 2);

               int size = ArraySize(mtfSwings);
               ArrayResize(mtfSwings, size + 1);
               mtfSwings[size].time   = time[highestIdx];
               mtfSwings[size].price  = maxHigh;
               mtfSwings[size].type   = 2;
               mtfSwings[size].barIdx = highestIdx;
            }
         }
      }

      if(mTFs[t].drawFan)
         DrawFanTrendlines(mtfSwings, mTFs[t].name, mTFs[t].fanCol);
   }

   // =======================================================================
   // هشدارها
   // =======================================================================
   if(time[0] != lastAlertTime)
   {
      int checkBar = 1 + InpBase_BarsAfter;
      int s1 = checkBar + InpBase_MA1_Shift;
      int s2 = checkBar + InpBase_MA2_Shift;

      if(s1 >= 0 && s2 >= 0 && s1 + 1 < rates_total && s2 + 1 < rates_total)
      {
         if(BufferMA1[s1 + 1] <= BufferMA2[s2 + 1] && BufferMA1[s1] > BufferMA2[s2])
         {
            SendAlerts("سیگنال نقطه Low چارت جاری", _Symbol);
            lastAlertTime = time[0];
         }
         else if(BufferMA1[s1 + 1] >= BufferMA2[s2 + 1] && BufferMA1[s1] < BufferMA2[s2])
         {
            SendAlerts("سیگنال نقطه High چارت جاری", _Symbol);
            lastAlertTime = time[0];
         }
      }
   }

   PanelDraw();

   if(Trade_Enable)
      Trade_OnAlignment();
}

//+------------------------------------------------------------------+
//| Fan Trendlines                                                    |
//+------------------------------------------------------------------+
void DrawFanTrendlines(SwingPoint &swings[], string tfName, color fanColor)
{
   if(Fan_AutoCleanup)
      ObjectsDeleteAll(0, "FAN_TREND_" + tfName + "_");

   int totalSwings = ArraySize(swings);
   if(totalSwings < 2)
      return;

   int drawnLinesCount = 0;

   for(int i = 0; i < totalSwings - 1; i++)
   {
      if(swings[i].barIdx > Fan_MaxLookback)
         continue;

      int anchorType = swings[i].type;
      int fanIndex = 1;

      int maxSearch = MathMin(i + 1 + Fan_CandidateRadius, totalSwings);

      for(int j = i + 1; j < maxSearch; j++)
      {
         if(drawnLinesCount >= Fan_MaxActiveLines)
            return;

         if(swings[j].type == anchorType)
         {
            if(MathAbs(swings[j].barIdx - swings[i].barIdx) < Fan_MinCandleDist)
               continue;

            if(MathAbs(swings[j].price - swings[i].price) / _Point < Fan_MinPriceDist)
               continue;

            bool isCounterTrend = (anchorType == 1 && swings[j].price < swings[i].price) ||
                                  (anchorType == 2 && swings[j].price > swings[i].price);

            if(!Fan_DrawCounterTrend && isCounterTrend)
               continue;

            string objName = "FAN_TREND_" + tfName + "_" + IntegerToString((long)swings[i].time) + "_Fan" + IntegerToString(fanIndex);

            ObjectCreate(0, objName, OBJ_TREND, 0, swings[i].time, swings[i].price, swings[j].time, swings[j].price);
            ObjectSetInteger(0, objName, OBJPROP_COLOR, fanColor);

            if(Fan_DrawingMode == DRAW_INFINITE || Fan_ExtendRight)
               ObjectSetInteger(0, objName, OBJPROP_RAY_RIGHT, true);
            else
               ObjectSetInteger(0, objName, OBJPROP_RAY_RIGHT, false);

            fanIndex++;
            drawnLinesCount++;

            if(fanIndex > Fan_MaxFanLines)
               break;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Alerts                                                            |
//+------------------------------------------------------------------+
void SendAlerts(string signalType, string symbol)
{
   string msg = signalType + " در جفت‌ارز " + symbol + " | تایم‌فریم: " + EnumToString(_Period);

   if(InpEnableAlert)
      Alert(msg);

   if(InpEnableSound)
      PlaySound("alert.wav");

   if(InpEnablePush)
      SendNotification(msg);

   if(InpEnableEmail)
      SendMail("سیگنال نقطه پوتین/پیووت", msg);
}

//+------------------------------------------------------------------+
//| Rama Empire Panel functions                                      |
//+------------------------------------------------------------------+
void PanelResetSignals()
{
   Panel_CurrentLastTime = 0;
   Panel_CurrentLastType = 0;
   ArrayInitialize(Panel_TFLastTime, 0);
   ArrayInitialize(Panel_TFLastType, 0);
}

void PanelUpdateCurrent(datetime t, int type)
{
   if(t > Panel_CurrentLastTime || (t == Panel_CurrentLastTime && type != 0))
   {
      Panel_CurrentLastTime = t;
      Panel_CurrentLastType = type;
   }
}

void PanelUpdateTF(int idx, datetime t, int type)
{
   if(idx < 0 || idx >= 8)
      return;

   if(t > Panel_TFLastTime[idx] || (t == Panel_TFLastTime[idx] && type != 0))
   {
      Panel_TFLastTime[idx] = t;
      Panel_TFLastType[idx] = type;
   }
}

void PanelHideLabel(string name)
{
   if(ObjectFind(0, name) >= 0)
   {
      ObjectSetString(0, name, OBJPROP_TEXT, "");
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, -10000);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, -10000);
   }
}

void PanelCreateRect(string name, int x, int y, int w, int h, color bg, color border)
{
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);

   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, name, OBJPROP_COLOR, border);
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 10);
}

void PanelCreateLabel(string name, int x, int y, string text, color clr, int fontSize, string font, ENUM_ANCHOR_POINT anchor)
{
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);

   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
   ObjectSetString(0, name, OBJPROP_FONT, font);
   ObjectSetInteger(0, name, OBJPROP_ANCHOR, (long)anchor);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 11);
}

void PanelCreateBitmap(string name, int x, int y, int w, int h, string file)
{
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_BITMAP_LABEL, 0, 0, 0);

   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetString(0, name, OBJPROP_BMPFILE, file);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 11);
}

void PanelDraw()
{
   if(!Panel_Enable)
   {
      ObjectsDeleteAll(0, PanelPrefix);
      return;
   }

   string rowLabel[9];
   int    rowType[9];
   int    rowCount = 0;

   if(Panel_Show_Current)
   {
      rowLabel[rowCount] = Panel_CurrentLabel;
      rowType[rowCount]  = Panel_CurrentLastType;
      rowCount++;
   }

   if(Panel_Show_M5)
   {
      rowLabel[rowCount] = "M5";
      rowType[rowCount]  = (mTFs[0].enabled ? Panel_TFLastType[0] : 0);
      rowCount++;
   }

   if(Panel_Show_M15)
   {
      rowLabel[rowCount] = "M15";
      rowType[rowCount]  = (mTFs[1].enabled ? Panel_TFLastType[1] : 0);
      rowCount++;
   }

   if(Panel_Show_M30)
   {
      rowLabel[rowCount] = "M30";
      rowType[rowCount]  = (mTFs[2].enabled ? Panel_TFLastType[2] : 0);
      rowCount++;
   }

   if(Panel_Show_H1)
   {
      rowLabel[rowCount] = "H1";
      rowType[rowCount]  = (mTFs[3].enabled ? Panel_TFLastType[3] : 0);
      rowCount++;
   }

   if(Panel_Show_H4)
   {
      rowLabel[rowCount] = "H4";
      rowType[rowCount]  = (mTFs[4].enabled ? Panel_TFLastType[4] : 0);
      rowCount++;
   }

   if(Panel_Show_D1)
   {
      rowLabel[rowCount] = "D";
      rowType[rowCount]  = (mTFs[5].enabled ? Panel_TFLastType[5] : 0);
      rowCount++;
   }

   if(Panel_Show_W1)
   {
      rowLabel[rowCount] = "W";
      rowType[rowCount]  = (mTFs[6].enabled ? Panel_TFLastType[6] : 0);
      rowCount++;
   }

   if(Panel_Show_MN1)
   {
      rowLabel[rowCount] = "M";
      rowType[rowCount]  = (mTFs[7].enabled ? Panel_TFLastType[7] : 0);
      rowCount++;
   }

   bool useBmp      = (Panel_LogoBmpFile != "");
   bool useLogoText = (!useBmp && Panel_ShowLogoText && Panel_LogoText != "");

   int logoBlock = 0;

   if(useBmp)
      logoBlock = Panel_LogoHeight + 4;
   else if(useLogoText)
      logoBlock = Panel_LogoFontSize + 10;

   int titleBlock   = (Panel_TitleText == "")   ? 0 : Panel_TitleFontSize + 10;
   int versionBlock = (Panel_VersionText == "") ? 0 : Panel_VersionFontSize + 8;

   int height = 10 + logoBlock + titleBlock + versionBlock + rowCount * Panel_RowHeight + 8;
   int width  = Panel_Width;

   int chartW = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS, 0);
   int chartH = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS, 0);

   int x = Panel_X_Offset;
   int y = Panel_Y_Offset;

   if(Panel_Position == PANEL_TOP_RIGHT)
      x = chartW - width - Panel_X_Offset;
   else if(Panel_Position == PANEL_BOTTOM_RIGHT)
   {
      x = chartW - width - Panel_X_Offset;
      y = chartH - height - Panel_Y_Offset;
   }
   else if(Panel_Position == PANEL_BOTTOM_LEFT)
      y = chartH - height - Panel_Y_Offset;

   if(x < 0) x = 0;
   if(y < 0) y = 0;

   PanelCreateRect(PanelPrefix + "BG", x, y, width, height, Panel_BackgroundColor, Panel_BorderColor);

   int ty = y + 8;

   if(useBmp)
   {
      PanelCreateBitmap(PanelPrefix + "LOGO_BMP", x + (width - Panel_LogoWidth) / 2, ty, Panel_LogoWidth, Panel_LogoHeight, Panel_LogoBmpFile);
      PanelHideLabel(PanelPrefix + "LOGO_TXT");
      ty += Panel_LogoHeight + 4;
   }
   else
   {
      if(ObjectFind(0, PanelPrefix + "LOGO_BMP") >= 0)
         ObjectDelete(0, PanelPrefix + "LOGO_BMP");

      if(useLogoText)
      {
         PanelCreateLabel(PanelPrefix + "LOGO_TXT", x + width / 2, ty, Panel_LogoText, Panel_LogoColor, Panel_LogoFontSize, Panel_FontName, ANCHOR_UPPER);
         ty += Panel_LogoFontSize + 10;
      }
      else
         PanelHideLabel(PanelPrefix + "LOGO_TXT");
   }

   if(Panel_TitleText != "")
   {
      PanelCreateLabel(PanelPrefix + "TITLE", x + width / 2, ty, Panel_TitleText, Panel_TitleColor, Panel_TitleFontSize, Panel_FontName, ANCHOR_UPPER);
      ty += Panel_TitleFontSize + 10;
   }
   else
      PanelHideLabel(PanelPrefix + "TITLE");

   if(Panel_VersionText != "")
   {
      PanelCreateLabel(PanelPrefix + "VERSION", x + width / 2, ty, Panel_VersionText, Panel_VersionColor, Panel_VersionFontSize, Panel_FontName, ANCHOR_UPPER);
      ty += Panel_VersionFontSize + 8;
   }
   else
      PanelHideLabel(PanelPrefix + "VERSION");

   for(int i = 0; i < 9; i++)
   {
      string tfObj  = PanelPrefix + "TF_"  + IntegerToString(i);
      string dotObj = PanelPrefix + "DOT_" + IntegerToString(i);

      if(i < rowCount)
      {
         PanelCreateLabel(tfObj, x + 10, ty, rowLabel[i], Panel_TextColor, Panel_FontSize, Panel_FontName, ANCHOR_LEFT_UPPER);

         color dotColor = Panel_NoSignalColor;

         if(rowType[i] == 1)
            dotColor = Panel_BuyDotColor;
         else if(rowType[i] == 2)
            dotColor = Panel_SellDotColor;

         string dotText = (Panel_DotSymbol == "") ? "O" : Panel_DotSymbol;

         PanelCreateLabel(dotObj, x + width - 10, ty, dotText, dotColor, Panel_FontSize, Panel_FontName, ANCHOR_RIGHT_UPPER);

         ty += Panel_RowHeight;
      }
      else
      {
         PanelHideLabel(tfObj);
         PanelHideLabel(dotObj);
      }
   }
}

//+------------------------------------------------------------------+
//| Auto Trading functions                                           |
//+------------------------------------------------------------------+
bool Trade_AddSignal(bool use, bool enabled, int type, int &dir)
{
   if(!use)
      return true;

   if(!enabled)
      return Trade_IgnoreDisabledTF;

   if(type == 0)
      return false;

   if(dir == 0)
      dir = type;
   else if(dir != type)
      return false;

   return true;
}

int Trade_GetAlignedDirection()
{
   int dir = 0;

   if(!Trade_AddSignal(Trade_UseCurrent, true,             Panel_CurrentLastType, dir)) return 0;
   if(!Trade_AddSignal(Trade_UseM5,      mTFs[0].enabled,  Panel_TFLastType[0],   dir)) return 0;
   if(!Trade_AddSignal(Trade_UseM15,     mTFs[1].enabled,  Panel_TFLastType[1],   dir)) return 0;
   if(!Trade_AddSignal(Trade_UseM30,     mTFs[2].enabled,  Panel_TFLastType[2],   dir)) return 0;
   if(!Trade_AddSignal(Trade_UseH1,      mTFs[3].enabled,  Panel_TFLastType[3],   dir)) return 0;
   if(!Trade_AddSignal(Trade_UseH4,      mTFs[4].enabled,  Panel_TFLastType[4],   dir)) return 0;
   if(!Trade_AddSignal(Trade_UseD1,      mTFs[5].enabled,  Panel_TFLastType[5],   dir)) return 0;
   if(!Trade_AddSignal(Trade_UseW1,      mTFs[6].enabled,  Panel_TFLastType[6],   dir)) return 0;
   if(!Trade_AddSignal(Trade_UseMN1,     mTFs[7].enabled,  Panel_TFLastType[7],   dir)) return 0;

   if(dir != 1 && dir != 2)
      return 0;

   return dir;
}

double Trade_NormalizeLot(double lot)
{
   double minLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double stepLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   if(stepLot <= 0.0)
      stepLot = 0.01;

   lot = MathRound(lot / stepLot) * stepLot;

   if(lot < minLot) lot = minLot;
   if(lot > maxLot) lot = maxLot;

   return NormalizeDouble(lot, 8);
}

bool Trade_HasPositionType(ENUM_POSITION_TYPE ptype)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;

      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;

      if((ulong)PositionGetInteger(POSITION_MAGIC) != Trade_Magic)
         continue;

      if((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE) == ptype)
         return true;
   }

   return false;
}

void Trade_ClosePositionsByMagic(ulong magic, long onlyType)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;

      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;

      if((ulong)PositionGetInteger(POSITION_MAGIC) != magic)
         continue;

      long ptype = PositionGetInteger(POSITION_TYPE);
      if(onlyType != -1 && ptype != onlyType)
         continue;

      if(!trade.PositionClose(ticket))
      {
         Print("خطا در بستن پوزیشن ", ticket,
               " کد خطا: ", trade.ResultRetcode(),
               " توضیح: ", trade.ResultRetcodeDescription());
      }
   }
}

bool Trade_OpenBuy()
{
   double lot = Trade_NormalizeLot(Trade_Lots);
   if(lot <= 0.0)
      return false;

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   if(ask <= 0.0)
      return false;

   if(!trade.Buy(lot, _Symbol, ask, 0.0, 0.0, Trade_Comment))
   {
      Print("خطا در باز کردن Buy. کد خطا: ", trade.ResultRetcode(),
            " توضیح: ", trade.ResultRetcodeDescription());
      return false;
   }

   Print("معامله Buy توسط هم‌جهتی باز شد. حجم=", lot);
   return true;
}

bool Trade_OpenSell()
{
   double lot = Trade_NormalizeLot(Trade_Lots);
   if(lot <= 0.0)
      return false;

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(bid <= 0.0)
      return false;

   if(!trade.Sell(lot, _Symbol, bid, 0.0, 0.0, Trade_Comment))
   {
      Print("خطا در باز کردن Sell. کد خطا: ", trade.ResultRetcode(),
            " توضیح: ", trade.ResultRetcodeDescription());
      return false;
   }

   Print("معامله Sell توسط هم‌جهتی باز شد. حجم=", lot);
   return true;
}

void Trade_OnAlignment()
{
   if(!Trade_Enable)
      return;

   ulong now = GetTickCount64();

   if(Trade_LastCheckMs != 0 && now - Trade_LastCheckMs < (ulong)MathMax(1, Trade_CheckIntervalSeconds) * 1000)
      return;

   Trade_LastCheckMs = now;

   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
      return;

   if(!MQLInfoInteger(MQL_TRADE_ALLOWED))
   {
      static bool warned = false;
      if(!warned)
      {
         Print("هشدار: MT5 به این برنامه اجازه معامله نمی‌دهد. برای معامله واقعی باید Algo Trading فعال باشد.");
         warned = true;
      }
      return;
   }

   int dir = Trade_GetAlignedDirection();

   bool hasBuy  = Trade_HasPositionType(POSITION_TYPE_BUY);
   bool hasSell = Trade_HasPositionType(POSITION_TYPE_SELL);

   if(dir == 0)
   {
      if(hasBuy || hasSell)
         Trade_ClosePositionsByMagic(Trade_Magic, -1);
      return;
   }

   if(dir == 1)
   {
      if(hasSell)
         Trade_ClosePositionsByMagic(Trade_Magic, POSITION_TYPE_SELL);

      bool nowHasBuy  = Trade_HasPositionType(POSITION_TYPE_BUY);
      bool nowHasSell = Trade_HasPositionType(POSITION_TYPE_SELL);

      if(!nowHasBuy && !nowHasSell)
      {
         if(Trade_MaxSpreadPoints > 0)
         {
            long spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
            if(spread > Trade_MaxSpreadPoints)
               return;
         }

         if(Trade_AllowBuy)
            Trade_OpenBuy();
      }
   }
   else if(dir == 2)
   {
      if(hasBuy)
         Trade_ClosePositionsByMagic(Trade_Magic, POSITION_TYPE_BUY);

      bool nowHasSell = Trade_HasPositionType(POSITION_TYPE_SELL);
      bool nowHasBuy  = Trade_HasPositionType(POSITION_TYPE_BUY);

      if(!nowHasSell && !nowHasBuy)
      {
         if(Trade_MaxSpreadPoints > 0)
         {
            long spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
            if(spread > Trade_MaxSpreadPoints)
               return;
         }

         if(Trade_AllowSell)
            Trade_OpenSell();
      }
   }
}

//+------------------------------------------------------------------+
//| Chart event                                                       |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(id == CHARTEVENT_CHART_CHANGE)
      PanelDraw();
}
//+------------------------------------------------------------------+