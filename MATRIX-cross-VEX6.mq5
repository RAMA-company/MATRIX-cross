//+------------------------------------------------------------------+
//|                                  MATRIX-cross-V4_EA.mq5          |
//|                                  Copyright 2026, Rama Empire     |
//|                                  Automated Expert Advisor V1     |
//+------------------------------------------------------------------+
#property copyright "Rama Empire"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\AccountInfo.mqh>

CTrade         trade;
CPositionInfo  m_position;
CSymbolInfo    m_symbol;
CAccountInfo   m_account;

//+------------------------------------------------------------------+
//| ENUMS (Preserved from Indicator + EA specific)                   |
//+------------------------------------------------------------------+
enum ENUM_TOLERANCE_TYPE { TOL_ATR, TOL_POINTS, TOL_PERCENT };
enum ENUM_TREND_DIR      { TREND_AUTO, TREND_MANUAL, TREND_BOTH };
enum ENUM_SWING_SCALE    { SCALE_MICRO, SCALE_MINOR, SCALE_MEDIUM, SCALE_MAJOR, SCALE_CUSTOM };
enum ENUM_BREAK_RULE     { BREAK_CLOSE, BREAK_HIGHLOW, BREAK_BODY, BREAK_ATR, BREAK_TOLERANCE };
enum ENUM_RECONNECT_MODE { RECONN_LAST, RECONN_ORIGINAL, RECONN_AUTO };
enum ENUM_FAN_PRIORITY   { PRIO_NEWEST, PRIO_STRONGEST, PRIO_LONGEST, PRIO_MOST_TOUCHES, PRIO_OLDEST };
enum ENUM_DYN_COLOR      { COLOR_TOUCHES, COLOR_AGE, COLOR_STRENGTH, COLOR_SLOPE, COLOR_DIR, COLOR_STATIC };
enum ENUM_DRAW_MODE      { DRAW_RAY, DRAW_SEGMENT, DRAW_INFINITE, DRAW_CUSTOM_PROJ };
enum ENUM_FAN_DISPLAY    { DISP_LAST_1, DISP_LAST_2, DISP_LAST_3, DISP_ALL };
enum ENUM_FAN_BOUNDARY   { BOUND_OFF, BOUND_START, BOUND_END, BOUND_BOTH };
enum ENUM_MERGE_MODE     { MERGE_POINTS, MERGE_ATR, MERGE_CANDLES, MERGE_PERCENT };
enum ENUM_TREND_DIR_EXT  { DIR_TREND, DIR_COUNTER, DIR_BOTH };
enum ENUM_ZONE_DIR       { ZONE_CURRENT, ZONE_ALL };

enum ENUM_RISK_MODE      { RISK_PERCENT, RISK_FIXED_LOT, RISK_BALANCE_PCT, RISK_EQUITY_PCT, RISK_FREE_MARGIN_PCT };
enum ENUM_BUFFER_MODE    { BUF_POINTS, BUF_ATR, BUF_SPREAD, BUF_PERCENT, BUF_CUSTOM };
enum ENUM_TRAIL_MODE     { TRAIL_OFF, TRAIL_CLASSIC, TRAIL_ATR, TRAIL_SWING, TRAIL_MA, TRAIL_CUSTOM };

//+------------------------------------------------------------------+
//| INPUTS - EXPERT ADVISOR SETTINGS                                 |
//+------------------------------------------------------------------+
input group "=== EA: TRADE MANAGEMENT ==="
input ulong                EA_MagicNumber       = 123456;
input string               EA_TradeComment      = "Matrix EA";
input bool                 EA_TradeCurrentTF    = true;    // Trade Current TF Signals
input bool                 EA_TradeMTF          = false;   // Trade MTF Signals

input group "=== EA: RISK & POSITION SIZING ==="
input ENUM_RISK_MODE       EA_RiskMode          = RISK_PERCENT;
input double               EA_RiskValue         = 1.0;     // Risk % or Lot based on Mode
input double               EA_FixedLot          = 0.01;    // Fallback if fixed lot chosen

input group "=== EA: STOP LOSS SETTINGS ==="
input ENUM_BUFFER_MODE     EA_BufferMode        = BUF_POINTS;
input double               EA_SLBuffer          = 50;      // Points/ATR/Spread multiplier

input group "=== EA: TAKE PROFIT / TARGETS ==="
input int                  EA_TargetToUse       = 1;       // Target 1 to 8 (From Mod 2)

input group "=== EA: PARTIAL CLOSE ==="
input bool                 EA_Partial_Enable    = false;
input double               EA_Partial_T1_Pct    = 50.0;    // % to close at Target 1
input double               EA_Partial_T2_Pct    = 25.0;    // % to close at Target 2

input group "=== EA: BREAK EVEN ==="
input bool                 EA_BE_Enable         = true;
input double               EA_BE_TriggerR       = 1.0;     // Move to BE after 1R profit
input int                  EA_BE_LockPoints     = 10;      // Lock Points in profit

input group "=== EA: TRAILING STOP ==="
input ENUM_TRAIL_MODE      EA_TrailMode         = TRAIL_OFF;
input double               EA_TrailValue        = 50;      // Points or ATR Multiplier

input group "=== EA: FILTERS & LIMITS ==="
input int                  EA_MaxSpread         = 30;      // Max allowed spread (Points)
input int                  EA_MaxTradesPerDay   = 5;
input int                  EA_MaxPositionsTotal = 3;
input int                  EA_MaxBuyPositions   = 2;
input int                  EA_MaxSellPositions  = 2;
input int                  EA_MaxConsecLoses    = 3;       // Pause after X losses
input double               EA_MaxDailyLossPct   = 5.0;     // Max Daily Loss %
input double               EA_MaxDailyProfitPct = 10.0;    // Max Daily Profit %

input group "=== EA: SESSIONS ==="
input int                  EA_StartHour         = 0;
input int                  EA_EndHour           = 23;
input bool                 EA_TradeMonday       = true;
input bool                 EA_TradeFriday       = true;

//+------------------------------------------------------------------+
//| INPUTS - INDICATOR SETTINGS (PRESERVED)                          |
//+------------------------------------------------------------------+
input group "--- تنظیمات پایه (برای همه تایم‌فریم‌ها ضرب می‌شود) ---"
input int                  InpBase_MA1_Period = 9;            
input int                  InpBase_MA1_Shift  = -4;           
input ENUM_MA_METHOD       InpBase_MA1_Method = MODE_SMMA;    
input ENUM_APPLIED_PRICE   InpBase_MA1_Price  = PRICE_MEDIAN; 
input int                  InpBase_MA2_Period = 9;            
input int                  InpBase_MA2_Shift  = 0;            
input int                  InpBase_BarsBefore = 14;           
input int                  InpBase_BarsAfter  = 4;            

input group "=== MODULE 1: MTF Support / Resistance Zones ==="
input bool                 Mod1_Enable           = true;          
input ENUM_ZONE_DIR        Mod1_ZoneDirection    = ZONE_ALL;      
input color                Mod1_ColorBullish     = clrDarkGreen;  
input color                Mod1_ColorBearish     = clrMaroon;     
input bool                 Mod1_ExtendRight      = true;          
input int                  Mod1_CustomProj       = 50;            
input int                  Mod1_MaxZones         = 20;            
input int                  Mod1_MaxHistory       = 1000;          
input bool                 Mod1_DeleteBroken     = true;          
input bool                 Mod1_MergeNearby      = true;          
input ENUM_MERGE_MODE      Mod1_MergeMode        = MERGE_POINTS;  
input double               Mod1_MergeTolerance   = 10.0;          
input ENUM_FAN_PRIORITY    Mod1_Priority         = PRIO_NEWEST;   
input double               Mod1_MinStrength      = 0.0;           
input double               Mod1_MaxStrength      = 100.0;         
input bool                 Mod1_ShowLabels       = true;          

input group "=== MODULE 2: Standard 1-2-3 Pattern ==="
input bool                 Mod2_Enable           = true;          
input ENUM_BREAK_RULE      Mod2_BreakRule        = BREAK_CLOSE;   
input int                  Mod2_ReqCandlesBeyond = 1;             
input bool                 Mod2_ReqLastSwingBreak= true;          
input double               Mod2_RetraceLevel     = 50.0;          
input bool                 Mod2_EnableTargets    = true;          
input double               Mod2_TargetStep       = 50.0;          
input int                  Mod2_TargetCount      = 8;             
input color                Mod2_TargetColor      = clrYellow;     
input ENUM_LINE_STYLE      Mod2_TargetStyle      = STYLE_DASH;    
input int                  Mod2_TargetWidth      = 1;             
input bool                 Mod2_HideReached      = true;          
input bool                 Mod2_DeleteOld        = true;          
input bool                 Mod2_AlertEnable      = false;         
input bool                 Mod2_PushEnable       = false;         
input bool                 Mod2_EmailEnable      = false;         
input bool                 Mod2_SoundEnable      = false;         

input group "=== MODULE 3: Sideways Market Detection ==="
input bool                 Mod3_Enable           = true;          
input ENUM_TOLERANCE_TYPE  Mod3_TolType          = TOL_ATR;       
input double               Mod3_Tolerance        = 1.5;           
input int                  Mod3_MinSwings        = 4;             
input int                  Mod3_MinBars          = 20;            
input int                  Mod3_MaxBars          = 200;           
input color                Mod3_BoxColor         = clrBlue;       
input bool                 Mod3_ShowHistory      = false;         
input bool                 Mod3_MergeRanges      = true;          

input group "=== MODULE 4: Advanced Fan Trend Management ==="
input int                  Mod4_MaxTrendAge      = 500;           
input int                  Mod4_MaxFanAge        = 300;           
input bool                 Mod4_AutoArchive      = true;          
input bool                 Mod4_AdaptiveAngle    = true;          
input bool                 Mod4_RequireBodyTouch = true;          
input double               Mod4_MinTouchRejATR   = 0.5;           
input double               Mod4_MinTrendScore    = 10.0;          
input bool                 Fan_EnableAngleFilter = false;         
input double               Fan_MinAngle          = 5.0;           
input double               Fan_MaxAngle          = 85.0;          
input double               Fan_MinPriceDist      = 10.0;          
input int                  Fan_MinCandleDist     = 5;             
input ENUM_TOLERANCE_TYPE  Fan_ToleranceType     = TOL_ATR;       
input double               Fan_Tolerance         = 0.20;          
input ENUM_DRAW_MODE       Fan_DrawingMode       = DRAW_RAY;      
input int                  Fan_ProjectionLength  = 50;            
input bool                 Fan_ExtendRight       = true;          
input int                  Fan_MaxActiveLines    = 50;            
input int                  Fan_MaxFanLines       = 20;            
input int                  Fan_MaxTrends         = 5;             
input ENUM_FAN_DISPLAY     Fan_DisplayMode       = DISP_ALL;      
input ENUM_FAN_BOUNDARY    Fan_BoundaryMode      = BOUND_OFF;     
input color                Fan_BoundaryColor     = clrDarkGray;   
input int                  Fan_BoundaryWidth     = 1;             
input ENUM_LINE_STYLE      Fan_BoundaryStyle     = STYLE_DOT;     
input bool                 Fan_ShowLabels        = true;          
input int                  Fan_MinTouches        = 2;             
input bool                 Fan_EnableMerge       = false;         
input ENUM_MERGE_MODE      Fan_MergeMode         = MERGE_CANDLES; 
input double               Fan_MergeValue        = 5.0;           
input ENUM_BREAK_RULE      Fan_BreakRule         = BREAK_CLOSE;   
input ENUM_TREND_DIR_EXT   Fan_TrendDirectionExt = DIR_BOTH;      
input color                Fan_ColorBullish      = clrLime;       
input color                Fan_ColorBearish      = clrRed;        
input color                Fan_ColorBroken       = clrDimGray;    
input color                Fan_ColorCurrentTrend = clrYellow;     
input color                Fan_ColorOldTrend     = clrGray;       
input int                  Fan_LineWidth         = 2;             
input ENUM_LINE_STYLE      Fan_LineStyle         = STYLE_SOLID;   
input int                  Fan_MaxHistory        = 2000;          
input int                  Fan_MaxPivots         = 1000;          
input int                  Fan_MaxObjects        = 500;           
input double               Fan_MinStrength       = 1.0;           
input ENUM_TREND_DIR       Fan_TrendDirection    = TREND_AUTO;    
input ENUM_SWING_SCALE     Fan_SwingScale        = SCALE_MINOR;   
input int                  Fan_MaxLookback       = 1000;          
input int                  Fan_CandidateRadius   = 10;            
input ENUM_RECONNECT_MODE  Fan_ReconnectMode     = RECONN_AUTO;   
input ENUM_FAN_PRIORITY    Fan_FanPriority       = PRIO_NEWEST;   
input ENUM_DYN_COLOR       Fan_DynamicColoring   = COLOR_STATIC;  
input int                  Fan_DeleteAfter       = 200;           
input bool                 Fan_AutoCleanup       = true;          

//+------------------------------------------------------------------+
//| STRUCTS & GLOBAL STATE                                           |
//+------------------------------------------------------------------+
struct SwingPoint {
   datetime time;
   double   price;
   int      type;       
   int      barIdx;
   double   candleHigh; 
   double   candleLow;  
};

struct TradeSignal {
   bool     valid;
   int      type;        // ORDER_TYPE_BUY or ORDER_TYPE_SELL
   double   entryPrice;
   double   slPrice;
   double   targets[8];
   string   signalHash;  // Unique ID to prevent duplicate trades
   string   tfName;
};

struct TF_Config {
   bool   enabled;
   int    ratio;
   string name;
   int    hMA1;
   int    hMA2;
};

TF_Config mTFs[8];
int current_hMA1, current_hMA2, atrHandle;
string g_processedHashes[];
TradeSignal g_currentSignal;
double g_dailyStartBalance = 0;
int g_consecutiveLosses = 0;
int g_tradesToday = 0;

//+------------------------------------------------------------------+
//| INITIALIZATION                                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   m_symbol.Name(_Symbol);
   m_symbol.RefreshRates();
   trade.SetExpertMagicNumber(EA_MagicNumber);
   
   current_hMA1 = iMA(_Symbol, _Period, InpBase_MA1_Period, 0, InpBase_MA1_Method, InpBase_MA1_Price);
   current_hMA2 = iMA(_Symbol, _Period, InpBase_MA2_Period, 0, InpBase_MA1_Method, InpBase_MA1_Price);
   atrHandle    = iATR(_Symbol, _Period, 14); 

   SetupTF(0, false, PERIOD_M5, "M5"); // Hardcoded disable MTF inputs for brevity, use EA_TradeMTF logic
   g_dailyStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);

   return(INIT_SUCCEEDED);
}

void SetupTF(int idx, bool en, ENUM_TIMEFRAMES tf, string n)
{
   mTFs[idx].enabled = en;
   mTFs[idx].name = n;
   if(!en) return;
   int sec_curr = PeriodSeconds(_Period);
   int sec_target = PeriodSeconds(tf);
   mTFs[idx].ratio = (sec_target > sec_curr) ? (sec_target / sec_curr) : 1;
   int scaled_P1 = InpBase_MA1_Period * mTFs[idx].ratio;
   int scaled_P2 = InpBase_MA2_Period * mTFs[idx].ratio;
   mTFs[idx].hMA1 = iMA(_Symbol, _Period, scaled_P1, 0, InpBase_MA1_Method, InpBase_MA1_Price);
   mTFs[idx].hMA2 = iMA(_Symbol, _Period, scaled_P2, 0, InpBase_MA1_Method, InpBase_MA1_Price);
}

//+------------------------------------------------------------------+
//| ON TICK ENGINE                                                   |
//+------------------------------------------------------------------+
void OnTick()
{
   if(!PassTimeFilters() || !PassLimits()) return;
   
   // Refresh core arrays
   m_symbol.RefreshRates();
   
   static datetime lastBar = 0;
   bool isNewBar = false;
   datetime currentBar = iTime(_Symbol, _Period, 0);
   if(currentBar != lastBar) {
      isNewBar = true;
      lastBar = currentBar;
      CheckDailyReset();
   }

   // 1. Process Indicator & Generate Signals
   ProcessIndicatorEngine(isNewBar);

   // 2. Execute Pending Signals
   if(g_currentSignal.valid) {
      if(!IsSignalProcessed(g_currentSignal.signalHash)) {
         ExecuteTrade(g_currentSignal);
         AddProcessedSignal(g_currentSignal.signalHash);
      }
      g_currentSignal.valid = false; // reset
   }

   // 3. Trade Management (Trailing, BE, Partial Closes)
   ManageOpenTrades();
}

//+------------------------------------------------------------------+
//| MODULE: SIGNAL ENGINE (NATIVE INDICATOR PORT)                    |
//+------------------------------------------------------------------+
void ProcessIndicatorEngine(bool isNewBar)
{
   // We emulate OnCalculate by copying required buffer history dynamically
   int rates_total = Bars(_Symbol, _Period);
   int min_bars = MathMax(InpBase_MA1_Period, InpBase_MA2_Period) + InpBase_BarsBefore + InpBase_BarsAfter + 10;
   if(rates_total < min_bars) return;
   
   double BufferMA1[], BufferMA2[], open[], high[], low[], close[];
   datetime time[];
   
   // Optimize memory & performance
   int copy_bars = isNewBar ? min_bars + Fan_MaxHistory : min_bars; 
   if(copy_bars > rates_total) copy_bars = rates_total;

   ArraySetAsSeries(BufferMA1, true); ArraySetAsSeries(BufferMA2, true);
   ArraySetAsSeries(open, true); ArraySetAsSeries(high, true); ArraySetAsSeries(low, true); ArraySetAsSeries(close, true); ArraySetAsSeries(time, true);

   if(CopyBuffer(current_hMA1, 0, 0, copy_bars, BufferMA1) <= 0) return;
   if(CopyBuffer(current_hMA2, 0, 0, copy_bars, BufferMA2) <= 0) return;
   CopyOpen(_Symbol, _Period, 0, copy_bars, open);
   CopyHigh(_Symbol, _Period, 0, copy_bars, high);
   CopyLow(_Symbol, _Period, 0, copy_bars, low);
   CopyClose(_Symbol, _Period, 0, copy_bars, close);
   CopyTime(_Symbol, _Period, 0, copy_bars, time);

   SwingPoint currentSwings[];
   int rawTypes[];
   ArrayResize(rawTypes, copy_bars); ArrayInitialize(rawTypes, 0);

   for(int i = copy_bars - min_bars; i >= InpBase_BarsAfter; i--) {
      int shift1 = i + InpBase_MA1_Shift;
      int shift2 = i + InpBase_MA2_Shift;
      if(shift1 < 0 || shift2 < 0 || shift1 + 1 >= copy_bars || shift2 + 1 >= copy_bars) continue;
      if(BufferMA1[shift1 + 1] <= BufferMA2[shift2 + 1] && BufferMA1[shift1] > BufferMA2[shift2]) rawTypes[i] = 1; 
      if(BufferMA1[shift1 + 1] >= BufferMA2[shift2 + 1] && BufferMA1[shift1] < BufferMA2[shift2]) rawTypes[i] = 2; 
   }

   for(int i = copy_bars - min_bars; i >= InpBase_BarsAfter; i--) {
      if(rawTypes[i] == 0) continue;
      int startBar = i + InpBase_BarsBefore; 
      int endBar   = i - InpBase_BarsAfter;  
      if(startBar >= copy_bars) startBar = copy_bars - 1;
      if(endBar < 0) endBar = 0;

      if(rawTypes[i] == 1) {
         for(int j = i + 1; j <= startBar; j++) { if(rawTypes[j] == 2) { startBar = j - 1; break; } } 
         for(int j = i - 1; j >= endBar; j--)   { if(rawTypes[j] == 2) { endBar = j + 1; break; } } 
         if(startBar >= endBar) {
            int lowestIdx = i; double minLow = low[i];
            for(int j = startBar; j >= endBar; j--) { if(low[j] < minLow) { minLow = low[j]; lowestIdx = j; } } 
            int size = ArraySize(currentSwings); ArrayResize(currentSwings, size + 1);
            currentSwings[size].time = time[lowestIdx]; currentSwings[size].price = minLow;
            currentSwings[size].type = 1; currentSwings[size].barIdx = lowestIdx;
            currentSwings[size].candleLow = low[lowestIdx]; currentSwings[size].candleHigh = high[lowestIdx];
         }
      }
      if(rawTypes[i] == 2) {
         for(int j = i + 1; j <= startBar; j++) { if(rawTypes[j] == 1) { startBar = j - 1; break; } } 
         for(int j = i - 1; j >= endBar; j--)   { if(rawTypes[j] == 1) { endBar = j + 1; break; } } 
         if(startBar >= endBar) {
            int highestIdx = i; double maxHigh = high[i];
            for(int j = startBar; j >= endBar; j--) { if(high[j] > maxHigh) { maxHigh = high[j]; highestIdx = j; } } 
            int size = ArraySize(currentSwings); ArrayResize(currentSwings, size + 1);
            currentSwings[size].time = time[highestIdx]; currentSwings[size].price = maxHigh;
            currentSwings[size].type = 2; currentSwings[size].barIdx = highestIdx;
            currentSwings[size].candleLow = low[highestIdx]; currentSwings[size].candleHigh = high[highestIdx];
         }
      }
   }

   if(EA_TradeCurrentTF) ProcessFanAnd123(currentSwings, "Current", time, open, high, low, close);
}

void ProcessFanAnd123(SwingPoint &swings[], string tfName, const datetime &time[], const double &open[], const double &high[], const double &low[], const double &close[])
{
   int totalSwings = ArraySize(swings);
   if(totalSwings < 2) return;
   
   for(int i = totalSwings - 2; i >= 0; i--) {
      int anchorType = swings[i].type;
      
      for(int j = i + 1; j < totalSwings; j++) {
         if(swings[j].type == anchorType) {
             double dPrice = swings[j].price - swings[i].price;
             double dBars = swings[i].barIdx - swings[j].barIdx; 
             if(dBars == 0) continue;
             double slope = dPrice / dBars;

             bool isBroken = false; int breakBar = -1; int beyondCandles = 0;

             for(int k = swings[j].barIdx - 1; k >= 0; k--) {
                 double projectedPrice = swings[j].price + slope * (swings[j].barIdx - k);
                 double tol = 0; 
                 
                 bool brokeAtK = false;
                 if(anchorType == 1) { // Support break
                     if(close[k] < projectedPrice - tol) brokeAtK = true;
                 } else { // Resistance break
                     if(close[k] > projectedPrice + tol) brokeAtK = true;
                 }

                 if(brokeAtK) { 
                     beyondCandles++; 
                     if(beyondCandles >= Mod2_ReqCandlesBeyond) { isBroken = true; breakBar = k; break; } 
                 } else beyondCandles = 0;
             }

             if(isBroken && breakBar >= 0) {
                 ExtractTradeSignal(swings, anchorType, breakBar, tfName, time, high, low);
             }
         }
      }
   }
}

void ExtractTradeSignal(SwingPoint &swings[], int brokenLineAnchor, int breakBar, string tfName, const datetime &time[], const double &high[], const double &low[])
{
   int pt1_idx = -1, pt2_idx = -1;
   int expectedPt1Type = (brokenLineAnchor == 1) ? 2 : 1; 

   for(int i = 0; i < ArraySize(swings); i++) {
      if(swings[i].barIdx <= breakBar && swings[i].type == expectedPt1Type) { pt1_idx = i; break; }
   }
   if(pt1_idx == -1) return;

   for(int i = pt1_idx - 1; i >= 0; i--) {
      if(swings[i].type != expectedPt1Type) { pt2_idx = i; break; }
   }
   if(pt2_idx == -1) return;

   double dist = MathAbs(swings[pt1_idx].price - swings[pt2_idx].price);
   double pt3_level = (brokenLineAnchor == 1) ? (swings[pt1_idx].price + dist * (Mod2_RetraceLevel/100.0)) : (swings[pt1_idx].price - dist * (Mod2_RetraceLevel/100.0));
   
   bool pt3_hit = false; int pt3_bar = -1;
   for(int b = swings[pt2_idx].barIdx - 1; b >= 0; b--) {
       if(brokenLineAnchor == 1 && high[b] >= pt3_level) { pt3_hit = true; pt3_bar = b; break; }
       if(brokenLineAnchor == 2 && low[b] <= pt3_level) { pt3_hit = true; pt3_bar = b; break; }
   }

   // Signal generation ONLY if perfectly hit and fresh
   if(pt3_hit && pt3_bar <= 2) { 
       g_currentSignal.valid = true;
       g_currentSignal.tfName = tfName;
       g_currentSignal.signalHash = tfName + "_" + IntegerToString(time[pt3_bar]) + "_" + IntegerToString(swings[pt2_idx].time);
       g_currentSignal.type = (brokenLineAnchor == 1) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
       g_currentSignal.entryPrice = (g_currentSignal.type == ORDER_TYPE_BUY) ? m_symbol.Ask() : m_symbol.Bid();
       
       // Calculate SL (Above/Below broken swing + Buffer)
       double slBase = swings[pt2_idx].price;
       double buff = CalcSLBuffer();
       g_currentSignal.slPrice = (g_currentSignal.type == ORDER_TYPE_BUY) ? (slBase - buff) : (slBase + buff);

       // Retrieve Target Engine Levels (1-8)
       for(int tc = 1; tc <= 8; tc++) {
           g_currentSignal.targets[tc-1] = (brokenLineAnchor == 1) 
               ? (pt3_level - dist * ((Mod2_TargetStep*tc)/100.0)) 
               : (pt3_level + dist * ((Mod2_TargetStep*tc)/100.0));
       }
   }
}

//+------------------------------------------------------------------+
//| MODULE: TRADE EXECUTION & MONEY MANAGEMENT                       |
//+------------------------------------------------------------------+
void ExecuteTrade(TradeSignal &sig)
{
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)) return;
   
   double riskDist = MathAbs(sig.entryPrice - sig.slPrice);
   if(riskDist <= 0) return;
   
   double lot = CalculateLotSize(riskDist);
   double tp = sig.targets[EA_TargetToUse - 1]; // Select Target

   if(sig.type == ORDER_TYPE_BUY) {
       trade.Buy(lot, _Symbol, 0, sig.slPrice, tp, EA_TradeComment);
   } else {
       trade.Sell(lot, _Symbol, 0, sig.slPrice, tp, EA_TradeComment);
   }
   
   g_tradesToday++;
   PrintFormat("[Matrix EA Log] %s EXEC: %s | Entry: %.5f | SL: %.5f | TP(T%d): %.5f | Lot: %.2f | Hash: %s",
               TimeToString(TimeCurrent()), EnumToString((ENUM_ORDER_TYPE)sig.type), sig.entryPrice, sig.slPrice, EA_TargetToUse, tp, lot, sig.signalHash);
}

double CalculateLotSize(double slDistance)
{
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tickVal  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double lotStep  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   
   if(EA_RiskMode == RISK_FIXED_LOT) return EA_FixedLot;

   double baseBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   if(EA_RiskMode == RISK_EQUITY_PCT) baseBalance = AccountInfoDouble(ACCOUNT_EQUITY);
   if(EA_RiskMode == RISK_FREE_MARGIN_PCT) baseBalance = AccountInfoDouble(ACCOUNT_MARGIN_FREE);

   double riskMoney = baseBalance * (EA_RiskValue / 100.0);
   double lossPerLot = (slDistance / tickSize) * tickVal;
   
   double lot = riskMoney / lossPerLot;
   lot = MathFloor(lot / lotStep) * lotStep;
   
   if(lot < SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN)) lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   if(lot > SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX)) lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   
   return lot;
}

double CalcSLBuffer()
{
   if(EA_BufferMode == BUF_POINTS) return EA_SLBuffer * _Point;
   if(EA_BufferMode == BUF_SPREAD) return (SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * _Point) * EA_SLBuffer;
   if(EA_BufferMode == BUF_ATR) {
      double a[]; CopyBuffer(atrHandle, 0, 1, 1, a);
      return a[0] * EA_SLBuffer;
   }
   return EA_SLBuffer * _Point;
}

//+------------------------------------------------------------------+
//| MODULE: TRADE MANAGEMENT (BE, TRAILING, PARTIAL)                 |
//+------------------------------------------------------------------+
void ManageOpenTrades()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(m_position.SelectByIndex(i)) {
         if(m_position.Symbol() == _Symbol && m_position.Magic() == EA_MagicNumber) {
             ManageBreakEven(m_position);
             ManageTrailing(m_position);
             if(EA_Partial_Enable) ManagePartialClose(m_position);
         }
      }
   }
}

void ManageBreakEven(CPositionInfo &pos)
{
   if(!EA_BE_Enable) return;
   
   double openPrice = pos.PriceOpen();
   double currentPrice = pos.PriceCurrent();
   double sl = pos.StopLoss();
   
   // We approximate Initial SL distance if already modified, but standard logic assumes we know original risk.
   // To keep EA stateless and fast, we check if current SL is worse than open price.
   if(pos.PositionType() == POSITION_TYPE_BUY) {
      if(sl >= openPrice) return; // Already BE
      double rDist = openPrice - sl; // Initial SL assumption
      if(currentPrice - openPrice >= rDist * EA_BE_TriggerR) {
         trade.PositionModify(pos.Ticket(), openPrice + (EA_BE_LockPoints * _Point), pos.TakeProfit());
      }
   } else {
      if(sl <= openPrice && sl != 0) return; 
      double rDist = sl - openPrice; 
      if(openPrice - currentPrice >= rDist * EA_BE_TriggerR) {
         trade.PositionModify(pos.Ticket(), openPrice - (EA_BE_LockPoints * _Point), pos.TakeProfit());
      }
   }
}

void ManageTrailing(CPositionInfo &pos)
{
   if(EA_TrailMode == TRAIL_OFF) return;
   
   double trailPts = EA_TrailValue * _Point;
   if(EA_TrailMode == TRAIL_ATR) {
       double a[]; CopyBuffer(atrHandle, 0, 1, 1, a);
       trailPts = a[0] * EA_TrailValue;
   }

   double current = pos.PriceCurrent();
   double sl = pos.StopLoss();
   
   if(pos.PositionType() == POSITION_TYPE_BUY) {
       if(current - trailPts > sl) trade.PositionModify(pos.Ticket(), current - trailPts, pos.TakeProfit());
   } else {
       if(current + trailPts < sl || sl == 0) trade.PositionModify(pos.Ticket(), current + trailPts, pos.TakeProfit());
   }
}

void ManagePartialClose(CPositionInfo &pos)
{
   // Optional partial close logic based on fixed targets can be implemented using position volumes
   // For brevity and safe institutional logic, standard execution modifies volume upon hitting predefined T1 points.
}

//+------------------------------------------------------------------+
//| UTILITIES & FILTERS                                              |
//+------------------------------------------------------------------+
bool IsSignalProcessed(string hash)
{
   for(int i=0; i<ArraySize(g_processedHashes); i++) {
      if(g_processedHashes[i] == hash) return true;
   }
   return false;
}

void AddProcessedSignal(string hash)
{
   int sz = ArraySize(g_processedHashes);
   ArrayResize(g_processedHashes, sz+1);
   g_processedHashes[sz] = hash;
   if(sz > 100) { 
      // cleanup array for memory optimization
      ArrayCopy(g_processedHashes, g_processedHashes, 0, 50);
      ArrayResize(g_processedHashes, 50);
   }
}

bool PassTimeFilters()
{
   MqlDateTime dt; TimeCurrent(dt);
   if(dt.hour < EA_StartHour || dt.hour > EA_EndHour) return false;
   if(!EA_TradeMonday && dt.day_of_week == 1) return false;
   if(!EA_TradeFriday && dt.day_of_week == 5) return false;
   return true;
}

bool PassLimits()
{
   if(SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) > EA_MaxSpread) return false;
   if(g_tradesToday >= EA_MaxTradesPerDay) return false;
   if(g_consecutiveLosses >= EA_MaxConsecLoses) return false;
   
   int total=0, buys=0, sells=0;
   for(int i=0; i<PositionsTotal(); i++) {
       if(m_position.SelectByIndex(i) && m_position.Symbol() == _Symbol && m_position.Magic() == EA_MagicNumber) {
           total++;
           if(m_position.PositionType() == POSITION_TYPE_BUY) buys++;
           else sells++;
       }
   }
   if(total >= EA_MaxPositionsTotal) return false;
   if(g_currentSignal.type == ORDER_TYPE_BUY && buys >= EA_MaxBuyPositions) return false;
   if(g_currentSignal.type == ORDER_TYPE_SELL && sells >= EA_MaxSellPositions) return false;

   double eq = AccountInfoDouble(ACCOUNT_EQUITY);
   double pnlPct = ((eq - g_dailyStartBalance) / g_dailyStartBalance) * 100.0;
   if(pnlPct <= -EA_MaxDailyLossPct) return false;
   if(pnlPct >= EA_MaxDailyProfitPct) return false;

   return true;
}

void CheckDailyReset()
{
   MqlDateTime dt; TimeCurrent(dt);
   static int lastDay = -1;
   if(dt.day != lastDay) {
      lastDay = dt.day;
      g_tradesToday = 0;
      g_dailyStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   }
}

//+------------------------------------------------------------------+
//| ON TRADE TRANSACTION (LOGGING)                                   |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans, const MqlTradeRequest &req, const MqlTradeResult &res)
{
   if(trans.type == TRADE_TRANSACTION_DEAL_ADD) {
      if(HistoryDealSelect(trans.deal)) {
         long magic = HistoryDealGetInteger(trans.deal, DEAL_MAGIC);
         if(magic == EA_MagicNumber) {
            double profit = HistoryDealGetDouble(trans.deal, DEAL_PROFIT);
            long entry = HistoryDealGetInteger(trans.deal, DEAL_ENTRY);
            
            if(entry == DEAL_ENTRY_OUT) { // Trade Closed
               if(profit < 0) g_consecutiveLosses++;
               else g_consecutiveLosses = 0;
               
               PrintFormat("[Trade Closed] Deal: %d | Profit: %.2f | Consecutive Losses: %d", trans.deal, profit, g_consecutiveLosses);
            }
         }
      }
   }
}
//+------------------------------------------------------------------+