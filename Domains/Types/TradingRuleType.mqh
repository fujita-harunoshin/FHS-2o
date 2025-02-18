/// <summary>
/// 売買ルール種別
/// </summary>
enum TRADING_RULE_TYPE
{    
    /// <summary>
    /// タートル流トレーディング
    /// </summary>
    TURTLE = 0,
    
    /// <summary>
    /// キングケルトナー売買ルール
    /// </summary>
    KING_KELTNER = 1,
    
    /// <summary>
    /// ボリンジャーバンディット売買ルール
    /// </summary>
    BOLLINGER_BANDIT = 2,
    
    /// <summary>
    /// サーモスタット売買ルール
    /// </summary>
    THERMOSTAT = 3,
    
    /// <summary>
    /// ダイナミックブレイクアウト売買ルール
    /// </summary>
    DYNAMIC_BREAKOUT = 4,
    
    /// <summary>
    /// スーパーコンボ売買ルール
    /// </summary>
    SUPER_COMBO = 5,
    
    /// <summary>
    /// ドラゴンクラウド売買ルール
    /// </summary>
    DRAGON_CLOUD = 6,
    
    /// <summary>
    /// テスト用売買ルール
    /// </summary>
    Test = 99,
};
