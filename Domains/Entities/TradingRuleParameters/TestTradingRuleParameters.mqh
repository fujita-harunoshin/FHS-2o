#include "ITradingRuleParameters.mqh"

/// <summary>
/// テスト用売買ルールクラスのパラメータ
/// </summary>
class TestTradingRuleParameters : public ITradingRuleParameters
{
public:
    /// <summary>
    /// 売買シグナル発生時の価格
    /// </summary>
    double PriceAtSignal;
};
