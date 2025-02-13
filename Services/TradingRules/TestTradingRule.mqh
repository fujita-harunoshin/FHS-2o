#include "ITradingRule.mqh"
#include "../../Domains/Entities/TradingRuleParameters/TestTradingRuleParameters.mqh"

class TestTradingRule : public ITradingRule
{
public:
    /// <summary>
    /// コンストラクタ
    /// </summary>
    TestTradingRule()
    {
    }
    
    /// <summary>
    /// 初期化
    /// </summary>
    /// <returns>初期化成否</returns>
    bool Init() override
    {
        return true;
    }

    /// <summary>
    /// エントリーシグナル判定
    /// </summary>
    /// <param name="params">売買ルールパラメータ</param>
    /// <param name="entry_price">指値の場合はその価格param>
    /// <returns>エントリー種別</returns>
    ENUM_ORDER_TYPE CheckEntrySignal(ITradingRuleParameters &params, double &entry_price) override
    {
        TestTradingRuleParameters *parameters = dynamic_cast<TestTradingRuleParameters *>(&params);
        if(MathRand() % 1000 == 0)
        {
            if(MathRand() % 2 == 0)
                return ORDER_TYPE_BUY;
            else
                return ORDER_TYPE_SELL;
        }

        return WRONG_VALUE;
    }

    /// <summary>
    /// エグジットシグナル判定
    /// </summary>
    /// <param name="params">売買ルールパラメータ</param>
    /// <returns>エグジットシグナル</returns>
    bool CheckExitSignal(ITradingRuleParameters &params) override
    {
        TestTradingRuleParameters *parameters = dynamic_cast<TestTradingRuleParameters *>(&params);
        return (MathRand() % 1000 == 0);
    }

    /// <summary>
    /// 損切ライン計算
    /// </summary>
    /// <param name="params">売買ルールパラメータ</param>
    /// <returns>損切ライン</returns>
    double CalculateStopLossPrice(ITradingRuleParameters &params) override
    {
        TestTradingRuleParameters *parameters = dynamic_cast<TestTradingRuleParameters *>(&params);
        double sl_price = 0.0;
        
        if (parameters.OrderType == ORDER_TYPE_BUY)
            sl_price = parameters.PriceAtSignal - Utility::PipsToPrice(10);
        else if (parameters.OrderType == ORDER_TYPE_SELL)
            sl_price = parameters.PriceAtSignal + Utility::PipsToPrice(10);
        
        return sl_price;
    }

    /// <summary>
    /// 利確ライン計算
    /// </summary>
    /// <param name="params">売買ルールパラメータ</param>
    /// <returns>損切ライン</returns>
    double CalculateTakeProfitPrice(ITradingRuleParameters &params) override
    {
        TestTradingRuleParameters *parameters = dynamic_cast<TestTradingRuleParameters *>(&params);
        double tp_price = 0.0;
        
        if (parameters.OrderType == ORDER_TYPE_BUY)
            tp_price = parameters.PriceAtSignal + Utility::PipsToPrice(20);
        else if (parameters.OrderType == ORDER_TYPE_SELL)
            tp_price = parameters.PriceAtSignal - Utility::PipsToPrice(20);
        
        return tp_price;
    }
    
    /// <summary>
    /// トレーリングストップロスライン計算
    /// </summary>
    /// <param name="params">売買ルールパラメータ</param>
    /// <param name="new_sl_price">新しい損切ライン</param>
    /// <returns>トレーリングの適否</returns>
    bool CalculateTrailingStopLossPrice(ITradingRuleParameters &params, double &trailing_stop_price) override
    {
        return false;
    }
    
    /// <summary>
    /// オーダー時に売買ルールパラメータのインスタンスを作成
    /// </summary>
    ITradingRuleParameters* CreateParametersInstance() override
    {
        return new TestTradingRuleParameters();
    }
    
    /// <summary>
    /// ティック毎に売買ルールパラメータを更新する処理
    /// </summary>
    void UpdateParametersOnTick() override
    {
    }
    
    /// <summary>
    /// 売買シグナル発生時に売買ルールパラメータを更新する処理
    /// </summary>
    /// <param name="deal_ticket">チケットID/param>
    /// <param name="params">売買ルールパラメータ</param>
    void UpdateParametersOnSignaled(ENUM_ORDER_TYPE order_type, ITradingRuleParameters &params) override
    {
        TestTradingRuleParameters *parameters = dynamic_cast<TestTradingRuleParameters *>(&params);
        parameters.OrderType = order_type;
        parameters.PriceAtSignal = (order_type == ORDER_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK)
                                                                  : SymbolInfoDouble(_Symbol, SYMBOL_BID);
    }
    
    /// <summary>
    /// ポジション作成時に売買ルールパラメータを更新する処理
    /// </summary>
    /// <param name="deal_ticket">チケットID/param>
    /// <param name="params">売買ルールパラメータ</param>
    void UpdateParametersOnEntryIn(ulong deal_ticket, ITradingRuleParameters &params) override
    {
    }
    
    /// <summary>
    /// トレーリングストップ計算前に売買ルールパラメータを更新する処理
    /// </summary>
    /// <param name="deal_ticket">チケットID/param>
    /// <param name="params">売買ルールパラメータ</param>
    void UpdateParametersBeforeTrail(ulong deal_ticket, ITradingRuleParameters &params)
    {
    }
    
    /// <summary>
    /// ポジション更新毎に売買ルールパラメータを更新する処理
    /// </summary>
    /// <param name="deal_ticket">チケットID/param>
    /// <param name="params">売買ルールパラメータ</param>
    void UpdateParametersOnDealUpdate(ulong deal_ticket, ITradingRuleParameters &params) override
    {
    }
    
    /// <summary>
    /// 手仕舞い時に売買ルールパラメータを更新する処理
    /// </summary>
    /// <param name="deal_ticket">チケットID/param>
    /// <param name="params">売買ルールパラメータ</param>
    void UpdateParametersOnEntryOut(ulong deal_ticket, ITradingRuleParameters &params) override
    {
        TestTradingRuleParameters *parameters = dynamic_cast<TestTradingRuleParameters *>(&params);
    }
};
