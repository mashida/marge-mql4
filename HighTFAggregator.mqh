//+------------------------------------------------------------------+
//|               HighTfAggregator.mqh                               |
//|     Поточная агрегация OHLC старшего TF без хранения истории     |
//+------------------------------------------------------------------+
#property strict

//+------------------------------------------------------------------+
//| Класс для одного агрегированного бара                            |
//+------------------------------------------------------------------+
class CBarStorage
{
public:
   datetime timeOpenReal;   // начало окна
   datetime timeOpenNext;   // конец окна
   double   open, high, low, close;
   datetime timeOpen, timeHigh, timeLow, timeClose;

   // Сброс перед первой обработкой
   void Reset()
   {
      timeOpenReal = 0;
      timeOpenNext = 0;
      open = high = low = close = 0.0;
      timeOpen = timeHigh = timeLow = timeClose = 0;
   }

   // Обработка одного бара текущего TF
   // возвращает true при смене окна (новый агрегат)
   bool ProcessBar(int idx, int periodSeconds)
   {
      datetime t = Time[idx];
      datetime newOpen = (t/periodSeconds)*periodSeconds;
      if(newOpen != timeOpenReal)
      {
         timeOpenReal = newOpen;
         timeOpenNext = newOpen + periodSeconds;
         timeOpen  = t;
         timeHigh  = t;
         timeLow   = t;
         timeClose = t;
         open  = Open[idx];
         high  = High[idx];
         low   = Low[idx];
         close = Close[idx];
         return(true);
      }
      if(High[idx] > high)  { high = High[idx]; timeHigh = t; }
      if(Low[idx]  < low )  { low  = Low[idx];  timeLow  = t; }
      close    = Close[idx];
      timeClose= t;
      return(false);
   }
};

//+------------------------------------------------------------------+
//| Класс-агрегатор старшего TF (без хранения прошлого)              |
//+------------------------------------------------------------------+

class CHighTfAggregator
{
private:
   int         periodSeconds;  // длина окна в секундах
   CBarStorage curBar;         // текущий агрегированный бар

public:
   // Инициализация: targetTfMinutes — целевой TF в минутах
   void Init(int targetTfMinutes)
   {
      periodSeconds = targetTfMinutes * 60;
      curBar.Reset();
   }

   // Поточный расчёт
   // rates_total      - общее число баров текущего TF
   // prev_calculated - число уже обработанных баров
   // buffer[]         - выходной буфер (close текущего агрегата)
   int Calculate(const int rates_total,
                 const int prev_calculated,
                 double &buffer[])
   {
      int start = prev_calculated > 0 ? prev_calculated - 1 : 0;
      for(int i = start; i < rates_total; i++)
      {
         // обновляем текущий агрегат
         curBar.ProcessBar(i, periodSeconds);

         // записываем close в буфер
         buffer[i] = curBar.close;

         // если TF не совпадает с текущим, растягиваем до конца окна
         if(periodSeconds != _Period * 60)
         {
            for(int j = i+1; j < rates_total; j++)
            {
               if(Time[j] < curBar.timeOpenNext)
                  buffer[j] = buffer[i];
               else
                  break;
            }
         }
      }
      return(rates_total);
   }
};

//+------------------------------------------------------------------+
//| End of HighTfAggregator.mqh                                      |
//+------------------------------------------------------------------+
