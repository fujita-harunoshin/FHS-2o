//+------------------------------------------------------------------+
//|                                                       FHS-2o.mq5 |
//|                               Copyright 2024, Harunoshin Fujita. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

#property version "1.00"

#include "Application/FHSBase.mqh"
#include "Domains/Types/TradingRuleType.mqh"
#include "Domains/Types/MoneyManagementType.mqh"
#include "Services/TradingRules/TurtleTradingRule.mqh"
#include "Services/TradingRules/KingKeltnerTradingRule.mqh"
#include "Services/TradingRules/BollingerBanditTradingRule.mqh"
#include "Services/TradingRules/ThermostatTradingRule.mqh"
#include "Services/TradingRules/DynamicBreakoutTradingRule.mqh"
#include "Services/TradingRules/SuperComboTradingRule.mqh"
#include "Services/TradingRules/DragonCloudTradingRule.mqh"
#include "Services/TradingRules/TestTradingRule.mqh"
#include "Services/MoneyManagement/NLotMoneyManagement.mqh"
#include "Services/MoneyManagement/FixedRiskMoneyManagement.mqh"
#include "Services/MoneyManagement/FixedCapitalMoneyManagement.mqh"
#include "Services/MoneyManagement/FixedRatioMoneyManagement.mqh"
#include "Services/MoneyManagement/FixedUnitsMoneyManagement.mqh"
#include "Services/MoneyManagement/WilliamsFixedRiskMoneyManagement.mqh"
#include "Services/MoneyManagement/FixedPercentageMoneyManagement.mqh"
#include "Services/MoneyManagement/FixedVolatilityMoneyManagement.mqh"
#include "Services/ErrorLogger.mqh"

input string TitleMGMT = "";                        //【資金管理】---------------------------------------------------------

//=== Nロット法のパラメータ
input string SubTitleNL = "";                       // ★ Nロット法
input double InpLotNumberNL = 1;                    //   └ ロット数[ロット]

//=== 固定リスク額法のパラメータ
input string SubTitleFRSK = "";                     // ★ 固定リスク額法
input int InpUnitNumberFRSK =  100;                 //   └ ユニット数[]

//=== 固定資金法のパラメータ
input string SubTitleFC = "";                       // ★ 固定資金法
input double InpMaxDrawdownFC = 0;                  //   └ 最大ドローダウン[アカウント通貨単位/ロット]
input double InpBlowtorchRiskPercentageFC = 5;      //   └ ブロートーチリスク率[%]

//=== 固定比率法のパラメータ
input string SubTitleFRTO = "";                     // ★ 固定比率法
input double InpMaxDrawdownFRTO = 0;                //   └ 最大ドローダウン[アカウント通貨単位/ロット]

//=== 固定ユニット法のパラメータ
input string SubTitleFU = "";                       // ★ 固定ユニット法
input int InpUnitNumberFU = 20;                     //   └ ユニット数[]

//===ウィリアムズの固定リスク率法のパラメータ
input string SubTitleWFR = "";                      // ★ ウィリアムズの固定リスク率法
input double InpRiskPercentWFR = 1;                 //   └ リスク率[%]
input double InpMaxLossPriceDefaultWFR = 10000;     //   └ デフォルトの1回のトレードの最大損失額[アカウント通貨単位/ロット]

//=== 定率法のパラメータ
input string SubTitleFP = "";                       // ★ 定率法
input double InpRiskPercentFP = 2;                  //   └ 定率[%]

//=== 固定ボラティリティ法のパラメータ
input string SubTitleFV = "";                       // ★ 固定ボラティリティ法
input double InpRiskPercentFV = 2;                  //   └ 定率[%]
input int InpAtrPeriodFV = 10;                      //   └ ATRの期間[本]


input string TitleTR = "";                          //【売買ルール】---------------------------------------------------------

//=== 売買ルール1: タートル流トレーディング
input string SubTitleTT = "";                       // ★ タートル流トレーディング
input bool UseTurtleTradingRule = true;             //   └ 採否
input MONEY_MANAGEMENT_TYPE TTMoneyManagement
                            = FIXED_VOLATILITY;     //   └ 資金管理法選択(原則固定ボラティリティ固定 : 定率2%, 期間20)

//=== 売買ルール2: キングケルトナー売買ルール
input string SubTitleKK = "";                       // ★ キングケルトナー売買ルール
input bool UseKingKeltnerTradingRule = true;        //   └ 採否
input MONEY_MANAGEMENT_TYPE KKMoneyManagement;      //   └ 資金管理法選択

//=== 売買ルール3: ボリンジャーバンディット売買ルール
input string SubTitleBB = "";                       // ★ ボリンジャーバンディット売買ルール
input bool UseBollingerBanditTradingRule = true;    //   └ 採否
input MONEY_MANAGEMENT_TYPE BBMoneyManagement;      //   └ 資金管理法選択

//=== 売買ルール4: サーモスタット売買ルール
input string SubTitleTS = "";                       // ★ サーモスタット売買ルール
input bool UseThermostatTradingRule = true;         //   └ 採否
input MONEY_MANAGEMENT_TYPE TSMoneyManagement;      //   └ 資金管理法選択

//=== 売買ルール5: ダイナミックブレイクアウト売買ルール
input string SubTitleDB = "";                       // ★ ダイナミックブレイクアウト売買ルール
input bool UseDynamicBreakoutTradingRule = true;  //   └ 採否
input MONEY_MANAGEMENT_TYPE DBMoneyManagement;      //   └ 資金管理法選択
                            
//=== 売買ルール99: テスト用売買ルール
input string SubTitleTestTest = "";                 // ★ テスト用売買ルール
input bool UseTestTradingRule = false;              //   └ 採否
input MONEY_MANAGEMENT_TYPE TestMoneyManagement;    //   └ 資金管理法選択(原則固定ボラティリティ固定 : 定率2%, 期間20)

input string TitleOTH = "";                         //【その他】----------------------------------------------------------

//=== 入力パラメータ ===
input bool InpLogIndicesOnDealOut = false;          // 手仕舞い時の指標出力の適否
input bool InpLogIndicesOnEAStop = true;            // EA停止時の指標出力の適否
input ulong InpMagicNumber = 318;                   // マジックナンバー

FHSBase g_FHSBase;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    if (!g_FHSBase.Init(InpMagicNumber, InpLogIndicesOnDealOut, InpLogIndicesOnEAStop))
    {
        Print("Failed to init TradingService.");
        return INIT_FAILED;
    }
    
    if (UseTurtleTradingRule)
        if (!AddStrategy(new TurtleTradingRule(), TTMoneyManagement))
            return INIT_FAILED;
    
    if (UseKingKeltnerTradingRule)
        if (!AddStrategy(new KingKeltnerTradingRule(), KKMoneyManagement))
            return INIT_FAILED;
            
    if (UseBollingerBanditTradingRule)
        if (!AddStrategy(new BollingerBanditTradingRule(), BBMoneyManagement))
            return INIT_FAILED;
    
    if (UseThermostatTradingRule)
        if (!AddStrategy(new ThermostatTradingRule(), TSMoneyManagement))
            return INIT_FAILED;
    
    if (UseDynamicBreakoutTradingRule)
        if (!AddStrategy(new DynamicBreakoutTradingRule(), DBMoneyManagement))
            return INIT_FAILED;
    
    if (UseTestTradingRule)
        if (!AddStrategy(new TestTradingRule(), TestMoneyManagement))
            return INIT_FAILED;

    return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    g_FHSBase.Deinit();
    ErrorLogger::LogDeinitReason(reason);
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    g_FHSBase.OnTick();
}
//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
{
    g_FHSBase.OnTradeTransaction(trans, request, result);
}

/// <summary>
/// 売買ルールと資金管理法を追加する共通関数
/// </summary>
/// <param name="trading_rule">売買ルール</param>
/// <param name="money_management_type">資金管理法</param>
/// <returns>追加の成否</returns>
bool AddStrategy(ITradingRule* trading_rule, MONEY_MANAGEMENT_TYPE money_management_type)
{
    IMoneyManagement* money_management = CreateMoneyManagementInstance(money_management_type);
    
    if (!trading_rule.Init())
    {
        Print("エラー: " + trading_rule.GetName() + "の初期化に失敗しました。");
        delete trading_rule;
        return false;
    }

    if (money_management == NULL)
    {
        Print("エラー: " + trading_rule.GetName() + "に設定した資金管理法のインスタンス生成に失敗しました。");
        delete trading_rule;
        return false;
    }
    
    g_FHSBase.AddStrategy(trading_rule, money_management);

    return true;
}

/// <summary>
/// 資金管理法のインスタン生成
/// </summary>
/// <param name="money_management_type">資金管理法</param>
/// <returns>資金管理法のインスタンス</returns>
IMoneyManagement* CreateMoneyManagementInstance(MONEY_MANAGEMENT_TYPE money_management_type)
{
    switch (money_management_type)
    {
        case N_LOT:
            return new NLotMoneyManagement(InpLotNumberNL);
            break;
        case FIXED_RISK:
            return new FixedRiskMoneyManagement(InpUnitNumberFRSK);
            break;
        case FIXED_CAPITAL:
            return new FixedCapitalMoneyManagement(InpMaxDrawdownFC, InpBlowtorchRiskPercentageFC);
            break;
        case FIXED_RATIO:
            return new FixedRatioMoneyManagement(InpMaxDrawdownFRTO);
            break;
        case FIXED_UNITS:
            return new FixedUnitsMoneyManagement(InpUnitNumberFU);
            break;
        case WILLIAMS_FIXED_RISK:
            return new WilliamsFixedRiskMoneyManagement(InpRiskPercentWFR, InpMaxLossPriceDefaultWFR);
            break;
        case FIXED_PERCENTAGE:
            return new FixedPercentageMoneyManagement(InpRiskPercentFP);
            break;
        case FIXED_VOLATILITY:
            return new FixedVolatilityMoneyManagement(InpRiskPercentFV, InpAtrPeriodFV);
        default:
            Print("エラー: 未知の MONEY_MANAGEMENT_TYPE が渡されました: " + IntegerToString(money_management_type));
            return NULL;
    }
}