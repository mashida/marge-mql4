//+------------------------------------------------------------------+
//| OsmaOnArray.mqh                                                  |
//| Helper class to compute OsMA on small arrays using iMAOnArray    |
//+------------------------------------------------------------------+
#ifndef __OSMAONARRAY_MQH__
#define __OSMAONARRAY_MQH__
#property strict

//+------------------------------------------------------------------+
//| OsMA calculation on array                                        |
//+------------------------------------------------------------------+
class COsMAOnArray
  {
private:
   int m_fast;    // Fast EMA period
   int m_slow;    // Slow EMA period
   int m_signal;  // Signal SMA period

public:
   // Инициализация периодов
   void Init(int fast,int slow,int signal);

   // Расчёт OsMA по буферу close
   int  OnCalculate(const int rates_total,
                    const int prev_calculated,
                    const double &close[],
                    double &osma[]);
  };

//+------------------------------------------------------------------+
//| Инициализация                                       |
//+------------------------------------------------------------------+
void COsMAOnArray::Init(int fast,int slow,int signal)
  {
   m_fast   = fast;
   m_slow   = slow;
   m_signal = signal;
  }

//+------------------------------------------------------------------+
//| Основной расчёт OsMA                               |
//+------------------------------------------------------------------+
int COsMAOnArray::OnCalculate(const int rates_total,
                              const int prev_calculated,
                              const double &close[],
                              double &osma[])
  {
   int start = prev_calculated>0 ? prev_calculated-1 : 0;

   static double raw[];
   ArrayResize(raw,rates_total);
   ArraySetAsSeries(raw,true);

   double arrFast[];
   double arrSlow[];
   double arrSignal[];
   ArrayResize(arrFast,m_fast);
   ArrayResize(arrSlow,m_slow);
   ArrayResize(arrSignal,m_signal);
   ArraySetAsSeries(arrFast,true);
   ArraySetAsSeries(arrSlow,true);
   ArraySetAsSeries(arrSignal,true);

   for(int i=start;i<rates_total;i++)
     {
      if(i+m_slow>rates_total)
        {
         raw[i]=EMPTY_VALUE;
         continue;
        }
      for(int j=0;j<m_fast;j++)
         arrFast[j] = close[i+j];
      double emaFast = iMAOnArray(arrFast,m_fast,m_fast,0,MODE_EMA,0);
      for(int j=0;j<m_slow;j++)
         arrSlow[j] = close[i+j];
      double emaSlow = iMAOnArray(arrSlow,m_slow,m_slow,0,MODE_EMA,0);
      raw[i] = emaFast - emaSlow;
     }

   for(int i=start;i<rates_total;i++)
     {
      if(raw[i]==EMPTY_VALUE || i+m_signal>rates_total)
        {
         osma[i]=EMPTY_VALUE;
         continue;
        }
      for(int j=0;j<m_signal;j++)
         arrSignal[j]=raw[i+j];
      double signal = iMAOnArray(arrSignal,m_signal,m_signal,0,MODE_SMA,0);
      osma[i] = raw[i] - signal;
     }
   return(rates_total);
  }

#endif // __OSMAONARRAY_MQH__
