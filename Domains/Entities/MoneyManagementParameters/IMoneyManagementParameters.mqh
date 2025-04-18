#include "../../../Services/Utility.mqh"

/// <summary>
/// 資金管理パラメータの抽象インターフェース
/// 各ポジション固有のパラメータは、このインターフェースを継承して実装する
/// </summary>
class IMoneyManagementParameters
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
    /// オーダータイプ
    /// </summary>
    ENUM_ORDER_TYPE OrderType;
    
    /// <summary>
    /// ポジションタイプ
    /// </summary>
    ENUM_POSITION_TYPE PositionType;
    
    /// <summary>
    /// 損切ライン
    /// </summary>
    double StopLossPrice;

    /// <summary>
    /// デストラクタ
    /// </summary>
    virtual ~IMoneyManagementParameters() {}
};
