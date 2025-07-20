//+------------------------------------------------------------------+
//|                                                    BarBuilder.mqh |
//|  Класс для агрегации М1-баров в бары произвольного таймфрейма  |
//+------------------------------------------------------------------+
#ifndef __BARBUILDER_MQH__
#define __BARBUILDER_MQH__

class CBarBuilder
  {
private:
   int         m_periodSec;      // период агрегации в секундах
   int         m_timeShiftSec;   // смещение старта бара в секундах
   int         m_ratesTotal;     // кол-во входных М1-баров
   int         m_barsCount;      // кол-во агрегированных баров

   // внутренние массивы для входных М1-данных
   datetime    m_timeIn[];
   double      m_openIn[];
   double      m_highIn[];
   double      m_lowIn[];
   double      m_closeIn[];
   long        m_volumeIn[];

   // выходные массивы — агрегированные бары
   datetime    m_timeAgg[];
   double      m_openAgg[];
   double      m_highAgg[];
   double      m_lowAgg[];
   double      m_closeAgg[];
   long        m_volumeAgg[];
   
public:
   // Инициализация: период в минутах, смещение в минутах (по умолчанию 0)
   bool Initialize(int periodMinutes, int timeShiftMinutes=0)
   {
      m_periodSec    = periodMinutes * 60;
      m_timeShiftSec = timeShiftMinutes * 60;  // переводим минуты в секунды
      m_barsCount    = 0;
      m_ratesTotal   = 0;
      return(true);
   }

   // Собрать агрегированные бары из входных М1-массивов
   void Build(const datetime &timeArr[], const double &openArr[], const double &highArr[],
              const double &lowArr[],  const double &closeArr[], const long &volumeArr[],
              int rates_total)
   {
      PrintFormat("%s | INFO: rates_total=%d", __FUNCTION__, rates_total);
      // копируем входные массивы
      ArrayCopy(m_timeIn,   timeArr);
      ArrayCopy(m_openIn,   openArr);
      ArrayCopy(m_highIn,   highArr);
      ArrayCopy(m_lowIn,    lowArr);
      ArrayCopy(m_closeIn,  closeArr);
      ArrayCopy(m_volumeIn, volumeArr);
      m_ratesTotal = rates_total;

      // подготавливаем выходные массивы максимального размера
      ArrayResize(m_timeAgg,    m_ratesTotal);
      ArrayResize(m_openAgg,    m_ratesTotal);
      ArrayResize(m_highAgg,    m_ratesTotal);
      ArrayResize(m_lowAgg,     m_ratesTotal);
      ArrayResize(m_closeAgg,   m_ratesTotal);
      ArrayResize(m_volumeAgg,  m_ratesTotal);

      m_barsCount = 0;
      int   lastBucket = 0;

      // итерируем от старых к новым: rates_total-1 → 0
      for(int idx = m_ratesTotal - 1; idx >= 0; idx--)
      {
         datetime t = m_timeIn[idx];
         // вычисляем номер временного блока
         double raw = ((double)t - m_timeShiftSec) / m_periodSec;
         int bucket = (int)MathFloor(raw);
         PrintFormat("%s | raw=%s | bucket=%d | lastBucket=%d | t=%s | m_timeShiftSec=%d | m_periodSec=%d", __FUNCTION__, DoubleToString(raw, 5), bucket, lastBucket, TimeToString(t, TIME_DATE|TIME_SECONDS), m_timeShiftSec, m_periodSec);

         if(m_barsCount == 0 || bucket != lastBucket)
         {
            PrintFormat("%s | новый аггрегированный бар: idx=%d | m_barsCount=%d | bucket=%d", __FUNCTION__, idx, m_barsCount, bucket);
            // новый аггрегированный бар
            datetime startTime = (datetime)(bucket * m_periodSec + m_timeShiftSec);
            m_timeAgg[m_barsCount]   = startTime;
            PrintFormat("%s | INFO: m_timeAgg[%d]=%s", __FUNCTION__, m_barsCount, TimeToString(m_timeAgg[m_barsCount], TIME_DATE|TIME_SECONDS));
            m_openAgg[m_barsCount]   = m_openIn[idx];
            m_highAgg[m_barsCount]   = m_highIn[idx];
            m_lowAgg[m_barsCount]    = m_lowIn[idx];
            m_closeAgg[m_barsCount]  = m_closeIn[idx];
            m_volumeAgg[m_barsCount] = m_volumeIn[idx];

            lastBucket = bucket;
            m_barsCount++;
        }
      else
        {
            PrintFormat("%s | обновляем текущий агрегированный бар: m_barsCount=%d", __FUNCTION__, m_barsCount);
            // обновляем текущий агрегированный бар
            int pos = m_barsCount - 1;
            m_highAgg[pos]   = MathMax(m_highAgg[pos],   m_highIn[idx]);
            m_lowAgg[pos]    = MathMin(m_lowAgg[pos],    m_lowIn[idx]);
            m_closeAgg[pos]  = m_closeIn[idx];
            m_volumeAgg[pos] = m_volumeAgg[pos] + m_volumeIn[idx];
         }
      }

      // устанавливаем как временные ряды
      ArrayResize(m_timeAgg, m_barsCount);
      ArraySetAsSeries(m_timeAgg, true);
   }

   // Получить кол-во агрегированных баров
   int BarsCount() const
   {
      return(m_barsCount);
   }

   // Получить поля агрегированного бара по индексу (0 — текущий бар)
   datetime GetTime(int bar)    const { 
      if(bar < 0 || bar >= ArraySize(m_timeAgg))
      {
         PrintFormat("%s | ERROR: bar=%d | ArraySize(m_timeAgg)=%d", __FUNCTION__, bar, ArraySize(m_timeAgg));
         return(0);
      }
      return(m_timeAgg[bar]); }
   
   // Функция вывода на экран всего массива m_timeAgg
   void PrintTimeAgg() const
   {
      PrintFormat("%s | Вывод массива m_timeAgg: ArraySize(m_timeAgg)=%d", __FUNCTION__, ArraySize(m_timeAgg));
      for(int i = 0; i < ArraySize(m_timeAgg); i++)
      {
         PrintFormat("%s | INFO: m_timeAgg[%d]=%s", __FUNCTION__, i, TimeToString(m_timeAgg[i], TIME_DATE|TIME_SECONDS));
      }
   }
   
   double   GetOpen(int bar)    const { return(m_openAgg[bar]); }
   double   GetHigh(int bar)    const { return(m_highAgg[bar]); }
   double   GetLow(int bar)     const { return(m_lowAgg[bar]); }
   double   GetClose(int bar)   const { return(m_closeAgg[bar]); }
   long     GetVolume(int bar)  const { return(m_volumeAgg[bar]); }

   // Очистить данные
   void Clear()
   {
      m_barsCount  = 0;
      m_ratesTotal = 0;
      ArrayFree(m_timeAgg);
      ArrayFree(m_openAgg);
      ArrayFree(m_highAgg);
      ArrayFree(m_lowAgg);
      ArrayFree(m_closeAgg);
      ArrayFree(m_volumeAgg);
   }
};

#endif // __BARBUILDER_MQH__