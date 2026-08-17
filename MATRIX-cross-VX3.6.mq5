//+------------------------------------------------------------------+
//|                                      MATRIX-cross-V4-TRUE-MTF.mq5|
//|                                     Refactored structural engine |
//+------------------------------------------------------------------+
#property copyright   "Refactored MATRIX Engine"
#property version     "4.00"
#property description "True MTF swing engine with structural trend and anchored regression validation."
#property description "Preserves original MATRIX MA-cross swing philosophy."
#property indicator_chart_window

#property indicator_buffers 4
#property indicator_plots   4

#property indicator_label1  "Minor Buy"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrLimeGreen
#property indicator_width1  2

#property indicator_label2  "Minor Sell"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrDeepPink
#property indicator_width2  2

#property indicator_label3  "Major Buy"
#property indicator_type3   DRAW_ARROW
#property indicator_color3  clrAqua
#property indicator_width3  3

#property indicator_label4  "Major Sell"
#property indicator_type4   DRAW_ARROW
#property indicator_color4  clrOrangeRed
#property indicator_width4  3

//+------------------------------------------------------------------+
//| Enums                                                            |
//+------------------------------------------------------------------+
enum ENUM_TREND_STATE
{
   TREND_UNKNOWN = 0,
   TREND_SIDEWAYS,
   TREND_TRANSITION,
   TREND_WEAK_BULL,
   TREND_WEAK_BEAR,
   TREND_BULLISH,
   TREND_BEARISH,
   TREND_STRONG_BULL,
   TREND_STRONG_BEAR,
   TREND_REVERSAL_CANDIDATE
};

//+------------------------------------------------------------------+
//| Input groups                                                     |
//+------------------------------------------------------------------+
input group "=== Analysis Timeframe ==="
input ENUM_TIMEFRAMES InpAnalysisTF              = PERIOD_CURRENT; // Primary Analysis Timeframe
input int             InpMaxTargetBars           = 5000;           // Maximum Target TF Bars To Load
input int             InpCalcIntervalSeconds     = 1;              // Minimum Calculation Interval Seconds
input bool            InpStrictNoRepaint         = true;           // Use Only Closed Target Bars

input group "=== Preserved Swing Engine ==="
input int             InpMA1Period               = 5;              // MA 1 Period
input int             InpMA1Shift                = -4;             // MA 1 Manual Shift
input ENUM_MA_METHOD  InpMAMethod                = MODE_SMMA;      // MA Method
input ENUM_APPLIED_PRICE InpMAPrice              = PRICE_MEDIAN;   // MA Applied Price
input int             InpMA2Period               = 5;              // MA 2 Period
input int             InpMA2Shift                = 0;              // MA 2 Manual Shift
input int             InpBarsBefore              = 14;             // X: Confirmation Bars Before
input int             InpBarsAfter               = 4;              // Y: Confirmation Bars After

input group "=== Major Swing Engine ==="
input bool            InpUseMajorSwings          = true;           // Detect Major Swings
input int             InpMajorBarsBefore         = 28;             // Major X: Bars Before
input int             InpMajorBarsAfter          = 8;              // Major Y: Bars After

input group "=== Structural Trend Engine ==="
input bool            InpEnableTrend             = true;           // Enable Structural Trend Engine
input int             InpTrendSwingLookback      = 6;              // Number Of Swings Per Side To Evaluate
input double          InpStructMinDistancePoints = 20.0;           // Minimum Structural Distance In Points
input int             InpWeakScore               = 2;              // Weak Trend Minimum Score
input int             InpStrongScore             = 4;              // Strong Trend Minimum Score
input int             InpReversalScore           = 2;              // Reversal Candidate Minimum Score

input group "=== Regression Validation Engine ==="
input bool            InpEnableRegression        = true;           // Enable Regression Validation
input int             InpRegressionMinBars       = 10;             // Minimum Regression Bars
input int             InpRegressionMaxBars       = 2000;           // Maximum Regression Bars
input ENUM_APPLIED_PRICE InpRegressionPrice      = PRICE_CLOSE;    // Regression Price
input double          InpRegressionStdDevMult    = 2.0;            // Regression Channel StdDev Multiplier
input double          InpMinSlopePointsPerBar    = 0.1;            // Minimum Absolute Slope Points/Bar
input bool            InpRegressionUpdateOnPivot = true;           // Update Only After New Confirmed Pivot
input bool            InpRegressionProject       = true;           // Project Regression To Current Bar

input group "=== Display ==="
input bool            InpDrawMinorSwings         = true;           // Draw Minor Swing Arrows
input bool            InpDrawMajorSwings         = true;           // Draw Major Swing Arrows
input bool            InpDrawZigZag              = true;           // Draw Structural ZigZag
input bool            InpDrawRegression          = true;           // Draw Regression Line/Channel
input bool            InpDrawTrendLabel          = true;           // Draw Trend Label
input color           InpMinorBuyColor           = clrLimeGreen;   // Minor Buy Color
input color           InpMinorSellColor          = clrDeepPink;    // Minor Sell Color
input color           InpMajorBuyColor           = clrAqua;        // Major Buy Color
input color           InpMajorSellColor          = clrOrangeRed;   // Major Sell Color
input color           InpZigZagColor             = clrGray;        // ZigZag Color
input int             InpZigZagWidth             = 2;              // ZigZag Width
input color           InpRegressionColor         = clrGold;        // Regression Line Color
input color           InpRegressionChannelColor  = clrDimGray;     // Regression Channel Color
input int             InpRegressionWidth         = 2;              // Regression Width
input int             InpLabelX                  = 12;             // Trend Label X
input int             InpLabelY                  = 25;             // Trend Label Y
input color           InpLabelColor              = clrWhite;       // Trend Label Color
input int             InpLabelFontSize           = 9;              // Trend Label Font Size
input string          InpLabelFont               = "Arial";        // Trend Label Font

//+------------------------------------------------------------------+
//| Structures                                                       |
//+------------------------------------------------------------------+
struct SwingPoint
{
   datetime time;
   double   price;
   int      type;      // 1 = Low/Buy, 2 = High/Sell
   int      tfBar;     // bar index on analysis timeframe
   bool     major;
};

struct TrendState
{
   int      structureDir;       // +1 bullish structure, -1 bearish structure, 0 neutral
   int      bullScore;
   int      bearScore;
   int      lastHighRelation;   // +1 HH, -1 LH, 0 equal
   int      lastLowRelation;    // +1 HL, -1 LL, 0 equal
   ENUM_TREND_STATE state;
   int      previousFinalDir;
};

struct RegressionState
{
   bool     valid;
   int      structDir;
   datetime anchorTime;
   datetime expansionTime;
   double   anchorPrice;
   double   expansionPrice;
   double   slope;              // price units per target TF bar
   double   intercept;
   double   stdDev;
   double   slopePointsPerBar;
   int      slopeDir;           // +1, -1, 0
   datetime lastPivotTime;
};

//+------------------------------------------------------------------+
//| Buffers                                                          |
//+------------------------------------------------------------------+
double BufferMinorBuy[];
double BufferMinorSell[];
double BufferMajorBuy[];
double BufferMajorSell[];

//+------------------------------------------------------------------+
//| Globals                                                          |
//+------------------------------------------------------------------+
ENUM_TIMEFRAMES g_tf = PERIOD_CURRENT;

int g_hMA1 = INVALID_HANDLE;
int g_hMA2 = INVALID_HANDLE;

SwingPoint g_minorSwings[];
SwingPoint g_majorSwings[];

TrendState     g_trend;
RegressionState g_regression;

datetime g_lastTargetBarTime = 0;
ulong    g_lastCalcMs        = 0;

string g_prefix = "MATRIX_V4_";

//+------------------------------------------------------------------+
//| Initialization                                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   g_tf = (InpAnalysisTF == PERIOD_CURRENT) ? _Period : InpAnalysisTF;

   SetIndexBuffer(0, BufferMinorBuy,  INDICATOR_DATA);
   SetIndexBuffer(1, BufferMinorSell, INDICATOR_DATA);
   SetIndexBuffer(2, BufferMajorBuy,  INDICATOR_DATA);
   SetIndexBuffer(3, BufferMajorSell, INDICATOR_DATA);

   PlotIndexSetInteger(0, PLOT_ARROW, 158);
   PlotIndexSetInteger(1, PLOT_ARROW, 158);
   PlotIndexSetInteger(2, PLOT_ARROW, 158);
   PlotIndexSetInteger(3, PLOT_ARROW, 158);

   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetDouble(2, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetDouble(3, PLOT_EMPTY_VALUE, 0.0);

   ArraySetAsSeries(BufferMinorBuy,  true);
   ArraySetAsSeries(BufferMinorSell, true);
   ArraySetAsSeries(BufferMajorBuy,  true);
   ArraySetAsSeries(BufferMajorSell, true);

   g_hMA1 = iMA(_Symbol, g_tf, InpMA1Period, 0, InpMAMethod, InpMAPrice);
   g_hMA2 = iMA(_Symbol, g_tf, InpMA2Period, 0, InpMAMethod, InpMAPrice);

   if(g_hMA1 == INVALID_HANDLE || g_hMA2 == INVALID_HANDLE)
   {
      Print("MATRIX V4: cannot create MA handles for ", EnumToString(g_tf));
      return(INIT_FAILED);
   }

   ZeroMemory(g_trend);
   ZeroMemory(g_regression);

   g_prefix = "MATRIX_V4_" + _Symbol + "_" + EnumToString(g_tf) + "_";

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Deinitialization                                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(g_hMA1 != INVALID_HANDLE)
      IndicatorRelease(g_hMA1);

   if(g_hMA2 != INVALID_HANDLE)
      IndicatorRelease(g_hMA2);

   ObjectsDeleteAll(0, g_prefix);
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Main calculation                                                 |
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
   if(rates_total < 10)
      return(0);

   datetime targetBarTime = iTime(_Symbol, g_tf, 0);
   if(targetBarTime == 0)
      return(prev_calculated);

   bool newTargetBar = (targetBarTime != g_lastTargetBarTime);
   bool elapsed = false;

   ulong nowMs = GetTickCount64();

   if(g_lastCalcMs == 0)
      elapsed = true;
   else
      elapsed = (nowMs - g_lastCalcMs >= (ulong)MathMax(1, InpCalcIntervalSeconds) * 1000);

   if(prev_calculated > 0 && !newTargetBar && !elapsed)
      return(prev_calculated);

   int minMinorBars = Engine_MinRequiredBars(InpBarsBefore, InpBarsAfter);
   int minMajorBars = Engine_MinRequiredBars(InpMajorBarsBefore, InpMajorBarsAfter);
   int minBars = MathMax(minMinorBars, minMajorBars);

   MqlRates rates[];
   ArraySetAsSeries(rates, true);

   int targetBars = CopyRates(_Symbol, g_tf, 0, InpMaxTargetBars, rates);
   if(targetBars < minBars)
      return(prev_calculated);

   double ma1[], ma2[];
   ArraySetAsSeries(ma1, true);
   ArraySetAsSeries(ma2, true);

   if(CopyBuffer(g_hMA1, 0, 0, targetBars, ma1) < targetBars)
      return(prev_calculated);

   if(CopyBuffer(g_hMA2, 0, 0, targetBars, ma2) < targetBars)
      return(prev_calculated);

   if(prev_calculated == 0 || newTargetBar)
   {
      ArrayInitialize(BufferMinorBuy,  0.0);
      ArrayInitialize(BufferMinorSell, 0.0);
      ArrayInitialize(BufferMajorBuy,  0.0);
      ArrayInitialize(BufferMajorSell, 0.0);
   }

   ArrayResize(g_minorSwings, 0);
   ArrayResize(g_majorSwings, 0);

   // Minor swings: original MATRIX confirmation engine
   SwingEngine_Detect(rates, ma1, ma2,
                      InpBarsBefore, InpBarsAfter,
                      false,
                      g_minorSwings);

   // Major swings: same philosophy, larger confirmation window
   if(InpUseMajorSwings)
   {
      SwingEngine_Detect(rates, ma1, ma2,
                         InpMajorBarsBefore, InpMajorBarsAfter,
                         true,
                         g_majorSwings);
   }
   else
   {
      SwingEngine_Copy(g_minorSwings, g_majorSwings);
   }

   // Map target timeframe swings to current chart buffers when possible.
   // For lower timeframe analysis, objects are more reliable than buffers.
   if(PeriodSeconds(g_tf) >= PeriodSeconds(_Period))
   {
      SwingEngine_MapToBuffers(g_minorSwings, BufferMinorBuy, BufferMinorSell, rates_total);
      SwingEngine_MapToBuffers(g_majorSwings, BufferMajorBuy, BufferMajorSell, rates_total);
   }

   // Structural trend classification
   if(InpEnableTrend)
      TrendEngine_Evaluate(g_majorSwings, g_trend);
   else
      ZeroMemory(g_trend);

   // Anchored regression validation
   if(InpEnableRegression)
      RegressionEngine_Update(g_majorSwings, rates, targetBars, g_trend);
   else
      ZeroMemory(g_regression);

   int finalDir = FusionEngine_FinalDirection(g_trend, g_regression);

   if(prev_calculated == 0 || newTargetBar)
   {
      ObjectsDeleteAll(0, g_prefix);

      if(InpDrawMinorSwings)
         Draw_SwingArrows(g_minorSwings, false);

      if(InpDrawMajorSwings)
         Draw_SwingArrows(g_majorSwings, true);

      if(InpDrawZigZag)
         Draw_StructuralZigZag(g_majorSwings);

      if(InpDrawRegression)
         Draw_Regression(g_regression, finalDir);

      if(InpDrawTrendLabel)
         Draw_TrendLabel(finalDir, g_trend, g_regression);

      ChartRedraw();
   }

   g_lastCalcMs = nowMs;
   g_lastTargetBarTime = targetBarTime;

   return(rates_total);
}

//+------------------------------------------------------------------+
//| Minimum bars required for swing engine                           |
//+------------------------------------------------------------------+
int Engine_MinRequiredBars(int barsBefore, int barsAfter)
{
   int maxPeriod = MathMax(InpMA1Period, InpMA2Period);
   int maxShift  = MathMax(MathAbs(InpMA1Shift), MathAbs(InpMA2Shift));

   return(maxPeriod + maxShift + barsBefore + barsAfter + 20);
}

//+------------------------------------------------------------------+
//| Preserve original MATRIX swing detection                         |
//|                                                                  |
//| This is the core original philosophy:                            |
//| 1. Detect raw MA relationship change.                            |
//| 2. Clamp window using opposite raw signals.                      |
//| 3. Select true extreme inside window.                            |
//| 4. Confirm only after Y bars.                                    |
//+------------------------------------------------------------------+
void SwingEngine_Detect(const MqlRates &rates[],
                        const double &ma1[],
                        const double &ma2[],
                        int barsBefore,
                        int barsAfter,
                        bool majorFlag,
                        SwingPoint &out[])
{
   int total = ArraySize(rates);

   int minBars = Engine_MinRequiredBars(barsBefore, barsAfter);
   if(total < minBars)
      return;

   int rawTypes[];
   ArrayResize(rawTypes, total);
   ArrayInitialize(rawTypes, 0);

   int oldest = total - minBars;

   // Strict no-repaint:
   // barsAfter + 1 ensures the confirmation window is fully closed.
   int newestConfirmed = barsAfter;
   if(InpStrictNoRepaint)
      newestConfirmed = barsAfter + 1;

   if(oldest < newestConfirmed)
      return;

   // ------------------------------------------------------------
   // Step 1: raw MA relationship detection
   // ------------------------------------------------------------
   for(int i = oldest; i >= newestConfirmed; i--)
   {
      int s1 = i + InpMA1Shift;
      int s2 = i + InpMA2Shift;

      if(s1 < 0 || s2 < 0)
         continue;

      if(s1 + 1 >= total || s2 + 1 >= total)
         continue;

      if(ma1[s1 + 1] <= ma2[s2 + 1] && ma1[s1] > ma2[s2])
         rawTypes[i] = 1;

      if(ma1[s1 + 1] >= ma2[s2 + 1] && ma1[s1] < ma2[s2])
         rawTypes[i] = 2;
   }

   // ------------------------------------------------------------
   // Step 2: boundary clamping and extreme selection
   // ------------------------------------------------------------
   for(int i = oldest; i >= newestConfirmed; i--)
   {
      if(rawTypes[i] == 0)
         continue;

      int startBar = i + barsBefore;
      int endBar   = i - barsAfter;

      if(startBar >= total)
         startBar = total - 1;

      int minEnd = InpStrictNoRepaint ? 1 : 0;
      if(endBar < minEnd)
         endBar = minEnd;

      int opposite = (rawTypes[i] == 1) ? 2 : 1;

      // Clamp older boundary by opposite signal
      for(int j = i + 1; j <= startBar; j++)
      {
         if(rawTypes[j] == opposite)
         {
            startBar = j - 1;
            break;
         }
      }

      // Clamp newer boundary by opposite signal
      for(int j = i - 1; j >= endBar; j--)
      {
         if(rawTypes[j] == opposite)
         {
            endBar = j + 1;
            break;
         }
      }

      if(startBar < endBar)
         continue;

      if(rawTypes[i] == 1)
      {
         int    lowestIdx = i;
         double minLow    = rates[i].low;

         for(int j = startBar; j >= endBar; j--)
         {
            if(rates[j].low < minLow)
            {
               minLow    = rates[j].low;
               lowestIdx = j;
            }
         }

         SwingEngine_Add(out,
                         rates[lowestIdx].time,
                         minLow,
                         1,
                         lowestIdx,
                         majorFlag);
      }
      else if(rawTypes[i] == 2)
      {
         int    highestIdx = i;
         double maxHigh    = rates[i].high;

         for(int j = startBar; j >= endBar; j--)
         {
            if(rates[j].high > maxHigh)
            {
               maxHigh    = rates[j].high;
               highestIdx = j;
            }
         }

         SwingEngine_Add(out,
                         rates[highestIdx].time,
                         maxHigh,
                         2,
                         highestIdx,
                         majorFlag);
      }
   }
}

//+------------------------------------------------------------------+
//| Add swing with duplicate protection                              |
//+------------------------------------------------------------------+
void SwingEngine_Add(SwingPoint &out[],
                     datetime t,
                     double price,
                     int type,
                     int tfBar,
                     bool majorFlag)
{
   int size = ArraySize(out);

   if(size > 0)
   {
      if(out[size - 1].time == t && out[size - 1].type == type)
         return;
   }

   ArrayResize(out, size + 1);

   out[size].time  = t;
   out[size].price = price;
   out[size].type  = type;
   out[size].tfBar = tfBar;
   out[size].major = majorFlag;
}

//+------------------------------------------------------------------+
//| Copy swing array                                                 |
//+------------------------------------------------------------------+
void SwingEngine_Copy(const SwingPoint &source[], SwingPoint &dest[])
{
   int count = ArraySize(source);
   ArrayResize(dest, count);

   for(int i = 0; i < count; i++)
      dest[i] = source[i];
}

//+------------------------------------------------------------------+
//| Map target timeframe swings to current chart buffers             |
//+------------------------------------------------------------------+
void SwingEngine_MapToBuffers(const SwingPoint &swings[],
                              double &buyBuffer[],
                              double &sellBuffer[],
                              int rates_total)
{
   int count = ArraySize(swings);

   for(int i = 0; i < count; i++)
   {
      int shift = iBarShift(_Symbol, _Period, swings[i].time, true);

      if(shift < 0)
         shift = iBarShift(_Symbol, _Period, swings[i].time, false);

      if(shift < 0 || shift >= rates_total)
         continue;

      if(swings[i].type == 1)
         buyBuffer[shift] = swings[i].price;
      else if(swings[i].type == 2)
         sellBuffer[shift] = swings[i].price;
   }
}

//+------------------------------------------------------------------+
//| Get latest swings of one type, sorted old -> new                 |
//+------------------------------------------------------------------+
int TrendEngine_GetLastByType(const SwingPoint &swings[],
                              int type,
                              int count,
                              SwingPoint &out[])
{
   ArrayResize(out, 0);

   SwingPoint tmp[];
   ArrayResize(tmp, count);

   int found = 0;

   for(int i = ArraySize(swings) - 1; i >= 0 && found < count; i--)
   {
      if(swings[i].type == type)
      {
         tmp[found] = swings[i];
         found++;
      }
   }

   ArrayResize(out, found);

   for(int i = 0; i < found; i++)
      out[i] = tmp[found - 1 - i];

   return(found);
}

//+------------------------------------------------------------------+
//| Structural trend engine                                          |
//|                                                                  |
//| HH = Higher High                                                 |
//| HL = Higher Low                                                  |
//| LH = Lower High                                                  |
//| LL = Lower Low                                                   |
//+------------------------------------------------------------------+
void TrendEngine_Evaluate(const SwingPoint &swings[], TrendState &st)
{
   st.bullScore = 0;
   st.bearScore = 0;
   st.structureDir = 0;
   st.lastHighRelation = 0;
   st.lastLowRelation = 0;
   st.state = TREND_SIDEWAYS;

   if(ArraySize(swings) < 2)
      return;

   SwingPoint highs[];
   SwingPoint lows[];

   int highCount = TrendEngine_GetLastByType(swings, 2, InpTrendSwingLookback, highs);
   int lowCount  = TrendEngine_GetLastByType(swings, 1, InpTrendSwingLookback, lows);

   double minDist = InpStructMinDistancePoints * _Point;

   // Evaluate highs: HH / LH
   for(int i = 1; i < highCount; i++)
   {
      if(highs[i].price > highs[i - 1].price + minDist)
      {
         st.bullScore++;

         if(i == highCount - 1)
            st.lastHighRelation = 1;
      }
      else if(highs[i].price < highs[i - 1].price - minDist)
      {
         st.bearScore++;

         if(i == highCount - 1)
            st.lastHighRelation = -1;
      }
   }

   // Evaluate lows: HL / LL
   for(int i = 1; i < lowCount; i++)
   {
      if(lows[i].price > lows[i - 1].price + minDist)
      {
         st.bullScore++;

         if(i == lowCount - 1)
            st.lastLowRelation = 1;
      }
      else if(lows[i].price < lows[i - 1].price - minDist)
      {
         st.bearScore++;

         if(i == lowCount - 1)
            st.lastLowRelation = -1;
      }
   }

   bool bullishStructure = (st.lastHighRelation > 0 && st.lastLowRelation > 0);
   bool bearishStructure = (st.lastHighRelation < 0 && st.lastLowRelation < 0);

   if(bullishStructure)
      st.structureDir = 1;
   else if(bearishStructure)
      st.structureDir = -1;
   else
      st.structureDir = 0;

   // Basic state classification
   if(st.bullScore >= InpStrongScore && st.bullScore > st.bearScore)
      st.state = TREND_STRONG_BULL;
   else if(st.bearScore >= InpStrongScore && st.bearScore > st.bullScore)
      st.state = TREND_STRONG_BEAR;
   else if(st.bullScore >= InpWeakScore && st.bullScore > st.bearScore)
      st.state = TREND_BULLISH;
   else if(st.bearScore >= InpWeakScore && st.bearScore > st.bullScore)
      st.state = TREND_BEARISH;
   else if(st.bullScore == 0 && st.bearScore == 0)
      st.state = TREND_SIDEWAYS;
   else
      st.state = TREND_TRANSITION;

   // Mixed latest structure often indicates transition
   if(st.lastHighRelation != 0 && st.lastLowRelation != 0)
   {
      if(st.lastHighRelation != st.lastLowRelation)
         st.state = TREND_TRANSITION;
   }

   // Reversal candidate detection
   if(st.previousFinalDir > 0 && st.structureDir < 0 && st.bearScore >= InpReversalScore)
      st.state = TREND_REVERSAL_CANDIDATE;

   if(st.previousFinalDir < 0 && st.structureDir > 0 && st.bullScore >= InpReversalScore)
      st.state = TREND_REVERSAL_CANDIDATE;

   // Remember last meaningful structural direction
   if(st.structureDir != 0)
      st.previousFinalDir = st.structureDir;
}

//+------------------------------------------------------------------+
//| Select regression anchor and expansion points                    |
//+------------------------------------------------------------------+
bool RegressionEngine_SelectAnchors(const SwingPoint &swings[],
                                    int structureDir,
                                    datetime &anchorTime,
                                    double &anchorPrice,
                                    datetime &expansionTime,
                                    double &expansionPrice)
{
   int count = ArraySize(swings);

   if(count < 2)
      return(false);

   if(structureDir > 0)
   {
      int expansion = -1;
      int anchor = -1;

      // Bullish expansion point: latest confirmed high
      for(int i = count - 1; i >= 0; i--)
      {
         if(swings[i].type == 2)
         {
            expansion = i;
            break;
         }
      }

      if(expansion < 0)
         return(false);

      // Anchor: latest confirmed low before that high
      for(int i = expansion - 1; i >= 0; i--)
      {
         if(swings[i].type == 1)
         {
            anchor = i;
            break;
         }
      }

      if(anchor < 0)
         return(false);

      anchorTime     = swings[anchor].time;
      anchorPrice    = swings[anchor].price;
      expansionTime  = swings[expansion].time;
      expansionPrice = swings[expansion].price;

      return(true);
   }

   if(structureDir < 0)
   {
      int expansion = -1;
      int anchor = -1;

      // Bearish expansion point: latest confirmed low
      for(int i = count - 1; i >= 0; i--)
      {
         if(swings[i].type == 1)
         {
            expansion = i;
            break;
         }
      }

      if(expansion < 0)
         return(false);

      // Anchor: latest confirmed high before that low
      for(int i = expansion - 1; i >= 0; i--)
      {
         if(swings[i].type == 2)
         {
            anchor = i;
            break;
         }
      }

      if(anchor < 0)
         return(false);

      anchorTime     = swings[anchor].time;
      anchorPrice    = swings[anchor].price;
      expansionTime  = swings[expansion].time;
      expansionPrice = swings[expansion].price;

      return(true);
   }

   return(false);
}

//+------------------------------------------------------------------+
//| Get applied price from MqlRates                                  |
//+------------------------------------------------------------------+
double PriceEngine_Get(const MqlRates &rate, ENUM_APPLIED_PRICE price)
{
   switch(price)
   {
      case PRICE_OPEN:    return(rate.open);
      case PRICE_HIGH:    return(rate.high);
      case PRICE_LOW:     return(rate.low);
      case PRICE_CLOSE:   return(rate.close);
      case PRICE_MEDIAN:  return((rate.high + rate.low) / 2.0);
      case PRICE_TYPICAL: return((rate.high + rate.low + rate.close) / 3.0);
      case PRICE_WEIGHTED:return((rate.high + rate.low + rate.close + rate.close) / 4.0);
   }

   return(rate.close);
}

//+------------------------------------------------------------------+
//| Anchored linear regression engine                                |
//|                                                                  |
//| Regression is updated only after a new confirmed structural      |
//| pivot, not on every tick/candle.                                 |
//+------------------------------------------------------------------+
void RegressionEngine_Update(const SwingPoint &swings[],
                             const MqlRates &rates[],
                             int targetBars,
                             const TrendState &trend)
{
   if(!InpEnableRegression)
      return;

   if(trend.structureDir == 0)
   {
      // Keep last regression but mark it not currently validating a trend
      g_regression.structDir = 0;
      return;
   }

   datetime anchorTime, expansionTime;
   double   anchorPrice, expansionPrice;

   if(!RegressionEngine_SelectAnchors(swings,
                                      trend.structureDir,
                                      anchorTime,
                                      anchorPrice,
                                      expansionTime,
                                      expansionPrice))
   {
      return;
   }

   // Pivot-only update filter
   if(InpRegressionUpdateOnPivot)
   {
      if(expansionTime == g_regression.lastPivotTime &&
         trend.structureDir == g_regression.structDir &&
         g_regression.valid)
      {
         return;
      }
   }

   int anchorShift = iBarShift(_Symbol, g_tf, anchorTime, true);
   int expansionShift = iBarShift(_Symbol, g_tf, expansionTime, true);

   if(anchorShift < 0 || expansionShift < 0)
      return;

   if(anchorShift <= expansionShift)
      return;

   int n = anchorShift - expansionShift + 1;

   if(n < InpRegressionMinBars)
      return;

   if(InpRegressionMaxBars > 0 && n > InpRegressionMaxBars)
      return;

   double sumX = 0.0;
   double sumY = 0.0;
   double sumXY = 0.0;
   double sumXX = 0.0;

   // x = 0 at anchor, x = n-1 at expansion
   for(int shift = expansionShift; shift <= anchorShift; shift++)
   {
      int x = anchorShift - shift;
      double y = PriceEngine_Get(rates[shift], InpRegressionPrice);

      sumX  += x;
      sumY  += y;
      sumXY += x * y;
      sumXX += x * x;
   }

   double denom = (double)n * sumXX - sumX * sumX;

   if(MathAbs(denom) < 1e-12)
      return;

   double slope = ((double)n * sumXY - sumX * sumY) / denom;
   double intercept = (sumY - slope * sumX) / (double)n;

   double sumResid2 = 0.0;

   for(int shift = expansionShift; shift <= anchorShift; shift++)
   {
      int x = anchorShift - shift;
      double y = PriceEngine_Get(rates[shift], InpRegressionPrice);
      double fitted = intercept + slope * x;
      double resid = y - fitted;
      sumResid2 += resid * resid;
   }

   double stdDev = 0.0;

   if(n > 2)
      stdDev = MathSqrt(sumResid2 / (double)(n - 2));

   double slopePoints = slope / _Point;

   g_regression.valid = true;
   g_regression.structDir = trend.structureDir;
   g_regression.anchorTime = anchorTime;
   g_regression.expansionTime = expansionTime;
   g_regression.anchorPrice = anchorPrice;
   g_regression.expansionPrice = expansionPrice;
   g_regression.slope = slope;
   g_regression.intercept = intercept;
   g_regression.stdDev = stdDev;
   g_regression.slopePointsPerBar = slopePoints;
   g_regression.lastPivotTime = expansionTime;

   if(slopePoints > InpMinSlopePointsPerBar)
      g_regression.slopeDir = 1;
   else if(slopePoints < -InpMinSlopePointsPerBar)
      g_regression.slopeDir = -1;
   else
      g_regression.slopeDir = 0;
}

//+------------------------------------------------------------------+
//| Fusion engine: structure + regression                            |
//+------------------------------------------------------------------+
int FusionEngine_FinalDirection(const TrendState &trend,
                                const RegressionState &reg)
{
   if(!InpEnableTrend)
      return(0);

   if(!InpEnableRegression)
      return(trend.structureDir);

   if(!reg.valid)
      return(0);

   if(trend.structureDir > 0 && reg.slopeDir > 0)
      return(1);

   if(trend.structureDir < 0 && reg.slopeDir < 0)
      return(-1);

   return(0);
}

//+------------------------------------------------------------------+
//| Draw swing arrows                                                |
//+------------------------------------------------------------------+
void Draw_SwingArrows(const SwingPoint &swings[], bool major)
{
   int count = ArraySize(swings);

   for(int i = 0; i < count; i++)
   {
      string name = g_prefix + (major ? "MAJ_" : "MIN_") +
                    IntegerToString(swings[i].type) + "_" +
                    IntegerToString((long)swings[i].time);

      if(ObjectFind(0, name) >= 0)
         continue;

      ObjectCreate(0, name, OBJ_ARROW, 0, swings[i].time, swings[i].price);
      ObjectSetInteger(0, name, OBJPROP_ARROWCODE, 158);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, major ? 3 : 2);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);

      color arrowColor = clrWhite;

      if(!major)
         arrowColor = (swings[i].type == 1) ? InpMinorBuyColor : InpMinorSellColor;
      else
         arrowColor = (swings[i].type == 1) ? InpMajorBuyColor : InpMajorSellColor;

      ObjectSetInteger(0, name, OBJPROP_COLOR, arrowColor);
   }
}

//+------------------------------------------------------------------+
//| Draw structural ZigZag                                           |
//+------------------------------------------------------------------+
void Draw_StructuralZigZag(const SwingPoint &swings[])
{
   int count = ArraySize(swings);

   if(count < 2)
      return;

   datetime lastTime = 0;
   double   lastPrice = 0.0;
   int      lastType = 0;

   for(int i = 0; i < count; i++)
   {
      if(lastType != 0 && swings[i].type != lastType)
      {
         string name = g_prefix + "ZZ_" +
                       IntegerToString((long)lastTime) + "_" +
                       IntegerToString((long)swings[i].time);

         if(ObjectFind(0, name) < 0)
         {
            ObjectCreate(0, name, OBJ_TREND, 0,
                         lastTime, lastPrice,
                         swings[i].time, swings[i].price);

            ObjectSetInteger(0, name, OBJPROP_COLOR, InpZigZagColor);
            ObjectSetInteger(0, name, OBJPROP_WIDTH, InpZigZagWidth);
            ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
            ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
         }
      }

      lastTime  = swings[i].time;
      lastPrice = swings[i].price;
      lastType  = swings[i].type;
   }
}

//+------------------------------------------------------------------+
//| Draw anchored regression line/channel                            |
//+------------------------------------------------------------------+
void Draw_Regression(const RegressionState &reg, int finalDir)
{
   if(!reg.valid)
      return;

   int anchorShift = iBarShift(_Symbol, g_tf, reg.anchorTime, true);
   if(anchorShift < 0)
      return;

   datetime endTime = reg.expansionTime;
   int endShift = iBarShift(_Symbol, g_tf, endTime, true);

   if(InpRegressionProject)
   {
      endTime = iTime(_Symbol, g_tf, 0);
      endShift = 0;
   }

   if(endShift < 0)
      return;

   double anchorY = reg.intercept;
   double endY = reg.intercept + reg.slope * (anchorShift - endShift);

   double upperAnchor = anchorY + InpRegressionStdDevMult * reg.stdDev;
   double lowerAnchor = anchorY - InpRegressionStdDevMult * reg.stdDev;

   double upperEnd = endY + InpRegressionStdDevMult * reg.stdDev;
   double lowerEnd = endY - InpRegressionStdDevMult * reg.stdDev;

   color lineColor = InpRegressionColor;

   if(finalDir > 0)
      lineColor = clrLimeGreen;
   else if(finalDir < 0)
      lineColor = clrRed;

   Draw_TrendLine(g_prefix + "REG_LINE",
                  reg.anchorTime, anchorY,
                  endTime, endY,
                  lineColor,
                  InpRegressionWidth);

   Draw_TrendLine(g_prefix + "REG_UPPER",
                  reg.anchorTime, upperAnchor,
                  endTime, upperEnd,
                  InpRegressionChannelColor,
                  1);

   Draw_TrendLine(g_prefix + "REG_LOWER",
                  reg.anchorTime, lowerAnchor,
                  endTime, lowerEnd,
                  InpRegressionChannelColor,
                  1);
}

//+------------------------------------------------------------------+
//| Helper: draw trend line object                                   |
//+------------------------------------------------------------------+
void Draw_TrendLine(string name,
                    datetime time1,
                    double price1,
                    datetime time2,
                    double price2,
                    color lineColor,
                    int width)
{
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_TREND, 0, time1, price1, time2, price2);
   else
   {
      ObjectMove(0, name, 0, time1, price1);
      ObjectMove(0, name, 1, time2, price2);
   }

   ObjectSetInteger(0, name, OBJPROP_COLOR, lineColor);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
   ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
}

//+------------------------------------------------------------------+
//| Trend state to text                                              |
//+------------------------------------------------------------------+
string TrendEngine_StateToString(ENUM_TREND_STATE state)
{
   switch(state)
   {
      case TREND_SIDEWAYS:            return("SIDEWAYS");
      case TREND_TRANSITION:          return("TRANSITION");
      case TREND_WEAK_BULL:           return("WEAK BULL");
      case TREND_WEAK_BEAR:           return("WEAK BEAR");
      case TREND_BULLISH:             return("BULLISH");
      case TREND_BEARISH:             return("BEARISH");
      case TREND_STRONG_BULL:         return("STRONG BULL");
      case TREND_STRONG_BEAR:         return("STRONG BEAR");
      case TREND_REVERSAL_CANDIDATE:  return("REVERSAL CANDIDATE");
   }

   return("UNKNOWN");
}

//+------------------------------------------------------------------+
//| Draw trend dashboard label                                       |
//+------------------------------------------------------------------+
void Draw_TrendLabel(int finalDir,
                     const TrendState &trend,
                     const RegressionState &reg)
{
   string name = g_prefix + "TREND_LABEL";

   string structureText = "NEUTRAL";

   if(trend.structureDir > 0)
      structureText = "BULL STRUCTURE";
   else if(trend.structureDir < 0)
      structureText = "BEAR STRUCTURE";

   string regText = "REG: OFF";

   if(InpEnableRegression && reg.valid)
   {
      if(reg.slopeDir > 0)
         regText = "REG: +";
      else if(reg.slopeDir < 0)
         regText = "REG: -";
      else
         regText = "REG: 0";
   }

   string finalText = "FINAL: NEUTRAL";

   if(finalDir > 0)
      finalText = "FINAL: BULL";
   else if(finalDir < 0)
      finalText = "FINAL: BEAR";

   string text = StringFormat("%s | %s | %s | %s",
                              _Symbol,
                              TrendEngine_StateToString(trend.state),
                              regText,
                              finalText);

   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);

   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, InpLabelX);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, InpLabelY);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetString(0, name, OBJPROP_FONT, InpLabelFont);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, InpLabelFontSize);
   ObjectSetInteger(0, name, OBJPROP_COLOR, InpLabelColor);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
}