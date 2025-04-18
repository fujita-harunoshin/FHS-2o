#include "../../../Services/MarketData/BarData.mqh"
#include "../../../Services/MarketData/TimeData.mqh"

/// <summary>
/// 売買ルールパラメータの抽象インターフェース
/// 各ポジション固有のパラメータは、このインターフェースを継承して実装する
/// </summary>
/// <remarks>
/// 売買ルールの共通情報:クラス変数
/// チケット別の情報:インスタンス変数
/// </remarks>
class ITradingRuleParameters
{
public:
    /// <summary>
    /// オーダーID
    /// </summary>
    ulong OrderId;
    
    /// <summary>
    /// ポジションID
    /// </summary>
    ulong PositionId;
    
    /// <summary>
    /// オーダー種別
    /// </summary>
    ENUM_ORDER_TYPE OrderType;

    /// <summary>
    /// ポジション種別
    /// </summary>
    ENUM_POSITION_TYPE PositionType;
    
    /// <summary>
    /// デストラクタ
    /// </summary>
    virtual ~ITradingRuleParameters() {}
};
