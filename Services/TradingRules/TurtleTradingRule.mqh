#include "../../Domains/Entities/TradingRuleParameters/TurtleTradingRuleParameters.mqh"
#include "ITradingRule.mqh"

/// <summary>
/// タートル流売買ルール
/// </summary>
class TurtleTradingRule : public ITradingRule
{
public:
    /// <summary>
    /// コンストラクタ
    /// </summary>
    TurtleTradingRule()
    {
        m_tradingRule = TRADING_RULE_TYPE::TURTLE;
        m_name = "タートル流トレーディング";
        
        TurtleTradingRuleParameters::AtrHandle = ATRIndicator::CreateHandle(_Symbol, _Period, 20);
        TurtleTradingRuleParameters::BarDataInstance = new BarData();
        TurtleTradingRuleParameters::EntriedCurrentBar = false;
        TurtleTradingRuleParameters::HasPosition = false;
    }

    /// <summary>
    /// 初期化
    /// </summary>
    /// <returns>初期化成否</returns>
    bool Init() override
    {
        if (TurtleTradingRuleParameters::AtrHandle == INVALID_HANDLE) return false;
        
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
        TurtleTradingRuleParameters *parameters = dynamic_cast<TurtleTradingRuleParameters *>(&params);
        if (parameters.HasPosition || parameters.EntriedCurrentBar) return WRONG_VALUE;
        
        double high_price_current_bar = PriceData::GetHighPrice();
        double low_price_current_bar = PriceData::GetLowPrice();
        double highest_price_completed_bar = PriceData::GetHighestPriceCompletedBar(20);
        double lowest_price_completed_bar = PriceData::GetLowestPriceCompletedBar(20);

        if (high_price_current_bar > highest_price_completed_bar) return ORDER_TYPE_BUY;
        
        if (low_price_current_bar < lowest_price_completed_bar) return ORDER_TYPE_SELL;

        return WRONG_VALUE;
    }
    
    /// <summary>
    /// ペンディングオーダー破棄シグナル判定
    /// </summary>
    /// <param name="params">売買ルールパラメータ</param>
    /// <returns>シグナル発生時は true</returns>
    bool CheckOrderCancelSignal(ITradingRuleParameters &params) override { return false; }
    
    /// <summary>
    /// エグジットシグナル判定
    /// </summary>
    /// <param name="params">売買ルールパラメータ</param>
    /// <returns>エグジットシグナル</returns>
    bool CheckExitSignal(ITradingRuleParameters &params) override
    {
        TurtleTradingRuleParameters *parameters = dynamic_cast<TurtleTradingRuleParameters *>(&params);

        double high_price_current_bar = PriceData::GetHighPrice();
        double low_price_current_bar = PriceData::GetLowPrice();
        double highest_price_completed_bar = PriceData::GetHighestPriceCompletedBar(10);
        double lowest_price_completed_bar = PriceData::GetLowestPriceCompletedBar(10);

        if (parameters.PositionType == POSITION_TYPE_BUY && low_price_current_bar < lowest_price_completed_bar)
            return true;
        else if (parameters.PositionType == POSITION_TYPE_SELL && high_price_current_bar > highest_price_completed_bar)
            return true;

        return false;
    }

    /// <summary>
    /// 損切ライン計算
    /// </summary>
    /// <param name="params">売買ルールパラメータ</param>
    /// <returns>損切ライン</returns>
    double CalculateStopLossPrice(ITradingRuleParameters &params) override
    {
        TurtleTradingRuleParameters *parameters = dynamic_cast<TurtleTradingRuleParameters *>(&params);
    
        double stop_distance = parameters.AtrValue * 2.0;
        double sl_price = 0.0;
        if (parameters.OrderType == ORDER_TYPE_BUY)
            sl_price = parameters.PriceAtSignal - stop_distance;
        else if (parameters.OrderType == ORDER_TYPE_SELL)
            sl_price = parameters.PriceAtSignal + stop_distance;
            
        return sl_price;
    }

    /// <summary>
    /// 利確ライン計算
    /// </summary>
    /// <param name="params">売買ルールパラメータ</param>
    /// <returns>利確ライン</returns>
    double CalculateTakeProfitPrice(ITradingRuleParameters &params) override
    {
        TurtleTradingRuleParameters *parameters = dynamic_cast<TurtleTradingRuleParameters *>(&params);

        double take_distance = parameters.AtrValue * 2.0;
        double tp_price = 0.0;
        if (parameters.OrderType == ORDER_TYPE_BUY)
            tp_price = parameters.PriceAtSignal + take_distance;
        else if (parameters.OrderType == ORDER_TYPE_SELL)
            tp_price = parameters.PriceAtSignal - take_distance;

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
        TurtleTradingRuleParameters *parameters = dynamic_cast<TurtleTradingRuleParameters *>(&params);

        double entry_price = parameters.EntryPrice;  
        double initial_stop_loss_price = parameters.InitialStopLossPrice;
        double initial_stop_loss_width_price = MathAbs(entry_price - initial_stop_loss_price);

        double current_price = parameters.CurrentPriceBeforeTrail;
        double current_stop_loss_price = parameters.CurrentStopLossPrice;
        if (parameters.PositionType == POSITION_TYPE_BUY)
        {
            double current_stop_loss_width_price = current_price - current_stop_loss_price;

            if (current_stop_loss_width_price > initial_stop_loss_width_price)
            {
                trailing_stop_price = current_price - initial_stop_loss_width_price;
                return true;
            }
        }
        else if (parameters.PositionType == POSITION_TYPE_SELL)
        {
            double current_stop_loss_width_price = current_stop_loss_price - current_price;

            if (current_stop_loss_width_price > initial_stop_loss_width_price)
            {
                trailing_stop_price = current_price + initial_stop_loss_width_price;
                return true;
            }
        }

        return false;
    }

    /// <summary>
    /// オーダー時に売買ルールパラメータのインスタンスを作成
    /// </summary>
    ITradingRuleParameters* CreateParametersInstance() override
    {
        return new TurtleTradingRuleParameters();
    }
    
    /// <summary>
    /// ティック毎に売買ルールパラメータを更新する処理
    /// </summary>
    void UpdateParametersOnTick() override
    {
        if (TurtleTradingRuleParameters::BarDataInstance.IsNewBar())
            TurtleTradingRuleParameters::EntriedCurrentBar = false;
    }
    
    /// <summary>
    /// 売買シグナル発生時に売買ルールパラメータを更新する処理
    /// </summary>
    /// <param name="deal_ticket">チケットID/param>
    /// <param name="params">売買ルールパラメータ</param>
    void UpdateParametersOnSignaled(ENUM_ORDER_TYPE order_type, ITradingRuleParameters &params) override
    {
        TurtleTradingRuleParameters *parameters = dynamic_cast<TurtleTradingRuleParameters *>(&params);
        parameters.OrderType = order_type;
        parameters.PriceAtSignal = (order_type == ORDER_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK)
                                                                  : SymbolInfoDouble(_Symbol, SYMBOL_BID);

        double atr_value;
        if (!ATRIndicator::GetLatestValue(parameters.AtrHandle, atr_value)) atr_value = 0;
        parameters.AtrValue = atr_value;
    }
    
    /// <summary>
    /// ポジション作成時に売買ルールパラメータを更新する処理
    /// </summary>
    /// <param name="deal_ticket">チケットID/param>
    /// <param name="params">売買ルールパラメータ</param>
    void UpdateParametersOnEntryIn(ulong deal_ticket, ITradingRuleParameters &params) override
    {
        TurtleTradingRuleParameters *parameters = dynamic_cast<TurtleTradingRuleParameters *>(&params);
        parameters.EntriedCurrentBar = true;
        parameters.HasPosition = true;
        parameters.EntryPrice = HistoryDealGetDouble(deal_ticket, DEAL_PRICE);
        parameters.PositionType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
        parameters.InitialStopLossPrice = HistoryDealGetDouble(deal_ticket, DEAL_SL);
    }
    
    /// <summary>
    /// トレーリングストップ計算前に売買ルールパラメータを更新する処理
    /// </summary>
    /// <param name="deal_ticket">チケットID/param>
    /// <param name="params">売買ルールパラメータ</param>
    virtual void UpdateParametersBeforeTrail(ulong deal_ticket, ITradingRuleParameters &params)
    {
        TurtleTradingRuleParameters *parameters = dynamic_cast<TurtleTradingRuleParameters *>(&params);
        parameters.CurrentPriceBeforeTrail = (parameters.PositionType == POSITION_TYPE_BUY)
                                   ? SymbolInfoDouble(_Symbol, SYMBOL_BID)
                                   : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
        parameters.CurrentStopLossPrice = HistoryDealGetDouble(deal_ticket, DEAL_SL);
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
        TurtleTradingRuleParameters *parameters = dynamic_cast<TurtleTradingRuleParameters *>(&params);
        parameters.HasPosition = false;
    }
};
