#include "ITradingRuleParameters.mqh"

/// <summary>
/// ドラゴンクラウド売買ルールクラスのパラメータ
/// </summary>
class DragonCloudTradingRuleParameters : public ITradingRuleParameters
{
public:
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
    /// 売買シグナル発生時の価格
    /// </summary>
    double PriceAtSignal;
};

bool DragonCloudTradingRuleParameters::HasBuyPosition = false;
bool DragonCloudTradingRuleParameters::HasSellPosition = false;
int DragonCloudTradingRuleParameters::IchimokuHandle = 0;

