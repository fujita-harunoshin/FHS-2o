#include "../../Domains/Entities/TradingRuleParameters/BollingerBanditTradingRuleParameters.mqh"
#include "../Indicators/BollingerBandsIndicator.mqh"
#include "../Indicators/SMAIndicator.mqh"
#include "ITradingRule.mqh"

/// <summary>
/// ボリンジャーバンディット売買ルール
/// </summary>
class BollingerBanditTradingRule : public ITradingRule
{
public:
    /// <summary>
    /// コンストラクタ
    /// </summary>
    BollingerBanditTradingRule()
    {
        m_tradingRule = TRADING_RULE_TYPE::BOLLINGER_BANDIT;
        m_name = "ボリンジャーバンディット売買ルール";
        
        BollingerBanditTradingRuleParameters::BollingerBandsHandle = BollingerBandsIndicator::CreateHandle(_Symbol, _Period, 50, 0, 1.0, PRICE_CLOSE);
        BollingerBanditTradingRuleParameters::BarDataForOrder = new BarData();
        BollingerBanditTradingRuleParameters::EntriedCurrentBar = false;
        
        for (int period = 10; period <= 50; period++)
        {
            BollingerBanditTradingRuleParameters::SMAHandles[period - 10] = SMAIndicator::CreateHandle(_Symbol, _Period, period, 0);
        }
    }

    /// <summary>
    /// 初期化
    /// </summary>
    /// <returns>初期化成否</returns>
    bool Init() override
    {
        if (BollingerBanditTradingRuleParameters::BollingerBandsHandle == INVALID_HANDLE) return false;
        if (BollingerBanditTradingRuleParameters::SMAHandles[0] == 0) return false;
        
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
        BollingerBanditTradingRuleParameters *parameters = dynamic_cast<BollingerBanditTradingRuleParameters *>(&params);
        
        if (parameters.HasPosition || parameters.EntriedCurrentBar) return WRONG_VALUE;
        
        double upper_band = 0.0, lower_band = 0.0;
        if (!BollingerBandsIndicator::GetLatestValue(parameters.BollingerBandsHandle, 1, upper_band) ||
            !BollingerBandsIndicator::GetLatestValue(parameters.BollingerBandsHandle, 2, lower_band) )
        {
            return WRONG_VALUE;
        }
        
        
        double current_close = PriceData::GetClosePrice(0);
        double past_close = PriceData::GetClosePrice(30);

        if(current_close >= upper_band && current_close > past_close) return ORDER_TYPE_BUY;
        if(current_close <= lower_band && current_close < past_close) return ORDER_TYPE_SELL;
        
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
        BollingerBanditTradingRuleParameters *parameters = dynamic_cast<BollingerBanditTradingRuleParameters *>(&params);

        double upper_band = 0.0, lower_band = 0.0;
        if (!BollingerBandsIndicator::GetLatestValue(parameters.BollingerBandsHandle, 1, upper_band) ||
            !BollingerBandsIndicator::GetLatestValue(parameters.BollingerBandsHandle, 2, lower_band) )
        {
            return false;
        }
        
        if(parameters.OrderType == ORDER_TYPE_BUY)
        {
            // 買い：保護的ストップが上側バンド以上なら Exit シグナル
            if(parameters.ProtectiveStop >= upper_band && parameters.ProtectiveStop >= parameters.CurrentPriceBeforeTrail)
                return true;
        }
        else if(parameters.OrderType == ORDER_TYPE_SELL)
        {
            // 売り：保護的ストップが下側バンド以下なら Exit シグナル
            if(parameters.ProtectiveStop <= lower_band && parameters.ProtectiveStop <= parameters.CurrentPriceBeforeTrail)
                return true;
        }
        
        return false;
    }

    /// <summary>
    /// 損切ライン計算
    /// </summary>
    /// <param name="params">売買ルールパラメータ</param>
    /// <returns>損切ライン</returns>
    double CalculateStopLossPrice(ITradingRuleParameters &params) override
    {
        BollingerBanditTradingRuleParameters *parameters = dynamic_cast<BollingerBanditTradingRuleParameters *>(&params);
    
        return parameters.ProtectiveStop;
    }

    /// <summary>
    /// 利確ライン計算
    /// </summary>
    /// <param name="params">売買ルールパラメータ</param>
    /// <returns>利確ライン</returns>
    double CalculateTakeProfitPrice(ITradingRuleParameters &params) override
    {    
        BollingerBanditTradingRuleParameters *parameters = dynamic_cast<BollingerBanditTradingRuleParameters *>(&params);

        double protective_stop = 0.0;
        if(!SMAIndicator::GetLatestValue(parameters.SMAHandle, protective_stop))
            return 0.0;
        
        double risk = 0.0, tp_price = 0.0;
        if(parameters.OrderType == ORDER_TYPE_BUY)
        {
            risk = parameters.PriceAtSignal - protective_stop;
            tp_price = parameters.PriceAtSignal + 2.0 * risk;
        }
        else if(parameters.OrderType == ORDER_TYPE_SELL)
        {
            risk = protective_stop - parameters.PriceAtSignal;
            tp_price = parameters.PriceAtSignal - 2.0 * risk;
        }
        
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
        return new BollingerBanditTradingRuleParameters();
    }
    
    /// <summary>
    /// ティック毎に売買ルールパラメータを更新する処理
    /// </summary>
    void UpdateParametersOnTick() override
    {
        if (BollingerBanditTradingRuleParameters::BarDataForOrder.IsNewBar())
            BollingerBanditTradingRuleParameters::EntriedCurrentBar = false;
    }
    
    /// <summary>
    /// 売買シグナル発生時に売買ルールパラメータを更新する処理
    /// </summary>
    /// <param name="deal_ticket">チケットID/param>
    /// <param name="params">売買ルールパラメータ</param>
    void UpdateParametersOnSignaled(ENUM_ORDER_TYPE order_type, ITradingRuleParameters &params) override
    {
        BollingerBanditTradingRuleParameters *parameters = dynamic_cast<BollingerBanditTradingRuleParameters *>(&params);
        parameters.OrderType = order_type;
        parameters.PriceAtSignal = (order_type == ORDER_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK)
                                                                  : SymbolInfoDouble(_Symbol, SYMBOL_BID);

        parameters.CurrentMAPeriod = 50;
        parameters.SMAHandle = BollingerBanditTradingRuleParameters::SMAHandles[50 - 10];
        if(!SMAIndicator::GetLatestValue(parameters.SMAHandle, parameters.ProtectiveStop))
            parameters.ProtectiveStop = 0;
    }
    
    /// <summary>
    /// ポジション作成時に売買ルールパラメータを更新する処理
    /// </summary>
    /// <param name="deal_ticket">チケットID/param>
    /// <param name="params">売買ルールパラメータ</param>
    void UpdateParametersOnEntryIn(ulong deal_ticket, ITradingRuleParameters &params) override
    {
        BollingerBanditTradingRuleParameters *parameters = dynamic_cast<BollingerBanditTradingRuleParameters *>(&params);
        parameters.EntriedCurrentBar = true;
        parameters.HasPosition = true;
        parameters.PositionType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
        parameters.BarDataForTrail = new BarData();
    }
    
    /// <summary>
    /// トレーリングストップ計算前に売買ルールパラメータを更新する処理
    /// </summary>
    /// <param name="deal_ticket">チケットID/param>
    /// <param name="params">売買ルールパラメータ</param>
    void UpdateParametersBeforeTrail(ulong deal_ticket, ITradingRuleParameters &params)
    {
        BollingerBanditTradingRuleParameters *parameters = dynamic_cast<BollingerBanditTradingRuleParameters *>(&params);
        parameters.CurrentPriceBeforeTrail = (parameters.PositionType == POSITION_TYPE_BUY)
                                    ? SymbolInfoDouble(_Symbol, SYMBOL_BID)
                                    : SymbolInfoDouble(_Symbol, SYMBOL_ASK);

        if (parameters.BarDataForTrail.IsNewBar())
        {
            if (parameters.CurrentMAPeriod > 10)
            {
                parameters.CurrentMAPeriod--;
                parameters.SMAHandle = BollingerBanditTradingRuleParameters::SMAHandles[parameters.CurrentMAPeriod - 10];
            }
        }
        
        if(!SMAIndicator::GetLatestValue(parameters.SMAHandle, parameters.ProtectiveStop))
            parameters.ProtectiveStop = 0;
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
        BollingerBanditTradingRuleParameters *parameters = dynamic_cast<BollingerBanditTradingRuleParameters *>(&params);
        parameters.HasPosition = false;
    }
};
