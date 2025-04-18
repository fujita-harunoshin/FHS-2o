/// <summary>
/// 資金管理戦略種別
/// </summary>
enum MONEY_MANAGEMENT_TYPE
{
    /// <summary>
    /// Nロット法
    /// </summary>
    N_LOT = 0,

    /// <summary>
    /// 固定リスク額
    /// </summary>
    FIXED_RISK = 1,

    /// <summary>
    /// 固定資金法
    /// </summary>
    FIXED_CAPITAL = 2,

    /// <summary>
    /// 固定比率法
    /// </summary>
    FIXED_RATIO = 3,

    /// <summary>
    /// 固定ユニット法
    /// </summary>
    FIXED_UNITS = 4,

    /// <summary>
    /// ウィリアムズの固定リスク率法
    /// </summary>
    WILLIAMS_FIXED_RISK = 5,

    /// <summary>
    /// 定率法
    /// </summary>
    FIXED_PERCENTAGE = 6,

    /// <summary>
    /// 固定ボラティリティ法
    /// </summary>
    FIXED_VOLATILITY = 7,
};
