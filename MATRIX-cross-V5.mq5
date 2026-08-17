//+------------------------------------------------------------------+
//|                                  MATRIX-cross-V3.mq5             |
//|                                  Copyright 2026, Rama Empire     |
//+------------------------------------------------------------------+
#property copyright "Rama Empire"
#property indicator_chart_window
#property indicator_buffers 5
#property indicator_plots   5

// --- رسم مووینگ اول چارت جاری ---
#property indicator_label1  "MA 1 (Current)"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrDodgerBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

// --- رسم مووینگ دوم چارت جاری ---
#property indicator_label2  "MA 2 (Current)"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrOrangeRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2

// --- نقطه خرید چارت جاری ---
#property indicator_label3  "Buy Dot (Current)"
#property indicator_type3   DRAW_ARROW
#property indicator_color3  clrLimeGreen
#property indicator_width3  3

// --- نقطه فروش چارت جاری ---
#property indicator_label4  "Sell Dot (Current)"
#property indicator_type4   DRAW_ARROW
#property indicator_color4  clrDeepPink
#property indicator_width4  3

// --- خط زیگ‌زاگ چارت جاری ---
#property indicator_label5  "ZigZag (Current)"
#property indicator_type5   DRAW_SECTION
#property indicator_color5  clrGray
#property indicator_width5  1

//+------------------------------------------------------------------+
//| ENUMS برای Fan Trendline (شامل امکانات جدید اضافه شده)           |
//+------------------------------------------------------------------+
enum ENUM_TOLERANCE_TYPE { TOL_ATR, TOL_POINTS, TOL_PERCENT };
enum ENUM_TREND_DIR      { TREND_AUTO, TREND_MANUAL, TREND_BOTH };
enum ENUM_SWING_SCALE    { SCALE_MICRO, SCALE_MINOR, SCALE_MEDIUM, SCALE_MAJOR, SCALE_CUSTOM };
enum ENUM_BREAK_RULE     { BREAK_CLOSE, BREAK_HIGHLOW, BREAK_BODY, BREAK_ATR, BREAK_TOLERANCE };
enum ENUM_RECONNECT_MODE { RECONN_LAST, RECONN_ORIGINAL, RECONN_AUTO };
enum ENUM_FAN_PRIORITY   { PRIO_NEWEST, PRIO_STRONGEST, PRIO_LONGEST, PRIO_MOST_TOUCHES };
enum ENUM_DYN_COLOR      { COLOR_TOUCHES, COLOR_AGE, COLOR_STRENGTH, COLOR_SLOPE, COLOR_DIR, COLOR_STATIC };
enum ENUM_DRAW_MODE      { DRAW_RAY, DRAW_SEGMENT, DRAW_INFINITE, DRAW_CUSTOM_PROJ };
enum ENUM_FAN_DISPLAY    { DISP_LAST_1, DISP_LAST_2, DISP_LAST_3, DISP_ALL };
enum ENUM_FAN_BOUNDARY   { BOUND_OFF, BOUND_START, BOUND_END, BOUND_BOTH };
enum ENUM_MERGE_MODE     { MERGE_POINTS, MERGE_ATR, MERGE_CANDLES };
enum ENUM_TREND_DIR_EXT  { DIR_TREND, DIR_COUNTER, DIR_BOTH };

//+------------------------------------------------------------------+
//| ورودی‌های تنظیمات (Input Parameters)                               |
//+------------------------------------------------------------------+
input group "--- تنظیمات پایه (برای همه تایم‌فریم‌ها ضرب می‌شود) ---"
input int                  InpBase_MA1_Period = 9;            // دوره مووینگ ۱
input int                  InpBase_MA1_Shift  = -4;           // شیفت مووینگ ۱
input ENUM_MA_METHOD       InpBase_MA1_Method = MODE_SMMA;    // روش محاسبه
input ENUM_APPLIED_PRICE   InpBase_MA1_Price  = PRICE_MEDIAN; // قیمت پایه
input int                  InpBase_MA2_Period = 9;            // دوره مووینگ ۲
input int                  InpBase_MA2_Shift  = 0;            // شیفت مووینگ ۲
input int                  InpBase_BarsBefore = 14;           // X: کندل‌های قبل
input int                  InpBase_BarsAfter  = 4;            // Y: کندل‌های بعد

input group "--- 1) TRENDLINE ANGLE FILTER ---"
input bool                 Fan_EnableAngleFilter = false;         // Enable Angle Filter
input double               Fan_MinAngle          = 5.0;           // Minimum Angle (Degrees)
input double               Fan_MaxAngle          = 85.0;          // Maximum Angle (Degrees)

input group "--- 2 & 3) DISTANCE FILTERS ---"
input double               Fan_MinPriceDist      = 10.0;          // Min Price Distance (Points)
input int                  Fan_MinCandleDist     = 5;             // Min Candle Distance (Bars)

input group "--- 4) TRENDLINE TOLERANCE ---"
input ENUM_TOLERANCE_TYPE  Fan_ToleranceType     = TOL_ATR;       // Tolerance Type
input double               Fan_Tolerance         = 0.20;          // Tolerance Value

input group "--- 5) TRENDLINE EXTENSION ---"
input ENUM_DRAW_MODE       Fan_DrawingMode       = DRAW_RAY;      // Trendline Extension Mode
input int                  Fan_ProjectionLength  = 50;            // Custom Projection Length (Candles)
input bool                 Fan_ExtendRight       = true;          // Infinite Ray Toggle (Legacy)

input group "--- 6) MAXIMUM FAN LINES ---"
input int                  Fan_MaxActiveLines    = 50;            // Maximum Active Lines on Chart
input int                  Fan_MaxFanLines       = 20;            // Maximum Fan Lines Per Trend
input int                  Fan_MaxTrends         = 5;             // Maximum Trendlines per trend

input group "--- 7) LAST TREND ONLY ---"
input ENUM_FAN_DISPLAY     Fan_DisplayMode       = DISP_ALL;      // Display Mode

input group "--- 8) TREND BOUNDARIES ---"
input ENUM_FAN_BOUNDARY    Fan_BoundaryMode      = BOUND_OFF;     // Draw Vertical Separators
input color                Fan_BoundaryColor     = clrDarkGray;   // Separator Color
input int                  Fan_BoundaryWidth     = 1;             // Separator Width
input ENUM_LINE_STYLE      Fan_BoundaryStyle     = STYLE_DOT;     // Separator Style

input group "--- 9) TREND LABELS ---"
input bool                 Fan_ShowLabels        = true;          // Display Trend Labels

input group "--- 10) TOUCH FILTER ---"
input int                  Fan_MinTouches        = 2;             // Minimum Touches (>= 2)

input group "--- 11) MERGE NEARBY PIVOTS ---"
input bool                 Fan_EnableMerge       = false;         // Enable Pivot Merging
input ENUM_MERGE_MODE      Fan_MergeMode         = MERGE_CANDLES; // Merge Based On
input double               Fan_MergeValue        = 5.0;           // Merge Tolerance Value

input group "--- 12) BREAK RULE ---"
input ENUM_BREAK_RULE      Fan_BreakRule         = BREAK_CLOSE;   // Define Broken Trendline

input group "--- 13) COUNTER TREND ---"
input ENUM_TREND_DIR_EXT   Fan_TrendDirectionExt = DIR_BOTH;      // Trend Direction Drawing

input group "--- 14 & 15) COLORS AND STYLES ---"
input color                Fan_ColorBullish      = clrLime;       // Bullish Trend Color
input color                Fan_ColorBearish      = clrRed;        // Bearish Trend Color
input color                Fan_ColorBroken       = clrDimGray;    // Broken Line Color
input color                Fan_ColorCurrentTrend = clrYellow;     // Current Trend Color
input color                Fan_ColorOldTrend     = clrGray;       // Old Trend Color
input int                  Fan_LineWidth         = 2;             // Trendline Width
input ENUM_LINE_STYLE      Fan_LineStyle         = STYLE_SOLID;   // Trendline Style

input group "--- 16) PERFORMANCE ---"
input int                  Fan_MaxHistory        = 2000;          // Maximum History Checked (Bars)
input int                  Fan_MaxPivots         = 1000;          // Maximum Swings Processed
input int                  Fan_MaxObjects        = 500;           // Maximum Total Graphic Objects

input group "--- Legacy Configs (DO NOT REMOVE) ---"
input double               Fan_MinStrength       = 1.0;           // Min Strength (ATR Multiplier)
input ENUM_TREND_DIR       Fan_TrendDirection    = TREND_AUTO;    // Legacy Trend Dir
input ENUM_SWING_SCALE     Fan_SwingScale        = SCALE_MINOR;   // Swing Scale
input int                  Fan_MaxLookback       = 1000;          // Max Lookback (Candles)
input int                  Fan_CandidateRadius   = 10;            // Candidate Search Radius
input ENUM_RECONNECT_MODE  Fan_ReconnectMode     = RECONN_AUTO;   // Reconnect Rule
input ENUM_FAN_PRIORITY    Fan_FanPriority       = PRIO_NEWEST;   // Fan Priority
input ENUM_DYN_COLOR       Fan_DynamicColoring   = COLOR_STATIC;  // Dynamic Coloring
input int                  Fan_DeleteAfter       = 200;           // Remove Invalid Lines
input bool                 Fan_AutoCleanup       = true;          // Auto Cleanup

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

// --- بافرهای داده چارت جاری ---
double BufferMA1[];
double BufferMA2[];
double BufferBuy[];
double BufferSell[];
double BufferZigZag[];

// --- ساختار مدیریت تایم‌فریم‌ها ---
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

// --- ساختار مدیریت Swing ها (اضافه شده برای پردازش Fan) ---
struct SwingPoint {
   datetime time;
   double   price;
   int      type;   // 1 = Low, 2 = High
   int      barIdx;
};

TF_Config mTFs[8];
int current_hMA1, current_hMA2;
int atrHandle; // برای محاسبه تلورانس ATR
datetime lastAlertTime;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   SetIndexBuffer(0, BufferMA1, INDICATOR_DATA);
   SetIndexBuffer(1, BufferMA2, INDICATOR_DATA);
   SetIndexBuffer(2, BufferBuy, INDICATOR_DATA);
   SetIndexBuffer(3, BufferSell, INDICATOR_DATA);
   SetIndexBuffer(4, BufferZigZag, INDICATOR_DATA);

   PlotIndexSetInteger(0, PLOT_SHIFT, InpBase_MA1_Shift);
   PlotIndexSetInteger(1, PLOT_SHIFT, InpBase_MA2_Shift);

   PlotIndexSetInteger(2, PLOT_ARROW, 158); // نقطه پر خریدار
   PlotIndexSetInteger(3, PLOT_ARROW, 158); // نقطه پر فروشنده

   PlotIndexSetDouble(2, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetDouble(3, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetDouble(4, PLOT_EMPTY_VALUE, 0.0);

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
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   int min_bars = MathMax(InpBase_MA1_Period, InpBase_MA2_Period) + InpBase_BarsBefore + InpBase_BarsAfter + 10;
   if(rates_total < min_bars) return(0);

   ArraySetAsSeries(BufferMA1, true);
   ArraySetAsSeries(BufferMA2, true);
   ArraySetAsSeries(BufferBuy, true);
   ArraySetAsSeries(BufferSell, true);
   ArraySetAsSeries(BufferZigZag, true);
   
   // Added series initializations required for the newly extended engine features
   ArraySetAsSeries(open, true);
   ArraySetAsSeries(close, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(time, true);

   if(CopyBuffer(current_hMA1, 0, 0, rates_total, BufferMA1) <= 0) return(0);
   if(CopyBuffer(current_hMA2, 0, 0, rates_total, BufferMA2) <= 0) return(0);

   int limit = rates_total - prev_calculated;
   if(limit > rates_total - min_bars) limit = rates_total - min_bars;

   for(int k = limit; k >= 0; k--)
   {
      BufferBuy[k]    = 0.0;
      BufferSell[k]   = 0.0;
      BufferZigZag[k] = 0.0;
   }

   SwingPoint currentSwings[];
   
   // =======================================================================
   // پردازش چارت جاری 
   // =======================================================================
   int rawTypes[];
   ArrayResize(rawTypes, rates_total);
   ArrayInitialize(rawTypes, 0);

   for(int i = rates_total - min_bars; i >= InpBase_BarsAfter; i--)
   {
      int shift1 = i + InpBase_MA1_Shift;
      int shift2 = i + InpBase_MA2_Shift;

      if(shift1 < 0 || shift2 < 0 || shift1 + 1 >= rates_total || shift2 + 1 >= rates_total) continue;

      double ma1_curr = BufferMA1[shift1];
      double ma1_prev = BufferMA1[shift1 + 1];
      double ma2_curr = BufferMA2[shift2];
      double ma2_prev = BufferMA2[shift2 + 1];

      if(ma1_prev <= ma2_prev && ma1_curr > ma2_curr) rawTypes[i] = 1; 
      if(ma1_prev >= ma2_prev && ma1_curr < ma2_curr) rawTypes[i] = 2; 
   }

   for(int i = rates_total - min_bars; i >= InpBase_BarsAfter; i--)
   {
      if(rawTypes[i] == 0) continue;

      int startBar = i + InpBase_BarsBefore; 
      int endBar   = i - InpBase_BarsAfter;  

      if(startBar >= rates_total) startBar = rates_total - 1;
      if(endBar < 0) endBar = 0;

      if(rawTypes[i] == 1) 
      {
         for(int j = i + 1; j <= startBar; j++) { if(rawTypes[j] == 2) { startBar = j - 1; break; } } 
         for(int j = i - 1; j >= endBar; j--)   { if(rawTypes[j] == 2) { endBar = j + 1; break; } } 

         if(startBar >= endBar)
         {
            int lowestIdx = i;
            double minLow = low[i];
            for(int j = startBar; j >= endBar; j--) { if(low[j] < minLow) { minLow = low[j]; lowestIdx = j; } } 
            
            BufferBuy[lowestIdx] = minLow;
            if(InpCurr_DrawZigZag) BufferZigZag[lowestIdx] = minLow;
            
            int size = ArraySize(currentSwings);
            ArrayResize(currentSwings, size + 1);
            currentSwings[size].time = time[lowestIdx];
            currentSwings[size].price = minLow;
            currentSwings[size].type = 1;
            currentSwings[size].barIdx = lowestIdx;
         }
      }

      if(rawTypes[i] == 2) 
      {
         for(int j = i + 1; j <= startBar; j++) { if(rawTypes[j] == 1) { startBar = j - 1; break; } } 
         for(int j = i - 1; j >= endBar; j--)   { if(rawTypes[j] == 1) { endBar = j + 1; break; } } 

         if(startBar >= endBar)
         {
            int highestIdx = i;
            double maxHigh = high[i];
            for(int j = startBar; j >= endBar; j--) { if(high[j] > maxHigh) { maxHigh = high[j]; highestIdx = j; } } 
            
            BufferSell[highestIdx] = maxHigh;
            if(InpCurr_DrawZigZag) BufferZigZag[highestIdx] = maxHigh; 
            
            int size = ArraySize(currentSwings);
            ArrayResize(currentSwings, size + 1);
            currentSwings[size].time = time[highestIdx];
            currentSwings[size].price = maxHigh;
            currentSwings[size].type = 2;
            currentSwings[size].barIdx = highestIdx;
         }
      }
   }

   // --- اجرای قانون رسم Fan برای چارت جاری ---
   if(InpCurr_DrawFan) {
      DrawFanTrendlines(currentSwings, "Current", InpCurr_FanColor, time, open, high, low, close);
   }

   // =======================================================================
   // پردازش تایم‌فریم‌های بالاتر 
   // =======================================================================
   for(int t = 0; t < 8; t++)
   {
      if(!mTFs[t].enabled) continue;

      int r = mTFs[t].ratio;
      int scaled_s1 = InpBase_MA1_Shift * r;
      int scaled_s2 = InpBase_MA2_Shift * r;
      int scaled_x  = InpBase_BarsBefore * r;
      int scaled_y  = InpBase_BarsAfter * r;
      
      double tMA1[], tMA2[];
      ArraySetAsSeries(tMA1, true); ArraySetAsSeries(tMA2, true);
      
      if(CopyBuffer(mTFs[t].hMA1, 0, 0, rates_total, tMA1) <= 0) continue;
      if(CopyBuffer(mTFs[t].hMA2, 0, 0, rates_total, tMA2) <= 0) continue;

      int tRawTypes[]; 
      ArrayResize(tRawTypes, rates_total);
      ArrayInitialize(tRawTypes, 0);

      for(int i = rates_total - (min_bars * r); i >= scaled_y; i--)
      {
         int shift1 = i + scaled_s1;
         int shift2 = i + scaled_s2;
         if(shift1 < 0 || shift2 < 0 || shift1 + 1 >= rates_total || shift2 + 1 >= rates_total) continue;

         if(tMA1[shift1 + 1] <= tMA2[shift2 + 1] && tMA1[shift1] > tMA2[shift2]) tRawTypes[i] = 1; 
         if(tMA1[shift1 + 1] >= tMA2[shift2 + 1] && tMA1[shift1] < tMA2[shift2]) tRawTypes[i] = 2; 
      }

      ObjectsDeleteAll(0, "MTF_ZIGZAG_" + mTFs[t].name + "_");
      int lastType = 0;
      datetime lastTime = 0;
      double lastPrice = 0;
      
      SwingPoint mtfSwings[]; 
      
      for(int i = rates_total - (min_bars * r); i >= scaled_y; i--)
      {
         if(tRawTypes[i] == 0) continue;
         
         int startBar = i + scaled_x;
         int endBar   = i - scaled_y;
         if(startBar >= rates_total) startBar = rates_total - 1;
         if(endBar < 0) endBar = 0;

         if(tRawTypes[i] == 1)
         {
            for(int j = i + 1; j <= startBar; j++) { if(tRawTypes[j] == 2) { startBar = j - 1; break; } }
            for(int j = i - 1; j >= endBar; j--)   { if(tRawTypes[j] == 2) { endBar = j + 1; break; } }

            if(startBar >= endBar)
            {
               int lowestIdx = i;
               double minLow = low[i];
               for(int j = startBar; j >= endBar; j--) { if(low[j] < minLow) { minLow = low[j]; lowestIdx = j; } }
               
               string dotName = "MTF_ZIGZAG_" + mTFs[t].name + "_Dot_" + IntegerToString(time[lowestIdx]);
               ObjectCreate(0, dotName, OBJ_ARROW, 0, time[lowestIdx], minLow);
               ObjectSetInteger(0, dotName, OBJPROP_ARROWCODE, 158);
               ObjectSetInteger(0, dotName, OBJPROP_COLOR, mTFs[t].dotCol);
               ObjectSetInteger(0, dotName, OBJPROP_WIDTH, 4);

               if(mTFs[t].drawZZ && lastTime != 0)
               {
                  string lineName = "MTF_ZIGZAG_" + mTFs[t].name + "_Line_" + IntegerToString(lastTime) + "_" + IntegerToString(time[lowestIdx]);
                  ObjectCreate(0, lineName, OBJ_TREND, 0, lastTime, lastPrice, time[lowestIdx], minLow);
                  ObjectSetInteger(0, lineName, OBJPROP_COLOR, mTFs[t].zzCol);
                  ObjectSetInteger(0, lineName, OBJPROP_WIDTH, mTFs[t].zzWidth);
                  ObjectSetInteger(0, lineName, OBJPROP_RAY_RIGHT, false);
               }
               lastTime = time[lowestIdx]; lastPrice = minLow; lastType = 1;
               
               int size = ArraySize(mtfSwings);
               ArrayResize(mtfSwings, size + 1);
               mtfSwings[size].time = time[lowestIdx];
               mtfSwings[size].price = minLow;
               mtfSwings[size].type = 1;
               mtfSwings[size].barIdx = lowestIdx;
            }
         }

         if(tRawTypes[i] == 2)
         {
            for(int j = i + 1; j <= startBar; j++) { if(tRawTypes[j] == 1) { startBar = j - 1; break; } }
            for(int j = i - 1; j >= endBar; j--)   { if(tRawTypes[j] == 1) { endBar = j + 1; break; } }

            if(startBar >= endBar)
            {
               int highestIdx = i;
               double maxHigh = high[i];
               for(int j = startBar; j >= endBar; j--) { if(high[j] > maxHigh) { maxHigh = high[j]; highestIdx = j; } }
               
               string dotName = "MTF_ZIGZAG_" + mTFs[t].name + "_Dot_" + IntegerToString(time[highestIdx]);
               ObjectCreate(0, dotName, OBJ_ARROW, 0, time[highestIdx], maxHigh);
               ObjectSetInteger(0, dotName, OBJPROP_ARROWCODE, 158);
               ObjectSetInteger(0, dotName, OBJPROP_COLOR, mTFs[t].dotCol);
               ObjectSetInteger(0, dotName, OBJPROP_WIDTH, 4);

               if(mTFs[t].drawZZ && lastTime != 0)
               {
                  string lineName = "MTF_ZIGZAG_" + mTFs[t].name + "_Line_" + IntegerToString(lastTime) + "_" + IntegerToString(time[highestIdx]);
                  ObjectCreate(0, lineName, OBJ_TREND, 0, lastTime, lastPrice, time[highestIdx], maxHigh);
                  ObjectSetInteger(0, lineName, OBJPROP_COLOR, mTFs[t].zzCol);
                  ObjectSetInteger(0, lineName, OBJPROP_WIDTH, mTFs[t].zzWidth);
                  ObjectSetInteger(0, lineName, OBJPROP_RAY_RIGHT, false);
               }
               lastTime = time[highestIdx]; lastPrice = maxHigh; lastType = 2;
               
               int size = ArraySize(mtfSwings);
               ArrayResize(mtfSwings, size + 1);
               mtfSwings[size].time = time[highestIdx];
               mtfSwings[size].price = maxHigh;
               mtfSwings[size].type = 2;
               mtfSwings[size].barIdx = highestIdx;
            }
         }
      }
      
      // --- اجرای قانون رسم Fan برای این تایم فریم ---
      if(mTFs[t].drawFan) {
         DrawFanTrendlines(mtfSwings, mTFs[t].name, mTFs[t].fanCol, time, open, high, low, close);
      }
   }

   // --- مدیریت سیستم هشدار ---
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

   return(rates_total);
}

//+------------------------------------------------------------------+
//| Extended Fan Trendlines Engine (Configurable 25+ Rules)          |
//+------------------------------------------------------------------+
void DrawFanTrendlines(SwingPoint &swings[], string tfName, color baseFanColor,
                       const datetime &time[], const double &open[], const double &high[], 
                       const double &low[], const double &close[])
{
   if(Fan_AutoCleanup) ObjectsDeleteAll(0, "FAN_TREND_" + tfName + "_");
   
   int totalSwings = ArraySize(swings);
   if(totalSwings < 2) return;
   
   if(totalSwings > Fan_MaxPivots) totalSwings = Fan_MaxPivots;

   // 11) Merge Nearby Pivots Filtering Phase
   SwingPoint processedSwings[];
   if(Fan_EnableMerge) {
      int pSize = 0;
      for(int i = 0; i < totalSwings; i++) {
         if(pSize == 0) {
            ArrayResize(processedSwings, pSize + 1);
            processedSwings[pSize] = swings[i];
            pSize++;
         } else {
            bool shouldMerge = false;
            double lastP = processedSwings[pSize-1].price;
            int lastB = processedSwings[pSize-1].barIdx;

            if(Fan_MergeMode == MERGE_CANDLES && MathAbs(swings[i].barIdx - lastB) <= Fan_MergeValue) shouldMerge = true;
            else if(Fan_MergeMode == MERGE_POINTS && MathAbs(swings[i].price - lastP)/_Point <= Fan_MergeValue) shouldMerge = true;
            else if(Fan_MergeMode == MERGE_ATR) {
               double aVal[];
               if(CopyBuffer(atrHandle, 0, swings[i].barIdx, 1, aVal) > 0) {
                  if(MathAbs(swings[i].price - lastP) <= Fan_MergeValue * aVal[0]) shouldMerge = true;
               }
            }

            if(!shouldMerge) {
               ArrayResize(processedSwings, pSize + 1);
               processedSwings[pSize] = swings[i];
               pSize++;
            }
         }
      }
   } else {
      ArrayCopy(processedSwings, swings);
   }

   totalSwings = ArraySize(processedSwings);
   if(totalSwings < 2) return;

   int drawnLinesCount = 0;
   int activeTrends = 0;
   int currentAnchorIdx = -1;

   // Start processing from Newest to Oldest Anchor to enforce "Display Mode (Last N Trends)" (Rule 7)
   for(int i = totalSwings - 2; i >= 0; i--) 
   {
      if(drawnLinesCount >= Fan_MaxObjects) break;
      if(processedSwings[i].barIdx > Fan_MaxHistory) continue;

      int anchorType = processedSwings[i].type;

      // Grouping and Display Mode Filter
      if(currentAnchorIdx != i) {
         activeTrends++;
         currentAnchorIdx = i;
         if(Fan_DisplayMode == DISP_LAST_1 && activeTrends > 1) break;
         if(Fan_DisplayMode == DISP_LAST_2 && activeTrends > 2) break;
         if(Fan_DisplayMode == DISP_LAST_3 && activeTrends > 3) break;
      }

      int fanIndex = 1;
      int maxSearch = MathMin(i + 1 + Fan_CandidateRadius, totalSwings);
      datetime latestPivotTime = 0;

      for(int j = i + 1; j < maxSearch; j++) 
      {
         if(drawnLinesCount >= Fan_MaxObjects || fanIndex > Fan_MaxFanLines) break;
         
         if(processedSwings[j].type == anchorType) 
         {
             // 3) Minimum Candle Distance
             if(MathAbs(processedSwings[i].barIdx - processedSwings[j].barIdx) < Fan_MinCandleDist) continue;
             
             // 2) Minimum Price Distance
             if(MathAbs(processedSwings[j].price - processedSwings[i].price) / _Point < Fan_MinPriceDist) continue;

             // 13) Counter Trend Filter
             bool isCounterTrend = (anchorType == 1 && processedSwings[j].price < processedSwings[i].price) || 
                                   (anchorType == 2 && processedSwings[j].price > processedSwings[i].price);
             if(Fan_TrendDirectionExt == DIR_TREND && isCounterTrend) continue;
             if(Fan_TrendDirectionExt == DIR_COUNTER && !isCounterTrend) continue;

             // Prepare Line Equation Base
             double dPrice = processedSwings[j].price - processedSwings[i].price;
             double dBars = processedSwings[i].barIdx - processedSwings[j].barIdx; 
             double slope = dPrice / dBars;

             // 1) Trendline Angle Filter
             if(Fan_EnableAngleFilter) {
                 double angDeg = MathArctan(MathAbs(dPrice / _Point) / dBars) * 180.0 / M_PI;
                 if(angDeg < Fan_MinAngle || angDeg > Fan_MaxAngle) continue;
             }

             // 10 & 12) Touch Rules & Break Logic Loop Over Target History
             int touches = 0;
             bool isBroken = false;
             int breakBar = -1;

             for(int k = processedSwings[j].barIdx - 1; k >= 0; k--) {
                 if(processedSwings[j].barIdx - k > Fan_MaxHistory) break;
                 
                 double projectedPrice = processedSwings[j].price + slope * (processedSwings[j].barIdx - k);
                 
                 // Dynamic Tolerance Value
                 double tol = Fan_Tolerance;
                 if(Fan_ToleranceType == TOL_POINTS) tol = Fan_Tolerance * _Point;
                 else if(Fan_ToleranceType == TOL_PERCENT) tol = projectedPrice * (Fan_Tolerance / 100.0);
                 else if(Fan_ToleranceType == TOL_ATR) {
                     double aVal[];
                     if(CopyBuffer(atrHandle, 0, k, 1, aVal) > 0) tol = Fan_Tolerance * aVal[0]; else tol = 0;
                 }

                 // Touch verification
                 if(low[k] - tol <= projectedPrice && high[k] + tol >= projectedPrice) touches++;

                 // Break detection
                 bool brokeAtK = false;
                 if(anchorType == 1) { // Support Line
                     if(Fan_BreakRule == BREAK_CLOSE && close[k] < projectedPrice - tol) brokeAtK = true;
                     else if(Fan_BreakRule == BREAK_BODY && MathMin(open[k], close[k]) < projectedPrice - tol) brokeAtK = true;
                     else if(Fan_BreakRule == BREAK_HIGHLOW && low[k] < projectedPrice - tol) brokeAtK = true;
                 } else { // Resistance Line
                     if(Fan_BreakRule == BREAK_CLOSE && close[k] > projectedPrice + tol) brokeAtK = true;
                     else if(Fan_BreakRule == BREAK_BODY && MathMax(open[k], close[k]) > projectedPrice + tol) brokeAtK = true;
                     else if(Fan_BreakRule == BREAK_HIGHLOW && high[k] > projectedPrice + tol) brokeAtK = true;
                 }

                 if(brokeAtK) {
                     isBroken = true;
                     breakBar = k;
                     break;
                 }
             }

             // Evaluate Required Touches (Initial Anchor + Base Pivot = 2)
             if(touches < (Fan_MinTouches - 2)) continue;

             // 5) Extension & Break Coordination Configuration
             datetime t1 = processedSwings[i].time;
             double p1 = processedSwings[i].price;
             datetime t2 = processedSwings[j].time;
             double p2 = processedSwings[j].price;
             bool setRay = false;

             if(Fan_DrawingMode == DRAW_INFINITE || (Fan_DrawingMode == DRAW_RAY && !isBroken && Fan_ExtendRight)) {
                 setRay = true;
             } 
             else if(Fan_DrawingMode == DRAW_RAY && isBroken) {
                 t2 = time[breakBar];
                 p2 = processedSwings[j].price + slope * (processedSwings[j].barIdx - breakBar);
             }
             else if(Fan_DrawingMode == DRAW_CUSTOM_PROJ) {
                 int endingBar = MathMax(0, processedSwings[j].barIdx - Fan_ProjectionLength);
                 if(isBroken && endingBar < breakBar) endingBar = breakBar;
                 t2 = time[endingBar];
                 p2 = processedSwings[j].price + slope * (processedSwings[j].barIdx - endingBar);
             }

             // Track Farthest Boundary Point
             if(t2 > latestPivotTime) latestPivotTime = t2;

             // 14) Conditional Coloring Strategy
             color lineColor = baseFanColor;
             if(isBroken) lineColor = Fan_ColorBroken;
             else {
                 if(Fan_DynamicColoring == COLOR_STATIC) {
                     lineColor = (activeTrends == 1) ? Fan_ColorCurrentTrend : Fan_ColorOldTrend;
                     if(lineColor == clrBlack) lineColor = (anchorType == 1) ? Fan_ColorBullish : Fan_ColorBearish;
                 } else {
                     lineColor = (anchorType == 1) ? Fan_ColorBullish : Fan_ColorBearish;
                 }
             }

             // Object Deployment
             string objName = "FAN_TREND_" + tfName + "_" + IntegerToString(t1) + "_Fan" + IntegerToString(fanIndex);
             ObjectCreate(0, objName, OBJ_TREND, 0, t1, p1, t2, p2);
             ObjectSetInteger(0, objName, OBJPROP_COLOR, lineColor); 
             ObjectSetInteger(0, objName, OBJPROP_RAY_RIGHT, setRay);
             
             // 15) Line Styles configuration
             ObjectSetInteger(0, objName, OBJPROP_WIDTH, Fan_LineWidth);
             ObjectSetInteger(0, objName, OBJPROP_STYLE, Fan_LineStyle);
             
             // 9) Data Labels Injection
             if(Fan_ShowLabels) {
                 string textObj = objName + "_lbl";
                 ObjectCreate(0, textObj, OBJ_TEXT, 0, t2, p2);
                 ObjectSetString(0, textObj, OBJPROP_TEXT, "Trend " + IntegerToString(activeTrends) + " (F" + IntegerToString(fanIndex) + ")");
                 ObjectSetInteger(0, textObj, OBJPROP_COLOR, lineColor);
                 ObjectSetInteger(0, textObj, OBJPROP_FONTSIZE, 9);
             }

             fanIndex++;
             drawnLinesCount++;
         }
      }
      
      // 8) Trend Boundaries Application
      if(fanIndex > 1 && Fan_BoundaryMode != BOUND_OFF) {
          if(Fan_BoundaryMode == BOUND_START || Fan_BoundaryMode == BOUND_BOTH) {
              string v1 = "FAN_TREND_" + tfName + "_BND_START_" + IntegerToString(processedSwings[i].time);
              ObjectCreate(0, v1, OBJ_VLINE, 0, processedSwings[i].time, 0);
              ObjectSetInteger(0, v1, OBJPROP_COLOR, Fan_BoundaryColor);
              ObjectSetInteger(0, v1, OBJPROP_WIDTH, Fan_BoundaryWidth);
              ObjectSetInteger(0, v1, OBJPROP_STYLE, Fan_BoundaryStyle);
          }
          if((Fan_BoundaryMode == BOUND_END || Fan_BoundaryMode == BOUND_BOTH) && latestPivotTime > 0) {
              string v2 = "FAN_TREND_" + tfName + "_BND_END_" + IntegerToString(latestPivotTime);
              ObjectCreate(0, v2, OBJ_VLINE, 0, latestPivotTime, 0);
              ObjectSetInteger(0, v2, OBJPROP_COLOR, Fan_BoundaryColor);
              ObjectSetInteger(0, v2, OBJPROP_WIDTH, Fan_BoundaryWidth);
              ObjectSetInteger(0, v2, OBJPROP_STYLE, Fan_BoundaryStyle);
          }
      }
   }
}

//+------------------------------------------------------------------+
//| تابع ارسال انواع هشدار                                           |
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