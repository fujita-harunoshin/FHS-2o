#include "ITradingRuleParameters.mqh"

/// <summary>
/// キングケルトナー売買ルールのパラメータ
/// </summary>
class KingKeltnerTradingRuleParameters : public ITradingRuleParameters
{
public:
    /// <summary>
    /// バー情報
    /// </summary>
    static BarData *BarDataInstance;
    
    /// <summary>
    /// ATRハンドル
    /// </summary>
    static int AtrHandle;
    
    /// <summary>
    /// 現在のバーでエントリー済みかのフラグ
    /// </summary>
    static bool EntriedCurrentBar;
    
    /// <summary>
    /// このルールでポジションを取り済みかのフラグ
    /// </summary>
    static bool HasPosition;
    
    /// <summary>
    /// オーダーシグナル発生時のレート [クォート通貨単位]
    /// </summary>
    double PriceAtSignal;
    
    /// <summary>
    /// ATRの値 [クォート通貨単位]
    /// </summary>
    double AtrValue;
    
    /// <summary>
    /// キングケルトナー移動平均の値
    /// </summary>
    double MoveAverage;
    
    /// <summary>
    /// エントリー価格 [クォート通貨単位]
    /// </summary>
    double EntryPrice;
    
    /// <summary>
    /// 初期の損切ライン [クォート通貨単位]
    /// </summary>
    double InitialStopLossPrice;
    
    /// <summary>
    /// トレーリングストップ計算前の現在価格 [クォート通貨単位]
    /// </summary>
    double CurrentPriceBeforeTrail;
    
    /// <summary>
    /// 現在の損切ライン [クォート通貨単位]
    /// </summary>
    double CurrentStopLossPrice;
};

BarData *KingKeltnerTradingRuleParameters::BarDataInstance = new BarData();
int KingKeltnerTradingRuleParameters::AtrHandle = 0;
bool KingKeltnerTradingRuleParameters::EntriedCurrentBar = false;
bool KingKeltnerTradingRuleParameters::HasPosition = false;
