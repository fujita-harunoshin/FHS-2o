#include "../../Domains/Types/TradingRuleType.mqh"
#include "../MarketData/BarData.mqh"
#include "../MarketData/TimeData.mqh"
#include "../MarketData/PriceData.mqh"
#include "../MarketData/EconomicCalendarData.mqh"
#include "../Utility.mqh"

/// <summary>
/// 売買ルール(エントリー/エグジット/SL/TP/トレーリングストップ計算)の抽象インターフェース
/// </summary>
class ITradingRule
{
protected:
    /// <summary>
    /// 売買ルール
    /// </summary>
    TRADING_RULE_TYPE m_tradingRule;

    /// <summary>
    /// 売買ルール名
    /// </summary>
    string m_name;

public:
    /// <summary>
    /// 初期化
    /// </summary>
    /// <returns>初期化成否</returns>
    virtual bool Init() = 0;
    
    /// <summary>
    /// 売買ルール種別取得
    /// </summary>
    /// <returns>資金管理戦略</returns>
    TRADING_RULE_TYPE GetType() const { return m_tradingRule; };
    
    /// <summary>
    /// 売買ルール名取得
    /// </summary>
    /// <returns>資金管理戦略名</returns>
    string GetName() const { return m_name; }

    /// <summary>
    /// エントリーシグナル判定
    /// </summary>
    /// <param name="params">売買ルールパラメータ</param>
    /// <param name="entry_price">指値の場合はその価格param>
    /// <returns>エントリー種別</returns>
    virtual ENUM_ORDER_TYPE CheckEntrySignal(ITradingRuleParameters &params, double &entry_price) = 0;
    
    /// <summary>
    /// ペンディングオーダー破棄シグナル判定
    /// </summary>
    /// <param name="params">売買ルールパラメータ</param>
    /// <returns>シグナル発生時は true</returns>
    virtual bool CheckOrderCancelSignal(ITradingRuleParameters &params) = 0;
    
    /// <summary>
    /// エグジットシグナル判定
    /// </summary>
    /// <param name="params">売買ルールパラメータ</param>
    /// <returns>エグジットシグナル</returns>
    virtual bool CheckExitSignal(ITradingRuleParameters &params) = 0;
    
    /// <summary>
    /// 損切ライン計算
    /// </summary>
    /// <param name="params">売買ルールパラメータ</param>
    /// <returns>損切ライン</returns>
    virtual double CalculateStopLossPrice(ITradingRuleParameters &params) = 0;
    
    /// <summary>
    /// 利確ライン計算
    /// </summary>
    /// <param name="params">売買ルールパラメータ</param>
    /// <returns>利確ライン</returns>
    virtual double CalculateTakeProfitPrice(ITradingRuleParameters &params) = 0;
    
    /// <summary>
    /// トレーリングストップ計算
    /// </summary>
    /// <param name="params">売買ルールパラメータ</param>
    /// <param name="new_sl_price">新しい損切ライン</param>
    /// <returns>トレーリングの適否</returns>
    virtual bool CalculateTrailingStopLossPrice(ITradingRuleParameters &params, double &new_sl_price) = 0;
    
    /// <summary>
    /// オーダー時に売買ルールパラメータのインスタンスを作成
    /// </summary>
    virtual ITradingRuleParameters* CreateParametersInstance() = 0;
    
    /// <summary>
    /// 売買シグナル発生時に売買ルールパラメータを更新する処理
    /// </summary>
    /// <param name="order_type">オーダー種類</param>
    /// <param name="params">売買ルールパラメータ</param>
    virtual void UpdateParametersOnSignaled(ENUM_ORDER_TYPE order_type, ITradingRuleParameters &params) = 0;
    
    /// <summary>
    /// ティック毎に売買ルールパラメータを更新する処理
    /// </summary>
    virtual void UpdateParametersOnTick() = 0;
    
    /// <summary>
    /// ポジション発生時に売買ルールパラメータを更新する処理
    /// </summary>
    /// <param name="deal_ticket">チケットID/param>
    /// <param name="params">売買ルールパラメータ</param>
    virtual void UpdateParametersOnEntryIn(ulong deal_ticket, ITradingRuleParameters &params) = 0;
    
    /// <summary>
    /// トレーリングストップ計算前に売買ルールパラメータを更新する処理
    /// </summary>
    /// <param name="deal_ticket">チケットID/param>
    /// <param name="params">売買ルールパラメータ</param>
    virtual void UpdateParametersBeforeTrail(ulong deal_ticket, ITradingRuleParameters &params) = 0;
    
    /// <summary>
    /// ポジション更新毎に売買ルールパラメータを更新する処理
    /// </summary>
    /// <param name="deal_ticket">チケットID/param>
    /// <param name="params">売買ルールパラメータ</param>
    virtual void UpdateParametersOnDealUpdate(ulong deal_ticket, ITradingRuleParameters &params) = 0;
    
    /// <summary>
    /// 手仕舞い時に売買ルールパラメータを更新する処理
    /// </summary>
    /// <param name="deal_ticket">チケットID/param>
    /// <param name="params">売買ルールパラメータ</param>
    virtual void UpdateParametersOnEntryOut(ulong deal_ticket, ITradingRuleParameters &params) = 0;
};
