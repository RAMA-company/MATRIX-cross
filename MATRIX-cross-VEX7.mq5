//+------------------------------------------------------------------+
//|                                  MATRIX-cross-V5.mq5             |
//|                                  (Modified for EA Buffer Export) |
//+------------------------------------------------------------------+
#property copyright "Rama Empire"
#property indicator_chart_window
#property indicator_buffers 16
#property indicator_plots   5

// --- Visual Plots ---
#property indicator_label1  "MA 1 (Current)"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrDodgerBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

#property indicator_label2  "MA 2 (Current)"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrOrangeRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2

#property indicator_label3  "Buy Dot (Current)"
#property indicator_type3   DRAW_ARROW
#property indicator_color3  clrLimeGreen
#property indicator_width3  3

#property indicator_label4  "Sell Dot (Current)"
#property indicator_type4   DRAW_ARROW
#property indicator_color4  clrDeepPink
#property indicator_width4  3

#property indicator_label5  "ZigZag (Current)"
#property indicator_type5   DRAW_SECTION
#property indicator_color5  clrGray
#property indicator_width5  1

//+------------------------------------------------------------------+
//| ENUMS                                                            |
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
//| INPUTS                                                           |
//+------------------------------------------------------------------+
input group "--- Base Settings ---"
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

input group "--- Fan Advanced Filters ---"
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

input group "--- Legacy Configs ---"
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

input group "--- Current Chart Settings ---"
input bool                 InpCurr_DrawZigZag    = true;          
input bool                 InpCurr_DrawFan       = true;          
input color                InpCurr_FanColor      = clrWhite;

// +------------------------------------------------------------------+
// | Data Buffers                                                     |
// +------------------------------------------------------------------+
double BufferMA1[];
double BufferMA2[];
double BufferBuy[];
double BufferSell[];
double BufferZigZag[];
// EA Export Buffers
double BufSigType[]; // 1=Buy, -1=Sell
double BufSigID[];   // Unique Time ID
double BufSigSL[];   
double BufSigTP1[];
double BufSigTP2[];
double BufSigTP3[];
double BufSigTP4[];
double BufSigTP5[];
double BufSigTP6[];
double BufSigTP7[];
double BufSigTP8[];

struct SwingPoint {
   datetime time;
   double   price;
   int      type;       
   int      barIdx;
   double   candleHigh; 
   double   candleLow;  
};

int current_hMA1, current_hMA2, atrHandle; 

//+------------------------------------------------------------------+
int OnInit()
{
   SetIndexBuffer(0, BufferMA1, INDICATOR_DATA);
   SetIndexBuffer(1, BufferMA2, INDICATOR_DATA);
   SetIndexBuffer(2, BufferBuy, INDICATOR_DATA);
   SetIndexBuffer(3, BufferSell, INDICATOR_DATA);
   SetIndexBuffer(4, BufferZigZag, INDICATOR_DATA);
   
   // Map Export Buffers for EA
   SetIndexBuffer(5, BufSigType, INDICATOR_DATA);
   SetIndexBuffer(6, BufSigID, INDICATOR_DATA);
   SetIndexBuffer(7, BufSigSL, INDICATOR_DATA);
   SetIndexBuffer(8, BufSigTP1, INDICATOR_DATA);
   SetIndexBuffer(9, BufSigTP2, INDICATOR_DATA);
   SetIndexBuffer(10, BufSigTP3, INDICATOR_DATA);
   SetIndexBuffer(11, BufSigTP4, INDICATOR_DATA);
   SetIndexBuffer(12, BufSigTP5, INDICATOR_DATA);
   SetIndexBuffer(13, BufSigTP6, INDICATOR_DATA);
   SetIndexBuffer(14, BufSigTP7, INDICATOR_DATA);
   SetIndexBuffer(15, BufSigTP8, INDICATOR_DATA);

   PlotIndexSetInteger(0, PLOT_SHIFT, InpBase_MA1_Shift);
   PlotIndexSetInteger(1, PLOT_SHIFT, InpBase_MA2_Shift);
   PlotIndexSetInteger(2, PLOT_ARROW, 158); 
   PlotIndexSetInteger(3, PLOT_ARROW, 158); 
   PlotIndexSetDouble(2, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetDouble(3, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetDouble(4, PLOT_EMPTY_VALUE, 0.0);

   current_hMA1 = iMA(_Symbol, _Period, InpBase_MA1_Period, 0, InpBase_MA1_Method, InpBase_MA1_Price);
   current_hMA2 = iMA(_Symbol, _Period, InpBase_MA2_Period, 0, InpBase_MA1_Method, InpBase_MA1_Price);
   atrHandle    = iATR(_Symbol, _Period, 14); 

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
int OnCalculate(const int rates_total, const int prev_calculated, const datetime &time[], const double &open[],
                const double &high[], const double &low[], const double &close[], const long &tick_volume[],
                const long &volume[], const int &spread[])
{
   int min_bars = MathMax(InpBase_MA1_Period, InpBase_MA2_Period) + InpBase_BarsBefore + InpBase_BarsAfter + 10;
   if(rates_total < min_bars) return(0);

   ArraySetAsSeries(BufferMA1, true); ArraySetAsSeries(BufferMA2, true);
   ArraySetAsSeries(BufferBuy, true); ArraySetAsSeries(BufferSell, true); ArraySetAsSeries(BufferZigZag, true);
   ArraySetAsSeries(BufSigType, true); ArraySetAsSeries(BufSigID, true); ArraySetAsSeries(BufSigSL, true);
   ArraySetAsSeries(BufSigTP1, true); ArraySetAsSeries(BufSigTP2, true); ArraySetAsSeries(BufSigTP3, true);
   ArraySetAsSeries(BufSigTP4, true); ArraySetAsSeries(BufSigTP5, true); ArraySetAsSeries(BufSigTP6, true);
   ArraySetAsSeries(BufSigTP7, true); ArraySetAsSeries(BufSigTP8, true);
   
   ArraySetAsSeries(open, true); ArraySetAsSeries(close, true);
   ArraySetAsSeries(low, true); ArraySetAsSeries(high, true); ArraySetAsSeries(time, true);

   if(CopyBuffer(current_hMA1, 0, 0, rates_total, BufferMA1) <= 0) return(0);
   if(CopyBuffer(current_hMA2, 0, 0, rates_total, BufferMA2) <= 0) return(0);

   int limit = rates_total - prev_calculated;
   if(limit > rates_total - min_bars) limit = rates_total - min_bars;
   
   // Clean buffers
   for(int k = limit; k >= 0; k--) { 
       BufferBuy[k] = 0.0; BufferSell[k] = 0.0; BufferZigZag[k] = 0.0; 
       BufSigType[k] = 0.0; BufSigID[k] = 0.0; BufSigSL[k] = 0.0;
       BufSigTP1[k] = 0.0; BufSigTP2[k] = 0.0; BufSigTP3[k] = 0.0; BufSigTP4[k] = 0.0;
       BufSigTP5[k] = 0.0; BufSigTP6[k] = 0.0; BufSigTP7[k] = 0.0; BufSigTP8[k] = 0.0;
   }

   SwingPoint currentSwings[];
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
            currentSwings[size].candleLow = low[lowestIdx]; currentSwings[size].candleHigh = high[lowestIdx];
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
            currentSwings[size].candleLow = low[highestIdx]; currentSwings[size].candleHigh = high[highestIdx];
         }
      }
   }

   DrawFanTrendlines(currentSwings, time, open, high, low, close);
   return(rates_total);
}

//+------------------------------------------------------------------+
void DrawFanTrendlines(SwingPoint &swings[], const datetime &time[], const double &open[], const double &high[], const double &low[], const double &close[])
{
   int totalSwings = ArraySize(swings);
   if(totalSwings < 2) return;
   if(totalSwings > Fan_MaxPivots) totalSwings = Fan_MaxPivots;

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
                 double tol = 0; // Simplified for EA signal focus

                 bool brokeAtK = false;
                 if(anchorType == 1 && close[k] < projectedPrice - tol) brokeAtK = true;
                 else if(anchorType == 2 && close[k] > projectedPrice + tol) brokeAtK = true;

                 if(brokeAtK) { 
                    beyondCandles++; 
                    if(beyondCandles >= Mod2_ReqCandlesBeyond) { isBroken = true; breakBar = k; break; } 
                 } 
                 else beyondCandles = 0;
             }
             if(Mod2_Enable && isBroken && breakBar >= 0) {
                 Detect123Pattern(swings, anchorType, breakBar, time, high, low);
             }
         }
      }
   }
}

//+------------------------------------------------------------------+
void Detect123Pattern(SwingPoint &swings[], int brokenLineAnchor, int breakBar, const datetime &time[], const double &high[], const double &low[])
{
   int pt1_idx = -1; int pt2_idx = -1;
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

   // --- POPULATE BUFFERS FOR EXPERT ADVISOR ---
   if(pt3_hit) {
       BufSigType[pt3_bar] = (brokenLineAnchor == 2) ? 1.0 : -1.0;  // 1=Buy, -1=Sell
       BufSigID[pt3_bar]   = (double)time[pt3_bar];                 // Unique signal ID via datetime
       BufSigSL[pt3_bar]   = swings[pt2_idx].price;                 // SL Anchor
       
       for(int tc = 1; tc <= 8; tc++) {
           double tgLvl = (brokenLineAnchor == 1) ? (pt3_level - dist * ((Mod2_TargetStep*tc)/100.0)) : (pt3_level + dist * ((Mod2_TargetStep*tc)/100.0));
           switch(tc) {
               case 1: BufSigTP1[pt3_bar] = tgLvl; break;
               case 2: BufSigTP2[pt3_bar] = tgLvl; break;
               case 3: BufSigTP3[pt3_bar] = tgLvl; break;
               case 4: BufSigTP4[pt3_bar] = tgLvl; break;
               case 5: BufSigTP5[pt3_bar] = tgLvl; break;
               case 6: BufSigTP6[pt3_bar] = tgLvl; break;
               case 7: BufSigTP7[pt3_bar] = tgLvl; break;
               case 8: BufSigTP8[pt3_bar] = tgLvl; break;
           }
       }
   }
}