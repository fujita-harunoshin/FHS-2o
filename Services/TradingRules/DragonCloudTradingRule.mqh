#include "ITradingRule.mqh"
#include "../../Domains/Entities/TradingRuleParameters/DragonCloudTradingRuleParameters.mqh"
#include "../Indicators/IchimokuIndicator.mqh"

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
        DragonCloudTradingRuleParameters::HasBuyPosition = false;
        DragonCloudTradingRuleParameters::HasSellPosition = false;
        DragonCloudTradingRuleParameters::IchimokuHandle = IchimokuIndicator::CreateHandle(_Symbol, _Period, 9, 26, 52);
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
        
        double move_average_today = 0.0;
        double move_average_tomorrow = 0.0;
        if (!KingKeltnerMAIndicator::GetLatestValue(move_average_today, 40, 0))
            return WRONG_VALUE;
        if (!KingKeltnerMAIndicator::GetLatestValue(move_average_tomorrow, 40, 1))
            return WRONG_VALUE;
        
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
        return false;
    }

    /// <summary>
    /// 損切ライン計算
    /// </summary>
    /// <param name="params">売買ルールパラメータ</param>
    /// <returns>損切ライン</returns>
    double CalculateStopLossPrice(ITradingRuleParameters &params) override
    {
        return 0.0;
    }

    /// <summary>
    /// 利確ライン計算
    /// </summary>
    /// <param name="params">売買ルールパラメータ</param>
    /// <returns>損切ライン</returns>
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
        
        parameters.PositionType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
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
