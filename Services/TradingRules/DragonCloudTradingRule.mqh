#include "../../Domains/Entities/TradingRuleParameters/DragonCloudTradingRuleParameters.mqh"
#include "../Indicators/IchimokuIndicator.mqh"
#include "ITradingRule.mqh"

/// <summary>
/// ドラゴンクラウド売買ルール
/// </summary>
/// <remarks>
/// 三役好転(逆転)をエントリーシグナル、基準線と転換線のクロスをエグジットシグナルとした、
/// 長期トレンドフォロー型戦略
/// </remarks>
class DragonCloudTradingRule : public ITradingRule
{
public:
    /// <summary>
    /// コンストラクタ
    /// </summary>
    DragonCloudTradingRule()
    {
        m_tradingRule = TRADING_RULE_TYPE::DRAGON_CLOUD;
        m_name = "ドラゴンクラウド売買ルール";
    
        DragonCloudTradingRuleParameters::BarDataInstance = new BarData();
        DragonCloudTradingRuleParameters::HasBuyPosition = false;
        DragonCloudTradingRuleParameters::HasSellPosition = false;
        DragonCloudTradingRuleParameters::IchimokuHandle = IchimokuIndicator::CreateHandle(_Symbol, _Period, 9, 26, 52);
        DragonCloudTradingRuleParameters::EntriedCurrentBar = false;
    }
    
    /// <summary>
    /// 初期化
    /// </summary>
    /// <returns>初期化成否</returns>
    bool Init() override
    {
        if (DragonCloudTradingRuleParameters::IchimokuHandle == INVALID_HANDLE) return false;
        
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
        DragonCloudTradingRuleParameters *parameters = dynamic_cast<DragonCloudTradingRuleParameters *>(&params);
        
        if (parameters.EntriedCurrentBar) return WRONG_VALUE;
        
        int three_roles_signal = 0;
        if (!IchimokuIndicator::GetThreeRolesSignal(parameters.IchimokuHandle, three_roles_signal))
            return WRONG_VALUE;
        
        if (three_roles_signal == 1 && !parameters.HasBuyPosition) return ORDER_TYPE_BUY;
        else if (three_roles_signal == -1 && !parameters.HasSellPosition) return ORDER_TYPE_SELL;
        
        return WRONG_VALUE;
    }
    
    /// <summary>
    /// ペンディングオーダー破棄シグナル判定
    /// </summary>
    /// <param name="params">売買ルールパラメータ</param>
    /// <returns>シグナル発生時は true</returns>
    bool CheckOrderCancelSignal(ITradingRuleParameters &params) override
    {
        return false;
    }

    /// <summary>
    /// エグジットシグナル判定
    /// </summary>
    /// <param name="params">売買ルールパラメータ</param>
    /// <returns>エグジットシグナル</returns>
    bool CheckExitSignal(ITradingRuleParameters &params) override
    {
        DragonCloudTradingRuleParameters *parameters = dynamic_cast<DragonCloudTradingRuleParameters *>(&params);
        
        int tenkan_kijun_state = 0;
        if (!IchimokuIndicator::GetTenkanKijunState(parameters.IchimokuHandle, tenkan_kijun_state))
            return false;
        
        if (tenkan_kijun_state == -1 && parameters.PositionType == POSITION_TYPE_BUY) return true;
        else if (tenkan_kijun_state == 1 && parameters.PositionType == POSITION_TYPE_SELL) return true;
        
        return false;
    }

    /// <summary>
    /// 損切ライン計算
    /// </summary>
    /// <param name="params">売買ルールパラメータ</param>
    /// <returns>損切ライン</returns>
    double CalculateStopLossPrice(ITradingRuleParameters &params) override
    {
        DragonCloudTradingRuleParameters *parameters = dynamic_cast<DragonCloudTradingRuleParameters*>(&params);

        parameters.StopLossPrice = 0;

        double sl_price = 0.0;
        double kijun = 0.0;
        double senkou_spanB = 0.0;
        
        if(!IchimokuIndicator::GetLatestKijunSen(parameters.IchimokuHandle, kijun) ||
        !IchimokuIndicator::GetLatestSenkouSpanB(parameters.IchimokuHandle, senkou_spanB))
        {
            return sl_price;
        }
        
        if(parameters.PositionType == POSITION_TYPE_BUY)
        {
            double base_stop = MathMin(kijun, senkou_spanB);
            double offset = Utility::PipsToPrice(3);
            sl_price = base_stop - offset;
        }
        else if(parameters.PositionType == POSITION_TYPE_SELL)
        {
            double base_stop = MathMax(kijun, senkou_spanB);
            double offset = Utility::PipsToPrice(3);
            sl_price = base_stop + offset;
        }
        
        parameters.StopLossPrice = sl_price;
        return sl_price;
    }

    /// <summary>
    /// 利確ライン計算
    /// </summary>
    /// <param name="params">売買ルールパラメータ</param>
    /// <returns>損切ライン</returns>
    double CalculateTakeProfitPrice(ITradingRuleParameters &params) override
    {
        DragonCloudTradingRuleParameters *parameters = dynamic_cast<DragonCloudTradingRuleParameters*>(&params);

        double tp_price = 0.0;
        double sl_price = parameters.StopLossPrice;
        double entry_price = parameters.PriceAtSignal;
        
        if(sl_price <= 0.0) return 0.0;
        
        double risk_reward_ratio = 1.0;
    
        if(parameters.PositionType == POSITION_TYPE_BUY)
        {
            double risk = entry_price - sl_price;
            tp_price = entry_price + (risk * risk_reward_ratio);
        }
        else if(parameters.PositionType == POSITION_TYPE_SELL)
        {
            double risk = sl_price - entry_price;
            tp_price = entry_price - (risk * risk_reward_ratio);
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
        DragonCloudTradingRuleParameters *parameters = dynamic_cast<DragonCloudTradingRuleParameters *>(&params);

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
        return new DragonCloudTradingRuleParameters();
    }
    
    /// <summary>
    /// ティック毎に売買ルールパラメータを更新する処理
    /// </summary>
    void UpdateParametersOnTick() override
    {
        if (DragonCloudTradingRuleParameters::BarDataInstance.IsNewBar())
            DragonCloudTradingRuleParameters::EntriedCurrentBar = false;
    }
    
    /// <summary>
    /// 売買シグナル発生時に売買ルールパラメータを更新する処理
    /// </summary>
    /// <param name="deal_ticket">チケットID/param>
    /// <param name="params">売買ルールパラメータ</param>
    void UpdateParametersOnSignaled(ENUM_ORDER_TYPE order_type, ITradingRuleParameters &params) override
    {
        DragonCloudTradingRuleParameters *parameters = dynamic_cast<DragonCloudTradingRuleParameters *>(&params);
    
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
        DragonCloudTradingRuleParameters *parameters = dynamic_cast<DragonCloudTradingRuleParameters *>(&params);
        
        parameters.EntriedCurrentBar = true;
        parameters.PositionType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
        parameters.EntryPrice = HistoryDealGetDouble(deal_ticket, DEAL_PRICE);
        parameters.InitialStopLossPrice = HistoryDealGetDouble(deal_ticket, DEAL_SL);
        if (parameters.PositionType == POSITION_TYPE_BUY)
            parameters.HasBuyPosition = true;
        else if (parameters.PositionType == POSITION_TYPE_SELL)
            parameters.HasSellPosition = true;   
    }
    
    /// <summary>
    /// トレーリングストップ計算前に売買ルールパラメータを更新する処理
    /// </summary>
    /// <param name="deal_ticket">チケットID/param>
    /// <param name="params">売買ルールパラメータ</param>
    void UpdateParametersBeforeTrail(ulong deal_ticket, ITradingRuleParameters &params)
    {
        DragonCloudTradingRuleParameters *parameters = dynamic_cast<DragonCloudTradingRuleParameters *>(&params);
        
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
        DragonCloudTradingRuleParameters *parameters = dynamic_cast<DragonCloudTradingRuleParameters *>(&params);
        
        if (parameters.PositionType == POSITION_TYPE_BUY)
            parameters.HasBuyPosition = false;
        else if (parameters.PositionType == POSITION_TYPE_SELL)
            parameters.HasSellPosition = false;   
    }
};
