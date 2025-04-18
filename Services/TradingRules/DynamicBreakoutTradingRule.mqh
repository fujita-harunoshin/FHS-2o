#include "../../Domains/Entities/TradingRuleParameters/DynamicBreakoutTradingRuleParameters.mqh"
#include "../Indicators/BollingerBandsIndicator.mqh"
#include "../Indicators/SMAIndicator.mqh"
#include "ITradingRule.mqh"

/// <summary>
/// ダイナミックブレイクアウト売買ルール
/// https://piquant-eyebrow-081.notion.site/197e7b760a1d802dba80c0dbab7d3a92?pvs=4
/// </summary>
class DynamicBreakoutTradingRule : public ITradingRule
{
public:
    /// <summary>
    /// コンストラクタ
    /// </summary>
    DynamicBreakoutTradingRule()
    {
        m_tradingRule = TRADING_RULE_TYPE::DYNAMIC_BREAKOUT;
        m_name = "ダイナミックブレイクアウト売買ルール";
        
        DynamicBreakoutTradingRuleParameters::DeviationToday = CalculateStandardDeviation(30);
        DynamicBreakoutTradingRuleParameters::LookBackDaysToday = 20;
        
        DynamicBreakoutTradingRuleParameters::BarDataInstance = new BarData();
        DynamicBreakoutTradingRuleParameters::EntriedCurrentBar = false;
        DynamicBreakoutTradingRuleParameters::HasPosition = false;
        
        for (int period = 20; period <= 60; period++)
        {
            DynamicBreakoutTradingRuleParameters::BollingerBandHandles[period - 20] = BollingerBandsIndicator::CreateHandle(_Symbol, _Period, period, 0, 2, PRICE_CLOSE);
            DynamicBreakoutTradingRuleParameters::SMAHandles[period - 20] = SMAIndicator::CreateHandleCustom(_Symbol, _Period, period, 0, PRICE_CLOSE);
        }
    }

    /// <summary>
    /// 初期化
    /// </summary>
    /// <returns>初期化成否</returns>
    bool Init() override
    {
        if (DynamicBreakoutTradingRuleParameters::BollingerBandHandles[0] == 0) return false;
        if (DynamicBreakoutTradingRuleParameters::SMAHandles[0] == 0) return false;
        
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
        DynamicBreakoutTradingRuleParameters *parameters = dynamic_cast<DynamicBreakoutTradingRuleParameters *>(&params);
        if (parameters.HasPosition || parameters.EntriedCurrentBar) return WRONG_VALUE;
        
        double high_price_current_bar = PriceData::GetHighPrice();
        double low_price_current_bar = PriceData::GetLowPrice();
        double highest_price_completed_bar = PriceData::GetHighestPriceCompletedBar(parameters.LookBackDaysToday);
        double lowest_price_completed_bar = PriceData::GetLowestPriceCompletedBar(parameters.LookBackDaysToday);
        
        double upper_band = 0.0, lower_band = 0.0;
        if (!BollingerBandsIndicator::GetLatestValue(parameters.BollingerBandHandleToday, 1, upper_band) ||
            !BollingerBandsIndicator::GetLatestValue(parameters.BollingerBandHandleToday, 2, lower_band) )
        {
            return WRONG_VALUE;
        }

        if(parameters.PriceCloseYesterday >= upper_band && high_price_current_bar > highest_price_completed_bar) return ORDER_TYPE_BUY;
        if(parameters.PriceCloseYesterday <= lower_band && low_price_current_bar < lowest_price_completed_bar) return ORDER_TYPE_SELL;

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
        return false;
    }

    /// <summary>
    /// 損切ライン計算
    /// </summary>
    /// <param name="params">売買ルールパラメータ</param>
    /// <returns>損切ライン</returns>
    double CalculateStopLossPrice(ITradingRuleParameters &params) override
    {
        DynamicBreakoutTradingRuleParameters *parameters = dynamic_cast<DynamicBreakoutTradingRuleParameters *>(&params);
        
        int sma_handle = parameters.SMAHandles[parameters.LookBackDaysAtSignal - 20];
        double sl_price = 0.0;
        if(!SMAIndicator::GetLatestValue(sma_handle, sl_price))
            sl_price = 0;
        
        return sl_price;
    }

    /// <summary>
    /// 利確ライン計算
    /// </summary>
    /// <param name="params">売買ルールパラメータ</param>
    /// <returns>利確ライン</returns>
    double CalculateTakeProfitPrice(ITradingRuleParameters &params) override
    {
        DynamicBreakoutTradingRuleParameters *parameters = dynamic_cast<DynamicBreakoutTradingRuleParameters *>(&params);

        return 0;
    }

    /// <summary>
    /// トレーリングストップロスライン計算
    /// </summary>
    /// <param name="params">売買ルールパラメータ</param>
    /// <param name="new_sl_price">新しい損切ライン</param>
    /// <returns>トレーリングの適否</returns>
    bool CalculateTrailingStopLossPrice(ITradingRuleParameters &params, double &trailing_stop_price) override
    {
        DynamicBreakoutTradingRuleParameters *parameters = dynamic_cast<DynamicBreakoutTradingRuleParameters *>(&params);

        int sma_handle = parameters.SMAHandles[parameters.LookBackDaysAtSignal - 20];
        double sl_price_temp = trailing_stop_price;
        if(!SMAIndicator::GetLatestValue(sma_handle, trailing_stop_price))
            return false;
        
        int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
        double tolerance = MathPow(10, -digits);
        
        if(MathAbs(sl_price_temp - trailing_stop_price) < tolerance)
            return false;
        
        return true;
    }

    /// <summary>
    /// オーダー時に売買ルールパラメータのインスタンスを作成
    /// </summary>
    ITradingRuleParameters* CreateParametersInstance() override
    {
        return new DynamicBreakoutTradingRuleParameters();
    }
    
    /// <summary>
    /// ティック毎に売買ルールパラメータを更新する処理
    /// </summary>
    void UpdateParametersOnTick() override
    {
        if (DynamicBreakoutTradingRuleParameters::BarDataInstance.IsNewBar())
        {
            DynamicBreakoutTradingRuleParameters::EntriedCurrentBar = false;
            
            DynamicBreakoutTradingRuleParameters::PriceCloseYesterday = PriceData::GetClosePrice(1);
            
            double deviation_temp = DynamicBreakoutTradingRuleParameters::DeviationToday;
            int look_back_days_temp = DynamicBreakoutTradingRuleParameters::LookBackDaysToday;
            
            DynamicBreakoutTradingRuleParameters::DeviationToday = CalculateStandardDeviation(30);
            int look_back_days_today = CalculateLookBackDays(
                DynamicBreakoutTradingRuleParameters::DeviationYesterday,
                DynamicBreakoutTradingRuleParameters::DeviationToday,
                DynamicBreakoutTradingRuleParameters::LookBackDaysYesterday);
            DynamicBreakoutTradingRuleParameters::LookBackDaysToday = look_back_days_today;
            
            DynamicBreakoutTradingRuleParameters::DeviationYesterday = deviation_temp;
            DynamicBreakoutTradingRuleParameters::LookBackDaysYesterday = look_back_days_temp;
            DynamicBreakoutTradingRuleParameters::BollingerBandHandleToday =
                DynamicBreakoutTradingRuleParameters::BollingerBandHandles[look_back_days_today - 20];
        }
    }
    
    /// <summary>
    /// 売買シグナル発生時に売買ルールパラメータを更新する処理
    /// </summary>
    /// <param name="deal_ticket">チケットID/param>
    /// <param name="params">売買ルールパラメータ</param>
    void UpdateParametersOnSignaled(ENUM_ORDER_TYPE order_type, ITradingRuleParameters &params) override
    {
        DynamicBreakoutTradingRuleParameters *parameters = dynamic_cast<DynamicBreakoutTradingRuleParameters *>(&params);
        parameters.OrderType = order_type;
        parameters.LookBackDaysAtSignal = parameters.LookBackDaysToday;
    }
    
    /// <summary>
    /// ポジション作成時に売買ルールパラメータを更新する処理
    /// </summary>
    /// <param name="deal_ticket">チケットID/param>
    /// <param name="params">売買ルールパラメータ</param>
    void UpdateParametersOnEntryIn(ulong deal_ticket, ITradingRuleParameters &params) override
    {
        DynamicBreakoutTradingRuleParameters *parameters = dynamic_cast<DynamicBreakoutTradingRuleParameters *>(&params);
        parameters.EntriedCurrentBar = true;
        parameters.HasPosition = true;
        parameters.PositionType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
    }
    
    /// <summary>
    /// トレーリングストップ計算前に売買ルールパラメータを更新する処理
    /// </summary>
    /// <param name="deal_ticket">チケットID/param>
    /// <param name="params">売買ルールパラメータ</param>
    virtual void UpdateParametersBeforeTrail(ulong deal_ticket, ITradingRuleParameters &params)
    {
        DynamicBreakoutTradingRuleParameters *parameters = dynamic_cast<DynamicBreakoutTradingRuleParameters *>(&params);
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
    /// <param name="deal_ticket">チケットID</param>
    /// <param name="params">売買ルールパラメータ</param>
    void UpdateParametersOnEntryOut(ulong deal_ticket, ITradingRuleParameters &params) override
    {
        DynamicBreakoutTradingRuleParameters *parameters = dynamic_cast<DynamicBreakoutTradingRuleParameters *>(&params);
        parameters.HasPosition = false;
    }

private:
    /// <summary>
    /// 終値の標準偏差を計算
    /// </summary>
    /// <param name="period">期間(この売買ルールでは原則30日)</param>
    /// <returns>標準偏差</returns>
    double CalculateStandardDeviation(int period)
    {
        double closes[];
        if (CopyClose(_Symbol, _Period, 1, period, closes) < period)
        {
            Print("CalculateStandardDeviation: 十分なデータが取得できませんでした");
            return 0.0;
        }
        ArraySetAsSeries(closes, true);
        double sum = 0.0;
        for (int i = 0; i < period; i++)
            sum += closes[i];
        
        double mean = sum / period;
        double variance = 0.0;
        for (int i = 0; i < period; i++)
            variance += (closes[i] - mean) * (closes[i] - mean);
        
        variance /= period;
        return MathSqrt(variance);
    }
    
    /// <summary>
    /// 適応エンジン
    /// 終値の標準偏差の変動分、ルックバック日数を変化
    /// </summary>
    /// <param name="deviation_yesterday">昨日の終値標準偏差</param>
    /// <param name="deviation_today">今日の終値標準偏差</param>
    /// <param name="look_back_days_yesterday">昨日のルックバック日数</param>
    /// <returns>今日のルックバック日数</returns>
    int CalculateLookBackDays(double deviation_yesterday, double deviation_today, int look_back_days_yesterday)
    {
        if (deviation_yesterday == 0.0) return 20;
        
        double ratio = deviation_today / deviation_yesterday;
        double new_look_back_days = look_back_days_yesterday * ratio;
        
        if (new_look_back_days < 20) new_look_back_days = 20;
        if (new_look_back_days > 60) new_look_back_days = 60;
        
        return (int)MathRound(new_look_back_days);
    }
};
