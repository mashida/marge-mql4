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
                     CBarStorage(void){}
                    ~CBarStorage(void){}

   datetime          timeOpen;
   datetime          timeOpenReal;
   datetime          timeHigh;
   datetime          timeLow;
   datetime          timeClose;
   datetime          timeOpenNext;
   double            open;
   double            high;
   double            low;
   double            close;

   string            BarToString();
   double            GetPrice(ENUM_APPLIED_PRICE price);
  };

string CBarStorage::BarToString()
  {
   return StringConcatenate("OPEN_",DoubleToString(open,_Digits)," at ",timeOpen,
                           " CLOSE_",DoubleToString(close,_Digits)," at ",timeClose,
                           " timeOpenNext_",timeOpenNext);
  }

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
   int               dayStartHour;
   int               periodInMinutes;
   int               periodInSeconds;
   CBarStorage       *curBar;
   CBarStorage       *preBar;
   CList             rates;
   MqlDateTime       timeWeekStart;
   datetime          curWeekStart;

public:
                     CHTF(void)
     {
      dayStartHour=0;
      periodInMinutes=60;
      periodInSeconds=periodInMinutes*60;
      curBar=NULL;
      preBar=NULL;
     }
                    ~CHTF(void){}

   void              saveInputs(int _dayStartHour,int _periodMinutes)
     {
      dayStartHour   = _dayStartHour;
      periodInMinutes= _periodMinutes;
      periodInSeconds= periodInMinutes*60;
     }

   void              OnInitCalc()
     {
      rates.Clear();
      curBar = new CBarStorage;
      BarToRates(*curBar);
     }

   void              Calc(const int rates_total,const int prev_calculated);
   void              BarToRates(CBarStorage &bar)
     {
      rates.Insert(&bar,0);
     }
   datetime          TimeWeekStart(datetime TIME,MqlDateTime &start,int hour)
     {
      TimeToStruct(TIME,start);
      start.hour=hour;
      start.min=0;
      start.sec=0;
      return StructToTime(start) - start.day_of_week*86400;
     }
   void              NewBarSet(int i,CBarStorage &bar,int sec)
     {
      curWeekStart   = TimeWeekStart(Time[i],timeWeekStart,dayStartHour);
      int nFullBars  = (int)(Time[i]-curWeekStart)/sec;
      bar.timeOpenReal = curWeekStart + nFullBars*sec;
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
   datetime          getCurrentBarTimeOpen()
     {
      CBarStorage *curNode=rates.GetNodeAtIndex(0);
      return(curNode.timeOpen);
     }
   void              GetOHLC(datetime &time[],double &open[],double &high[],double &low[],double &close[]);
  };

void CHTF::Calc(const int RATES_TOTAL,const int PREV_CALCULATED)
  {
   int nNewBars = RATES_TOTAL - PREV_CALCULATED;
   if(nNewBars==0)
     {
      curBar.timeClose = Time[0];
      curBar.close     = Close[0];
      if(NormalizeDouble(High[0]-curBar.high,_Digits)>0)
        {
         curBar.timeHigh = Time[0];
         curBar.high     = High[0];
        }
      if(NormalizeDouble(curBar.low-Low[0],_Digits)>0)
        {
         curBar.timeLow = Time[0];
         curBar.low     = Low[0];
        }
     }
   else if(nNewBars==1)
     {
      if(Time[0]>=curBar.timeOpenNext)
        {
         preBar=curBar;
         curBar = new CBarStorage;
         curBar.Prev(preBar);
         NewBarSet(0,*curBar,periodInSeconds);
         BarToRates(*curBar);
        }
     }
   else if(nNewBars>1)
     {
      rates.Clear();
      curBar = new CBarStorage;
      BarToRates(*curBar);
      int i = RATES_TOTAL - 1;
      NewBarSet(i,*curBar,periodInSeconds);
      for(i--; i>=0; i--)
        {
         if(Time[i]>=curBar.timeOpenNext)
           {
            curBar = new CBarStorage;
            NewBarSet(i,*curBar,periodInSeconds);
            BarToRates(*curBar);
           }
         curBar.timeClose = Time[i];
         curBar.close     = Close[i];
         if(NormalizeDouble(High[i]-curBar.high,_Digits)>0)
           {
            curBar.timeHigh = Time[i];
            curBar.high     = High[i];
           }
         if(NormalizeDouble(curBar.low-Low[i],_Digits)>0)
           {
            curBar.timeLow = Time[i];
            curBar.low     = Low[i];
           }
        }
     }
  }

void CHTF::GetOHLC(datetime &time[],double &open[],double &high[],double &low[],double &close[])
  {
   int n = rates.Total();
   ArrayResize(time,n);
   ArrayResize(open,n);
   ArrayResize(high,n);
   ArrayResize(low,n);
   ArrayResize(close,n);
   ArraySetAsSeries(time,true);
   ArraySetAsSeries(open,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);
   for(int i=0;i<n;i++)
     {
      CBarStorage *b = rates.GetNodeAtIndex(i);
      time[i]  = b.timeOpen;
      open[i]  = b.open;
      high[i]  = b.high;
      low[i]   = b.low;
      close[i] = b.close;
     }
  }

#endif // __HTF_MQH__
