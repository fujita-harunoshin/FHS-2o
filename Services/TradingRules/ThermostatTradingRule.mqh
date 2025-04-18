#include "../../Domains/Entities/TradingRuleParameters/ThermostatTradingRuleParameters.mqh"
#include "../Indicators/ChoppyMarketIndexIndicator.mqh"
#include "../Indicators/BollingerBandsIndicator.mqh"
#include "../Indicators/ATRIndicator.mqh"
#include "../Indicators/SMAIndicator.mqh"
#include "ITradingRule.mqh"

/// <summary>
/// サーモスタット売買ルール
/// https://piquant-eyebrow-081.notion.site/197e7b760a1d809599a5da5e5d0b4314?pvs=4
/// </summary>
class ThermostatTradingRule : public ITradingRule
{
public:
    /// <summary>
    /// コンストラクタ
    /// </summary>
    ThermostatTradingRule()
    {
        m_tradingRule = TRADING_RULE_TYPE::THERMOSTAT;
        m_name = "サーモスタット売買ルール";

        ThermostatTradingRuleParameters::BollingerBandsHandle = BollingerBandsIndicator::CreateHandle(_Symbol, _Period, 50, 0, 2.0, PRICE_CLOSE);
        ThermostatTradingRuleParameters::ATRHandle = ATRIndicator::CreateHandle(_Symbol, _Period, 10);
        ThermostatTradingRuleParameters::SMAHandleForRangeHigh = SMAIndicator::CreateHandleCustom(_Symbol, _Period, 3, 0, PRICE_HIGH);
        ThermostatTradingRuleParameters::SMAHandleForRangeLow = SMAIndicator::CreateHandleCustom(_Symbol, _Period, 3, 0, PRICE_LOW);
        ThermostatTradingRuleParameters::BarDataForOrder = new BarData();
        ThermostatTradingRuleParameters::EntriedCurrentBar = false;
        
        for (int period = 10; period <= 50; period++)
        {
            ThermostatTradingRuleParameters::SMAHandles[period - 10] = SMAIndicator::CreateHandle(_Symbol, _Period, period, 0);
        }
    }

    /// <summary>
    /// 初期化
    /// </summary>
    /// <returns>初期化成否</returns>
    bool Init() override
    {
        double cmi_price;
        if(!ChoppyMarketIndexIndicator::GetLatestValue(cmi_price, 30)) return false;
        ThermostatTradingRuleParameters::Mode = (cmi_price >= 20) ? 0 : 1;
    
        if (ThermostatTradingRuleParameters::BollingerBandsHandle == INVALID_HANDLE) return false;
        if (ThermostatTradingRuleParameters::SMAHandleForRangeHigh == INVALID_HANDLE) return false;
        if (ThermostatTradingRuleParameters::SMAHandleForRangeLow == INVALID_HANDLE) return false;
        if (ThermostatTradingRuleParameters::SMAHandles[0] == 0) return false;
        
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
        ThermostatTradingRuleParameters *parameters = dynamic_cast<ThermostatTradingRuleParameters *>(&params);
        
        if (parameters.HasPosition || parameters.EntriedCurrentBar) return WRONG_VALUE;
        
        if (parameters.Mode == 0)
        {
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
        }
        else if (parameters.Mode == 1)
        {
            double high_price_old = PriceData::GetHighPrice(1);
            double low_price_old = PriceData::GetLowPrice(1);
            double close_price_old = PriceData::GetClosePrice(1);
            double avg_price_old = (high_price_old + low_price_old + close_price_old) / 3.0;
            
            double close_price = PriceData::GetClosePrice(0);
            double open_price = PriceData::GetOpenPrice(0);
            double atr_value = 0.0;
            if (!ATRIndicator::GetLatestValue(parameters.ATRHandle, atr_value)) return WRONG_VALUE;
            
            if (close_price > avg_price_old)
            {
                if (close_price >= (open_price + atr_value * 0.5)) return ORDER_TYPE_BUY;
                if (close_price <= (open_price - atr_value * 1.0)) return ORDER_TYPE_SELL;
            }
            else if(close_price < avg_price_old)
            {
                if (close_price >= (open_price + atr_value * 1.0)) return ORDER_TYPE_BUY;
                if (close_price <= (open_price - atr_value * 0.5)) return ORDER_TYPE_SELL;
            }
        }
        
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
        ThermostatTradingRuleParameters *parameters = dynamic_cast<ThermostatTradingRuleParameters *>(&params);
        
        if(parameters.OrderType == ORDER_TYPE_BUY)
        {
            if(parameters.ProtectiveStop >= parameters.CurrentPriceBeforeTrail)
                return true;
        }
        else if(parameters.OrderType == ORDER_TYPE_SELL)
        {
            if(parameters.ProtectiveStop <= parameters.CurrentPriceBeforeTrail)
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
        ThermostatTradingRuleParameters *parameters = dynamic_cast<ThermostatTradingRuleParameters *>(&params);
    
        return parameters.ProtectiveStop;
    }

    /// <summary>
    /// 利確ライン計算
    /// </summary>
    /// <param name="params">売買ルールパラメータ</param>
    /// <returns>利確ライン</returns>
    double CalculateTakeProfitPrice(ITradingRuleParameters &params) override
    {    
        return 0.0;
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
        return new ThermostatTradingRuleParameters();
    }
    
    /// <summary>
    /// ティック毎に売買ルールパラメータを更新する処理
    /// </summary>
    void UpdateParametersOnTick() override
    {
        if (ThermostatTradingRuleParameters::BarDataForOrder.IsNewBar())
            ThermostatTradingRuleParameters::EntriedCurrentBar = false;
        
        double cmi_price;
        if(!ChoppyMarketIndexIndicator::GetLatestValue(cmi_price, 30))
        {
            ThermostatTradingRuleParameters::Mode = -1;
            return;
        }
        ThermostatTradingRuleParameters::Mode = (cmi_price >= 20) ? 0 : 1;
    }
    
    /// <summary>
    /// 売買シグナル発生時に売買ルールパラメータを更新する処理
    /// </summary>
    /// <param name="deal_ticket">チケットID/param>
    /// <param name="params">売買ルールパラメータ</param>
    void UpdateParametersOnSignaled(ENUM_ORDER_TYPE order_type, ITradingRuleParameters &params) override
    {
        ThermostatTradingRuleParameters *parameters = dynamic_cast<ThermostatTradingRuleParameters *>(&params);
        parameters.OrderType = order_type;
        parameters.ModeInitial = parameters.Mode;
        parameters.ModeCurrent = parameters.Mode;
        parameters.PriceAtSignal = (order_type == ORDER_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK)
                                                                  : SymbolInfoDouble(_Symbol, SYMBOL_BID);
        
        if (parameters.Mode == 0)
        {
            parameters.CurrentMAPeriod = 50;
            parameters.SMAHandle = ThermostatTradingRuleParameters::SMAHandles[50 - 10];
            if(!SMAIndicator::GetLatestValue(parameters.SMAHandle, parameters.ProtectiveStop))
                parameters.ProtectiveStop = 0;
        }
        else if (parameters.Mode == 1)
        {
            double atr_value = 0.0;
            if (!ATRIndicator::GetLatestValue(parameters.ATRHandle, atr_value)) return;
            
            if (order_type == ORDER_TYPE_BUY)
            {
                double sma3_low = 0.0;
                if (!SMAIndicator::GetLatestValue(parameters.SMAHandleForRangeLow, sma3_low)) return;
                parameters.ProtectiveStop = parameters.PriceAtSignal - atr_value;
                if (parameters.ProtectiveStop < sma3_low) parameters.ProtectiveStop = sma3_low;
            }
            else if (order_type == ORDER_TYPE_SELL)
            {
                double sma3_high = 0.0;
                if (!SMAIndicator::GetLatestValue(parameters.SMAHandleForRangeHigh, sma3_high)) return;
                parameters.ProtectiveStop = parameters.PriceAtSignal + atr_value;
                if (parameters.ProtectiveStop > sma3_high) parameters.ProtectiveStop = sma3_high;
            }
        }
    }
    
    /// <summary>
    /// ポジション作成時に売買ルールパラメータを更新する処理
    /// </summary>
    /// <param name="deal_ticket">チケットID/param>
    /// <param name="params">売買ルールパラメータ</param>
    void UpdateParametersOnEntryIn(ulong deal_ticket, ITradingRuleParameters &params) override
    {
        ThermostatTradingRuleParameters *parameters = dynamic_cast<ThermostatTradingRuleParameters *>(&params);
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
        ThermostatTradingRuleParameters *parameters = dynamic_cast<ThermostatTradingRuleParameters *>(&params);
        
        // 初手トレンドモードで、トレンドモード中 or スイングモード→トレンドモードに変化
        if (parameters.ModeInitial == 0 && parameters.Mode == 0)
        {
            if (parameters.BarDataForTrail.IsNewBar())
            {
                if (parameters.CurrentMAPeriod > 10)
                {
                    parameters.CurrentMAPeriod--;
                    parameters.SMAHandle = ThermostatTradingRuleParameters::SMAHandles[parameters.CurrentMAPeriod - 10];
                }
            }
            
            if(!SMAIndicator::GetLatestValue(parameters.SMAHandle, parameters.ProtectiveStop))
                parameters.ProtectiveStop = 0;
            
            parameters.ModeCurrent = 0;
        }
        // 初手スイングモードで、スイングモード→トレンドモードに変化
        else if (parameters.ModeInitial == 1 && parameters.ModeCurrent == 1 && parameters.Mode == 0)
        {
            double atr_value = 0.0;
            if (!ATRIndicator::GetLatestValue(parameters.ATRHandle, atr_value)) return;
            
            if (parameters.PositionType == POSITION_TYPE_BUY)
                parameters.ProtectiveStop = parameters.PriceAtSignal - atr_value * 3;
            else if (parameters.PositionType == POSITION_TYPE_SELL)
                parameters.ProtectiveStop = parameters.PriceAtSignal + atr_value * 3;
            
            parameters.ModeCurrent = 0;    
        }
        // トレンドモード→スイングモードに変化
        else if (parameters.ModeCurrent == 0 && parameters.Mode == 1)
        {
            double atr_value = 0.0;
            if (!ATRIndicator::GetLatestValue(parameters.ATRHandle, atr_value)) return;
            
            if (parameters.PositionType == POSITION_TYPE_BUY)
            {
                double sma3_low = 0.0;
                if (!SMAIndicator::GetLatestValue(parameters.SMAHandleForRangeLow, sma3_low)) return;
                parameters.ProtectiveStop = parameters.PriceAtSignal - atr_value;
                if (parameters.ProtectiveStop < sma3_low) parameters.ProtectiveStop = sma3_low;
            }
            else if (parameters.PositionType == POSITION_TYPE_SELL)
            {
                double sma3_high = 0.0;
                if (!SMAIndicator::GetLatestValue(parameters.SMAHandleForRangeHigh, sma3_high)) return;
                parameters.ProtectiveStop = parameters.PriceAtSignal + atr_value;
                if (parameters.ProtectiveStop > sma3_high) parameters.ProtectiveStop = sma3_high;
            }
            
            parameters.ModeCurrent = 1;
        }
        
        parameters.CurrentPriceBeforeTrail = (parameters.PositionType == POSITION_TYPE_BUY)
                                    ? SymbolInfoDouble(_Symbol, SYMBOL_BID)
                                    : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
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
        ThermostatTradingRuleParameters *parameters = dynamic_cast<ThermostatTradingRuleParameters *>(&params);
        parameters.HasPosition = false;
    }
};
