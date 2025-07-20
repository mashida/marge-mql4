//+------------------------------------------------------------------+
//| Marg-03.mq4                                                      |
//| Copyright 2025, Никита Сердитов                                  |
//| https://t.me/mashida                                             |
//+------------------------------------------------------------------+
#property strict
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_color1 clrBlue
#property indicator_width1 2
#property indicator_style1 STYLE_SOLID

#include "htf.mqh"
#include "OsmaOnArray.mqh"

//--- входные параметры
input int HigherTFMinutes = 60;         // Старший таймфрейм в минутах
input int OsMA_FastEMA    = 12;         // Быстрая EMA для OsMA
input int OsMA_SlowEMA    = 26;         // Медленная EMA для OsMA
input int OsMA_SignalSMA  = 9;          // Сигнальная SMA для OsMA

//--- буферы индикатора
double OsMA_Buffer[];       // буфер для OsMA
double CloseHTF_Buffer[];   // буфер цены Close старшего таймфрейма

//--- глобальные объекты
CHTF            htf;
COsMAOnArray    osma;

//+------------------------------------------------------------------+
//| Инициализация индикатора                                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   SetIndexBuffer(0, OsMA_Buffer, INDICATOR_DATA);
   SetIndexBuffer(1, CloseHTF_Buffer, INDICATOR_CALCULATIONS);
   ArraySetAsSeries(OsMA_Buffer, true);
   ArraySetAsSeries(CloseHTF_Buffer, true);

   SetIndexStyle(0, DRAW_HISTOGRAM, STYLE_SOLID, 2, clrBlue);
   SetIndexLabel(0, "OsMA HTF");

   htf.SaveInputs(0, HigherTFMinutes);
   htf.OnInitCalc();
   osma.Init(OsMA_FastEMA, OsMA_SlowEMA, OsMA_SignalSMA);

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Основная функция расчета                                         |
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
   htf.Calc(rates_total, prev_calculated);
   htf.CopyCloseBuffer(rates_total, CloseHTF_Buffer);

   osma.OnCalculate(rates_total, prev_calculated, CloseHTF_Buffer, OsMA_Buffer);

   return(rates_total);
  }
//+------------------------------------------------------------------+
