//+------------------------------------------------------------------------------------------------------+
//| Oasis Money Maker(v.1.023).mq4                                                                       |
//| Copyright 2018, OasisSoftTech, Developer:Rasim Şen                                                   |
//| https://www.oasissofttech.com                                                                        |
//|                                                                                                      |
//| WARNING 1: Use at your own risk, there is ABSOLUTELY NO GUARANTEE that it works with your MT4 client.|
//|                                                                                                      |
//| WARNING 2: Remember, that multiplying a trade with same or increased lot size will also multiply     |
//| your risk. Calculate with it in your MM.                                                             |
//|                                                                                                      |
//| WARNING 3: Author does not take any responsibility or claim for your losses that connected to,       |
//| or may come from this EA's possible malfunction. Remember: it's free.                                |
//|                                                                                                      |
//| Strategy: It has three strategies: Moving Avarage, Channel Strategy and Alligator Strategy.          |
//| You can set working date                                                                             | 
//| and time, take profit, stop loss. by default it follow trend lines and channel up and bottom lines.  |
//| Also trailing stop loss developed.                                                                   |
//| All of properties set easily from Expert Adviser setting panel.                                      |   
//+------------------------------------------------------------------------------------------------------+
#property copyright "Copyright 2016, OasisSoftTech, Developer:Rasim Şen"
#property link      "http://www.oasissofttech.com"
#property version   "1.00"
#property strict
//--- input parameters
extern int OASIS_MAGIC_NUMBER=999;                    //Operation Code(**must be unique for every graph window)
enum OASIS_STRATEGY_TYPES{
   ST_MA=1,                                   //Moving Avarege 
   ST_RL=2,                                   //Rasim Line
   ST_ALLIGATOR=3,                            //Alligator
};
extern OASIS_STRATEGY_TYPES OASIS_STRATEGY=ST_MA;     //Strategy
enum OASIS_MA_TYPES{
   MA_SMA=MODE_SMA,                                   //Simple averaging
   MA_EMA=MODE_EMA,                                   //Exponential averaging
   MA_SMMA=MODE_SMMA,                                 //Smoothed averaging
   MA_LWMA=MODE_LWMA                                  //Linear-weighted averaging
};
extern OASIS_MA_TYPES OASIS_MA_METHOD = MA_LWMA;    //Moving Average Method
extern int 
   OASIS_MA_PERIOD=500,           //Moving Avarage Period
   OASIS_MA_BAND_TOP=150,        //Moving Avarage Top Band
   OASIS_MA_BAND_BOTTOM=-150,    //Moving Avarage Bottom Band
   OASIS_MOVINGSHIFT=0;          //Moving Avarage Shift
extern double OASIS_ST_RL_TOP=0;             // RL Strategy Top Line
extern double OASIS_ST_RL_BOTTOM=0;          // RL Strategy Bottom Line

double
   OASIS_LOT_INCREASE_RATE=100.0,//Lot-Increase Lot Rate(%)
   OASIS_LOT_INCREASE_RATE2=0.0, //Lot-Increase Lot Rate 2(%,after x step loss,increase lot %)
   OASIS_LOT_INCREASE_RATE3=0.0; //Lot-Increase Lot Rate 3(%,after y step loss,increase lot %)
int   
   OASIS_LOT_INCREASE_LEVEL2=0,   //Lot-Increase Level 2(after x step loss)
   OASIS_LOT_INCREASE_LEVEL3=0;   //Lot-Increase Level 3(after y step loss)

extern datetime 
   OASIS_DATETIME_START = "00:00:00",//Start Time
   OASIS_DATETIME_END = "00:00:00";//End Time
//bool OASIS_USE_SECENARIO = true;
extern string OASIS_LOT_SECENARIO = "0.01;0.02;0.04;0.08;0.16;0.32;0.64;0.75;1.00;1.25;1.35;1.50;1.75;1.80;1.90;2.00;2.15;2.30;2.60;2.90;3.10;3.20;3.40;3.80;4.00;4.25;4.50;4.75;5.00";//Secenario   
extern double
   OASIS_LOT_MAXORDER_SIZE=5.0;  //Lot-Max Order Lot(Default 5 lots) 
extern int 
   OASIS_STOP_LOSS=0,            //Stop Loss (Pips)
   OASIS_TAKE_PROFIT=0,          //Take Profit(Pips)
   OASIS_SLIPPAGE=50;            //Slippage
   
//Kara geçildiğinde izleyen stop-loss ile karı korumak amaçlı geliştirildi
//eşik değeri verildiğinde izleyen stop loss eşik değer aşıldığında devreye girecek ve eşik değerden aşağı düşmemiş olacak. 
//örneğin 500 pips eşik değeri girildi, izleyen stop-loss ise 300 pips girildi
//bu durumda işlem açıldığında 500 pips yükselirse fiyatın 200 pips altında başlayarak fiyatı yukarı yönde takip etmesi sağlanır. 
//bu şekilde ani yükselişlerden gir-çık ile faydalanma sağlanacak. 
//aracı kurumların sunduğu "trailing stop" tan farklı ise izleyen stop loss'un aktif olma noktasının set edilememesidir, manuel el ile trailing-stopun set edilmesi gerekiyor anlık duruma göre
//izleyen stop loss çalışacak mı kontrol
extern bool     
   OASIS_EXT_TRAILING_STOP_IS_RUN = false;//Trailing Stop Activation
extern int   
   OASIS_EXT_TRAILING_STOP_THRESHOLD=0,//Trailing Stop Threshold(Pips)
   OASIS_EXT_TRAILING_STOP=0;// Trailing Stop Loss
   
extern int
   OASIS_LOT_MAX = 0;            //Max Lot Size

//--------------------------------------------------------------------------------------------------------------- extern variable : end 
bool  OASIS_DEBUG_LOG = false;
double OASIS_MA=0,
       OASIS_MA_BAND_VALUE_TOP=0,
       OASIS_MA_BAND_VALUE_BOTTOM=0,
       OASIS_TAKE_PROFIT_SELL=0,
       OASIS_TAKE_PROFIT_BUY=0,
       OASIS_SNIPER_LOT=0;
       
enum OASIS_ORDER_TYPES{
   OA_BUY      = OP_BUY,         //Buy operation
   OA_SELL     = OP_SELL,        //Sell operation
   OA_BUYLIMIT = OP_BUYLIMIT,	   //Buy limit pending order
   OA_SELLLIMIT = OP_SELLLIMIT,	//Sell limit pending order
   OA_BUYSTOP  = OP_BUYSTOP,	   //Buy stop pending order
   OA_SELLSTOP = OP_SELLSTOP,	   //Sell stop pending order   
   OA_WAIT     = -1
};
OASIS_ORDER_TYPES OASIS_SNIPER=OA_WAIT,
                  OASIS_SNIPER_PREVIOUS=OA_WAIT,
                  OASIS_SNIPER_NOW=OA_WAIT;       

double OASIS_BUY_PRICE=0,
       OASIS_SELL_PRICE=0,
       OASIS_HISTORY_LOSS_TOTAT_AMOUNT=0;
int    OASIS_COUNTER_SEQUENTIAL_LOSS = 0,//parçalı lotlarda geçmişe dönük zarar sayacı hatalı çalıştığı için bu yöntem kaldırıldı.
       OASIS_HISTORY_LOSS_COUNTER = 0;
int ticket=-1,magic=9740030;       

string   OASIS_SCENARIO_LOTS[];
int      OASIS_SCENARIO_COUNT = 0;
string   OASIS_LATEST_TICKETS = "";
//double var=StrToDouble("103.2812");
double   OASIS_LASTEST_ORDER_PROFITLOSS = 0;
double   OASIS_PERIOD_NET_PROFITLOSS = 0;
string   OASIS_FIRST_ACT = "NOT";
bool     OASIS_IS_FIRST_ORDER = true;
bool     OASIS_TRAILING_STOP_IS_RUN = false;
double   OASIS_TRAILING_STOP_CURRENT_VALUE = 0,
         OASIS_TRAILING_STOP_CURRENT_VALUE_OLD = 0,
         OASIS_ORDER_MODIFY_STOP_LOSS = 0;
//--------------------------------------------------------------------------------------------------------------- other variable : end

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(!OASIS_KILL_EXECUTION()){
      OASIS_LOG("Kill..");
      return(INIT_FAILED);
   }  
   OASIS_INIT();
   OASIS_LOG("Başladı..");
   return(INIT_SUCCEEDED);
  }
void OnDeinit(const int reason)
  {
   EventKillTimer();      
   OASIS_LOG("OnDeinit..");
  }
bool OASIS_STOP_ROBOT(){
   datetime OASIS_NOW = TimeCurrent();   

   if(OASIS_LOT_MAX == 0){return false;}
   if(OASIS_SNIPER_LOT>OASIS_LOT_MAX){
      OASIS_LOG("Çok fazla zarar edildi. İşlemler durduruldu (Max.lot miktarı aşıldı). "+ " OASIS_SNIPER_LOT:"+OASIS_SNIPER_LOT+" OASIS_LOT_MAX:"+OASIS_LOT_MAX);
      return true;
   }
   if(OASIS_SCENARIO_COUNT == 0){
      OASIS_LOG("Seneryo girilmemiş. Robotun çalışması durduruldu!!");
      return true;
   }
   return false;
}
void OnTick()
  {
   if(OASIS_STOP_ROBOT()){
      return;
   } // stop loss and exit robot
   if(OASIS_STRATEGY == ST_MA){
      OASIS_METHOD_MA();
   }else if(OASIS_STRATEGY == ST_RL){
      OASIS_METHOD_RL();
   }else if(OASIS_STRATEGY == ST_ALLIGATOR){
      OASIS_METHOD_ALLIGATOR();
   }else{
      return;
   }
   OASIS_METHOD_TRAILING_STOP();
   if(!OASIS_PREPARE()){
      return;
   }   
   OASIS_OPEN_POSITION();
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
   OASIS_LOG("OnTimer");
  }
//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester()
  {
//---
   double ret=0.0;
//---
   OASIS_LOG("OnTester");
//---
   return(ret);
  }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
//---
   OASIS_LOG("OnChartEvent");
  }
//+------------------------------------------------------------------+
void OASIS_INIT(){
   OASIS_MAGIC_NUMBER_METHOD();
   OASIS_METHOT_SCENARIO();
   OASIS_METHOD_TRAILING_STOP_INIT();
   OASIS_LOT_RESET();
   OASIS_LOG("başlangıç lot:"+OASIS_SNIPER_LOT);
}
// her graph ekranda ayri bir strateji uygulanacaksa magic number lar ile her robot 
// emri farklılaştırılacak, böylece her grafik ekrandaki robot sadece kendi 
//emirlerini koşturacak
void OASIS_MAGIC_NUMBER_METHOD(){ 
   if(OASIS_MAGIC_NUMBER != 999){
      magic = OASIS_MAGIC_NUMBER;
   }
}
bool OASIS_PREPARE(){   
   OASIS_BUY_PRICE    = MarketInfo(NULL,MODE_ASK);
   OASIS_SELL_PRICE    = MarketInfo(NULL,MODE_BID);
   
   if(OASIS_BUY_PRICE > OASIS_MA_BAND_VALUE_TOP){
//OASIS_LOG2("OASIS_PREPARE 1- "+OASIS_BUY_PRICE + ">" + OASIS_MA_BAND_VALUE_TOP);     
      OASIS_SNIPER_NOW = OA_BUY;
   }else if(OASIS_SELL_PRICE < OASIS_MA_BAND_VALUE_BOTTOM){
//OASIS_LOG2("OASIS_PREPARE 2- "+OASIS_SELL_PRICE +"<"+ OASIS_MA_BAND_VALUE_BOTTOM);     
      OASIS_SNIPER_NOW = OA_SELL;
   }else if(OASIS_IS_FIRST_ORDER){
      OASIS_SNIPER_NOW = -1;
   }
   
//OASIS_LOG2("önce OASIS_SNIPER: "+OASIS_SNIPER+" OASIS_SNIPER_PREVIOUS:"+OASIS_SNIPER_PREVIOUS +"!= OASIS_SNIPER_NOW:"+ OASIS_SNIPER_NOW+" OASIS_BUY_PRICE:"+OASIS_BUY_PRICE+" OASIS_SELL_PRICE:"+OASIS_SELL_PRICE);
   if(OASIS_SNIPER_PREVIOUS != OASIS_SNIPER_NOW){      
      OASIS_SNIPER_PREVIOUS = OASIS_SNIPER_NOW;
      if(OASIS_FIRST_ACT == "NOT"){
         OASIS_FIRST_ACT = "OK";
         return false;
      }else{
         OASIS_SNIPER = OASIS_SNIPER_NOW;
      }
   }
//OASIS_LOG2("sonra OASIS_SNIPER: "+OASIS_SNIPER+" OASIS_SNIPER_PREVIOUS:"+OASIS_SNIPER_PREVIOUS +"!= OASIS_SNIPER_NOW:"+ OASIS_SNIPER_NOW);

   if(OASIS_TAKE_PROFIT > 0){
      OASIS_TAKE_PROFIT_SELL = OASIS_SELL_PRICE - OASIS_TAKE_PROFIT * Point;
      OASIS_TAKE_PROFIT_BUY = OASIS_BUY_PRICE + OASIS_TAKE_PROFIT * Point; 
   }   
   return true;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////   moving average 
void OASIS_METHOD_MA(){
 
   OASIS_MA=iMA(NULL,0,OASIS_MA_PERIOD,OASIS_MOVINGSHIFT,ENUM_MA_METHOD(OASIS_MA_METHOD),PRICE_CLOSE,0);
   OASIS_MA_BAND_VALUE_TOP    = OASIS_MA + Point*OASIS_MA_BAND_TOP;
   OASIS_MA_BAND_VALUE_BOTTOM = OASIS_MA + Point*OASIS_MA_BAND_BOTTOM;
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////   between 2 lines - rasim yaylaci
void OASIS_METHOD_RL(){
   OASIS_MA_BAND_VALUE_TOP    =OASIS_ST_RL_TOP;
   OASIS_MA_BAND_VALUE_BOTTOM =OASIS_ST_RL_BOTTOM;
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////   alligator
void OASIS_METHOD_ALLIGATOR(){
   double jaw_val=iAlligator(NULL,0,13,8,8,5,5,3,MODE_SMMA,PRICE_MEDIAN,MODE_GATORJAW,1);   //blue line
   double teeth_val=iAlligator(NULL,0,13,8,8,5,5,3,MODE_SMMA,PRICE_MEDIAN,MODE_GATORTEETH,1);   //teeth line
   double lips_val=iAlligator(NULL,0,13,8,8,5,5,3,MODE_SMMA,PRICE_MEDIAN,MODE_GATORLIPS,1);   //lips line
   double topLine=0;
   double bottomLine=0;
   double diff = 0;
OASIS_LOG2("OASIS_METHOD_ALLIGATOR - OA_BUY jaw_val:"+jaw_val+"teeth_val:"+teeth_val+" lips_val:"+lips_val+" OASIS_BUY_PRICE:"+OASIS_BUY_PRICE);

   topLine = jaw_val;
   topLine = teeth_val>topLine?teeth_val:topLine;
   topLine = lips_val>topLine?lips_val:topLine;
   
   bottomLine = lips_val;
   bottomLine = jaw_val<bottomLine?jaw_val:bottomLine;
   bottomLine = teeth_val<bottomLine?teeth_val:bottomLine;

   diff = MathAbs(topLine - bottomLine);
   if(diff<200*Point){
      /*if(OASIS_SNIPER == OA_BUY){  
         OASIS_BUY_PRICE = topLine - diff/2;
      }else if(OASIS_SNIPER == OA_SELL){
         OASIS_SELL_PRICE = bottomLine + diff/2;   
      }*/
      topLine = topLine + 100*Point;
      bottomLine = bottomLine - 100*Point;
//OASIS_LOG2("xxxxx:"+" diff:"+diff+" OASIS_SELL_PRICE:"+OASIS_SELL_PRICE+" OASIS_BUY_PRICE:"+OASIS_BUY_PRICE);
   }

OASIS_LOG2("topLine:"+topLine+" bottomLine:"+bottomLine+" diff:"+diff);
   OASIS_MA_BAND_VALUE_TOP    = topLine;
   OASIS_MA_BAND_VALUE_BOTTOM = bottomLine;
}

void OASIS_METHOD_TRAILING_STOP_INIT(){
   if(OASIS_EXT_TRAILING_STOP_IS_RUN 
      && OASIS_EXT_TRAILING_STOP > 0 
      && (OASIS_EXT_TRAILING_STOP_THRESHOLD == 0 || OASIS_EXT_TRAILING_STOP_THRESHOLD > OASIS_EXT_TRAILING_STOP)){
      OASIS_TRAILING_STOP_IS_RUN = true;   
   }else{
      OASIS_LOG("Trailing stop loss is not activated!");
   }
}

void OASIS_METHOD_TRAILING_STOP(){
   if(!OASIS_TRAILING_STOP_IS_RUN){
      return;
   }
   if(OrderSelect(ticket,SELECT_BY_TICKET)==false){ 
      return;
   }
   double openPrice = OrderOpenPrice();
   double currentPrice = 0;
   double diffPrice = -1;
   double trailingTopCurrentValue = OASIS_TRAILING_STOP_CURRENT_VALUE_OLD;
   if(OASIS_SNIPER_NOW == OA_BUY){         
      currentPrice = OASIS_BUY_PRICE;
      if(OASIS_EXT_TRAILING_STOP_THRESHOLD>0){
         diffPrice = currentPrice-(openPrice + OASIS_EXT_TRAILING_STOP_THRESHOLD*Point);
      }else if(OASIS_EXT_TRAILING_STOP_THRESHOLD == 0){
         diffPrice = currentPrice-(openPrice + OASIS_EXT_TRAILING_STOP*Point);
      }
      if(diffPrice >= 0){
         trailingTopCurrentValue = currentPrice - Point*OASIS_EXT_TRAILING_STOP;   
      }
      OASIS_LOG2("trailing stop-buy:diffPrice:"+diffPrice+" p:"+trailingTopCurrentValue+" currentPrice:"+currentPrice+" openPrice:"+openPrice+" pip fark:"+(Point*OASIS_EXT_TRAILING_STOP));
   }else if(OASIS_SNIPER_NOW == OA_SELL){
      currentPrice = OASIS_SELL_PRICE;
      if(OASIS_EXT_TRAILING_STOP_THRESHOLD>0){
         diffPrice = openPrice - (currentPrice + OASIS_EXT_TRAILING_STOP_THRESHOLD*Point);
      }else if(OASIS_EXT_TRAILING_STOP_THRESHOLD == 0){
         diffPrice = openPrice - (currentPrice + OASIS_EXT_TRAILING_STOP*Point);
      }      
      if(diffPrice >= 0){
         trailingTopCurrentValue = currentPrice + Point*OASIS_EXT_TRAILING_STOP;   
      }
      OASIS_LOG2("trailing stop-sell:diffPrice:"+diffPrice+" p:"+trailingTopCurrentValue+" currentPrice:"+currentPrice+" openPrice:"+openPrice+" pip fark:"+(Point*OASIS_EXT_TRAILING_STOP));
   }
   OASIS_TRAILING_STOP_CURRENT_VALUE = trailingTopCurrentValue;
}


void OASIS_CLOSE_POSITION(){

}

void OASIS_OPEN_POSITION_RESET_VARIABLES(){
   OASIS_TRAILING_STOP_CURRENT_VALUE_OLD = 0;
   OASIS_TRAILING_STOP_CURRENT_VALUE = 0;
}


void OASIS_OPEN_POSITION()
{
OASIS_LOG2("OASIS_OPEN_POSITION-xx");
   bool OASIS_ALLOW_NEW_POSITION = OASIS_METHOD_DATETIME_CONTROL();
OASIS_LOG2("OASIS_OPEN_POSITION-xx1");
   if(OASIS_ALLOW_NEW_POSITION && OASIS_SNIPER == OA_BUY){
OASIS_LOG2("OASIS_OPEN_POSITION-xx2");
      OASIS_OPEN_POSITION_RESET_VARIABLES();
OASIS_LOG2("OASIS_OPEN_POSITION-xx3");
      OASIS_ORDER_CLOSE_ALL();
OASIS_LOG2("OASIS_OPEN_POSITION-xx4");
      if(!OASIS_METHOD_LOT_CALCULATE()){
         return;
      }//hata var
OASIS_LOG2("OASIS_OPEN_POSITION-xx5");
      //OASIS_LOG2("OASIS_OPEN_POSITION-3");
      OASIS_PREDEFINED_VARIABLES();
OASIS_LOG2("OASIS_OPEN_POSITION-xx6");
      OASIS_ORDER_SEND(OASIS_SNIPER,OASIS_SNIPER_LOT,Bid,OASIS_SLIPPAGE,OASIS_MA_BAND_VALUE_BOTTOM,OASIS_TAKE_PROFIT_BUY,Red );
      OASIS_LOG2("OASIS_OPEN_POSITION-4");
   }else if(OASIS_ALLOW_NEW_POSITION && OASIS_SNIPER == OA_SELL){
OASIS_LOG2("OASIS_OPEN_POSITION-yy1");
      OASIS_OPEN_POSITION_RESET_VARIABLES();
OASIS_LOG2("OASIS_OPEN_POSITION-yy2");
      OASIS_ORDER_CLOSE_ALL();
OASIS_LOG2("OASIS_OPEN_POSITION-yy3");
      if(!OASIS_METHOD_LOT_CALCULATE()){
         return;
      }//hata var
      OASIS_LOG2("OASIS_OPEN_POSITION-1-c");
      OASIS_PREDEFINED_VARIABLES();
      OASIS_ORDER_SEND(OASIS_SNIPER,OASIS_SNIPER_LOT,Ask,OASIS_SLIPPAGE,OASIS_MA_BAND_VALUE_TOP,OASIS_TAKE_PROFIT_SELL,Red );
      //OASIS_LOG("OASIS_OPEN_POSITION-1-d");
   }else{//modify position      
OASIS_LOG2("OASIS_OPEN_POSITION-zz1");
      if(OrderSelect(ticket,SELECT_BY_TICKET)==false){ 
         return;
      }
OASIS_LOG2("OASIS_OPEN_POSITION-zz2");
      OASIS_ORDER_MODIFY_SET_VARIABLE();
OASIS_LOG2("OASIS_OPEN_POSITION-zz3");
      OASIS_ORDER_MODIFY(ticket,OrderOpenPrice(),OASIS_ORDER_MODIFY_STOP_LOSS,0,0,clrNONE);  
      OASIS_LOG2("OASIS_ORDER_MODIFY-4"); 
   }
   OASIS_SNIPER = -1;
   OASIS_IS_FIRST_ORDER = false;
}

bool OASIS_METHOD_DATETIME_CONTROL(){
   datetime OASIS_VAR_DATETIME_START = OASIS_DATETIME_START;
   string OASIS_VAR_START = TimeToStr(OASIS_VAR_DATETIME_START,TIME_SECONDS);
   OASIS_VAR_DATETIME_START = OASIS_VAR_START;
   
   datetime OASIS_VAR_DATETIME_END = OASIS_DATETIME_END;      
   string OASIS_VAR_END = TimeToStr(OASIS_VAR_DATETIME_END,TIME_SECONDS);
   OASIS_VAR_DATETIME_END = OASIS_VAR_END;     
   
   datetime OASIS_TIME = TimeCurrent();
   string OASIS_TIME_STR = TimeToStr(OASIS_TIME,TIME_SECONDS);
   //OASIS_LOG("OASIS_METHOD_DATETIME_CONTROL - OASIS_VAR_DATETIME_START:"+OASIS_VAR_DATETIME_START+" OASIS_TIME:"+OASIS_TIME+" OASIS_VAR_DATETIME_END:"+OASIS_VAR_DATETIME_END);
   if((OASIS_VAR_START=="00:00:00" && OASIS_VAR_END=="00:00:00") 
      || (OASIS_TIME_STR >= OASIS_VAR_START && OASIS_VAR_END>=OASIS_TIME_STR)){
      if(!OASIS_DEBUG_LOG){Print("hep true");OASIS_DEBUG_LOG = true;}
      return true;
   }
   return false;
}

void OASIS_ORDER_SEND(int buyOrSell,double orderLot,double orderPrice,int orderSlip,double stopLoss,double takeProfit,color orderColor){   
  double orderLotPart = 0;
  OASIS_LATEST_TICKETS = "";
  int OASIS_TICKET=-1;
  OASIS_LOG("OASIS_ORDER_SEND-buyOrSell:"+buyOrSell+"-orderLot:"+orderLot+"-orderPrice:"+orderPrice+"-orderSlip:"+orderSlip+"-stopLoss:"+stopLoss+"-takeProfit:"+takeProfit+"-orderColor:"+orderColor);
  if(orderLot>OASIS_LOT_MAXORDER_SIZE){
      int countLotParts = MathCeil(orderLot/OASIS_LOT_MAXORDER_SIZE);
      for(int i=0;i<countLotParts;i++){
         double modeRemain = fmod(orderLot,OASIS_LOT_MAXORDER_SIZE);
         if(i==(countLotParts-1) && modeRemain>0){
            orderLotPart = modeRemain;
         }else{
            orderLotPart = OASIS_LOT_MAXORDER_SIZE;
         }
         OASIS_TICKET = OASIS_ORDER_SEND_PART(buyOrSell,orderLotPart,orderPrice,orderSlip,stopLoss,takeProfit,orderColor);
         OASIS_LATEST_TICKETS = OASIS_LATEST_TICKETS +"#"+OASIS_TICKET;
      }
   }else{
      OASIS_TICKET = OASIS_ORDER_SEND_PART(buyOrSell,orderLot,orderPrice,orderSlip,stopLoss,takeProfit,orderColor);
      OASIS_LATEST_TICKETS = OASIS_TICKET;
   }
   if(OASIS_TICKET<=0){
      OASIS_LOG("OASIS_ORDER_SEND hatadan dolayi seneryo arttırılamadı - counterLoss:"+OASIS_COUNTER_SEQUENTIAL_LOSS);   
   }else{
      OASIS_COUNTER_SEQUENTIAL_LOSS++;//zararda seneryoya göre sonraki girilecek lotu bulmak için
      OASIS_LOG("OASIS_ORDER_SEND sonu - counterLoss:"+OASIS_COUNTER_SEQUENTIAL_LOSS);   
   }
}
int OASIS_ORDER_SEND_PART(int buyOrSell,double orderLot,double orderPrice,int orderSlip,double stopLoss,double takeProfit,color orderColor){
      OASIS_LOG("OASIS_ORDER_SEND_PART-buyOrSell:"+buyOrSell+"-orderLot:"+orderLot+"-orderPrice:"+orderPrice+"-orderSlip:"+orderSlip+"-stopLoss:"+stopLoss+"-takeProfit:"+takeProfit+"-orderColor:"+orderColor);
      ticket=OrderSend(Symbol(),buyOrSell,orderLot,orderPrice,orderSlip,stopLoss,takeProfit,"",magic,0,orderColor);
      if(ticket <= 0) {
         OASIS_LOG("OASIS_ORDER_SEND_PART error ticket:"+ticket+" buyOrSell(0:buy):"+buyOrSell+" orderLot:"+orderLot+" orderPrice:"+orderPrice+" orderSlip:"+orderSlip+" stopLoss:"+stopLoss+" takeProfit:"+takeProfit+" orderColor:"+orderColor);
         return -1;
      }
      //OASIS_LOG("OASIS_ORDER_SEND_PART - emir başarılı. ticket:"+ticket);
      if(!OrderSelect(ticket,SELECT_BY_TICKET)) {OASIS_LOG("Error during selection."); return -1;}
      
      return ticket;
}

void OASIS_ORDER_MODIFY_SET_VARIABLE(){
   double trailingStopValue = OASIS_SNIPER_NOW == OA_BUY?OASIS_MA_BAND_VALUE_BOTTOM:OASIS_MA_BAND_VALUE_TOP;
   
   //hareketli ortalama değerler daha iyi duruma gelirse, stop loss u devre dışı bırak
   // hareketli ortalama bantlarını set et!!
   OASIS_LOG2("OASIS_ORDER_MODIFY_SET_VARIABLE-1:trailingStopValue:"+trailingStopValue+" is_run:" +OASIS_TRAILING_STOP_IS_RUN);
   if(OASIS_TRAILING_STOP_IS_RUN){
      if(OASIS_SNIPER_NOW == OA_BUY){
         OASIS_LOG2("OASIS_ORDER_MODIFY_SET_VARIABLE-buy-2:TRAILING_STOP:"+OASIS_TRAILING_STOP_CURRENT_VALUE +">"+ OASIS_TRAILING_STOP_CURRENT_VALUE_OLD);
         if(trailingStopValue < OASIS_TRAILING_STOP_CURRENT_VALUE){
            if(OASIS_TRAILING_STOP_CURRENT_VALUE > OASIS_TRAILING_STOP_CURRENT_VALUE_OLD || (OASIS_TRAILING_STOP_CURRENT_VALUE > 0 && OASIS_TRAILING_STOP_CURRENT_VALUE_OLD == 0 )){
               trailingStopValue = OASIS_TRAILING_STOP_CURRENT_VALUE;
               OASIS_TRAILING_STOP_CURRENT_VALUE_OLD = OASIS_TRAILING_STOP_CURRENT_VALUE;//fiyatın geri gelmemesi için      
            }else{
                  trailingStopValue = OASIS_TRAILING_STOP_CURRENT_VALUE_OLD;               
            }
         }else{
            OASIS_TRAILING_STOP_CURRENT_VALUE_OLD = trailingStopValue;//bant değerini set et, o daha avantajlı duruma gelmiş
         }         
      }else if(OASIS_SNIPER_NOW == OA_SELL){
   OASIS_LOG2("OASIS_ORDER_MODIFY_SET_VARIABLE-sell-1:"+OASIS_TRAILING_STOP_CURRENT_VALUE +"<"+ OASIS_TRAILING_STOP_CURRENT_VALUE_OLD+" trailingStopValue:"+trailingStopValue);

               if(trailingStopValue > OASIS_TRAILING_STOP_CURRENT_VALUE){
   OASIS_LOG2("sel2");
                  if(OASIS_TRAILING_STOP_CURRENT_VALUE < OASIS_TRAILING_STOP_CURRENT_VALUE_OLD  || (OASIS_TRAILING_STOP_CURRENT_VALUE_OLD == 0 && OASIS_TRAILING_STOP_CURRENT_VALUE >0)){
   OASIS_LOG2("sel3");
                     trailingStopValue = OASIS_TRAILING_STOP_CURRENT_VALUE;
                     OASIS_TRAILING_STOP_CURRENT_VALUE_OLD = OASIS_TRAILING_STOP_CURRENT_VALUE;//fiyatın geri gelmemesi için                     
                  }else{
   OASIS_LOG2("sel4");
                     trailingStopValue = OASIS_TRAILING_STOP_CURRENT_VALUE_OLD;
                  }
               }else{
   OASIS_LOG2("sel5");
                  OASIS_TRAILING_STOP_CURRENT_VALUE_OLD = trailingStopValue; //bant               
               }
      } 
   }
   OASIS_LOG2("modify set varxxxx-son-trailingStopValue:"+trailingStopValue);
   OASIS_ORDER_MODIFY_STOP_LOSS =  trailingStopValue;         
}

void OASIS_ORDER_MODIFY(
   int        ticket0,      // ticket
   double     price,       // price
   double     stoploss,    // stop loss
   double     takeprofit,  // take profit
   datetime   expiration,  // expiration
   color      arrow_color  // color
   ){   
    int OASIS_COUNT_ACTIVE_ORDER=OrdersTotal();   
    for(int k=0;k<OASIS_COUNT_ACTIVE_ORDER;k++){      
      if(!OrderSelect(k,SELECT_BY_POS)){
         OASIS_LOG("OASIS_ORDER_MODIFY HATA - OrderSelect("+k+", SELECT_BY_POS) - Error #"+GetLastError());
         continue;
      }
      if(OrderMagicNumber()!=magic || OrderSymbol()!=Symbol()){
         //OASIS_LOG("OASIS_ORDER_MODIFY HATA: Robotun açtığı işlem değil.OrderSymbol:"+OrderSymbol()+" Symbol:"+Symbol());
         continue;            
       }
      if(!OrderModify(OrderTicket(),price,stoploss,takeprofit,0,arrow_color)){
            OASIS_LOG("OASIS_ORDER_MODIFY HATA - ticket:"+OrderTicket()+" price:"+price+" stoploss"+stoploss+" takeprofit:"+takeprofit);
      }
    }   
}
bool OASIS_METHOD_LOT_CALCULATE(){
   if (OASIS_LOT_INCREASE_RATE == 0) {return true;}
   if (OASIS_SNIPER == -1) {return true;} 
   if(OASIS_SCENARIO_COUNT<OASIS_COUNTER_SEQUENTIAL_LOSS){ 
      OASIS_LOG("OASIS_METHOD_LOT_CALCULATE - Başlangıçta girilen senaryo lot adetleri aşıldı. Senaryo adet:"+OASIS_SCENARIO_COUNT+" kayıp sayac:"+OASIS_COUNTER_SEQUENTIAL_LOSS+".kayıp");
      return false;
   }
   
   OASIS_METHOD_HISTORY_TICKETS();
   OASIS_LOG("profit-loss:"+OASIS_LASTEST_ORDER_PROFITLOSS);
   if(OASIS_LASTEST_ORDER_PROFITLOSS>0){
     OASIS_METOD_CALCULATION_FOR_PROFIT();
   }
   if(OASIS_LASTEST_ORDER_PROFITLOSS<=0){
     OASIS_METOD_CALCULATION_FOR_LOSS();
   }   
   return true; 
}
void OASIS_METOD_CALCULATION_FOR_PROFIT(){
   //OASIS_LOG("OASIS_METOD_CALCULATION_FOR_PROFIT - OASIS_PERIOD_NET_PROFITLOSS:"+OASIS_PERIOD_NET_PROFITLOSS);
   if(OASIS_PERIOD_NET_PROFITLOSS>0){
      OASIS_LOT_RESET();
   }else{
      //OASIS_LOG("before: for profit - OASIS_COUNTER_SEQUENTIAL_LOSS:"+OASIS_COUNTER_SEQUENTIAL_LOSS+" OASIS_SNIPER_LOT:"+OASIS_SNIPER_LOT);      
      OASIS_COUNTER_SEQUENTIAL_LOSS--;
      OASIS_SNIPER_LOT = OASIS_SCENARIO_LOTS[OASIS_COUNTER_SEQUENTIAL_LOSS];
      //OASIS_LOG("after: for profit - OASIS_COUNTER_SEQUENTIAL_LOSS:"+OASIS_COUNTER_SEQUENTIAL_LOSS+" OASIS_SNIPER_LOT:"+OASIS_SNIPER_LOT);      
   }
}
void OASIS_METOD_CALCULATION_FOR_LOSS(){   
   //OASIS_LOG("OASIS_METOD_CALCULATION_FOR_LOSS - OASIS_SCENARIO_COUNT:"+OASIS_SCENARIO_COUNT+">OASIS_COUNTER_SEQUENTIAL_LOSS:"+OASIS_COUNTER_SEQUENTIAL_LOSS);
   if(OASIS_SCENARIO_COUNT>OASIS_COUNTER_SEQUENTIAL_LOSS){//seneryo bitti ise//durdur
      OASIS_SNIPER_LOT = OASIS_SCENARIO_LOTS[OASIS_COUNTER_SEQUENTIAL_LOSS];
      OASIS_LOG("zararda artırma OASIS_COUNTER_SEQUENTIAL_LOSS:"+OASIS_COUNTER_SEQUENTIAL_LOSS+" OASIS_SNIPER_LOT:"+OASIS_SNIPER_LOT);
   }
}
void OASIS_LOT_RESET(){
   OASIS_LOG("RESET'e girdi. Resetten önceki değerler: kayıp index:"+OASIS_COUNTER_SEQUENTIAL_LOSS+" lot:"+OASIS_SCENARIO_LOTS[OASIS_COUNTER_SEQUENTIAL_LOSS]+"Kar:"+OASIS_PERIOD_NET_PROFITLOSS);
   OASIS_COUNTER_SEQUENTIAL_LOSS = 0;
   OASIS_SNIPER_LOT = OASIS_SCENARIO_LOTS[0];
   OASIS_PERIOD_NET_PROFITLOSS = 0;//döngü başa döndü, karlı kapattı ve yeni periyod için kasa sıfırlandı
}
void OASIS_METHOT_SCENARIO(){
   ushort u_sep;  
   string sep=";"; 
   
   u_sep=StringGetCharacter(sep,0);
   OASIS_SCENARIO_COUNT=StringSplit(OASIS_LOT_SECENARIO,u_sep,OASIS_SCENARIO_LOTS);
   //PrintFormat("Strings obtained: %d. Used separator '%s' with the code %d",OASIS_SCENARIO_COUNT,sep,u_sep);
   
   if(OASIS_SCENARIO_COUNT>0)
     {
      Print("Seneryolar:");
      OASIS_SNIPER_LOT = OASIS_SCENARIO_LOTS[0];
      for(int i=0;i<OASIS_SCENARIO_COUNT;i++)
        {
         PrintFormat("OASIS_SCENARIO[%d]=%s",i,OASIS_SCENARIO_LOTS[i]);
        }
     }     
}

void OASIS_METHOD_HISTORY_TICKETS(){
   OASIS_LASTEST_ORDER_PROFITLOSS = 0;
   string   OASIS_LATEST_TICKET_ARRAY[];
   ushort u_sep;  
   string sep="#"; 
   
   u_sep=StringGetCharacter(sep,0);
   int ticketCount=StringSplit(OASIS_LATEST_TICKETS,u_sep,OASIS_LATEST_TICKET_ARRAY);
   //OASIS_LOG("OASIS_METHOD_HISTORY_TICKETS - döngü ticketları:"+OASIS_LATEST_TICKETS+" döngüdeki ticket sayısı:"+ticketCount);
   if(ticketCount>0){
      for(int i=0;i<ticketCount;i++){
            //OASIS_LOG("OASIS_METHOD_HISTORY_TICKETS-2 i:"+i+"OASIS_LATEST_TICKET_ARRAY_i:"+OASIS_LATEST_TICKET_ARRAY[i]);
            if(OASIS_LATEST_TICKET_ARRAY[i]=="" || OASIS_LATEST_TICKET_ARRAY[i]<=0){
               OASIS_LOG("OASIS_METHOD_HISTORY_TICKETS-3 "+i+".eleman boş geldi"+OASIS_LATEST_TICKET_ARRAY[i]+" kayıt atlandı");   
               continue;
            }//boşları geç
            int ticketx = OASIS_LATEST_TICKET_ARRAY[i];
            OASIS_LASTEST_ORDER_PROFITLOSS += OASIS_METHOD_HISTORY_TICKET(ticketx);
      }
  }     
}
double OASIS_METHOD_HISTORY_TICKET(int ticket){
  RefreshRates();
  double orderProfit = 0;
  if(OrderSelect(ticket, SELECT_BY_TICKET,MODE_HISTORY)==true){
     orderProfit = OrderProfit();
     OASIS_PERIOD_NET_PROFITLOSS += orderProfit; 
     //OASIS_LOG("OASIS_METHOD_HISTORY_TICKET - OASIS_PERIOD_NET : "+OASIS_PERIOD_NET_PROFITLOSS + " ticket : "+ticket+" orderProfit:"+orderProfit);
     return orderProfit;
  }else{
    OASIS_LOG("OASIS_METHOD_HISTORY_TICKET HATA - ticket:"+ticket+" OrderSelect hata aldı. Hata kodu: "+GetLastError());
  }
  return 0;
}
// ------------------------------------------------------------------------------------ close position
void OASIS_ORDER_CLOSE_ALL(){   
    int OASIS_COUNT_ACTIVE_ORDER=OrdersTotal();   
    for(int k=0;k<OASIS_COUNT_ACTIVE_ORDER;k++){      
      if(!OrderSelect(k,SELECT_BY_POS)){
         OASIS_LOG("OASIS_ORDER_CLOSE_ALL HATA - OrderSelect("+k+", SELECT_BY_POS) - Error #"+GetLastError());
         continue;
      }      
      if(OrderMagicNumber()!=magic || OrderSymbol()!=Symbol()){
         //OASIS_LOG("OASIS_ORDER_CLOSE_ALL HATA - Robotun açtığı işlem değil.OrderSymbol:"+OrderSymbol()+" Symbol:"+Symbol());
         continue;            
      }
      if(OASIS_SNIPER == OA_BUY){// close sells
         OASIS_LOG("OASIS_ORDER_CLOSE_ALL - Kapatılan SELL ticket:"+OrderTicket()+" OrderLots:"+OrderLots());
         if(!OrderClose(OrderTicket(),OrderLots(),Ask,OASIS_SLIPPAGE,clrGreen)){
            OASIS_LOG("OASIS_ORDER_CLOSE_ALL HATA - ticket:"+OrderTicket()+" OrderLots:"+OrderLots()+" Ask:"+Ask+" - Error #"+GetLastError());
            continue;
         }
      }else if(OASIS_SNIPER == OA_BUY){//close buys
         OASIS_LOG("OASIS_ORDER_CLOSE_ALL Kapatılan BUY ticket:"+OrderTicket()+" OrderLots:"+OrderLots());
         if(!OrderClose(OrderTicket(),OrderLots(),Bid,OASIS_SLIPPAGE,clrGreen)){
            OASIS_LOG("OASIS_ORDER_CLOSE_ALL HATA - ticket:"+OrderTicket()+" OrderLots:"+OrderLots()+" Bid:"+Bid+" - Error #"+GetLastError());
            continue;         
         }
      }      
    }   
}
void OASIS_LOG2(string oasisLog=""){
   Print(oasisLog);
}
void OASIS_LOG(string oasisLog=""){
   Print("T:"+ticket+"-MN:"+magic+"-Ü:"+Symbol()+"-İşlem(0-buy):"+OASIS_SNIPER==OA_BUY?"BUY":"SELL"+"("+OASIS_SNIPER+")"
            +"-Lot:"+OASIS_SNIPER_LOT
            +"-Lot[i]:"+OASIS_SCENARIO_LOTS[OASIS_COUNTER_SEQUENTIAL_LOSS]
            +"-"+OASIS_COUNTER_SEQUENTIAL_LOSS+".kayıp"
            +"-Log:"+oasisLog
            +"-MA_BAND_VALUE_BOTTOM:"+OASIS_MA_BAND_VALUE_BOTTOM
            +"-MA_BAND_VALUE_TOP:"+OASIS_MA_BAND_VALUE_TOP
            //+"-TRAILING_STOP_IS_RUN:"+OASIS_EXT_TRAILING_STOP_IS_RUN
            //+"-TRAILING_STOP_THRESHOLD:"+OASIS_EXT_TRAILING_STOP_THRESHOLD
            //+"-TRAILING_STOP:"+OASIS_EXT_TRAILING_STOP
            +"-OASIS_ORDER_MODIFY_STOP_LOSS:"+OASIS_ORDER_MODIFY_STOP_LOSS);
}
void OASIS_PREDEFINED_VARIABLES(){
   /*Print("Symbol name of the current chart=",_Symbol);
   Print("Timeframe of the current chart=",_Period);
   Print("The latest known seller's price (ask price) for the current symbol=",Ask);
   Print("The latest known buyer's price (bid price) of the current symbol=",Bid);   
   Print("Number of decimal places=",Digits);
   Print("Number of decimal places=",_Digits);
   Print("Size of the current symbol point in the quote currency=",_Point);
   Print("Size of the current symbol point in the quote currency=",Point);   
   Print("Number of bars in the current chart=",Bars);
   Print("Open price of the current bar of the current chart=",Open[0]);
   Print("Close price of the current bar of the current chart=",Close[0]);
   Print("High price of the current bar of the current chart=",High[0]);
   Print("Low price of the current bar of the current chart=",Low[0]);
   Print("Time of the current bar of the current chart=",Time[0]);
   Print("Tick volume of the current bar of the current chart=",Volume[0]);
   Print("Last error code=",_LastError);
   Print("Random seed=",_RandomSeed);
   Print("Stop flag=",_StopFlag);
   Print("Uninitialization reason code=",_UninitReason);  */
}


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////// ***************************************** KILL ***************************************** //////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
bool OASIS_KILL_EXECUTION(){
   datetime OASIS_EXPIRE_TIME=D'2018.12.30 12:30:27';  // Year Month Day Hours Minutes Seconds
   if(TimeCurrent()>OASIS_EXPIRE_TIME){
      Print("Errorexp");
      return false;
   }
   
   if(OASIS_STRATEGY==ST_RL && (OASIS_ST_RL_TOP==0 || OASIS_ST_RL_BOTTOM==0)){
      Print("RL Strateji için girilen parametreler eksik yada hatalı olduğundan işlemler durduruldu!! OASIS_ST_RL_TOP:"+OASIS_ST_RL_TOP+" OASIS_ST_RL_BOTTOM:"+OASIS_ST_RL_BOTTOM);
      return false;
   }
   
   return true;
}