//+------------------------------------------------------------------+
//|                                     MATRIX_Cross.mq5|
//|                                  Copyright 2026, Rama Empire     |
//+------------------------------------------------------------------+
#property copyright "Rama Empire"
#property indicator_chart_window
#property indicator_buffers 4
#property indicator_plots   4

// --- رسم مووینگ اول ---
#property indicator_label1  "MA 1 (Shifted)"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrDodgerBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

// --- رسم مووینگ دوم ---
#property indicator_label2  "MA 2 (Shifted)"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrOrangeRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2

// --- نقطه خرید (Low Signal) ---
#property indicator_label3  "Buy Dot Signal"
#property indicator_type3   DRAW_ARROW
#property indicator_color3  clrLimeGreen
#property indicator_width3  3

// --- نقطه فروش (High Signal) ---
#property indicator_label4  "Sell Dot Signal"
#property indicator_type4   DRAW_ARROW
#property indicator_color4  clrDeepPink
#property indicator_width4  3

//+------------------------------------------------------------------+
//| ورودی‌های تنظیمات (Input Parameters)                               |
//+------------------------------------------------------------------+
input group "--- تنظیمات مووینگ اول ---"
input int                  InpMA1_Period = 9;             // دوره تناوب (Period)
input int                  InpMA1_Shift  = -4;            // شیفت (Shift)
input ENUM_MA_METHOD       InpMA1_Method = MODE_SMMA;      // روش محاسبه
input ENUM_APPLIED_PRICE   InpMA1_Price  = PRICE_MEDIAN;  // قیمت پایه (HL/2)

input group "--- تنظیمات مووینگ دوم ---"
input int                  InpMA2_Period = 9;             // دوره تناوب (Period)
input int                  InpMA2_Shift  = 0;            // شیفت (Shift)
input ENUM_MA_METHOD       InpMA2_Method = MODE_SMMA;      // روش محاسبه
input ENUM_APPLIED_PRICE   InpMA2_Price  = PRICE_MEDIAN;  // قیمت پایه (HL/2)

input group "--- تنظیمات محدوده بررسی و مرزها ---"
input int                  InpBarsBefore = 14;             // X: تعداد کندل‌های قبل
input int                  InpBarsAfter  = 4;             // Y: تعداد کندل‌های بعد

input group "--- تنظیمات هشدارها (Alerts) ---"
input bool                 InpEnableAlert = false;         // هشدار روی صفحه (Pop-up)
input bool                 InpEnableSound = false;         // هشدار صوتی
input bool                 InpEnablePush  = false;        // ارسال به موبایل
input bool                 InpEnableEmail = false;        // ارسال ایمیل

// --- بافرهای داده ---
double BufferMA1[];
double BufferMA2[];
double BufferBuy[];
double BufferSell[];

// --- هندل‌های اندیکاتور ---
int handleMA1;
int handleMA2;

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

   PlotIndexSetInteger(0, PLOT_SHIFT, InpMA1_Shift);
   PlotIndexSetInteger(1, PLOT_SHIFT, InpMA2_Shift);

   PlotIndexSetInteger(2, PLOT_ARROW, 158); // کد نقطه پر
   PlotIndexSetInteger(3, PLOT_ARROW, 158); 

   PlotIndexSetDouble(2, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetDouble(3, PLOT_EMPTY_VALUE, 0.0);

   handleMA1 = iMA(_Symbol, _Period, InpMA1_Period, 0, InpMA1_Method, InpMA1_Price);
   handleMA2 = iMA(_Symbol, _Period, InpMA2_Period, 0, InpMA2_Method, InpMA2_Price);

   if(handleMA1 == INVALID_HANDLE || handleMA2 == INVALID_HANDLE)
   {
      Print("خطا در ایجاد هندل مووینگ اوریج‌ها!");
      return(INIT_FAILED);
   }

   lastAlertTime = 0;
   return(INIT_SUCCEEDED);
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
   int min_bars = MathMax(InpMA1_Period, InpMA2_Period) + InpBarsBefore + InpBarsAfter + 10;
   if(rates_total < min_bars) return(0);

   ArraySetAsSeries(BufferMA1, true);
   ArraySetAsSeries(BufferMA2, true);
   ArraySetAsSeries(BufferBuy, true);
   ArraySetAsSeries(BufferSell, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(time, true);

   if(CopyBuffer(handleMA1, 0, 0, rates_total, BufferMA1) <= 0) return(0);
   if(CopyBuffer(handleMA2, 0, 0, rates_total, BufferMA2) <= 0) return(0);

   int limit = rates_total - prev_calculated;
   if(limit > rates_total - min_bars)
      limit = rates_total - min_bars;

   for(int k = limit; k >= 0; k--)
   {
      BufferBuy[k]  = 0.0;
      BufferSell[k] = 0.0;
   }

   // گام اول: شناسایی محل اولیه کراس‌ها (نقاط خام)
   int rawTypes[]; // 1: Buy (Low), 2: Sell (High)
   ArrayResize(rawTypes, rates_total);
   ArrayInitialize(rawTypes, 0);

   for(int i = rates_total - min_bars; i >= InpBarsAfter; i--)
   {
      int shift1 = i + InpMA1_Shift;
      int shift2 = i + InpMA2_Shift;

      if(shift1 < 0 || shift2 < 0 || shift1 + 1 >= rates_total || shift2 + 1 >= rates_total)
         continue;

      double ma1_curr = BufferMA1[shift1];
      double ma1_prev = BufferMA1[shift1 + 1];
      
      double ma2_curr = BufferMA2[shift2];
      double ma2_prev = BufferMA2[shift2 + 1];

      // کراس صعودی -> نقطه Low
      if(ma1_prev <= ma2_prev && ma1_curr > ma2_curr)
         rawTypes[i] = 1;

      // کراس نزولی -> نقطه High
      if(ma1_prev >= ma2_prev && ma1_curr < ma2_curr)
         rawTypes[i] = 2;
   }

   // گام دوم: اعمال محدودیت مرزها و پیدا کردن اکسترمم واقعی درون مرز
   for(int i = rates_total - min_bars; i >= InpBarsAfter; i--)
   {
      if(rawTypes[i] == 0) continue;

      // تعیین بازه اولیه بر اساس X و Y
      int startBar = i + InpBarsBefore; // محدوده گذشته (سمت چپ)
      int endBar   = i - InpBarsAfter;  // محدوده آینده (سمت راست)

      if(startBar >= rates_total) startBar = rates_total - 1;
      if(endBar < 0) endBar = 0;

      // --- ۱. محدود کردن مرزها برای نقطه خرید (Low) بر اساس Highهای مجاور ---
      if(rawTypes[i] == 1)
      {
         // مرز چپ: جستجو برای اولین High قبل از این کراس
         for(int j = i + 1; j <= startBar; j++)
         {
            if(rawTypes[j] == 2) // برخورد به مرز High قبلی
            {
               startBar = j - 1; // یک کندل بعد از مرز High
               break;
            }
         }

         // مرز راست: جستجو برای اولین High بعد از این کراس
         for(int j = i - 1; j >= endBar; j--)
         {
            if(rawTypes[j] == 2) // برخورد به مرز High بعدی
            {
               endBar = j + 1; // یک کندل قبل از مرز High
               break;
            }
         }

         // یافتن Lowest Low در محدوده محصور شده بین مرزها
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
            BufferBuy[lowestIdx] = minLow;
         }
      }

      // --- ۲. محدود کردن مرزها برای نقطه فروش (High) بر اساس Lowهای مجاور ---
      if(rawTypes[i] == 2)
      {
         // مرز چپ: جستجو برای اولین Low قبل از این کراس
         for(int j = i + 1; j <= startBar; j++)
         {
            if(rawTypes[j] == 1) // برخورد به مرز Low قبلی
            {
               startBar = j - 1; // یک کندل بعد از مرز Low
               break;
            }
         }

         // مرز راست: جستجو برای اولین Low بعد از این کراس
         for(int j = i - 1; j >= endBar; j--)
         {
            if(rawTypes[j] == 1) // برخورد به مرز Low بعدی
            {
               endBar = j + 1; // یک کندل قبل از مرز Low
               break;
            }
         }

         // یافتن Highest High در محدوده محصور شده بین مرزها
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
            BufferSell[highestIdx] = maxHigh;
         }
      }
   }

   // --- مدیریت سیستم هشدار ---
   if(time[0] != lastAlertTime)
   {
      int checkBar = 1 + InpBarsAfter;
      int s1 = checkBar + InpMA1_Shift;
      int s2 = checkBar + InpMA2_Shift;

      if(s1 >= 0 && s2 >= 0 && s1 + 1 < rates_total && s2 + 1 < rates_total)
      {
         if(BufferMA1[s1 + 1] <= BufferMA2[s2 + 1] && BufferMA1[s1] > BufferMA2[s2])
         {
            SendAlerts("سیگنال نقطه Low با حفظ ساختار", _Symbol);
            lastAlertTime = time[0];
         }
         else if(BufferMA1[s1 + 1] >= BufferMA2[s2 + 1] && BufferMA1[s1] < BufferMA2[s2])
         {
            SendAlerts("سیگنال نقطه High با حفظ ساختار", _Symbol);
            lastAlertTime = time[0];
         }
      }
   }

   return(rates_total);
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
