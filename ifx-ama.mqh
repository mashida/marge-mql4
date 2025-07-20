//+------------------------------------------------------------------+
//| ifx-ama.mqh                                                     |
//| Copyright 2025, Никита Сердитов                                 |
//| https://t.me/mashida                                            |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Никита Сердитов"
#property link      "https://t.me/mashida"

#include <Arrays/List.mqh>

enum ENUM_MA_MODE_BAR_PRICE
  {
   MA_MODE_LAST_BAR_PRICE,
   MA_MODE_REAL_BAR_PRICE
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CBarStorage : public CObject
  {
public:
                     CBarStorage(void) {};
                    ~CBarStorage(void) {};

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

   double            abs;//MathAbs(Price(i)-Price(i+1));
   double            ama;
   double            noise;
   double            er;
   double            priceI;
   double            preAma;

   double            GetPrice(ENUM_APPLIED_PRICE APPLIED_PRICE);
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string CBarStorage::BarToString()
  {
   return StringConcatenate("OPEN_", DoubleToString(open, _Digits), " at ", timeOpen
//," HIGH_",DoubleToString(BAR.high,_Digits)," at ",BAR.timeHigh
//," LOW_",DoubleToString(BAR.low,_Digits)," at ",BAR.timeLow
                            , " CLOSE_", DoubleToString(close, _Digits), " at ", timeClose
                            , " timeOpenNext_", timeOpenNext
                           );
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CBarStorage::GetPrice(ENUM_APPLIED_PRICE APPLIED_PRICE)
  {
   double price = close;
   if(APPLIED_PRICE == PRICE_HIGH)
      price = high;
   else
      if(APPLIED_PRICE == PRICE_LOW)
         price = low;
      else
         if(APPLIED_PRICE == PRICE_MEDIAN)
            price = (high + low) / 2;
         else
            if(APPLIED_PRICE == PRICE_OPEN)
               price = open;
            else
               if(APPLIED_PRICE == PRICE_TYPICAL)
                  price = (high + low + close) / 3;
               else
                  if(APPLIED_PRICE == PRICE_WEIGHTED)
                     price = (high + low + close + close) / 4;
   return price;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CMain
  {
   //--- input parameters
   bool              displayComment;
   int               periodAMA;
   int               dayStartHour;
   bool              displayCommentRates;
   int               periodInSeconds;
   double            deltaFastSlow;
   double            G;
   double            slowSC;
   ENUM_MA_MODE_BAR_PRICE maModeBarPrice;
   string            maVAriables;
   int               periodInMinutes;
   double            dK;
   //--- usual parameters
   ENUM_APPLIED_PRICE maAppliedPrice;
   CBarStorage              *curBar, *preBar;
   CList             oRates;
   //SimpleBarArray    simpleBarArray;
   int               maxNBarsInRates;

   struct readyData
     {
      datetime          time0;
      double            arrPricesForMA[];
      double            arrABS[];
     };
   readyData         maReadyData;

   MqlDateTime       timeWeekStart;
   datetime          curWeekStart;
public:
                     CMain(void) {};
                    ~CMain(void) {};
   void              Calc(const int RATES_TOTAL, const int PREV_CALCULATED, const datetime TIME_BAR_OPEN,
                          double &AMAbuffer[], double &AmaUpBuffer[], double &AmaDownBuffer[],
                          double &AmaPunctureUpBuffer[],
                          double &AmaPunctureDownBuffer[]);

   void              OnInitCalc()
     {
      maxNBarsInRates = periodAMA + 1;
      ArrayResize(maReadyData.arrPricesForMA, maxNBarsInRates, 0);
      ArraySetAsSeries(maReadyData.arrPricesForMA, true);
      ArrayResize(maReadyData.arrABS, maxNBarsInRates, 0);
      ArraySetAsSeries(maReadyData.arrABS, true);
     };
   void              onInit();
   void              saveInputs(int _dayStartHour, int _PeriodInMinutes, string _maVAriables, int _periodAMA, ENUM_APPLIED_PRICE _maAppliedPrice,
                                double _G, double _dK, ENUM_MA_MODE_BAR_PRICE _maMode);

   void              BarToRates(CBarStorage &BAR, CList &RATES);
   datetime          TimeWeekStart(datetime TIME, MqlDateTime &TIME_DAY_START, int START_HOUR);
   void              NewBarSet(int I, CBarStorage &BAR, int PERIOD_SECONDS);
   string            ToString();
   void              DrawMyCustomMA(int I, const int RATES_TOTAL, CList &RATES, readyData &MA_DATA,
                                    double &AMAbuffer[], double &AmaUpBuffer[], double &AmaDownBuffer[],
                                    double &AmaPunctureUpBuffer[],
                                    double &AmaPunctureDownBuffer[]);

   void              setDeltaFastSlow(const double _fast = 0, const double _slow = 0.0) {slowSC = _slow; deltaFastSlow = _fast - _slow;};

   datetime          getCurrentBarTimeOpen();

  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CMain::onInit(void)
  {
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string CMain::ToString(void)
  {
   string ratesStr = "";
   if(displayCommentRates)
     {
      int nItems = oRates.Total();
      ratesStr = StringConcatenate("\noRates.Total()_", nItems, "/", maxNBarsInRates, " | ", EnumToString(maAppliedPrice) //," | ",EnumToString(maMethod)
                                  );
      CBarStorage *curNode;
      if(nItems > 0)
        {
         for(int i = 0; i < nItems; i++)
           {
            curNode = oRates.GetNodeAtIndex(i);
            StringAdd(ratesStr
                      , StringConcatenate("\n i", i, "/", oRates.IndexOf(curNode), " ", curNode.timeOpen
                                          //," Open_",DoubleToString(curNode.open,_Digits)
                                          //," Close_",DoubleToString(curNode.close,_Digits)
                                          //," maReadyPrice_",DoubleToString(maReadyData.arrPricesForMA[i],_Digits)
                                          , " abs_", DoubleToStr(curNode.abs, _Digits)
                                          , " noise_", DoubleToStr(curNode.noise, _Digits)
                                          , " er_", DoubleToStr(curNode.er, _Digits)
                                          , " ama_", DoubleToStr(curNode.ama, _Digits)
                                          , " price_", DoubleToStr(curNode.priceI, _Digits)
                                          , " preAMA_", DoubleToStr(curNode.preAma, _Digits)
                                         ));
           }
        }
     }
   return StringConcatenate(TimeCurrent(), " | curWeekStart ", curWeekStart, " | periodInSeconds_", periodInSeconds
                            , "\n", curBar.BarToString()
                            , ratesStr);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime CMain::getCurrentBarTimeOpen()
  {
   CBarStorage *curNode;
   curNode = oRates.GetNodeAtIndex(0);
   return curNode.timeOpen;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//datetime getCurrentBarTimeOpen()
//  {
//   return oMain.getCurrentBarTimeOpen();
//  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CMain::DrawMyCustomMA(int I, const int RATES_TOTAL, CList &RATES, readyData &MA_DATA,
                           double &AMAbuffer[], double &AmaUpBuffer[], double &AmaDownBuffer[], double &AmaPunctureUpBuffer[],
                           double &AmaPunctureDownBuffer[])
  {
   bool logging = false;
//PrintFormat("I: %d | RATES_TOTAL: %d | maxBarsInRates: %d | periodAMA: %d | rates.Total(): %d",
//              I, RATES_TOTAL, maxNBarsInRates, periodAMA, RATES.Total());
   if(RATES.Total() != maxNBarsInRates)
      return;
   CBarStorage *curNode = RATES.GetFirstNode();
   datetime bar0timeOpen = curBar.timeOpen;
   if(curNode.timeOpen == MA_DATA.time0)
      MA_DATA.arrPricesForMA[0] = curNode.GetPrice(maAppliedPrice);
   else //if(bar0.timeOpen!=MA_DATA.time0)
     {
      for(int i = 0, total = RATES.Total(); i < total; i++)
        {
         curNode = RATES.GetNodeAtIndex(i);
         MA_DATA.arrPricesForMA[i] = NormalizeDouble(curNode.GetPrice(maAppliedPrice), _Digits - 1);
         MA_DATA.arrABS[i] = curNode.abs;
        }
     }
   double Noise, ER;
   Noise = iMAOnArray(MA_DATA.arrABS, 0, periodAMA, 0, MODE_SMA, 0) * periodAMA;
   if(Noise != 0)
      ER = MathAbs(MA_DATA.arrPricesForMA[0] - MA_DATA.arrPricesForMA[periodAMA]) / Noise;
   else
      ER = 0;
   double SSC = MathPow(ER * deltaFastSlow + slowSC, G);
//PrintFormat("SSC calc: ER: %f, deltaFastSlow: %f, slowSC: %f, G: %f", ER, deltaFastSlow, slowSC, G);
   preBar = oRates.GetNodeAtIndex(1);
   curBar.preAma = preBar.ama;
   if(NormalizeDouble(curBar.preAma, _Digits) == 0)
     {
      curBar.preAma = MA_DATA.arrPricesForMA[0];
      //curBar.preAma=2147483647;
     }
   double curAMA = MA_DATA.arrPricesForMA[0] * SSC + curBar.preAma * (1 - SSC);
   AMAbuffer[I] = NormalizeDouble(curAMA, _Digits - 1); // MAIN BUFFER
   curBar = oRates.GetNodeAtIndex(0);
   curBar.ama = NormalizeDouble(curAMA, _Digits - 1);
   curBar.noise = Noise;
   curBar.er = ER;
   curBar.priceI = MA_DATA.arrPricesForMA[0];
//PrintFormat("%d:%s ama:%s | MA_DATA.arrPricesForMA[0]: %s, SSC: %s, curBar.preAma: %s",
//            I, TimeToString(iTime(_Symbol, PERIOD_CURRENT, I), TIME_DATE|TIME_SECONDS), DoubleToString(AMAbuffer[I], _Digits),
//            DoubleToString(MA_DATA.arrPricesForMA[0], _Digits), DoubleToString(SSC, _Digits), DoubleToString(curBar.preAma, _Digits));
//---
//simpleBarArray.eraseArray();
//--- saving all data to the current bar of the higher timeframe
//    based on the last data of the higher timeframe
   if(maModeBarPrice == MA_MODE_LAST_BAR_PRICE)
     {
      if(logging)
         PrintFormat("%s | periodInMinutes = %d | _Period = %d",
                     __FUNCTION__, periodInMinutes, _Period);
      if(periodInMinutes != _Period)
        {
         for(int j = I + 1, _total = RATES_TOTAL; j < _total; j++)
           {
            if(bar0timeOpen > Time[j])
               break;
            AMAbuffer[j] = AMAbuffer[I];
            if(I == 0)
               continue;
            if(curBar.ama > preBar.ama)
              {
               AmaUpBuffer[j] = AMAbuffer[j];
               AmaDownBuffer[j] = EMPTY_VALUE;
              }
            else
               if(curBar.ama < preBar.ama)
                 {
                  AmaDownBuffer[j] = AMAbuffer[I];
                  AmaUpBuffer[j] = EMPTY_VALUE;
                 }
               else
                 {
                  AmaDownBuffer[j] = EMPTY_VALUE;
                  AmaUpBuffer[j] = EMPTY_VALUE;
                 }
            //---
            //simpleBarArray.addNewElement(AMAbuffer[j], Time[j]);
           }
        }
      else
        {
         if(AMAbuffer[I + 1] > AMAbuffer[I])
           {
            if(logging)
               PrintFormat("ama going down: ama[%d][%f] | ama[%d][%f]",
                           I + 1, AMAbuffer[I + 1], I, AMAbuffer[I]);
            AmaDownBuffer[I] = AMAbuffer[I];
           }
         else
            if(AMAbuffer[I + 1] < AMAbuffer[I])
              {
               if(logging)
                  PrintFormat("ama going down: ama[%d][%f] | ama[%d][%f]",
                              I + 1, AMAbuffer[I + 1], I, AMAbuffer[I]);
               AmaUpBuffer[I] = AMAbuffer[I];
              }
        }
      //---
      //Print(simpleBarArray.getAllElementsAsString());
     }
//--- calculating puncture on the [1] bar of the current timeframe
   if(I == 0)
      return;
   double close_1 = NormalizeDouble(iClose(_Symbol, PERIOD_CURRENT, I), _Digits - 1);
   double close_2 = NormalizeDouble(iClose(_Symbol, PERIOD_CURRENT, I + 1), _Digits - 1);
   if(logging)
      PrintFormat("%s | %s | ama[I+1][%f] - close[I+1][%f] | ama[I][%f] - close[I][%f]",
                  __FUNCTION__, TimeToString(iTime(_Symbol, PERIOD_CURRENT, I)),
                  AMAbuffer[I + 1], close_2, AMAbuffer[I], close_1);
   if(AMAbuffer[I + 1] >= close_2 && AMAbuffer[I] <= close_1)
     {
      //--- this is puncture up
      AmaPunctureUpBuffer[I] = NormalizeDouble(iLow(_Symbol, PERIOD_CURRENT, I), _Digits);
      if(logging)
        {
         PrintFormat("%s | we have puncture up at %s", __FUNCTION__, TimeToString(iTime(_Symbol, PERIOD_CURRENT, I)));
        }
     }
   else
      if(AMAbuffer[I + 1] <= close_2 && AMAbuffer[I] >= close_1)
        {
         //--- this is puncture down
         AmaPunctureDownBuffer[I] = NormalizeDouble(iHigh(_Symbol, PERIOD_CURRENT, I), _Digits);
         if(logging)
           {
            PrintFormat("%s | we have puncture down at %s", __FUNCTION__, TimeToString(iTime(_Symbol, PERIOD_CURRENT, I)));
           }
        }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CMain::BarToRates(CBarStorage &BAR, CList &RATES)
  {
   RATES.Insert(&BAR, 0);
//PrintFormat("added bar [%s] to rates", TimeToString(BAR.timeOpen), TIME_DATE|TIME_SECONDS);
   if(RATES.Total() > maxNBarsInRates)
      RATES.Delete(RATES.Total() - 1);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CMain::NewBarSet(int I, CBarStorage &BAR, int PERIOD_SECONDS)
  {
   curWeekStart = TimeWeekStart(Time[I], timeWeekStart, dayStartHour);
   int nFullBars = (int)(Time[I] - curWeekStart) / PERIOD_SECONDS;
   BAR.timeOpenReal = curWeekStart + nFullBars * PERIOD_SECONDS;
   BAR.timeOpen = Time[I];
   BAR.open = Open[I];
   BAR.timeOpenNext = (datetime)BAR.timeOpenReal + PERIOD_SECONDS;
   BAR.timeHigh = BAR.timeOpen;
   BAR.high = High[I];
   BAR.timeLow = BAR.timeOpen;
   BAR.low = Low[I];
   BAR.timeClose = BAR.timeOpen;
   BAR.close = Close[I];
   BAR.abs = 0;
   BAR.noise = 0;
   BAR.er = 0;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CMain::Calc(const int RATES_TOTAL, const int PREV_CALCULATED, const datetime TIME_BAR_OPEN,
                 double &AMAbuffer[], double &AmaUpBuffer[], double &AmaDownBuffer[],
                 double &AmaPunctureUpBuffer[],
                 double &AmaPunctureDownBuffer[])
  {
//PrintFormat("%s | RATES_TOTAL: %d, PREV_CALCULATED: %d", __FUNCTION__, RATES_TOTAL, PREV_CALCULATED);
   int nNewBars = RATES_TOTAL - PREV_CALCULATED;
   if(nNewBars == 0)
     {
      curBar.timeClose = Time[0];
      curBar.close = Close[0];
      if(NormalizeDouble(High[0] - curBar.high, _Digits) > 0)
        {
         curBar.timeHigh = Time[0];
         curBar.high = High[0];
        }
      if(NormalizeDouble(curBar.low - Low[0], _Digits) > 0)
        {
         curBar.timeLow = Time[0];
         curBar.low = Low[0];
        }
      if(oRates.Total() > 1)
        {
         preBar = oRates.GetNodeAtIndex(1);
         curBar.abs = MathAbs(curBar.GetPrice(maAppliedPrice) - preBar.GetPrice(maAppliedPrice));
        }
      //Print("curBar.timeOpen_", curBar.timeOpen, " curBar.Prev()_", curBar.Prev());
      DrawMyCustomMA(0, RATES_TOTAL, oRates, maReadyData, AMAbuffer, AmaUpBuffer, AmaDownBuffer, AmaPunctureUpBuffer, AmaPunctureDownBuffer);
     }
   else
      if(nNewBars == 1)
        {
         if(Time[0] >= curBar.timeOpenNext)
           {
            DrawMyCustomMA(1, RATES_TOTAL, oRates, maReadyData, AMAbuffer, AmaUpBuffer, AmaDownBuffer, AmaPunctureUpBuffer, AmaPunctureDownBuffer);
            preBar = curBar;
            curBar = new CBarStorage;
            curBar.Prev(preBar);
            NewBarSet(0, curBar, periodInSeconds);
            BarToRates(curBar, oRates);
            if(oRates.Total() > 1)
              {
               preBar = oRates.GetNodeAtIndex(1);
               curBar.abs = MathAbs(curBar.GetPrice(maAppliedPrice) - preBar.GetPrice(maAppliedPrice));
              }
            DrawMyCustomMA(0, RATES_TOTAL, oRates, maReadyData, AMAbuffer, AmaUpBuffer, AmaDownBuffer, AmaPunctureUpBuffer, AmaPunctureDownBuffer);
           }
        }
      else
         if(nNewBars > 1)
           {
            //PrintFormat("newBars = %d", nNewBars);
            oRates.Clear();
            curBar = new CBarStorage;
            BarToRates(curBar, oRates);
            int i = RATES_TOTAL - 1;
            NewBarSet(i, curBar, periodInSeconds);
            for(i--; i >= 0; i--)
              {
               if(Time[i] >= curBar.timeOpenNext)
                 {
                  curBar = new CBarStorage;
                  NewBarSet(i, curBar, periodInSeconds);
                  BarToRates(curBar, oRates);
                  //Print("curBar.timeOpen_", curBar.timeOpen, " preBar.timeOpen_", preBar.timeOpen);
                 }
               curBar.timeClose = Time[i];
               curBar.close = Close[i];
               if(NormalizeDouble(High[i] - curBar.high, _Digits) > 0)
                 {
                  curBar.timeHigh = Time[i];
                  curBar.high = High[i];
                 }
               if(NormalizeDouble(curBar.low - Low[i], _Digits) > 0)
                 {
                  curBar.timeLow = Time[i];
                  curBar.low = Low[i];
                 }
               if(oRates.Total() > 1)
                 {
                  preBar = oRates.GetNodeAtIndex(1);
                  curBar.abs = MathAbs(curBar.GetPrice(maAppliedPrice) - preBar.GetPrice(maAppliedPrice));
                 }
               DrawMyCustomMA(i, RATES_TOTAL, oRates, maReadyData, AMAbuffer, AmaUpBuffer, AmaDownBuffer, AmaPunctureUpBuffer, AmaPunctureDownBuffer);
              }
           }
   if(displayComment)
      Comment(ToString());
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime CMain::TimeWeekStart(datetime TIME, MqlDateTime &TIME_WEEK_START, int START_HOUR)
  {
   TimeToStruct(TIME, TIME_WEEK_START);
   TIME_WEEK_START.hour = START_HOUR;
   TIME_WEEK_START.min = 0;
   TIME_WEEK_START.sec = 0;
   return StructToTime(TIME_WEEK_START) - TIME_WEEK_START.day_of_week * 86400;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CMain::saveInputs(int _dayStartHour,
                       int _PeriodInMinutes,
                       string _maVAriables,
                       int _periodAMA,
                       ENUM_APPLIED_PRICE _maAppliedPrice,
                       double _G,
                       double _dK,
                       ENUM_MA_MODE_BAR_PRICE _maMode)
  {
   dayStartHour = _dayStartHour;
   periodInMinutes = _PeriodInMinutes;
   periodInSeconds = periodInMinutes * 60;
   maVAriables = _maVAriables;
   periodAMA = _periodAMA;
   maAppliedPrice = _maAppliedPrice;
   G = _G;
   dK = _dK;
   maModeBarPrice = _maMode;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CIfxAMA
  {
public:
   int               dayStartHour;
   int               PeriodInMinutes;
   string            maVAriables;
   int               periodAMA;
   ENUM_APPLIED_PRICE maAppliedPrice;
   double            nfast;
   double            nslow;
   double            G;
   double            dK;
   int               periodInSeconds;
   double            slowSC;
   double            fastSC;
   double            deltaFastSlow;
   ENUM_MA_MODE_BAR_PRICE maModeBarPrice;
   bool              displayComment;
   bool              displayCommentRates;
   //--- objects
   CMain             oMain;

   string            prefix;

   int               onInit(int ifx_buffer, double &AMAbuffer[], color clr, bool drawAtChart = false, string label = "");
   void              onDeinit(const int reason);
   int               onCalculate(const int rates_total,
                                 const int prev_calculated,
                                 double &AMAbuffer[],
                                 double &AmaUpBuffer[], double &AmaDownBuffer[],
                                 double &AmaPunctureUpBuffer[],
                                 double &AmaPunctureDownBuffer[]);
   void              saveInputs(int _dayStartHour,
                                int _PeriodInMinutes,
                                string _maVAriables,
                                int _periodAMA,
                                ENUM_APPLIED_PRICE _maAppliedPrice,
                                double _nfast,
                                double _nslow,
                                double _G,
                                double _dK,
                                ENUM_MA_MODE_BAR_PRICE _maMode);


                     CIfxAMA(void)
     {
      dayStartHour = 0;
      PeriodInMinutes = 1440;
      maVAriables = "AMA Variables";
      periodAMA = 10;
      maAppliedPrice = PRICE_CLOSE;
      maModeBarPrice = MA_MODE_LAST_BAR_PRICE;
      nfast = 2.0;
      nslow = 30.0;
      G = 2.0;
      dK = 2.0;
      displayComment = true;
      displayCommentRates = true;
     };
                    ~CIfxAMA(void) {};
  };


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int CIfxAMA::onInit(int ifx_buffer, double &AMAbuffer[], color clr, bool drawAtChart = false, string label = "")
  {
//--- indicator buffers mapping
//IndicatorBuffers(11);
   if(drawAtChart)
      SetIndexStyle(ifx_buffer, DRAW_LINE, STYLE_SOLID, 1, clr);
   else
      SetIndexStyle(ifx_buffer, DRAW_NONE);
   SetIndexBuffer(ifx_buffer, AMAbuffer);
   prefix = label == "" ? "ama[" + IntegerToString(ifx_buffer) + "]" : label;
   SetIndexLabel(ifx_buffer, prefix);
//IndicatorDigits(_Digits);
   periodInSeconds = PeriodInMinutes * 60;
   oMain.OnInitCalc();
   slowSC = (2.0 / (nslow + 1));
   fastSC = (2.0 / (nfast + 1));
   oMain.setDeltaFastSlow(fastSC, slowSC);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CIfxAMA::onDeinit(const int reason)
  {
   if(displayComment)
      Comment("");
   ObjectsDeleteAll(0, prefix);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int CIfxAMA::onCalculate(const int rates_total,
                         const int prev_calculated,
                         double &AMAbuffer[],
                         double &AmaUpBuffer[], double &AmaDownBuffer[],
                         double &AmaPunctureUpBuffer[],
                         double &AmaPunctureDownBuffer[])
  {
//---
   oMain.Calc(rates_total, prev_calculated, dayStartHour, AMAbuffer,
              AmaUpBuffer, AmaDownBuffer, AmaPunctureUpBuffer, AmaPunctureDownBuffer);
//drawAMA(rates_total, AMAbuffer, oMain.getCurrentBarTimeOpen(), prefix, 0, 0);
//--- return value of prev_calculated for next call
   return(rates_total);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CIfxAMA::saveInputs(int _dayStartHour,
                         int _PeriodInMinutes,
                         string _maVAriables,
                         int _periodAMA,
                         ENUM_APPLIED_PRICE _maAppliedPrice,
                         double _nfast,
                         double _nslow,
                         double _G,
                         double _dK,
                         ENUM_MA_MODE_BAR_PRICE _maMode)
  {
   dayStartHour = _dayStartHour;
   PeriodInMinutes = _PeriodInMinutes;
   maVAriables = _maVAriables;
   periodAMA = _periodAMA;
   maAppliedPrice = _maAppliedPrice;
   nfast = _nfast;
   nslow = _nslow;
   G = _G;
   dK = _dK;
   maModeBarPrice = _maMode;
   oMain.saveInputs(dayStartHour, PeriodInMinutes, maVAriables, periodAMA, maAppliedPrice, G, dK, maModeBarPrice);
  }


//+------------------------------------------------------------------+
