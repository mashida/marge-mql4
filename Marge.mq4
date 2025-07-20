//+------------------------------------------------------------------+
//|                                                      Marge.mq4   |
//|                                  Copyright 2025, Никита Сердитов |
//|                                             https://t.me/mashida |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2025, Никита Сердитов"
#property link        "https://t.me/mashida"
#property version     "1.00"
#property strict
#property indicator_separate_window
#property indicator_buffers 1
#property indicator_color1 clrBlue
#property indicator_width1 2
#property indicator_style1 STYLE_SOLID

#include "BarBuilder.mqh"

//--- входные параметры
input int TimeFrame = PERIOD_H1;       // Таймфрейм для OsMA в минутах
input int OsMA_FastEMA = 12;                 // Быстрая EMA для OsMA
input int OsMA_SlowEMA = 26;                 // Медленная EMA для OsMA
input int OsMA_SignalSMA = 9;                // Сигнальная SMA для OsMA
input bool enableDebug = false;              // Режим отладки

//--- буферы индикатора
double OsMA_Buffer[];

//--- глобальные переменные
CBarBuilder barBuilder;

//+------------------------------------------------------------------+
//| Функция инициализации пользовательского индикатора              |
//+------------------------------------------------------------------+
int OnInit()
  {
   Print("=== Marge OnInit() ===");
   
   // Устанавливаем буферы
   SetIndexBuffer(0, OsMA_Buffer);       // Выходной буфер (видимый)
   ArraySetAsSeries(OsMA_Buffer, true);
   
   // Устанавливаем стили линий
   SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 2, clrBlue);  // Основной буфер
   
   // Устанавливаем названия буферов
   SetIndexLabel(0, "Marge");
   
   // Инициализируем BarBuilder
   Print("Инициализация BarBuilder...");
   int periodMinutes = TimeFrame; // TimeFrame задан в минутах
   Print("Период BarBuilder в минутах: ", periodMinutes);
   
   barBuilder.Initialize(periodMinutes);
   // Новый интерфейс CBarBuilder не требует настройки источника данных и режима отладки
   
   Print("BarBuilder инициализирован");
   Print("BarBuilder инициализирован успешно");
   Print("Размер выходного буфера OsMA_Buffer: " + IntegerToString(ArraySize(OsMA_Buffer)));
   
   return INIT_SUCCEEDED;
  }
//+------------------------------------------------------------------+
//| Функция деинициализации пользовательского индикатора            |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Print("=== Деинициализация индикатора Marge ===");
   Print("Причина: ", reason);
   Print("Количество баров в BarBuilder: ", barBuilder.BarsCount());
   
//--- очистка объекта BarBuilder
   barBuilder.Clear();
   
   Print("=== Деинициализация завершена ===");
  }
//+------------------------------------------------------------------+
//| Функция итерации пользовательского индикатора                   |
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
//--- проверка количества баров
   PrintFormat("%s | шаг 1: проверка количества баров", __FUNCTION__);
   if(rates_total < OsMA_SlowEMA)
     {
      Print("Недостаточно баров: ", rates_total, " < ", OsMA_SlowEMA);
      return(0);
     }

//--- управление перерасчётом
   PrintFormat("%s | шаг 2: смотрим diff=%d", __FUNCTION__, rates_total - prev_calculated);
   int diff = rates_total - prev_calculated;
   if(diff == 0)
      return(rates_total);

   int start;
   PrintFormat("%s | шаг 3: управление перерасчётом", __FUNCTION__);
   if(prev_calculated == 0 || diff > 1)
     {
      barBuilder.Clear();
      start = 0;
      Print("Пересборка всей истории, bars: ", rates_total);
     }
   else
     {
      start = rates_total - 1;
      Print("Добавляем один бар (index=", start, ")");
     }
   
//--- расчет начального бара
   PrintFormat("%s | шаг 4: расчет начального бара", __FUNCTION__);
   if(prev_calculated == 0)
     {
      Print("Первичный расчет. Всего баров: ", rates_total);
     }
   else
     {
      Print("Обновление. Обрабатываем с бара: ", start, " до: ", rates_total - 1);
     }
      
//--- обработка данных через BarBuilder: агрегируем цены и рассчитываем OsMA
   PrintFormat("%s | шаг 5: обработка данных через BarBuilder: агрегируем цены и рассчитываем OsMA", __FUNCTION__);
  //--- получаем данные М1 для агрегации
   PrintFormat("%s | шаг 6: получаем данные М1 для агрегации", __FUNCTION__);
   int    m1Count = iBars(Symbol(), PERIOD_M1);
   datetime timeM1[];
   double   openM1[], highM1[], lowM1[], closeM1[];
   long     volM1[];
   ArrayResize(timeM1, m1Count);
   ArrayResize(openM1, m1Count);
   ArrayResize(highM1, m1Count);
   ArrayResize(lowM1,  m1Count);
   ArrayResize(closeM1,m1Count);
   ArrayResize(volM1,  m1Count);
   ArraySetAsSeries(timeM1, true);
   ArraySetAsSeries(openM1, true);
   ArraySetAsSeries(highM1, true);
   ArraySetAsSeries(lowM1,  true);
   ArraySetAsSeries(closeM1,true);
   ArraySetAsSeries(volM1,  true);
   for(int k=0; k<m1Count; k++)
     {
      timeM1[k]  = iTime(Symbol(), PERIOD_M1, k);
      openM1[k]  = iOpen(Symbol(), PERIOD_M1, k);
      highM1[k]  = iHigh(Symbol(), PERIOD_M1, k);
      lowM1[k]   = iLow(Symbol(),  PERIOD_M1, k);
      closeM1[k] = iClose(Symbol(),PERIOD_M1, k);
      volM1[k]   = iVolume(Symbol(),PERIOD_M1, k);
     }
  //--- агрегация М1-баров в нужный таймфрейм
   PrintFormat("%s | шаг 7: агрегация М1-баров в нужный таймфрейм", __FUNCTION__);
   PrintFormat("%s | агрегация М1-баров в нужный таймфрейм: m1Count=%d", __FUNCTION__, m1Count);
   barBuilder.Build(timeM1, openM1, highM1, lowM1, closeM1, volM1, m1Count);
   barBuilder.PrintTimeAgg();
   int barsCount = barBuilder.BarsCount();
  
   //--- массив закрытий агрегированных баров
   PrintFormat("%s | шаг 8: массив закрытий агрегированных баров", __FUNCTION__);
   double closeAgg[];
   ArrayResize(closeAgg, barsCount);
   ArraySetAsSeries(closeAgg, true);
   for(int j = 0; j < barsCount; j++)
      closeAgg[j] = barBuilder.GetClose(j);
  
   //--- быстрый и медленный EMA
   PrintFormat("%s | шаг 9: быстрый и медленный EMA", __FUNCTION__);
   double emaFast[], emaSlow[];
   ArrayResize(emaFast, barsCount);
   ArrayResize(emaSlow, barsCount);
   ArraySetAsSeries(emaFast, true);
   ArraySetAsSeries(emaSlow, true);
   for(int j = 0; j < barsCount; j++)
     {
      emaFast[j] = iMAOnArray(closeAgg, barsCount, OsMA_FastEMA, 0, MODE_EMA, j);
      emaSlow[j] = iMAOnArray(closeAgg, barsCount, OsMA_SlowEMA, 0, MODE_EMA, j);
     }
  
   //--- raw OsMA и сигнальная SMA
   PrintFormat("%s | шаг 10: raw OsMA и сигнальная SMA", __FUNCTION__);
   double rawOsMA[], signalSMA[];
   ArrayResize(rawOsMA, barsCount);
   ArrayResize(signalSMA, barsCount);
   ArraySetAsSeries(rawOsMA, true);
   ArraySetAsSeries(signalSMA, true);
   for(int j = 0; j < barsCount; j++)
     {
      rawOsMA[j] = emaFast[j] - emaSlow[j];
      signalSMA[j] = iMAOnArray(rawOsMA, barsCount, OsMA_SignalSMA, 0, MODE_SMA, j);
     }
  
   //--- итоговый OsMA для агрегированных баров
   PrintFormat("%s | шаг 11: итоговый OsMA для агрегированных баров", __FUNCTION__);
   double osmaAgg[];
   ArrayResize(osmaAgg, barsCount);
   ArraySetAsSeries(osmaAgg, true);
   for(int j = 0; j < barsCount; j++)
      osmaAgg[j] = rawOsMA[j] - signalSMA[j];
  
   //--- записываем в выходной буфер на каждом баре текущего TF (универсальный TF)
   PrintFormat("%s | шаг 12: записываем в выходной буфер на каждом баре текущего TF (универсальный TF)", __FUNCTION__);
  int periodSec = TimeFrame * 60;
   for(int i = start; i < rates_total; i++)
     {
      datetime barTime = time[i];
      datetime bucketStart = (datetime)(((long)barTime / periodSec) * periodSec);
      int idxAgg = -1;
      for(int j = 0; j < barsCount; j++)
        {
         PrintFormat("barBuilder.GetTime(%d)=%s bucketStart=%s", j, TimeToString(barBuilder.GetTime(j), TIME_DATE|TIME_SECONDS), TimeToString(bucketStart, TIME_DATE|TIME_SECONDS));
         if(bucketStart == barBuilder.GetTime(j))
           {
            idxAgg = j;
            break;
           }
        }
      if(idxAgg >= 0)
         OsMA_Buffer[i] = osmaAgg[idxAgg];
      else
         OsMA_Buffer[i] = EMPTY_VALUE;
      if(enableDebug && i < start + 5)
         PrintFormat("MapBar[%d]: barTime=%s bucketStart=%s idxAgg=%d osma=%s",
               i,
               TimeToString(barTime, TIME_DATE|TIME_SECONDS),
               TimeToString(bucketStart, TIME_DATE|TIME_SECONDS),
               idxAgg,
               idxAgg>=0 ? DoubleToString(osmaAgg[idxAgg], 5) : "EMPTY");
     }
  
   //--- отладочный вывод первых 5 значений агрегированного OsMA
   PrintFormat("%s | шаг 13: отладочный вывод первых 5 значений агрегированного OsMA", __FUNCTION__);
   if(enableDebug)
     for(int j = 0; j < MathMin(5, barsCount); j++)
        PrintFormat("AggOsMA[%d] = %s", j, DoubleToString(osmaAgg[j], 5));
  
   return(rates_total);
  }
//+------------------------------------------------------------------+ 