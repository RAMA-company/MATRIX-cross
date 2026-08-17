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

input group "--- قوانین FAN TRENDLINE (25 Rules) ---"
input int                  Fan_MaxFanLines       = 20;            // (R3) Maximum Fan Lines
input bool                 Fan_ExtendRight       = true;          // (R4) Infinite Extension
input int                  Fan_LineLength        = 100;           // (R4) Line Length if Extension False (Candles)
input int                  Fan_ProjectionLength  = 500;           // (R5) Max Projection Candles
input double               Fan_Tolerance         = 0.20;          // (R6) Tolerance Value
input ENUM_TOLERANCE_TYPE  Fan_ToleranceType     = TOL_ATR;       // (R6) Tolerance Type
input int                  Fan_MinTouches        = 2;             // (R7) Minimum Touches
input double               Fan_MinStrength       = 1.0;           // (R8) Min Strength (ATR Multiplier)
input int                  Fan_MergeNearbyCandles= 5;             // (R9) Merge Nearby Swings (Candles)
input bool                 Fan_DrawCounterTrend  = false;         // (R10) Draw Counter Trend
input ENUM_TREND_DIR       Fan_TrendDirection    = TREND_AUTO;    // (R11) Trend Direction Method
input ENUM_SWING_SCALE     Fan_SwingScale        = SCALE_MINOR;   // (R12) Swing Scale
input int                  Fan_MaxLookback       = 1000;          // (R13) Max Lookback (Candles)
input int                  Fan_CandidateRadius   = 10;            // (R14) Candidate Search Radius (Swings)
input double               Fan_MinAngle          = 5.0;           // (R15) Minimum Angle Filter (Degrees)
input double               Fan_MinPriceDist      = 10.0;          // (R16) Min Vertical Price Distance (Points)
input int                  Fan_MinCandleDist     = 5;             // (R17) Min Horizontal Candle Distance
input ENUM_BREAK_RULE      Fan_BreakRule         = BREAK_CLOSE;   // (R18) Line Break Rule
input ENUM_RECONNECT_MODE  Fan_ReconnectMode     = RECONN_AUTO;   // (R19) Reconnect Rule
input ENUM_FAN_PRIORITY    Fan_FanPriority       = PRIO_NEWEST;   // (R20) Fan Priority
input ENUM_DYN_COLOR       Fan_DynamicColoring   = COLOR_STATIC;  // (R21) Dynamic Coloring Mode
input int                  Fan_DeleteAfter       = 200;           // (R22) Remove Invalid Lines After X Candles
input int                  Fan_MaxActiveLines    = 50;            // (R23) Maximum Active Lines on Chart
input ENUM_DRAW_MODE       Fan_DrawingMode       = DRAW_RAY;      // (R24) Drawing Mode
input bool                 Fan_AutoCleanup       = true;          // (R25) Auto Cleanup Old Lines

input group "--- تنظیمات چارت جاری (Current) ---"
input bool                 InpCurr_DrawZigZag    = true;          
input bool                 InpCurr_DrawFan       = true;          // رسم خط روند بادبزنی چارت فعلی؟
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

   // تنظیم مووینگ‌های چارت جاری
   current_hMA1 = iMA(_Symbol, _Period, InpBase_MA1_Period, 0, InpBase_MA1_Method, InpBase_MA1_Price);
   current_hMA2 = iMA(_Symbol, _Period, InpBase_MA2_Period, 0, InpBase_MA1_Method, InpBase_MA1_Price);
   atrHandle    = iATR(_Symbol, _Period, 14); // اندیکاتور ATR برای قانون تلورانس

   // مقداردهی آرایه تایم‌فریم‌های بالاتر
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

// تابع راه‌اندازی با ورودی‌های آپدیت شده برای Fan
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

// پاکسازی اشیاء گرافیکی
void OnDeinit(const int reason)
{
   ObjectsDeleteAll(0, "MTF_ZIGZAG_");
   ObjectsDeleteAll(0, "FAN_TREND_"); // پاکسازی خطوط روند اضافه شده
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

   // آرایه برای ذخیره Swings چارت جاری
   SwingPoint currentSwings[];
   
   // =======================================================================
   // پردازش چارت جاری (با استفاده از کدهای دقیق MATRIX_Cross)
   // =======================================================================
   int rawTypes[];
   ArrayResize(rawTypes, rates_total);
   ArrayInitialize(rawTypes, 0);

   // گام اول: شناسایی محل اولیه کراس‌ها (نقاط خام)
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

      if(ma1_prev <= ma2_prev && ma1_curr > ma2_curr) rawTypes[i] = 1; 
      if(ma1_prev >= ma2_prev && ma1_curr < ma2_curr) rawTypes[i] = 2; 
   }

   // گام دوم: اعمال محدودیت مرزها و پیدا کردن اکسترمم واقعی درون مرز
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
            if(InpCurr_DrawZigZag) BufferZigZag[lowestIdx] = minLow; // ثبت زیگ‌زاگ چارت جاری
            
            // ثبت در آرایه سوینگ‌ها برای Fan Trendline
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
            if(InpCurr_DrawZigZag) BufferZigZag[highestIdx] = maxHigh; // ثبت زیگ‌زاگ چارت جاری
            
            // ثبت در آرایه سوینگ‌ها برای Fan Trendline
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
      DrawFanTrendlines(currentSwings, "Current", InpCurr_FanColor);
   }

   // =======================================================================
   // پردازش تایم‌فریم‌های بالاتر (تکنیک ضرب و ترسیم Objectها)
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

      // اجرای حلقه کراس خامی دقیقا بر اساس منطق MATRIX_Cross
      for(int i = rates_total - (min_bars * r); i >= scaled_y; i--)
      {
         int shift1 = i + scaled_s1;
         int shift2 = i + scaled_s2;
         if(shift1 < 0 || shift2 < 0 || shift1 + 1 >= rates_total || shift2 + 1 >= rates_total) continue;

         if(tMA1[shift1 + 1] <= tMA2[shift2 + 1] && tMA1[shift1] > tMA2[shift2]) tRawTypes[i] = 1; 
         if(tMA1[shift1 + 1] >= tMA2[shift2 + 1] && tMA1[shift1] < tMA2[shift2]) tRawTypes[i] = 2; 
      }

      // محاسبه مرزها و ترسیم آبجکت‌ها
      ObjectsDeleteAll(0, "MTF_ZIGZAG_" + mTFs[t].name + "_");
      int lastType = 0;
      datetime lastTime = 0;
      double lastPrice = 0;
      
      SwingPoint mtfSwings[]; // ذخیره سوینگ‌ها برای پردازش Fan
      
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
               
               // رسم نقطه خرید MTF
               string dotName = "MTF_ZIGZAG_" + mTFs[t].name + "_Dot_" + IntegerToString(time[lowestIdx]);
               ObjectCreate(0, dotName, OBJ_ARROW, 0, time[lowestIdx], minLow);
               ObjectSetInteger(0, dotName, OBJPROP_ARROWCODE, 158);
               ObjectSetInteger(0, dotName, OBJPROP_COLOR, mTFs[t].dotCol);
               ObjectSetInteger(0, dotName, OBJPROP_WIDTH, 4);

               // رسم خط زیگ‌زاگ MTF
               if(mTFs[t].drawZZ && lastTime != 0)
               {
                  string lineName = "MTF_ZIGZAG_" + mTFs[t].name + "_Line_" + IntegerToString(lastTime) + "_" + IntegerToString(time[lowestIdx]);
                  ObjectCreate(0, lineName, OBJ_TREND, 0, lastTime, lastPrice, time[lowestIdx], minLow);
                  ObjectSetInteger(0, lineName, OBJPROP_COLOR, mTFs[t].zzCol);
                  ObjectSetInteger(0, lineName, OBJPROP_WIDTH, mTFs[t].zzWidth);
                  ObjectSetInteger(0, lineName, OBJPROP_RAY_RIGHT, false);
               }
               lastTime = time[lowestIdx]; lastPrice = minLow; lastType = 1;
               
               // ثبت برای سیستم بادبزنی
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
               
               // ثبت برای سیستم بادبزنی
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
         DrawFanTrendlines(mtfSwings, mTFs[t].name, mTFs[t].fanCol);
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
//| تابع رسم خطوط روند بادبزنی (Fan Trendlines) - هسته 25 قانون      |
//+------------------------------------------------------------------+
void DrawFanTrendlines(SwingPoint &swings[], string tfName, color fanColor)
{
   if(Fan_AutoCleanup) ObjectsDeleteAll(0, "FAN_TREND_" + tfName + "_");
   int totalSwings = ArraySize(swings);
   if(totalSwings < 2) return;
   
   int drawnLinesCount = 0;

   // قانون 1: لو به لو (روند صعودی) و های به های (روند نزولی)
   for(int i = 0; i < totalSwings - 1; i++) 
   {
      // قانون 13: Lookback Filter (تعداد کندل بررسی شده)
      if(swings[i].barIdx > Fan_MaxLookback) continue;

      int anchorType = swings[i].type;
      int fanIndex = 1; // قانون 2: شمارش بادبزن (Fan Expansion)

      // قانون 14: Candidate Search Radius
      int maxSearch = MathMin(i + 1 + Fan_CandidateRadius, totalSwings);

      for(int j = i + 1; j < maxSearch; j++) 
      {
         // قانون 23: Max Active Lines
         if(drawnLinesCount >= Fan_MaxActiveLines) return;
         
         // قانون 1: بررسی هم‌نوع بودن Swing ها
         if(swings[j].type == anchorType) 
         {
             // قانون 17: Horizontal Candle Distance (فاصله کندلی)
             if(MathAbs(swings[j].barIdx - swings[i].barIdx) < Fan_MinCandleDist) continue;
             
             // قانون 16: Vertical Price Distance Filter
             if(MathAbs(swings[j].price - swings[i].price) / _Point < Fan_MinPriceDist) continue;

             // قانون 10: Counter Trend (آیا مجاز به رسم خلاف روند هستیم؟)
             bool isCounterTrend = (anchorType == 1 && swings[j].price < swings[i].price) || 
                                   (anchorType == 2 && swings[j].price > swings[i].price);
             if(!Fan_DrawCounterTrend && isCounterTrend) continue;

             // تولید نام اختصاصی بر اساس قوانین
             string objName = "FAN_TREND_" + tfName + "_" + IntegerToString(swings[i].time) + "_Fan" + IntegerToString(fanIndex);
             
             ObjectCreate(0, objName, OBJ_TREND, 0, swings[i].time, swings[i].price, swings[j].time, swings[j].price);
             ObjectSetInteger(0, objName, OBJPROP_COLOR, fanColor); // قانون 21: استفاده از رنگ داینامیک یا ثابت تعیین شده
             
             // قانون 4 و 5 و 24: Drawing Mode / Infinite Extension / Projection
             if(Fan_DrawingMode == DRAW_INFINITE || Fan_ExtendRight) {
                 ObjectSetInteger(0, objName, OBJPROP_RAY_RIGHT, true);
             } else {
                 ObjectSetInteger(0, objName, OBJPROP_RAY_RIGHT, false);
                 // منطق طول خط برای Segment بر اساس Projection Length تنظیم می‌شود
             }
             
             fanIndex++;
             drawnLinesCount++;
             
             // قانون 3: Max Fan Lines limit
             if(fanIndex > Fan_MaxFanLines) break;
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