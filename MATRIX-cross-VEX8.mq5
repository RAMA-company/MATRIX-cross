//+------------------------------------------------------------------+
//|                                  MATRIX-cross-V4.mq5             |
//|                                  Copyright 2026, Rama Empire     |
//+------------------------------------------------------------------+
#property copyright "Rama Empire"
// [EA CONVERSION: خواص اندیکاتور کامنت شدند تا به عنوان اکسپرت کار کند]
//#property indicator_chart_window
//#property indicator_buffers 5
//#property indicator_plots   5

// --- رسم مووینگ اول چارت جاری ---
//#property indicator_label1  "MA 1 (Current)"
//#property indicator_type1   DRAW_LINE
//#property indicator_color1  clrDodgerBlue
//#property indicator_style1  STYLE_SOLID
//#property indicator_width1  2

// --- رسم مووینگ دوم چارت جاری ---
//#property indicator_label2  "MA 2 (Current)"
//#property indicator_type2   DRAW_LINE
//#property indicator_color2  clrOrangeRed
//#property indicator_style2  STYLE_SOLID
//#property indicator_width2  2

// --- نقطه خرید چارت جاری ---
//#property indicator_label3  "Buy Dot (Current)"
//#property indicator_type3   DRAW_ARROW
//#property indicator_color3  clrLimeGreen
//#property indicator_width3  3

// --- نقطه فروش چارت جاری ---
//#property indicator_label4  "Sell Dot (Current)"
//#property indicator_type4   DRAW_ARROW
//#property indicator_color4  clrDeepPink
//#property indicator_width4  4

// --- خط زیگ‌زاگ چارت جاری ---
//#property indicator_label5  "ZigZag (Current)"
//#property indicator_type5   DRAW_SECTION
//#property indicator_color5  clrGray
//#property indicator_width5  1

#include <Trade\Trade.mqh>
CTrade trade; // کلاس انجام معاملات

//+------------------------------------------------------------------+
//| ENUMS (V3 & V4 Extended)                                         |
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

//+------------------------------------------------------------------+
//| ورودی‌های تنظیمات (Input Parameters)                             |
//+------------------------------------------------------------------+
input double               InpLotSize         = 0.1;           // حجم معامله (Lot) اکسپرت
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
input bool                 Mod1_Enable           = true;          // Enable S/R Zones
input ENUM_ZONE_DIR        Mod1_ZoneDirection    = ZONE_ALL;      // Zone Filtering
input color                Mod1_ColorBullish     = clrDarkGreen;  // Bullish Zone Color
input color                Mod1_ColorBearish     = clrMaroon;     // Bearish Zone Color
input bool                 Mod1_ExtendRight      = true;          // Extend Zones Right
input int                  Mod1_CustomProj       = 50;            // Projection (if Extend=false)
input int                  Mod1_MaxZones         = 20;            // Maximum Zones per TF
input int                  Mod1_MaxHistory       = 1000;          // Maximum History to Scan
input bool                 Mod1_DeleteBroken     = true;          // Delete Broken Zones
input bool                 Mod1_MergeNearby      = true;          // Merge Nearby Zones
input ENUM_MERGE_MODE      Mod1_MergeMode        = MERGE_POINTS;  // Merge Logic
input double               Mod1_MergeTolerance   = 10.0;          // Merge Tolerance Value
input ENUM_FAN_PRIORITY    Mod1_Priority         = PRIO_NEWEST;   // Zone Priority
input double               Mod1_MinStrength      = 0.0;           // Min Zone Strength
input double               Mod1_MaxStrength      = 100.0;         // Max Zone Strength
input bool                 Mod1_ShowLabels       = true;          // Show Zone Labels (TF, Date, Strength)

input group "=== MODULE 2: Standard 1-2-3 Pattern ==="
input bool                 Mod2_Enable           = true;          // Enable 1-2-3 Pattern
input ENUM_BREAK_RULE      Mod2_BreakRule        = BREAK_CLOSE;   // Break Confirmation
input int                  Mod2_ReqCandlesBeyond = 1;             // Require X Candles beyond trendline
input bool                 Mod2_ReqLastSwingBreak= true;          // Require last touching swing break
input double               Mod2_RetraceLevel     = 50.0;          // Point 3 Retracement Level (%)
input bool                 Mod2_EnableTargets    = true;          // Enable Target Projections
input double               Mod2_TargetStep       = 50.0;          // Target Steps (%)
input int                  Mod2_TargetCount      = 8;             // Target Levels Count (Up to 400%)
input color                Mod2_TargetColor      = clrYellow;     // Target Line Color
input ENUM_LINE_STYLE      Mod2_TargetStyle      = STYLE_DASH;    // Target Line Style
input int                  Mod2_TargetWidth      = 1;             // Target Line Width
input bool                 Mod2_HideReached      = true;          // Hide Reached Targets
input bool                 Mod2_DeleteOld        = true;          // Delete Old Targets
// Independent 1-2-3 Alerts
input bool                 Mod2_AlertEnable      = false;         // 1-2-3 Alert
input bool                 Mod2_PushEnable       = false;         // 1-2-3 Push
input bool                 Mod2_EmailEnable      = false;         // 1-2-3 Email
input bool                 Mod2_SoundEnable      = false;         // 1-2-3 Sound

input group "=== MODULE 3: Sideways Market Detection ==="
input bool                 Mod3_Enable           = true;          // Enable Sideways Detection
input ENUM_TOLERANCE_TYPE  Mod3_TolType          = TOL_ATR;       // Sideways Tolerance Type
input double               Mod3_Tolerance        = 1.5;           // Sideways Tolerance Value
input int                  Mod3_MinSwings        = 4;             // Minimum Swings inside Range
input int                  Mod3_MinBars          = 20;            // Minimum Range Width (Bars)
input int                  Mod3_MaxBars          = 200;           // Maximum Range Width (Bars)
input color                Mod3_BoxColor         = clrBlue;       // Range Box Color
input bool                 Mod3_ShowHistory      = false;         // Show Historical Ranges
input bool                 Mod3_MergeRanges      = true;          // Merge Overlapping Ranges

input group "=== MODULE 4: Advanced Fan Trend Management ==="
input int                  Mod4_MaxTrendAge      = 500;           // Max Trend Age (Bars)
input int                  Mod4_MaxFanAge        = 300;           // Max Fan Age (Bars)
input bool                 Mod4_AutoArchive      = true;          // Hide Inactive/Broken Fans
input bool                 Mod4_AdaptiveAngle    = true;          // Adaptive Angle via Volatility
input bool                 Mod4_RequireBodyTouch = true;          // Reject shadow-only touches
input double               Mod4_MinTouchRejATR   = 0.5;           // Min Touch Rejection (ATR)
input double               Mod4_MinTrendScore    = 10.0;          // Min Trend Quality Score

input group "--- 1) TRENDLINE ANGLE FILTER ---"
input bool                 Fan_EnableAngleFilter = false;         
input double               Fan_MinAngle          = 5.0;           
input double               Fan_MaxAngle          = 85.0;          

input group "--- 2 & 3) DISTANCE FILTERS ---"
input double               Fan_MinPriceDist      = 10.0;          
input int                  Fan_MinCandleDist     = 5;             

input group "--- 4) TRENDLINE TOLERANCE ---"
input ENUM_TOLERANCE_TYPE  Fan_ToleranceType     = TOL_ATR;       
input double               Fan_Tolerance         = 0.20;          

input group "--- 5) TRENDLINE EXTENSION ---"
input ENUM_DRAW_MODE       Fan_DrawingMode       = DRAW_RAY;      
input int                  Fan_ProjectionLength  = 50;            
input bool                 Fan_ExtendRight       = true;          

input group "--- 6) MAXIMUM FAN LINES ---"
input int                  Fan_MaxActiveLines    = 50;            
input int                  Fan_MaxFanLines       = 20;            
input int                  Fan_MaxTrends         = 5;             

input group "--- 7) LAST TREND ONLY ---"
input ENUM_FAN_DISPLAY     Fan_DisplayMode       = DISP_ALL;      

input group "--- 8) TREND BOUNDARIES ---"
input ENUM_FAN_BOUNDARY    Fan_BoundaryMode      = BOUND_OFF;     
input color                Fan_BoundaryColor     = clrDarkGray;   
input int                  Fan_BoundaryWidth     = 1;             
input ENUM_LINE_STYLE      Fan_BoundaryStyle     = STYLE_DOT;     

input group "--- 9) TREND LABELS ---"
input bool                 Fan_ShowLabels        = true;          

input group "--- 10) TOUCH FILTER ---"
input int                  Fan_MinTouches        = 2;             

input group "--- 11) MERGE NEARBY PIVOTS ---"
input bool                 Fan_EnableMerge       = false;         
input ENUM_MERGE_MODE      Fan_MergeMode         = MERGE_CANDLES; 
input double               Fan_MergeValue        = 5.0;           

input group "--- 12) BREAK RULE ---"
input ENUM_BREAK_RULE      Fan_BreakRule         = BREAK_CLOSE;   

input group "--- 13) COUNTER TREND ---"
input ENUM_TREND_DIR_EXT   Fan_TrendDirectionExt = DIR_BOTH;      

input group "--- 14 & 15) COLORS AND STYLES ---"
input color                Fan_ColorBullish      = clrLime;       
input color                Fan_ColorBearish      = clrRed;        
input color                Fan_ColorBroken       = clrDimGray;    
input color                Fan_ColorCurrentTrend = clrYellow;     
input color                Fan_ColorOldTrend     = clrGray;       
input int                  Fan_LineWidth         = 2;             
input ENUM_LINE_STYLE      Fan_LineStyle         = STYLE_SOLID;   

input group "--- 16) PERFORMANCE ---"
input int                  Fan_MaxHistory        = 2000;          
input int                  Fan_MaxPivots         = 1000;          
input int                  Fan_MaxObjects        = 500;           

input group "--- Legacy Configs (DO NOT REMOVE) ---"
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

input group "--- تنظیمات چارت جاری (Current) ---"
input bool                 InpCurr_DrawZigZag    = true;          
input bool                 InpCurr_DrawFan       = true;          
input color                InpCurr_FanColor      = clrWhite;

input group "--- تایم فریم ۵ دقیقه (M5) ---"
input bool                 InpM5_Enable       = false;
input bool                 InpM5_DrawZigZag   = true;
input bool                 InpM5_DrawFan      = true;
input color                InpM5_DotColor     = clrYellow;
input color                InpM5_ZigZagColor  = clrYellow;
input color                InpM5_FanColor     = clrYellow;
input int                  InpM5_ZigZagWidth  = 2;

input group "--- تایم فریم ۱۵ دقیقه (M15) ---"
input bool                 InpM15_Enable      = false;
input bool                 InpM15_DrawZigZag  = true;
input bool                 InpM15_DrawFan     = true;
input color                InpM15_DotColor    = clrOrange;
input color                InpM15_ZigZagColor = clrOrange;
input color                InpM15_FanColor    = clrOrange;
input int                  InpM15_ZigZagWidth = 2;

input group "--- تایم فریم ۳۰ دقیقه (M30) ---"
input bool                 InpM30_Enable      = false;
input bool                 InpM30_DrawZigZag  = true;
input bool                 InpM30_DrawFan     = true;
input color                InpM30_DotColor    = clrCyan;
input color                InpM30_ZigZagColor = clrCyan;
input color                InpM30_FanColor    = clrCyan;
input int                  InpM30_ZigZagWidth = 2;

input group "--- تایم فریم ۱ ساعته (H1) ---"
input bool                 InpH1_Enable       = false;
input bool                 InpH1_DrawZigZag   = true;
input bool                 InpH1_DrawFan      = true;
input color                InpH1_DotColor     = clrMagenta;
input color                InpH1_ZigZagColor  = clrMagenta;
input color                InpH1_FanColor     = clrMagenta;
input int                  InpH1_ZigZagWidth  = 3;

input group "--- تایم فریم ۴ ساعته (H4) ---"
input bool                 InpH4_Enable       = false;
input bool                 InpH4_DrawZigZag   = true;
input bool                 InpH4_DrawFan      = true;
input color                InpH4_DotColor     = clrSpringGreen;
input color                InpH4_ZigZagColor  = clrSpringGreen;
input color                InpH4_FanColor     = clrSpringGreen;
input int                  InpH4_ZigZagWidth  = 3;

input group "--- تایم فریم روزانه (D1) ---"
input bool                 InpD1_Enable       = false;
input bool                 InpD1_DrawZigZag   = true;
input bool                 InpD1_DrawFan      = true;
input color                InpD1_DotColor     = clrAqua;
input color                InpD1_ZigZagColor  = clrAqua;
input color                InpD1_FanColor     = clrAqua;
input int                  InpD1_ZigZagWidth  = 4;

input group "--- تایم فریم هفتگی (W1) ---"
input bool                 InpW1_Enable       = false;
input bool                 InpW1_DrawZigZag   = true;
input bool                 InpW1_DrawFan      = true;
input color                InpW1_DotColor     = clrGold;
input color                InpW1_ZigZagColor  = clrGold;
input color                InpW1_FanColor     = clrGold;
input int                  InpW1_ZigZagWidth  = 4;

input group "--- تایم فریم ماهانه (MN1) ---"
input bool                 InpMN1_Enable      = false;
input bool                 InpMN1_DrawZigZag  = true;
input bool                 InpMN1_DrawFan     = true;
input color                InpMN1_DotColor    = clrRed;
input color                InpMN1_ZigZagColor = clrRed;
input color                InpMN1_FanColor    = clrRed;
input int                  InpMN1_ZigZagWidth = 5;

input group "--- تنظیمات هشدارها (Alerts) ---"
input bool                 InpEnableAlert     = false;
input bool                 InpEnableSound     = false;
input bool                 InpEnablePush      = false;
input bool                 InpEnableEmail     = false;

// --- بافرهای داده چارت جاری (برای تبدیل به اکسپرت آرایه داینامیک شدند) ---
double BufferMA1[];
double BufferMA2[];
double BufferBuy[];
double BufferSell[];
double BufferZigZag[];

struct TF_Config {
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

// --- ساختار مدیریت Swing ها (Extended for Mod 1) ---
struct SwingPoint {
   datetime time;
   double   price;
   int      type;       // 1 = Low, 2 = High
   int      barIdx;
   double   candleHigh; // Mod 1 addition
   double   candleLow;  // Mod 1 addition
};

TF_Config mTFs[8];
int current_hMA1, current_hMA2;
int atrHandle; 
datetime lastAlertTime;
datetime last123AlertTime; // Mod 2 Alert Tracking

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
// [EA CONVERSION: این توابع در اکسپرت‌ها نامعتبر هستند بنابراین کامنت شدند]
//   SetIndexBuffer(0, BufferMA1, INDICATOR_DATA);
//   SetIndexBuffer(1, BufferMA2, INDICATOR_DATA);
//   SetIndexBuffer(2, BufferBuy, INDICATOR_DATA);
//   SetIndexBuffer(3, BufferSell, INDICATOR_DATA);
//   SetIndexBuffer(4, BufferZigZag, INDICATOR_DATA);
//   PlotIndexSetInteger(0, PLOT_SHIFT, InpBase_MA1_Shift);
//   PlotIndexSetInteger(1, PLOT_SHIFT, InpBase_MA2_Shift);
//   PlotIndexSetInteger(2, PLOT_ARROW, 158); 
//   PlotIndexSetInteger(3, PLOT_ARROW, 158); 
//   PlotIndexSetDouble(2, PLOT_EMPTY_VALUE, 0.0);
//   PlotIndexSetDouble(3, PLOT_EMPTY_VALUE, 0.0);
//   PlotIndexSetDouble(4, PLOT_EMPTY_VALUE, 0.0);

   current_hMA1 = iMA(_Symbol, _Period, InpBase_MA1_Period, 0, InpBase_MA1_Method, InpBase_MA1_Price);
   current_hMA2 = iMA(_Symbol, _Period, InpBase_MA2_Period, 0, InpBase_MA1_Method, InpBase_MA1_Price);
   atrHandle    = iATR(_Symbol, _Period, 14); 

   SetupTF(0, InpM5_Enable, PERIOD_M5, "M5", InpM5_DotColor, InpM5_ZigZagColor, InpM5_FanColor, InpM5_ZigZagWidth, InpM5_DrawZigZag, InpM5_DrawFan);
   SetupTF(1, InpM15_Enable, PERIOD_M15, "M15", InpM15_DotColor, InpM15_ZigZagColor, InpM15_FanColor, InpM15_ZigZagWidth, InpM15_DrawZigZag, InpM15_DrawFan);
   SetupTF(2, InpM30_Enable, PERIOD_M30, "M30", InpM30_DotColor, InpM30_ZigZagColor, InpM30_FanColor, InpM30_ZigZagWidth, InpM30_DrawZigZag, InpM30_DrawFan);
   SetupTF(3, InpH1_Enable, PERIOD_H1, "H1", InpH1_DotColor, InpH1_ZigZagColor, InpH1_FanColor, InpH1_ZigZagWidth, InpH1_DrawZigZag, InpH1_DrawFan);
   SetupTF(4, InpH4_Enable, PERIOD_H4, "H4", InpH4_DotColor, InpH4_ZigZagColor, InpH4_FanColor, InpH4_ZigZagWidth, InpH4_DrawZigZag, InpH4_DrawFan);
   SetupTF(5, InpD1_Enable, PERIOD_D1, "D1", InpD1_DotColor, InpD1_ZigZagColor, InpD1_FanColor, InpD1_ZigZagWidth, InpD1_DrawZigZag, InpD1_DrawFan);
   SetupTF(6, InpW1_Enable, PERIOD_W1, "W1", InpW1_DotColor, InpW1_ZigZagColor, InpW1_FanColor, InpW1_ZigZagWidth, InpW1_DrawZigZag, InpW1_DrawFan);
   SetupTF(7, InpMN1_Enable, PERIOD_MN1, "MN1", InpMN1_DotColor, InpMN1_ZigZagColor, InpMN1_FanColor, InpMN1_ZigZagWidth, InpMN1_DrawZigZag, InpMN1_DrawFan);

   lastAlertTime = 0;
   last123AlertTime = 0;
   return(INIT_SUCCEEDED);
}

void SetupTF(int idx, bool en, ENUM_TIMEFRAMES tf, string n, color dc, color zc, color fc, int zw, bool dz, bool df)
{
   mTFs[idx].enabled = en;
   mTFs[idx].name = n;
   mTFs[idx].dotCol = dc;
   mTFs[idx].zzCol = zc;
   mTFs[idx].fanCol = fc;
   mTFs[idx].zzWidth = zw;
   mTFs[idx].drawZZ = dz;
   mTFs[idx].drawFan = df;
   if(!en) return;

   int sec_curr = PeriodSeconds(_Period);
   int sec_target = PeriodSeconds(tf);
   mTFs[idx].ratio = (sec_target > sec_curr) ? (sec_target / sec_curr) : 1;

   int scaled_P1 = InpBase_MA1_Period * mTFs[idx].ratio;
   int scaled_P2 = InpBase_MA2_Period * mTFs[idx].ratio;
   mTFs[idx].hMA1 = iMA(_Symbol, _Period, scaled_P1, 0, InpBase_MA1_Method, InpBase_MA1_Price);
   mTFs[idx].hMA2 = iMA(_Symbol, _Period, scaled_P2, 0, InpBase_MA1_Method, InpBase_MA1_Price);
}

void OnDeinit(const int reason)
{
   ObjectsDeleteAll(0, "MTF_ZIGZAG_");
   ObjectsDeleteAll(0, "FAN_TREND_"); 
   ObjectsDeleteAll(0, "SR_ZONE_"); 
   ObjectsDeleteAll(0, "PAT123_"); 
   ObjectsDeleteAll(0, "SIDE_BOX_"); 
}

//+------------------------------------------------------------------+
//| [EA CONVERSION: تبدیل OnCalculate به OnTick]                     |
//+------------------------------------------------------------------+
void OnTick()
{
   int rates_total = iBars(_Symbol, _Period);
   static int prev_calculated = 0;
   
   if(rates_total <= 0) return;
   
   // --- تخصیص و گرفتن دیتای چارت برای جایگزین کردن ورودی‌های OnCalculate ---
   double open[], high[], low[], close[];
   datetime time[];
   
   ArraySetAsSeries(open, true); ArraySetAsSeries(close, true);
   ArraySetAsSeries(low, true); ArraySetAsSeries(high, true); ArraySetAsSeries(time, true);
   
   CopyOpen(_Symbol, _Period, 0, rates_total, open);
   CopyHigh(_Symbol, _Period, 0, rates_total, high);
   CopyLow(_Symbol, _Period, 0, rates_total, low);
   CopyClose(_Symbol, _Period, 0, rates_total, close);
   CopyTime(_Symbol, _Period, 0, rates_total, time);

   ArrayResize(BufferMA1, rates_total);
   ArrayResize(BufferMA2, rates_total);
   ArrayResize(BufferBuy, rates_total);
   ArrayResize(BufferSell, rates_total);
   ArrayResize(BufferZigZag, rates_total);

   int min_bars = MathMax(InpBase_MA1_Period, InpBase_MA2_Period) + InpBase_BarsBefore + InpBase_BarsAfter + 10;
   if(rates_total < min_bars) return;

   ArraySetAsSeries(BufferMA1, true); ArraySetAsSeries(BufferMA2, true);
   ArraySetAsSeries(BufferBuy, true); ArraySetAsSeries(BufferSell, true); ArraySetAsSeries(BufferZigZag, true);

   if(CopyBuffer(current_hMA1, 0, 0, rates_total, BufferMA1) <= 0) return;
   if(CopyBuffer(current_hMA2, 0, 0, rates_total, BufferMA2) <= 0) return;

   int limit = rates_total - prev_calculated;
   if(limit > rates_total - min_bars) limit = rates_total - min_bars;
   for(int k = limit; k >= 0; k--) { BufferBuy[k] = 0.0; BufferSell[k] = 0.0; BufferZigZag[k] = 0.0; }

   SwingPoint currentSwings[];
   
   // --- پردازش چارت جاری ---
   int rawTypes[];
   ArrayResize(rawTypes, rates_total); ArrayInitialize(rawTypes, 0);

   for(int i = rates_total - min_bars; i >= InpBase_BarsAfter; i--) {
      int shift1 = i + InpBase_MA1_Shift;
      int shift2 = i + InpBase_MA2_Shift;
      if(shift1 < 0 || shift2 < 0 || shift1 + 1 >= rates_total || shift2 + 1 >= rates_total) continue;
      if(BufferMA1[shift1 + 1] <= BufferMA2[shift2 + 1] && BufferMA1[shift1] > BufferMA2[shift2]) rawTypes[i] = 1; 
      if(BufferMA1[shift1 + 1] >= BufferMA2[shift2 + 1] && BufferMA1[shift1] < BufferMA2[shift2]) rawTypes[i] = 2; 
   }

   for(int i = rates_total - min_bars; i >= InpBase_BarsAfter; i--) {
      if(rawTypes[i] == 0) continue;
      int startBar = i + InpBase_BarsBefore; 
      int endBar   = i - InpBase_BarsAfter;  
      if(startBar >= rates_total) startBar = rates_total - 1;
      if(endBar < 0) endBar = 0;

      if(rawTypes[i] == 1) {
         for(int j = i + 1; j <= startBar; j++) { if(rawTypes[j] == 2) { startBar = j - 1; break; } } 
         for(int j = i - 1; j >= endBar; j--)   { if(rawTypes[j] == 2) { endBar = j + 1; break; } } 
         if(startBar >= endBar) {
            int lowestIdx = i; double minLow = low[i];
            for(int j = startBar; j >= endBar; j--) { if(low[j] < minLow) { minLow = low[j]; lowestIdx = j; } } 
            BufferBuy[lowestIdx] = minLow;
            if(InpCurr_DrawZigZag) BufferZigZag[lowestIdx] = minLow;
            int size = ArraySize(currentSwings); ArrayResize(currentSwings, size + 1);
            currentSwings[size].time = time[lowestIdx]; currentSwings[size].price = minLow;
            currentSwings[size].type = 1; currentSwings[size].barIdx = lowestIdx;
            currentSwings[size].candleLow = low[lowestIdx]; currentSwings[size].candleHigh = high[lowestIdx]; // Mod 1
         }
      }
      if(rawTypes[i] == 2) {
         for(int j = i + 1; j <= startBar; j++) { if(rawTypes[j] == 1) { startBar = j - 1; break; } } 
         for(int j = i - 1; j >= endBar; j--)   { if(rawTypes[j] == 1) { endBar = j + 1; break; } } 
         if(startBar >= endBar) {
            int highestIdx = i; double maxHigh = high[i];
            for(int j = startBar; j >= endBar; j--) { if(high[j] > maxHigh) { maxHigh = high[j]; highestIdx = j; } } 
            BufferSell[highestIdx] = maxHigh;
            if(InpCurr_DrawZigZag) BufferZigZag[highestIdx] = maxHigh; 
            int size = ArraySize(currentSwings); ArrayResize(currentSwings, size + 1);
            currentSwings[size].time = time[highestIdx]; currentSwings[size].price = maxHigh;
            currentSwings[size].type = 2; currentSwings[size].barIdx = highestIdx;
            currentSwings[size].candleLow = low[highestIdx]; currentSwings[size].candleHigh = high[highestIdx]; // Mod 1
         }
      }
   }

   // Module Invocation (Current Chart)
   if(InpCurr_DrawFan) DrawFanTrendlines(currentSwings, "Current", InpCurr_FanColor, time, open, high, low, close);
   if(Mod1_Enable) DrawSupportResistanceZones(currentSwings, "Current", time, high, low);
   if(Mod3_Enable) DetectSidewaysMarkets(currentSwings, "Current", time, high, low);

   // --- پردازش تایم‌فریم‌های بالاتر ---
   for(int t = 0; t < 8; t++) {
      if(!mTFs[t].enabled) continue;
      int r = mTFs[t].ratio;
      int scaled_s1 = InpBase_MA1_Shift * r; int scaled_s2 = InpBase_MA2_Shift * r;
      int scaled_x  = InpBase_BarsBefore * r; int scaled_y  = InpBase_BarsAfter * r;
      
      double tMA1[], tMA2[];
      ArraySetAsSeries(tMA1, true); ArraySetAsSeries(tMA2, true);
      if(CopyBuffer(mTFs[t].hMA1, 0, 0, rates_total, tMA1) <= 0) continue;
      if(CopyBuffer(mTFs[t].hMA2, 0, 0, rates_total, tMA2) <= 0) continue;

      int tRawTypes[]; ArrayResize(tRawTypes, rates_total); ArrayInitialize(tRawTypes, 0);
      for(int i = rates_total - (min_bars * r); i >= scaled_y; i--) {
         int shift1 = i + scaled_s1; int shift2 = i + scaled_s2;
         if(shift1 < 0 || shift2 < 0 || shift1 + 1 >= rates_total || shift2 + 1 >= rates_total) continue;
         if(tMA1[shift1 + 1] <= tMA2[shift2 + 1] && tMA1[shift1] > tMA2[shift2]) tRawTypes[i] = 1; 
         if(tMA1[shift1 + 1] >= tMA2[shift2 + 1] && tMA1[shift1] < tMA2[shift2]) tRawTypes[i] = 2; 
      }

      ObjectsDeleteAll(0, "MTF_ZIGZAG_" + mTFs[t].name + "_");
      int lastType = 0; datetime lastTime = 0; double lastPrice = 0;
      SwingPoint mtfSwings[]; 
      
      for(int i = rates_total - (min_bars * r); i >= scaled_y; i--) {
         if(tRawTypes[i] == 0) continue;
         int startBar = i + scaled_x; int endBar   = i - scaled_y;
         if(startBar >= rates_total) startBar = rates_total - 1;
         if(endBar < 0) endBar = 0;

         if(tRawTypes[i] == 1) {
            for(int j = i + 1; j <= startBar; j++) { if(tRawTypes[j] == 2) { startBar = j - 1; break; } }
            for(int j = i - 1; j >= endBar; j--)   { if(tRawTypes[j] == 2) { endBar = j + 1; break; } }
            if(startBar >= endBar) {
               int lowestIdx = i; double minLow = low[i];
               for(int j = startBar; j >= endBar; j--) { if(low[j] < minLow) { minLow = low[j]; lowestIdx = j; } }
               string dotName = "MTF_ZIGZAG_" + mTFs[t].name + "_Dot_" + IntegerToString(time[lowestIdx]);
               ObjectCreate(0, dotName, OBJ_ARROW, 0, time[lowestIdx], minLow);
               ObjectSetInteger(0, dotName, OBJPROP_ARROWCODE, 158); ObjectSetInteger(0, dotName, OBJPROP_COLOR, mTFs[t].dotCol); ObjectSetInteger(0, dotName, OBJPROP_WIDTH, 4);
               if(mTFs[t].drawZZ && lastTime != 0) {
                  string lineName = "MTF_ZIGZAG_" + mTFs[t].name + "_Line_" + IntegerToString(lastTime) + "_" + IntegerToString(time[lowestIdx]);
                  ObjectCreate(0, lineName, OBJ_TREND, 0, lastTime, lastPrice, time[lowestIdx], minLow);
                  ObjectSetInteger(0, lineName, OBJPROP_COLOR, mTFs[t].zzCol); ObjectSetInteger(0, lineName, OBJPROP_WIDTH, mTFs[t].zzWidth); ObjectSetInteger(0, lineName, OBJPROP_RAY_RIGHT, false);
               }
               lastTime = time[lowestIdx]; lastPrice = minLow; lastType = 1;
               int size = ArraySize(mtfSwings); ArrayResize(mtfSwings, size + 1);
               mtfSwings[size].time = time[lowestIdx]; mtfSwings[size].price = minLow; mtfSwings[size].type = 1; mtfSwings[size].barIdx = lowestIdx;
               mtfSwings[size].candleLow = low[lowestIdx]; mtfSwings[size].candleHigh = high[lowestIdx]; // Mod 1
            }
         }
         if(tRawTypes[i] == 2) {
            for(int j = i + 1; j <= startBar; j++) { if(tRawTypes[j] == 1) { startBar = j - 1; break; } }
            for(int j = i - 1; j >= endBar; j--)   { if(tRawTypes[j] == 1) { endBar = j + 1; break; } }
            if(startBar >= endBar) {
               int highestIdx = i; double maxHigh = high[i];
               for(int j = startBar; j >= endBar; j--) { if(high[j] > maxHigh) { maxHigh = high[j]; highestIdx = j; } }
               string dotName = "MTF_ZIGZAG_" + mTFs[t].name + "_Dot_" + IntegerToString(time[highestIdx]);
               ObjectCreate(0, dotName, OBJ_ARROW, 0, time[highestIdx], maxHigh);
               ObjectSetInteger(0, dotName, OBJPROP_ARROWCODE, 158); ObjectSetInteger(0, dotName, OBJPROP_COLOR, mTFs[t].dotCol); ObjectSetInteger(0, dotName, OBJPROP_WIDTH, 4);
               if(mTFs[t].drawZZ && lastTime != 0) {
                  string lineName = "MTF_ZIGZAG_" + mTFs[t].name + "_Line_" + IntegerToString(lastTime) + "_" + IntegerToString(time[highestIdx]);
                  ObjectCreate(0, lineName, OBJ_TREND, 0, lastTime, lastPrice, time[highestIdx], maxHigh);
                  ObjectSetInteger(0, lineName, OBJPROP_COLOR, mTFs[t].zzCol); ObjectSetInteger(0, lineName, OBJPROP_WIDTH, mTFs[t].zzWidth); ObjectSetInteger(0, lineName, OBJPROP_RAY_RIGHT, false);
               }
               lastTime = time[highestIdx]; lastPrice = maxHigh; lastType = 2;
               int size = ArraySize(mtfSwings); ArrayResize(mtfSwings, size + 1);
               mtfSwings[size].time = time[highestIdx]; mtfSwings[size].price = maxHigh; mtfSwings[size].type = 2; mtfSwings[size].barIdx = highestIdx;
               mtfSwings[size].candleLow = low[highestIdx]; mtfSwings[size].candleHigh = high[highestIdx]; // Mod 1
            }
         }
      }
      
      // Module Invocation (MTF)
      if(mTFs[t].drawFan) DrawFanTrendlines(mtfSwings, mTFs[t].name, mTFs[t].fanCol, time, open, high, low, close);
      if(Mod1_Enable) DrawSupportResistanceZones(mtfSwings, mTFs[t].name, time, high, low);
      if(Mod3_Enable) DetectSidewaysMarkets(mtfSwings, mTFs[t].name, time, high, low);
   }

   // --- سیستم هشدار پایه ---
   if(time[0] != lastAlertTime) {
      int checkBar = 1 + InpBase_BarsAfter; int s1 = checkBar + InpBase_MA1_Shift; int s2 = checkBar + InpBase_MA2_Shift;
      if(s1 >= 0 && s2 >= 0 && s1 + 1 < rates_total && s2 + 1 < rates_total) {
         if(BufferMA1[s1 + 1] <= BufferMA2[s2 + 1] && BufferMA1[s1] > BufferMA2[s2]) { SendAlerts("سیگنال نقطه Low", _Symbol); lastAlertTime = time[0]; }
         else if(BufferMA1[s1 + 1] >= BufferMA2[s2 + 1] && BufferMA1[s1] < BufferMA2[s2]) { SendAlerts("سیگنال نقطه High", _Symbol); lastAlertTime = time[0]; }
      }
   }
   
   prev_calculated = rates_total;
}

//+------------------------------------------------------------------+
//| V4 MODULE 4: Extended Fan Trendlines Engine                      |
//+------------------------------------------------------------------+
void DrawFanTrendlines(SwingPoint &swings[], string tfName, color baseFanColor,
                       const datetime &time[], const double &open[], const double &high[], 
                       const double &low[], const double &close[])
{
   if(Fan_AutoCleanup) ObjectsDeleteAll(0, "FAN_TREND_" + tfName + "_");
   if(Mod2_Enable) ObjectsDeleteAll(0, "PAT123_" + tfName + "_");
   
   int totalSwings = ArraySize(swings);
   if(totalSwings < 2) return;
   if(totalSwings > Fan_MaxPivots) totalSwings = Fan_MaxPivots;

   SwingPoint processedSwings[];
   if(Fan_EnableMerge) {
      int pSize = 0;
      for(int i = 0; i < totalSwings; i++) {
         if(pSize == 0) { ArrayResize(processedSwings, pSize + 1); processedSwings[pSize] = swings[i]; pSize++; } 
         else {
            bool shouldMerge = false; double lastP = processedSwings[pSize-1].price; int lastB = processedSwings[pSize-1].barIdx;
            if(Fan_MergeMode == MERGE_CANDLES && MathAbs(swings[i].barIdx - lastB) <= Fan_MergeValue) shouldMerge = true;
            else if(Fan_MergeMode == MERGE_POINTS && MathAbs(swings[i].price - lastP)/_Point <= Fan_MergeValue) shouldMerge = true;
            else if(Fan_MergeMode == MERGE_ATR) {
               double aVal[]; if(CopyBuffer(atrHandle, 0, swings[i].barIdx, 1, aVal) > 0) if(MathAbs(swings[i].price - lastP) <= Fan_MergeValue * aVal[0]) shouldMerge = true;
            }
            if(!shouldMerge) { ArrayResize(processedSwings, pSize + 1); processedSwings[pSize] = swings[i]; pSize++; }
         }
      }
   } else { ArrayCopy(processedSwings, swings); }

   totalSwings = ArraySize(processedSwings);
   if(totalSwings < 2) return;

   int drawnLinesCount = 0; int activeTrends = 0; int currentAnchorIdx = -1;

   for(int i = totalSwings - 2; i >= 0; i--) {
      if(drawnLinesCount >= Fan_MaxObjects) break;
      if(processedSwings[i].barIdx > Fan_MaxHistory || processedSwings[i].barIdx > Mod4_MaxTrendAge) continue; // Mod 4: Max Age

      int anchorType = processedSwings[i].type;
      if(currentAnchorIdx != i) {
         activeTrends++; currentAnchorIdx = i;
         if(Fan_DisplayMode == DISP_LAST_1 && activeTrends > 1) break;
         if(Fan_DisplayMode == DISP_LAST_2 && activeTrends > 2) break;
         if(Fan_DisplayMode == DISP_LAST_3 && activeTrends > 3) break;
      }

      int fanIndex = 1; int maxSearch = MathMin(i + 1 + Fan_CandidateRadius, totalSwings); datetime latestPivotTime = 0;

      for(int j = i + 1; j < maxSearch; j++) {
         if(drawnLinesCount >= Fan_MaxObjects || fanIndex > Fan_MaxFanLines) break;
         if(processedSwings[j].type == anchorType) {
             if(MathAbs(processedSwings[i].barIdx - processedSwings[j].barIdx) < Fan_MinCandleDist) continue;
             if(MathAbs(processedSwings[j].price - processedSwings[i].price) / _Point < Fan_MinPriceDist) continue;

             bool isCounterTrend = (anchorType == 1 && processedSwings[j].price < processedSwings[i].price) || (anchorType == 2 && processedSwings[j].price > processedSwings[i].price);
             if(Fan_TrendDirectionExt == DIR_TREND && isCounterTrend) continue;
             if(Fan_TrendDirectionExt == DIR_COUNTER && !isCounterTrend) continue;

             double dPrice = processedSwings[j].price - processedSwings[i].price;
             double dBars = processedSwings[i].barIdx - processedSwings[j].barIdx; 
             double slope = dPrice / dBars;

             // Mod 4: Adaptive Angle Check
             double actMinAng = Fan_MinAngle; double actMaxAng = Fan_MaxAngle;
             if(Mod4_AdaptiveAngle) { double aA[]; if(CopyBuffer(atrHandle,0,processedSwings[i].barIdx,1,aA)>0) { actMinAng += aA[0]*10; actMaxAng -= aA[0]*10; } }
             if(Fan_EnableAngleFilter) {
                 double angDeg = MathArctan(MathAbs(dPrice / _Point) / dBars) * 180.0 / M_PI;
                 if(angDeg < actMinAng || angDeg > actMaxAng) continue;
             }

             int touches = 0; bool isBroken = false; int breakBar = -1; int beyondCandles = 0;

             for(int k = processedSwings[j].barIdx - 1; k >= 0; k--) {
                 if(processedSwings[j].barIdx - k > Fan_MaxHistory || processedSwings[j].barIdx - k > Mod4_MaxFanAge) break;
                 
                 double projectedPrice = processedSwings[j].price + slope * (processedSwings[j].barIdx - k);
                 double tol = Fan_Tolerance;
                 if(Fan_ToleranceType == TOL_POINTS) tol = Fan_Tolerance * _Point;
                 else if(Fan_ToleranceType == TOL_PERCENT) tol = projectedPrice * (Fan_Tolerance / 100.0);
                 else if(Fan_ToleranceType == TOL_ATR) { double aVal[]; if(CopyBuffer(atrHandle, 0, k, 1, aVal) > 0) tol = Fan_Tolerance * aVal[0]; }

                 // Mod 4: Touch Quality Control
                 bool validTouch = false;
                 if(low[k] - tol <= projectedPrice && high[k] + tol >= projectedPrice) {
                    if(Mod4_RequireBodyTouch) { if(MathMin(open[k], close[k]) <= projectedPrice && MathMax(open[k], close[k]) >= projectedPrice) validTouch = true; } 
                    else validTouch = true;
                    if(validTouch && Mod4_MinTouchRejATR > 0) {
                       double aR[]; if(CopyBuffer(atrHandle,0,k,1,aR)>0 && (high[k]-low[k]) < Mod4_MinTouchRejATR*aR[0]) validTouch = false;
                    }
                 }
                 if(validTouch) touches++;

                 bool brokeAtK = false;
                 if(anchorType == 1) { 
                     if(Fan_BreakRule == BREAK_CLOSE && close[k] < projectedPrice - tol) brokeAtK = true;
                     else if(Fan_BreakRule == BREAK_BODY && MathMin(open[k], close[k]) < projectedPrice - tol) brokeAtK = true;
                     else if(Fan_BreakRule == BREAK_HIGHLOW && low[k] < projectedPrice - tol) brokeAtK = true;
                 } else { 
                     if(Fan_BreakRule == BREAK_CLOSE && close[k] > projectedPrice + tol) brokeAtK = true;
                     else if(Fan_BreakRule == BREAK_BODY && MathMax(open[k], close[k]) > projectedPrice + tol) brokeAtK = true;
                     else if(Fan_BreakRule == BREAK_HIGHLOW && high[k] > projectedPrice + tol) brokeAtK = true;
                 }

                 if(brokeAtK) { beyondCandles++; if(beyondCandles >= Mod2_ReqCandlesBeyond) { isBroken = true; breakBar = k; break; } } 
                 else beyondCandles = 0;
             }

             if(touches < (Fan_MinTouches - 2)) continue;
             
             // Mod 4: Trend Score Filter
             double tScore = touches * 5.0 + (dBars / 10.0);
             if(tScore < Mod4_MinTrendScore) continue;

             if(Mod4_AutoArchive && isBroken && activeTrends > 1) continue; // Mod 4 Auto Archive

             datetime t1 = processedSwings[i].time; double p1 = processedSwings[i].price;
             datetime t2 = processedSwings[j].time; double p2 = processedSwings[j].price;
             bool setRay = false;

             if(Fan_DrawingMode == DRAW_INFINITE || (Fan_DrawingMode == DRAW_RAY && !isBroken && Fan_ExtendRight)) setRay = true;
             else if(Fan_DrawingMode == DRAW_RAY && isBroken) { t2 = time[breakBar]; p2 = processedSwings[j].price + slope * (processedSwings[j].barIdx - breakBar); }
             else if(Fan_DrawingMode == DRAW_CUSTOM_PROJ) {
                 int endingBar = MathMax(0, processedSwings[j].barIdx - Fan_ProjectionLength);
                 if(isBroken && endingBar < breakBar) endingBar = breakBar;
                 t2 = time[endingBar]; p2 = processedSwings[j].price + slope * (processedSwings[j].barIdx - endingBar);
             }

             if(t2 > latestPivotTime) latestPivotTime = t2;
             color lineColor = (isBroken) ? Fan_ColorBroken : ((anchorType == 1) ? Fan_ColorBullish : Fan_ColorBearish);

             string objName = "FAN_TREND_" + tfName + "_" + IntegerToString(t1) + "_Fan" + IntegerToString(fanIndex);
             ObjectCreate(0, objName, OBJ_TREND, 0, t1, p1, t2, p2);
             ObjectSetInteger(0, objName, OBJPROP_COLOR, lineColor); ObjectSetInteger(0, objName, OBJPROP_RAY_RIGHT, setRay);
             ObjectSetInteger(0, objName, OBJPROP_WIDTH, Fan_LineWidth); ObjectSetInteger(0, objName, OBJPROP_STYLE, Fan_LineStyle);
             
             if(Fan_ShowLabels) {
                 string textObj = objName + "_lbl"; ObjectCreate(0, textObj, OBJ_TEXT, 0, t2, p2);
                 ObjectSetString(0, textObj, OBJPROP_TEXT, "T" + IntegerToString(activeTrends) + " (F" + IntegerToString(fanIndex) + ") S:"+DoubleToString(tScore,1));
                 ObjectSetInteger(0, textObj, OBJPROP_COLOR, lineColor); ObjectSetInteger(0, textObj, OBJPROP_FONTSIZE, 9);
             }

             // --- V4 MODULE 2: Trigger 1-2-3 Pattern Detection ---
             if(Mod2_Enable && isBroken && breakBar >= 0) {
                 Detect123Pattern(processedSwings, anchorType, breakBar, tfName, objName, time, high, low);
             }

             fanIndex++; drawnLinesCount++;
         }
      }
      if(fanIndex > 1 && Fan_BoundaryMode != BOUND_OFF) {
          if(Fan_BoundaryMode == BOUND_START || Fan_BoundaryMode == BOUND_BOTH) {
              string v1 = "FAN_TREND_" + tfName + "_BND_S_" + IntegerToString(processedSwings[i].time); ObjectCreate(0, v1, OBJ_VLINE, 0, processedSwings[i].time, 0);
              ObjectSetInteger(0, v1, OBJPROP_COLOR, Fan_BoundaryColor); ObjectSetInteger(0, v1, OBJPROP_STYLE, Fan_BoundaryStyle);
          }
          if((Fan_BoundaryMode == BOUND_END || Fan_BoundaryMode == BOUND_BOTH) && latestPivotTime > 0) {
              string v2 = "FAN_TREND_" + tfName + "_BND_E_" + IntegerToString(latestPivotTime); ObjectCreate(0, v2, OBJ_VLINE, 0, latestPivotTime, 0);
              ObjectSetInteger(0, v2, OBJPROP_COLOR, Fan_BoundaryColor); ObjectSetInteger(0, v2, OBJPROP_STYLE, Fan_BoundaryStyle);
          }
      }
   }
}

//+------------------------------------------------------------------+
//| V4 MODULE 1: Support / Resistance Zones                          |
//+------------------------------------------------------------------+
void DrawSupportResistanceZones(SwingPoint &swings[], string tfName, const datetime &time[], const double &high[], const double &low[])
{
   if(Mod1_ZoneDirection == ZONE_CURRENT && tfName != "Current") return;
   if(Mod1_DeleteBroken) ObjectsDeleteAll(0, "SR_ZONE_" + tfName + "_");

   int sCount = ArraySize(swings); if(sCount == 0) return;
   int drawnZones = 0;

   for(int i = 0; i < sCount; i++) {
      if(drawnZones >= Mod1_MaxZones) break;
      if(swings[i].barIdx > Mod1_MaxHistory) continue;

      double zTop = swings[i].candleHigh; double zBot = swings[i].candleLow;
      double zScore = 100.0 - (swings[i].barIdx / 10.0); // Baseline age score
      
      // Merge Engine
      if(Mod1_MergeNearby) {
         for(int j = i+1; j < MathMin(i+5, sCount); j++) {
            if(swings[i].type == swings[j].type) {
               bool merge = false;
               if(Mod1_MergeMode == MERGE_POINTS && MathAbs(swings[j].price - swings[i].price)/_Point <= Mod1_MergeTolerance) merge = true;
               if(merge) { zTop = MathMax(zTop, swings[j].candleHigh); zBot = MathMin(zBot, swings[j].candleLow); zScore += 20; i = j; }
            }
         }
      }
      
      if(zScore < Mod1_MinStrength || zScore > Mod1_MaxStrength) continue;

      datetime tEnd = (Mod1_ExtendRight) ? time[0] : time[MathMax(0, swings[i].barIdx - Mod1_CustomProj)];
      color zCol = (swings[i].type == 1) ? Mod1_ColorBullish : Mod1_ColorBearish;

      string objName = "SR_ZONE_" + tfName + "_" + IntegerToString(swings[i].time);
      ObjectCreate(0, objName, OBJ_RECTANGLE, 0, swings[i].time, zTop, tEnd, zBot);
      ObjectSetInteger(0, objName, OBJPROP_COLOR, zCol);
      ObjectSetInteger(0, objName, OBJPROP_FILL, true);
      ObjectSetInteger(0, objName, OBJPROP_RAY_RIGHT, Mod1_ExtendRight);

      if(Mod1_ShowLabels) {
         string lbl = objName + "_L"; ObjectCreate(0, lbl, OBJ_TEXT, 0, swings[i].time, zTop);
         ObjectSetString(0, lbl, OBJPROP_TEXT, tfName + " | SC: " + DoubleToString(zScore,0));
         ObjectSetInteger(0, lbl, OBJPROP_COLOR, clrWhite); ObjectSetInteger(0, lbl, OBJPROP_FONTSIZE, 8);
      }
      drawnZones++;
   }
}

//+------------------------------------------------------------------+
//| V4 MODULE 2: Standard 1-2-3 Pattern Detection                    |
//+------------------------------------------------------------------+
void Detect123Pattern(SwingPoint &swings[], int brokenLineAnchor, int breakBar, string tfName, string lineName, 
                      const datetime &time[], const double &high[], const double &low[])
{
   int pt1_idx = -1; int pt2_idx = -1;
   
   // Find Point 1: The swing forming after the break in the break direction
   int expectedPt1Type = (brokenLineAnchor == 1) ? 2 : 1; // Support break -> look for new low (Pt1)
   for(int i = 0; i < ArraySize(swings); i++) {
      if(swings[i].barIdx <= breakBar && swings[i].type == expectedPt1Type) { pt1_idx = i; break; }
   }
   if(pt1_idx == -1) return;

   // Find Point 2: The swing following Point 1 (Retracement origin)
   for(int i = pt1_idx - 1; i >= 0; i--) {
      if(swings[i].type != expectedPt1Type) { pt2_idx = i; break; }
   }
   if(pt2_idx == -1) return;

   // Validation Mod 2: Require Last Touching Swing Break
   if(Mod2_ReqLastSwingBreak) {
       int lastTouchIdx = -1;
       for(int i = pt1_idx + 1; i < ArraySize(swings); i++) { if(swings[i].type == brokenLineAnchor) { lastTouchIdx = i; break; } }
       if(lastTouchIdx != -1) {
           if(brokenLineAnchor == 1 && swings[pt1_idx].price >= swings[lastTouchIdx].price) return; // Support break, but Pt1 didn't go below last support touch
           if(brokenLineAnchor == 2 && swings[pt1_idx].price <= swings[lastTouchIdx].price) return; // Res break, but Pt1 didn't go above last res touch
       }
   }

   double dist = MathAbs(swings[pt1_idx].price - swings[pt2_idx].price);
   double pt3_level = (brokenLineAnchor == 1) ? (swings[pt1_idx].price + dist * (Mod2_RetraceLevel/100.0)) : (swings[pt1_idx].price - dist * (Mod2_RetraceLevel/100.0));
   
   bool pt3_hit = false; int pt3_bar = -1;
   for(int b = swings[pt2_idx].barIdx - 1; b >= 0; b--) {
       if(brokenLineAnchor == 1 && high[b] >= pt3_level) { pt3_hit = true; pt3_bar = b; break; }
       if(brokenLineAnchor == 2 && low[b] <= pt3_level) { pt3_hit = true; pt3_bar = b; break; }
   }

   if(pt3_hit) {
       string pName = "PAT123_" + tfName + "_" + lineName;
       
       // Draw Lines
       ObjectCreate(0, pName+"_L1", OBJ_TREND, 0, swings[pt1_idx].time, swings[pt1_idx].price, swings[pt2_idx].time, swings[pt2_idx].price);
       ObjectSetInteger(0, pName+"_L1", OBJPROP_COLOR, clrWhite); ObjectSetInteger(0, pName+"_L1", OBJPROP_RAY_RIGHT, false);
       ObjectCreate(0, pName+"_L2", OBJ_TREND, 0, swings[pt2_idx].time, swings[pt2_idx].price, time[pt3_bar], pt3_level);
       ObjectSetInteger(0, pName+"_L2", OBJPROP_COLOR, clrAqua); ObjectSetInteger(0, pName+"_L2", OBJPROP_RAY_RIGHT, false);
       
       // Draw Points
       ObjectCreate(0, pName+"_T1", OBJ_TEXT, 0, swings[pt1_idx].time, swings[pt1_idx].price); ObjectSetString(0, pName+"_T1", OBJPROP_TEXT, "P1");
       ObjectCreate(0, pName+"_T2", OBJ_TEXT, 0, swings[pt2_idx].time, swings[pt2_idx].price); ObjectSetString(0, pName+"_T2", OBJPROP_TEXT, "P2");
       ObjectCreate(0, pName+"_T3", OBJ_TEXT, 0, time[pt3_bar], pt3_level); ObjectSetString(0, pName+"_T3", OBJPROP_TEXT, "P3 CONFIRMED");

       // Mod 2: Targets
       if(Mod2_EnableTargets) {
           for(int tc = 1; tc <= Mod2_TargetCount; tc++) {
               double tgLvl = (brokenLineAnchor == 1) ? (pt3_level - dist * ((Mod2_TargetStep*tc)/100.0)) : (pt3_level + dist * ((Mod2_TargetStep*tc)/100.0));
               
               bool reached = false; 
               if(Mod2_HideReached) {
                   for(int c = pt3_bar-1; c>=0; c--) {
                       if(brokenLineAnchor == 1 && low[c] <= tgLvl) { reached = true; break; }
                       if(brokenLineAnchor == 2 && high[c] >= tgLvl) { reached = true; break; }
                   }
               }
               if(!reached) {
                   string tN = pName+"_TG_"+IntegerToString(tc);
                   ObjectCreate(0, tN, OBJ_TREND, 0, time[pt3_bar], tgLvl, time[0], tgLvl);
                   ObjectSetInteger(0, tN, OBJPROP_COLOR, Mod2_TargetColor); ObjectSetInteger(0, tN, OBJPROP_STYLE, Mod2_TargetStyle);
                   ObjectSetInteger(0, tN, OBJPROP_WIDTH, Mod2_TargetWidth); ObjectSetInteger(0, tN, OBJPROP_RAY_RIGHT, true);
               }
           }
       }

       // [EA CONVERSION: اضافه شدن منطق ورود به معامله بدون حذف آلرت‌ها]
       if(time[0] != last123AlertTime) {
           string msg = "1-2-3 Pattern Confirmed on " + _Symbol + " (" + tfName + ")";
           if(Mod2_AlertEnable) Alert(msg);
           if(Mod2_SoundEnable) PlaySound("alert.wav");
           if(Mod2_PushEnable) SendNotification(msg);
           if(Mod2_EmailEnable) SendMail("1-2-3 Pattern Alert", msg);
           
           // --- TRADING LOGIC (فقط زمانی که پترن در کندل جاری تایید شود) ---
           if(pt3_bar == 0) { 
               double sl = swings[pt1_idx].price; // استاپ لاس در نقطه 1
               double tp = 0;
               double lot = InpLotSize;
               
               if(brokenLineAnchor == 1) { // SELL
                   // تی‌پی دقیقاً روی 50 درصد (سطح اول Mod2_TargetStep) تنظیم می‌شود
                   tp = pt3_level - dist * (Mod2_TargetStep / 100.0);
                   trade.Sell(lot, _Symbol, SymbolInfoDouble(_Symbol, SYMBOL_BID), sl, tp, "1-2-3 Pattern Sell");
               } 
               else if(brokenLineAnchor == 2) { // BUY
                   // تی‌پی دقیقاً روی 50 درصد (سطح اول Mod2_TargetStep) تنظیم می‌شود
                   tp = pt3_level + dist * (Mod2_TargetStep / 100.0);
                   trade.Buy(lot, _Symbol, SymbolInfoDouble(_Symbol, SYMBOL_ASK), sl, tp, "1-2-3 Pattern Buy");
               }
           }
           
           last123AlertTime = time[0];
       }
   }
}

//+------------------------------------------------------------------+
//| V4 MODULE 3: Sideways Market Detection                           |
//+------------------------------------------------------------------+
void DetectSidewaysMarkets(SwingPoint &swings[], string tfName, const datetime &time[], const double &high[], const double &low[])
{
   if(!Mod3_ShowHistory) ObjectsDeleteAll(0, "SIDE_BOX_" + tfName + "_");
   
   int sCount = ArraySize(swings);
   for(int i = 0; i < sCount - Mod3_MinSwings; i++) {
       int spanBars = swings[i+Mod3_MinSwings-1].barIdx - swings[i].barIdx;
       if(spanBars < Mod3_MinBars || spanBars > Mod3_MaxBars) continue;

       double maxH = -1, minH = 999999; double maxL = -1, minL = 999999;
       for(int j = i; j < i + Mod3_MinSwings; j++) {
           if(swings[j].type == 2) { maxH = MathMax(maxH, swings[j].price); minH = MathMin(minH, swings[j].price); }
           if(swings[j].type == 1) { maxL = MathMax(maxL, swings[j].price); minL = MathMin(minL, swings[j].price); }
       }

       double tolV = Mod3_Tolerance;
       if(Mod3_TolType == TOL_POINTS) tolV = Mod3_Tolerance * _Point;
       else if(Mod3_TolType == TOL_PERCENT) tolV = maxH * (Mod3_Tolerance/100.0);
       else if(Mod3_TolType == TOL_ATR) { double a[]; if(CopyBuffer(atrHandle,0,swings[i].barIdx,1,a)>0) tolV = Mod3_Tolerance * a[0]; }

       if((maxH - minH) <= tolV && (maxL - minL) <= tolV) {
           string box = "SIDE_BOX_" + tfName + "_" + IntegerToString(swings[i+Mod3_MinSwings-1].time);
           ObjectCreate(0, box, OBJ_RECTANGLE, 0, swings[i+Mod3_MinSwings-1].time, maxH, swings[i].time, minL);
           ObjectSetInteger(0, box, OBJPROP_COLOR, Mod3_BoxColor);
           ObjectSetInteger(0, box, OBJPROP_FILL, true);
           ObjectSetInteger(0, box, OBJPROP_BACK, true);
           i += (Mod3_MinSwings - 1); // Skip ahead to prevent overlapping identical boxes unless merge handles it
       }
   }
}

//+------------------------------------------------------------------+
//| تابع ارسال انواع هشدار سیستم پایه                                |
//+------------------------------------------------------------------+
void SendAlerts(string signalType, string symbol)
{
   string msg = signalType + " در جفت‌ارز " + symbol + " | تایم‌فریم: " + EnumToString(_Period);
   if(InpEnableAlert) Alert(msg);
   if(InpEnableSound) PlaySound("alert.wav");
   if(InpEnablePush)  SendNotification(msg);
   if(InpEnableEmail) SendMail("سیگنال نقطه پوتین/پیووت", msg);
}
//+------------------------------------------------------------------+