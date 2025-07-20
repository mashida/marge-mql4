//+------------------------------------------------------------------+
//| htf.mqh                                                          |
//| Refactored from ifx-ama.mqh to build higher timeframe OHLC       |
//+------------------------------------------------------------------+
#ifndef __HTF_MQH__
#define __HTF_MQH__

#include <Arrays/List.mqh>

//+------------------------------------------------------------------+
//| Structure to store one bar                                       |
//+------------------------------------------------------------------+
class CBarStorage : public CObject
  {
public:
                     CBarStorage(void);
                    ~CBarStorage(void);

   datetime          timeOpen;      // время открытия бара
   datetime          timeOpenReal;  // нормализованное время открытия
   datetime          timeHigh;      // время максимума
   datetime          timeLow;       // время минимума
   datetime          timeClose;     // время закрытия
   datetime          timeOpenNext;  // время начала следующего бара
   double            open;          // цена открытия
   double            high;          // максимум
   double            low;           // минимум
   double            close;         // цена закрытия

//+------------------------------------------------------------------+
//| Получить строковое представление бара                            |
//+------------------------------------------------------------------+
   string            BarToString();

//+------------------------------------------------------------------+
//| Вернуть цену по типу (open, high, low, close и т.д.)             |
//+------------------------------------------------------------------+
  double            GetPrice(ENUM_APPLIED_PRICE price);
  };

//+------------------------------------------------------------------+
//| Конструктор                                                      |
//+------------------------------------------------------------------+
CBarStorage::CBarStorage(void)
  {
  }

//+------------------------------------------------------------------+
//| Деструктор                                                       |
//+------------------------------------------------------------------+
CBarStorage::~CBarStorage(void)
  {
  }

//+------------------------------------------------------------------+
//| Возвращает строковое описание бара                               |
//+------------------------------------------------------------------+
string CBarStorage::BarToString()
  {
   return StringConcatenate("OPEN_",DoubleToString(open,_Digits)," at ",timeOpen,
                           " CLOSE_",DoubleToString(close,_Digits)," at ",timeClose,
                           " timeOpenNext_",timeOpenNext);
  }

//+------------------------------------------------------------------+
//| Возвращает цену бара в зависимости от типа цены                  |
//+------------------------------------------------------------------+
double CBarStorage::GetPrice(ENUM_APPLIED_PRICE price)
  {
   double res = close;
   if(price==PRICE_HIGH)          res = high;
   else if(price==PRICE_LOW)      res = low;
   else if(price==PRICE_MEDIAN)   res = (high+low)/2.0;
   else if(price==PRICE_OPEN)     res = open;
   else if(price==PRICE_TYPICAL)  res = (high+low+close)/3.0;
   else if(price==PRICE_WEIGHTED) res = (high+low+close+close)/4.0;
   return(res);
  }

//+------------------------------------------------------------------+
//| Higher timeframe builder                                         |
//+------------------------------------------------------------------+
class CHTF
  {
private:
   int               m_dayStartHour;      // час начала торгового дня
   int               m_periodMinutes;     // длительность HTF-бара в минутах
   int               m_periodSeconds;     // длительность HTF-бара в секундах
   CBarStorage       *m_currentBar;       // указатель на текущий бар
   CBarStorage       *m_previousBar;      // указатель на предыдущий бар
   CList             m_rates;             // список сформированных баров
   MqlDateTime       m_timeWeekStart;     // вспомогательная структура времени
   datetime          m_currentWeekStart;  // время начала текущей недели

public:
                     CHTF(void);
                    ~CHTF(void);

//+------------------------------------------------------------------+
//| Сохранить входные параметры агрегации                            |
//+------------------------------------------------------------------+
   void              SaveInputs(int dayStartHour,int periodMinutes);

//+------------------------------------------------------------------+
//| Очистить накопленные бары и создать стартовый бар                |
//+------------------------------------------------------------------+
   void              OnInitCalc();

//+------------------------------------------------------------------+
//| Основной расчёт агрегированных баров                             |
//+------------------------------------------------------------------+
   void              Calc(const int rates_total,const int prev_calculated);

//+------------------------------------------------------------------+
//| Поместить бар в список сформированных баров                      |
//+------------------------------------------------------------------+
   void              BarToRates(CBarStorage &bar);

//+------------------------------------------------------------------+
//| Вычислить начало недели для заданного времени                    |
//+------------------------------------------------------------------+
   datetime          TimeWeekStart(datetime TIME,MqlDateTime &start,int hour);

//+------------------------------------------------------------------+
//| Заполнить структуру bar данными из i-го тика                     |
//+------------------------------------------------------------------+
   void              NewBarSet(int i,CBarStorage &bar,int sec);

//+------------------------------------------------------------------+
//| Время открытия текущего бара                                     |
//+------------------------------------------------------------------+
   datetime          GetCurrentBarTimeOpen();

  };

//+------------------------------------------------------------------+
//| Конструктор                                                      |
//+------------------------------------------------------------------+
CHTF::CHTF(void)
  {
   m_dayStartHour   = 0;
   m_periodMinutes  = 60;
   m_periodSeconds  = m_periodMinutes*60;
   m_currentBar     = NULL;
   m_previousBar    = NULL;
  }

//+------------------------------------------------------------------+
//| Деструктор                                                       |
//+------------------------------------------------------------------+
CHTF::~CHTF(void)
  {
  }

//+------------------------------------------------------------------+
//| Сохранить входные параметры агрегации                            |
//+------------------------------------------------------------------+
void CHTF::SaveInputs(int dayStartHour,int periodMinutes)
  {
   m_dayStartHour   = dayStartHour;
   m_periodMinutes  = periodMinutes;
   m_periodSeconds  = m_periodMinutes*60;
  }

//+------------------------------------------------------------------+
//| Очистить накопленные бары и создать стартовый бар                |
//+------------------------------------------------------------------+
void CHTF::OnInitCalc()
  {
   m_rates.Clear();
   m_currentBar = new CBarStorage;
   BarToRates(*m_currentBar);
  }

//+------------------------------------------------------------------+
//| Поместить бар в список сформированных баров                      |
//+------------------------------------------------------------------+
void CHTF::BarToRates(CBarStorage &bar)
  {
   m_rates.Insert(&bar,0);
  }

//+------------------------------------------------------------------+
//| Вычислить начало недели для заданного времени                    |
//+------------------------------------------------------------------+
datetime CHTF::TimeWeekStart(datetime TIME,MqlDateTime &start,int hour)
  {
   TimeToStruct(TIME,start);
   start.hour=hour;
   start.min=0;
   start.sec=0;
   return StructToTime(start) - start.day_of_week*86400;
  }

//+------------------------------------------------------------------+
//| Заполнить структуру bar данными из i-го тика                     |
//+------------------------------------------------------------------+
void CHTF::NewBarSet(int i,CBarStorage &bar,int sec)
  {
   m_currentWeekStart = TimeWeekStart(Time[i],m_timeWeekStart,m_dayStartHour);
   int nFullBars  = (int)(Time[i]-m_currentWeekStart)/sec;
   bar.timeOpenReal = m_currentWeekStart + nFullBars*sec;
   bar.timeOpen     = Time[i];
   bar.open         = Open[i];
   bar.timeOpenNext = (datetime)bar.timeOpenReal + sec;
   bar.timeHigh     = bar.timeOpen;
   bar.high         = High[i];
   bar.timeLow      = bar.timeOpen;
   bar.low          = Low[i];
   bar.timeClose    = bar.timeOpen;
   bar.close        = Close[i];
  }

//+------------------------------------------------------------------+
//| Время открытия текущего бара                                     |
//+------------------------------------------------------------------+
datetime CHTF::GetCurrentBarTimeOpen()
  {
   CBarStorage *curNode=m_rates.GetNodeAtIndex(0);
   return(curNode.timeOpen);
  }

//+------------------------------------------------------------------+
//| Основной расчёт агрегированных баров                             |
//+------------------------------------------------------------------+
void CHTF::Calc(const int RATES_TOTAL,const int PREV_CALCULATED)
  {
   int nNewBars = RATES_TOTAL - PREV_CALCULATED;
   if(nNewBars==0)
     {
      m_currentBar.timeClose = Time[0];
      m_currentBar.close     = Close[0];
      if(NormalizeDouble(High[0]-m_currentBar.high,_Digits)>0)
        {
         m_currentBar.timeHigh = Time[0];
         m_currentBar.high     = High[0];
        }
      if(NormalizeDouble(m_currentBar.low-Low[0],_Digits)>0)
        {
         m_currentBar.timeLow = Time[0];
         m_currentBar.low     = Low[0];
        }
     }
   else if(nNewBars==1)
     {
      if(Time[0]>=m_currentBar.timeOpenNext)
        {
         m_previousBar=m_currentBar;
         m_currentBar = new CBarStorage;
         m_currentBar.Prev(m_previousBar);
         NewBarSet(0,*m_currentBar,m_periodSeconds);
         BarToRates(*m_currentBar);
        }
     }
   else if(nNewBars>1)
     {
      m_rates.Clear();
      m_currentBar = new CBarStorage;
      BarToRates(*m_currentBar);
      int i = RATES_TOTAL - 1;
      NewBarSet(i,*m_currentBar,m_periodSeconds);
      for(i--; i>=0; i--)
        {
         if(Time[i]>=m_currentBar.timeOpenNext)
           {
            m_currentBar = new CBarStorage;
            NewBarSet(i,*m_currentBar,m_periodSeconds);
            BarToRates(*m_currentBar);
           }
         m_currentBar.timeClose = Time[i];
         m_currentBar.close     = Close[i];
         if(NormalizeDouble(High[i]-m_currentBar.high,_Digits)>0)
           {
            m_currentBar.timeHigh = Time[i];
            m_currentBar.high     = High[i];
           }
         if(NormalizeDouble(m_currentBar.low-Low[i],_Digits)>0)
           {
            m_currentBar.timeLow = Time[i];
            m_currentBar.low     = Low[i];
           }
        }
     }
  }


//+------------------------------------------------------------------+
//| Copy close prices of HTF bars to buffer                           |
//+------------------------------------------------------------------+
void CHTF::CopyCloseBuffer(int rates_total,double &buffer[])
  {
   ArrayResize(buffer,rates_total);
   ArraySetAsSeries(buffer,true);

   CBarStorage *cur=m_rates.GetNodeAtIndex(0);
   for(int i=0;i<rates_total;i++)
     {
      datetime t=Time[i];
      while(cur.Prev()!=NULL && t<cur.timeOpenReal)
         cur=cur.Prev();
      buffer[i]=cur.close;
     }
  }


#endif // __HTF_MQH__
