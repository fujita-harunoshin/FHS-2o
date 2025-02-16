#include "../../Domains/Entities/TradingRuleParameters/SuperComboTradingRuleParameters.mqh"
#include "../Indicators/RangeIndicator.mqh"
#include "ITradingRule.mqh"

/// <summary>
/// スーパーコンボ売買ルール
/// </summary>
class SuperComboTradingRule : public ITradingRule
{
public:
    /// <summary>
    /// コンストラクタ
    /// </summary>
    SuperComboTradingRule()
    {
        m_tradingRule = TRADING_RULE_TYPE::KING_KELTNER;
        m_name = "スーパーコンボ売買ルール";
    
        SuperComboTradingRuleParameters::BarDataInstance = new BarData();
        SuperComboTradingRuleParameters::TimeDataInstance = new TimeData();
        SuperComboTradingRuleParameters::EntriedCurrentBar = false;
        SuperComboTradingRuleParameters::AtrHandle = ATRIndicator::CreateHandle(_Symbol, _Period, 20);
    }

    /// <summary>
    /// 初期化
    /// </summary>
    /// <returns>初期化成否</returns>
    bool Init() override
    {
        if (SuperComboTradingRuleParameters::AtrHandle == INVALID_HANDLE) return false;
    
        return true;
    }

    /// <summary>
    /// エントリーシグナル判定
    /// </summary>
    /// <param name="params">売買ルールパラメータ</param>
    /// <param name="entry_price">指値の場合はその価格param>
    /// <returns>エントリー種別</returns>
    /// <remarks>
    /// 毎ティック実行
    /// </remarks>
    ENUM_ORDER_TYPE CheckEntrySignal(ITradingRuleParameters &params, double &entry_price) override
    {
        SuperComboTradingRuleParameters *parameters = dynamic_cast<SuperComboTradingRuleParameters *>(&params);
        
        // この待機時間は指数用。FXバージョンに要変更
        if (parameters.BarCount <= (30 / 5))
            return WRONG_VALUE;
            
        if (!parameters.CanTradeToday) return WRONG_VALUE;
        
        // 買っているのであれば、それは今日買ったもののはず
        if (parameters.PositionType == POSITION_TYPE_BUY) parameters.BuysToday = true;
        // 売りについても同様
        if (parameters.PositionType == POSITION_TYPE_SELL) parameters.SellsToday = true;
            
        // ここ、逆指値オーダーを出す回数を限定した方が良い？
        // そもそも、BuyBreakOutPoint(売りも)は一日に一回だから、このオーダーも一回で良くない？
        if (!parameters.BuysToday)
        {
            entry_price = parameters.BuyBreakOutPoint;
            return ORDER_TYPE_BUY_STOP;
        }
        
        if (!parameters.SellsToday)
        {
            entry_price = parameters.SellBreakOutPoint;
            return ORDER_TYPE_SELL_STOP;
        }
        
        // ダマし（failed）ブレイクアウトのチェック
        if (parameters.HighIntra > parameters.LongBreakOutPoint && !parameters.SellsToday)
        {
            entry_price = parameters.SellFailedBreakOutPoint;
            return ORDER_TYPE_SELL_STOP;
        }
        
        if (parameters.LowIntra < parameters.ShortBreakOutPoint && !parameters.BuysToday)
        {
            entry_price = parameters.BuyFailedBreakOutPoint;
            return ORDER_TYPE_BUY_STOP;
        }
        
        return WRONG_VALUE;
    }
    
    /// <summary>
    /// ペンディングオーダー破棄シグナル判定
    /// </summary>
    /// <param name="params">売買ルールパラメータ</param>
    /// <returns>シグナル発生時は true</returns>
    /// <remarks>
    /// オーダー後、そのオーダーに対し毎ティック実行
    /// </remarks>
    bool CheckOrderCancelSignal(ITradingRuleParameters &params) override
    {
        // 一日が終了したら全部のポジションを閉じるべきだと思われる
        return false;
    }

    /// <summary>
    /// エグジットシグナル判定
    /// </summary>
    /// <param name="params">売買ルールパラメータ</param>
    /// <returns>エグジットシグナル</returns>
    /// <remarks>
    /// ポジションオープン後、そのポジションに対し毎ティック実行
    /// </remarks>
    bool CheckExitSignal(ITradingRuleParameters &params) override
    {
        SuperComboTradingRuleParameters *parameters = dynamic_cast<SuperComboTradingRuleParameters *>(&params);
        // 一日が終了したら全部のポジションを閉じるべきだと思われる
        return false;
    }

    /// <summary>
    /// 損切ライン計算
    /// </summary>
    /// <param name="params">売買ルールパラメータ</param>
    /// <returns>損切ライン</returns>
    /// <remarks>
    /// エントリー前に一度だけ実行
    /// </remarks>
    double CalculateStopLossPrice(ITradingRuleParameters &params) override
    {
        SuperComboTradingRuleParameters *parameters = dynamic_cast<SuperComboTradingRuleParameters *>(&params);
    
        double sl_price = 0.0;
        if (parameters.OrderType == ORDER_TYPE_BUY_STOP)
        {
            // 通常はエントリー価格 - (protStopPrcnt1×平均レンジ) とエントリー価格 - protStopAmt のうち小さい方
            double calc1 = parameters.EntryPrice - 0.25 * parameters.AverageRange;
            double calc2 = parameters.EntryPrice - 3.00;
            sl_price = (calc1 < calc2) ? calc1 : calc2;
            
            // 直前の逆転エントリーの場合は、protStopPrcnt2を使用
            // 逆転エントリーってなんだ？？？
            if(SuperComboTradingRuleParameters::CurrentTradeType == -2)
            {
                calc1 = parameters.EntryPrice - 0.15 * parameters.AverageRange;
                calc2 = parameters.EntryPrice - 3.00;
                sl_price = (calc1 < calc2) ? calc1 : calc2;
            }
            
            // もし相場が上昇し、EntryPrice + (breakEvenPrcnt×平均レンジ)を超えた場合はブレイクイーブン（エントリーレート）に移行
            // ここはトレーリングストップメソッドに移管した方が良さげ？？
            if(parameters.HighIntra >= parameters.EntryPrice + 0.50 * parameters.AverageRange)
                sl_price = parameters.EntryPrice;
        }
        else if(parameters.PositionType == POSITION_TYPE_SELL)
        {
            // ショートの場合はエントリー価格 + (protStopPrcnt1×平均レンジ) とエントリー価格 + protStopAmt のうち大きい方
            double calc1 = parameters.EntryPrice + 0.25 * parameters.AverageRange;
            double calc2 = parameters.EntryPrice + 3.00;
            sl_price = (calc1 > calc2) ? calc1 : calc2;
            
            if(SuperComboTradingRuleParameters::CurrentTradeType == +2)
            {
                calc1 = parameters.EntryPrice + 0.15 * parameters.AverageRange;
                calc2 = parameters.EntryPrice + 3.00;
                sl_price = (calc1 > calc2) ? calc1 : calc2;
            }
            
            if(parameters.LowIntra <= parameters.EntryPrice - 0.50 * parameters.AverageRange)
                sl_price = parameters.EntryPrice;
        }
        
        return sl_price;
    }

    /// <summary>
    /// 利確ライン計算
    /// </summary>
    /// <param name="params">売買ルールパラメータ</param>
    /// <returns>利確ライン</returns>
    /// <remarks>
    /// エントリー前に一度だけ実行
    /// </remarks>
    double CalculateTakeProfitPrice(ITradingRuleParameters &params) override
    {
        SuperComboTradingRuleParameters *parameters = dynamic_cast<SuperComboTradingRuleParameters *>(&params);

        return 0;
    }
    
    /// <summary>
    /// トレーリングストップロスライン計算
    /// </summary>
    /// <param name="params">売買ルールパラメータ</param>
    /// <param name="new_sl_price">新しい損切ライン</param>
    /// <returns>トレーリングの適否</returns>
    /// <remarks>
    /// ポジションオープン後、そのポジションに対し毎ティック実行
    /// </remarks>
    bool CalculateTrailingStopLossPrice(ITradingRuleParameters &params, double &trailing_stop_price) override
    {
        SuperComboTradingRuleParameters *parameters = dynamic_cast<SuperComboTradingRuleParameters *>(&params);
        
        int currentTime = TimeData::GetCurrentTimeHHMM();
        // 初期エントリー後、初回待機期間終了後かつ初期取引終了時刻以降ならトレーリング開始
        //　このトレード終了時刻は、必ず修正が必要。
        if(currentTime >= 1430 && parameters.HasPosition)
        {
            // 現在のプロテクティブストップラインを計算
            double currentSL = CalculateStopLossPrice(params);
            if(parameters.PositionType == POSITION_TYPE_BUY)
            {
                // 完結済みバー3本分の最安値でＯＫ？？
                double low3 = PriceData::GetLowestPriceCompletedBar(3);
                // ロングの場合は、既存のstopより直近3本の足の最低値が高ければ上方修正
                trailing_stop_price = (currentSL < low3) ? low3 : currentSL;
            }
            else if(parameters.PositionType == POSITION_TYPE_SELL)
            {
                // 完結済みバー3本分の最高値でＯＫ？？
                double high3 = PriceData::GetHighestPriceCompletedBar(3);
                // ショートの場合は、既存のstopより直近3本の足の最高値が低ければ下方修正
                trailing_stop_price = (currentSL > high3) ? high3 : currentSL;
            }
            return true;
        }
        return false;
    }
    
    /// <summary>
    /// オーダー時に売買ルールパラメータのインスタンスを作成
    /// </summary>
    ITradingRuleParameters* CreateParametersInstance() override
    {
        return new SuperComboTradingRuleParameters();
    }
    
    /// <summary>
    /// ティック毎に売買ルールパラメータを更新する処理
    /// </summary>
    void UpdateParametersOnTick() override
    {
        if (SuperComboTradingRuleParameters::TimeDataInstance.IsNewDay())
        {
            double high_yesterday = iHigh(_Symbol, PERIOD_D1, 1);
            double low_yesterday = iLow(_Symbol, PERIOD_D1, 1);
            double open_yesterday = iOpen(_Symbol, PERIOD_D1, 1);
            double close_yesterday = iClose(_Symbol, PERIOD_D1, 1);
            double open_today = iOpen(_Symbol, PERIOD_D1, 0);
            
            double average_range = 0.0;
            double average_oc_range = 0.0;
            if (RangeIndicator::CalculateAverageRangeCompleted(average_range, PERIOD_D1, 10) ||
                RangeIndicator::CalculateAverageOCRangeCompleted(average_oc_range, PERIOD_D1, 10))
            {
                SuperComboTradingRuleParameters::AverageRange = 0;
                SuperComboTradingRuleParameters::AverageOCRange = 0;
            }
            
            SuperComboTradingRuleParameters::AverageRange = average_range;
            SuperComboTradingRuleParameters::AverageOCRange = average_oc_range;
            
            // 昨日のレンジから今日売買を行うか判定
            double range_yesterday = MathAbs(open_yesterday - close_yesterday);
            SuperComboTradingRuleParameters::CanTradeToday = (range_yesterday < 0.85 * SuperComboTradingRuleParameters::AverageOCRange);
            if (!SuperComboTradingRuleParameters::CanTradeToday) return;
            
            //　一昨日の終値と昨日の終値を比較し、今日の買いと売りのどちらが適しているか判定
            double close_before_yesterday = iClose(_Symbol, PERIOD_D1, 2);
            if (close_before_yesterday >= close_yesterday)
            {
                SuperComboTradingRuleParameters::BuyEasierDay = true;
                SuperComboTradingRuleParameters::SellEasierDay = false;
            }
            else
            {
                SuperComboTradingRuleParameters::BuyEasierDay = false;
                SuperComboTradingRuleParameters::SellEasierDay = true;
            }
            
            // ブレイクアウトのエントリー水準計算
            if (SuperComboTradingRuleParameters::BuyEasierDay)
            {
                SuperComboTradingRuleParameters::BuyBreakOutPoint = open_today + average_range * 0.3;
                SuperComboTradingRuleParameters::SellBreakOutPoint = open_today - average_range * 0.6;
            }
            else if (SuperComboTradingRuleParameters::SellEasierDay)
            {
                SuperComboTradingRuleParameters::BuyBreakOutPoint = open_today + average_range * 0.6;
                SuperComboTradingRuleParameters::SellBreakOutPoint = open_today - average_range * 0.3;
            }
            
            // ダマしブレイクアウトのブレイクアウト水準計算
            SuperComboTradingRuleParameters::LongBreakOutPoint = high_yesterday + average_range * 0.25;
            SuperComboTradingRuleParameters::ShortBreakOutPoint = low_yesterday - average_range * 0.25;
            
            // ダマしブレイクアウト時の逆張りエントリー水準計算
            SuperComboTradingRuleParameters::BuyFailedBreakOutPoint = low_yesterday + average_range * 0.25;
            SuperComboTradingRuleParameters::SellFailedBreakOutPoint = high_yesterday - average_range * 0.25;
            
            SuperComboTradingRuleParameters::BarCount = 0;
            SuperComboTradingRuleParameters::HighIntra = -DBL_MAX;
            SuperComboTradingRuleParameters::LowIntra = DBL_MAX;
            SuperComboTradingRuleParameters::BuysToday = false;
            SuperComboTradingRuleParameters::SellsToday = false;
            SuperComboTradingRuleParameters::CurrentTradeType = 0;
        }
        
        if (SuperComboTradingRuleParameters::BarDataInstance.IsNewBar())
        {
            SuperComboTradingRuleParameters::EntriedCurrentBar = false;
            SuperComboTradingRuleParameters::BarCount++;
        }
        
        double current_high = iHigh(_Symbol, _Period, 0);
        double current_low  = iLow(_Symbol, _Period, 0);
        if (current_high > SuperComboTradingRuleParameters::HighIntra)
            SuperComboTradingRuleParameters::HighIntra = current_high;
        if (current_low < SuperComboTradingRuleParameters::LowIntra)
            SuperComboTradingRuleParameters::LowIntra = current_low;
    }
    
    /// <summary>
    /// 売買シグナル発生時に売買ルールパラメータを更新する処理
    /// </summary>
    /// <param name="deal_ticket">チケットID/param>
    /// <param name="params">売買ルールパラメータ</param>
    void UpdateParametersOnSignaled(ENUM_ORDER_TYPE order_type, ITradingRuleParameters &params) override
    {
        SuperComboTradingRuleParameters *parameters = dynamic_cast<SuperComboTradingRuleParameters *>(&params);
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
        SuperComboTradingRuleParameters *parameters = dynamic_cast<SuperComboTradingRuleParameters *>(&params);
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
        SuperComboTradingRuleParameters *parameters = dynamic_cast<SuperComboTradingRuleParameters *>(&params);
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
        SuperComboTradingRuleParameters *parameters = dynamic_cast<SuperComboTradingRuleParameters *>(&params);
        parameters.HasPosition = false;
    }
};
