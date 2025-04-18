#include "ITradingRuleParameters.mqh"

/// <summary>
/// タートル流売買ルールのパラメータ
/// </summary>
class TurtleTradingRuleParameters : public ITradingRuleParameters
{
public:
    /// <summary>
    /// ATRハンドル
    /// </summary>
    static int AtrHandle;
    
    /// <summary>
    /// バー情報
    /// </summary>
    static BarData *BarDataInstance;

    /// <summary>
    /// 現在のバーでエントリー済みかのフラグ
    /// </summary>
    static bool EntriedCurrentBar;
    
    /// <summary>
    /// このルールでポジションを取り済みかのフラグ
    /// </summary>
    static bool HasPosition;
    
    /// <summary>
    /// ATRの値 [クォート通貨単位]
    /// </summary>
    double AtrValue;
    
    /// <summary>
    /// オーダーシグナル発生時のレート [クォート通貨単位]
    /// </summary>
    double PriceAtSignal;
    
    /// <summary>
    /// トレーリングストップ計算前の現在価格 [クォート通貨単位]
    /// </summary>
    double CurrentPriceBeforeTrail;
    
    /// <summary>
    /// 現在の損切ライン [クォート通貨単位]
    /// </summary>
    double CurrentStopLossPrice;
    
    /// <summary>
    /// 初期の損切ライン [クォート通貨単位]
    /// </summary>
    double InitialStopLossPrice;
    
    /// <summary>
    /// エントリー価格 [クォート通貨単位]
    /// </summary>
    double EntryPrice;
};

int TurtleTradingRuleParameters::AtrHandle = 0;
BarData *TurtleTradingRuleParameters::BarDataInstance = new BarData();
bool TurtleTradingRuleParameters::EntriedCurrentBar = false;
bool TurtleTradingRuleParameters::HasPosition = false;
