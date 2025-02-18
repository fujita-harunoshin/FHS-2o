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
        
        return WRONG_VALUE;
    }
    
    /// <summary>
    /// ペンディングオーダー破棄シグナル判定
    /// </summary>
    /// <param name="params">売買ルールパラメータ</param>
    /// <returns>シグナル発生時は true</returns>
    bool CheckOrderCancelSignal(ITradingRuleParameters &params) override
    {
        if (MathRand() % 1000 == 0)
        {
            Print("ペンディングオーダーキャンセルシグナル発生");
            return true;
        }
        return false;
    }

    /// <summary>
    /// エグジットシグナル判定
    /// </summary>
    /// <param name="params">売買ルールパラメータ</param>
    /// <returns>エグジットシグナル</returns>
    bool CheckExitSignal(ITradingRuleParameters &params) override
    {
        if(MathRand() % 1000 == 0)
        {
            TestTradingRuleParameters *parameters = dynamic_cast<TestTradingRuleParameters *>(&params);
            switch(parameters.OrderType)
            {
                case ORDER_TYPE_BUY:
                    Print("エグジットシグナル発生: 成行買い注文の決済");
                    break;
                case ORDER_TYPE_SELL:
                    Print("エグジットシグナル発生: 成行売り注文の決済");
                    break;
                case ORDER_TYPE_BUY_LIMIT:
                    Print("エグジットシグナル発生: 指値買い注文の決済");
                    break;
                case ORDER_TYPE_SELL_LIMIT:
                    Print("エグジットシグナル発生: 指値売り注文の決済");
                    break;
                case ORDER_TYPE_BUY_STOP:
                    Print("エグジットシグナル発生: 逆指値買い注文の決済");
                    break;
                case ORDER_TYPE_SELL_STOP:
                    Print("エグジットシグナル発生: 逆指値売り注文の決済");
                    break;
                default:
                    Print("エグジットシグナル発生: 不明な注文タイプの決済");
                    break;
            }
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
        TestTradingRuleParameters *parameters = dynamic_cast<TestTradingRuleParameters *>(&params);
        double sl_price = 0.0;
        
        if (parameters.OrderType == ORDER_TYPE_BUY ||
            parameters.OrderType == ORDER_TYPE_BUY_LIMIT ||
            parameters.OrderType == ORDER_TYPE_BUY_STOP)
        {
            sl_price = parameters.PriceAtSignal - Utility::PipsToPrice(10);
        }
        else if (parameters.OrderType == ORDER_TYPE_SELL ||
                 parameters.OrderType == ORDER_TYPE_SELL_LIMIT ||
                 parameters.OrderType == ORDER_TYPE_SELL_STOP)
        {
            sl_price = parameters.PriceAtSignal + Utility::PipsToPrice(10);
        }
        
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
        
        if (parameters.OrderType == ORDER_TYPE_BUY ||
            parameters.OrderType == ORDER_TYPE_BUY_LIMIT ||
            parameters.OrderType == ORDER_TYPE_BUY_STOP)
        {
            tp_price = parameters.PriceAtSignal + Utility::PipsToPrice(20);
        }
        else if (parameters.OrderType == ORDER_TYPE_SELL ||
                 parameters.OrderType == ORDER_TYPE_SELL_LIMIT ||
                 parameters.OrderType == ORDER_TYPE_SELL_STOP)
        {
            tp_price = parameters.PriceAtSignal - Utility::PipsToPrice(20);
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
        return new TestTradingRuleParameters();
    }
    
    /// <summary>
    /// ティック毎に売買ルールパラメータを更新する処理
    /// </summary>
    void UpdateParametersOnTick() override
    {
        if (TestTradingRuleParameters::TimeDataInstance.IsNewDay())
        {
            EconomicCalendarData::ClearEventsData(TestTradingRuleParameters::Events);
            int eventCount = EconomicCalendarData::GetTodayEvents(_Symbol, TestTradingRuleParameters::Events);
        
            // 取得件数を表示
            Print("本日のイベント数: ", eventCount);
            
            // 取得した各イベントの詳細を表示
            for (int i = 0; i < ArraySize(TestTradingRuleParameters::Events); i++)
            {
                CalendarEventDetail detail = TestTradingRuleParameters::Events[i];
                // 発生時刻は TimeToString を利用して文字列化
                string eventTimeStr = TimeToString(detail.value.time, TIME_DATE|TIME_MINUTES);
                PrintFormat("イベント[%d] - ID: %d, 重要度: %d, 発生時刻: %s", 
                            i, detail.event.id, detail.event.importance, eventTimeStr);
            }
        }
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
                                                                  
        if (parameters.OrderType == ORDER_TYPE_BUY ||
            parameters.OrderType == ORDER_TYPE_BUY_LIMIT ||
            parameters.OrderType == ORDER_TYPE_BUY_STOP)
        {
            parameters.PriceAtSignal = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
        }
        else if (parameters.OrderType == ORDER_TYPE_SELL ||
                 parameters.OrderType == ORDER_TYPE_SELL_LIMIT ||
                 parameters.OrderType == ORDER_TYPE_SELL_STOP)
        {
            parameters.PriceAtSignal = SymbolInfoDouble(_Symbol, SYMBOL_BID);
        }
    }
    
    /// <summary>
    /// ポジション作成時に売買ルールパラメータを更新する処理
    /// </summary>
    /// <param name="deal_ticket">チケットID/param>
    /// <param name="params">売買ルールパラメータ</param>
    void UpdateParametersOnEntryIn(ulong deal_ticket, ITradingRuleParameters &params) override
    {
        TestTradingRuleParameters *parameters = dynamic_cast<TestTradingRuleParameters *>(&params);
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
        switch(parameters.OrderType)
        {
            case ORDER_TYPE_BUY:
                Print("成行買い注文の手仕舞い完了 - チケット番号: ", deal_ticket);
                break;
            case ORDER_TYPE_SELL:
                Print("成行売り注文の手仕舞い完了 - チケット番号: ", deal_ticket);
                break;
            case ORDER_TYPE_BUY_LIMIT:
                Print("指値買い注文の手仕舞い完了 - チケット番号: ", deal_ticket);
                break;
            case ORDER_TYPE_SELL_LIMIT:
                Print("指値売り注文の手仕舞い完了 - チケット番号: ", deal_ticket);
                break;
            case ORDER_TYPE_BUY_STOP:
                Print("逆指値買い注文の手仕舞い完了 - チケット番号: ", deal_ticket);
                break;
            case ORDER_TYPE_SELL_STOP:
                Print("逆指値売り注文の手仕舞い完了 - チケット番号: ", deal_ticket);
                break;
            default:
                Print("不明な注文タイプの手仕舞い完了 - チケット番号: ", deal_ticket);
                break;
        }
    }
};
