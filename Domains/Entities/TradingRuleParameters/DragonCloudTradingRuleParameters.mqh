#include "ITradingRuleParameters.mqh"

/// <summary>
/// ドラゴンクラウド売買ルールクラスのパラメータ
/// </summary>
class DragonCloudTradingRuleParameters : public ITradingRuleParameters
{
public:
    /// <summary>
    /// バー情報
    /// </summary>
    static BarData *BarDataInstance;

    /// <summary>
    /// 買いポジション所持フラグ
    /// </summary>
    static bool HasBuyPosition;

    /// <summary>
    /// 買いポジション所持フラグ
    /// </summary>
    static bool HasSellPosition;

    /// <summary>
    /// 一目均衡表ハンドル
    /// </summary>
    static int IchimokuHandle;
    
    /// <summary>
    /// 現在のバーでエントリー済みかのフラグ
    /// </summary>
    static bool EntriedCurrentBar;

    /// <summary>
    /// 売買シグナル発生時の価格
    /// </summary>
    double PriceAtSignal;
    
    /// <summary>
    /// 損切ライン
    /// </summary>
    double StopLossPrice;
    
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

BarData *DragonCloudTradingRuleParameters::BarDataInstance = new BarData();
bool DragonCloudTradingRuleParameters::HasBuyPosition = false;
bool DragonCloudTradingRuleParameters::HasSellPosition = false;
int DragonCloudTradingRuleParameters::IchimokuHandle = 0;
bool DragonCloudTradingRuleParameters::EntriedCurrentBar = false;
