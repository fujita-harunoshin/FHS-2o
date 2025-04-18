#include "../Types/TradingRuleType.mqh"
#include "../Types/MoneyManagementType.mqh"

/// <summary>
/// 指標
/// </summary>
class Indices
{
public:
    /// <summary>
    /// 売買ルール種別
    /// </summary>
    TRADING_RULE_TYPE TradingRuleType;

    /// <summary>
    /// 売買ルール名
    /// </summary>
    string TradingRuleName;
    
    /// <summary>
    /// 資金管理種別
    /// </summary>
    MONEY_MANAGEMENT_TYPE MoneyManagementType;
    
    /// <summary>
    /// 資金管理名
    /// </summary>
    string MoneyManagementName;
    
    /// <summary>
    /// 取引数[回]
    /// </summary>
    int TotalTradeTimes;
    
    /// <summary>
    /// 勝ちトレード数[回]
    /// </summary>
    int WinTradeTimes;
    
    /// <summary>
    /// 負けトレード数[回]
    /// </summary>
    int LoseTradeTimes;
    
    /// <summary>
    /// 勝トレードの累積利益 [アカウント通貨単位]
    /// </summary>
    double TotalGain;
    
    /// <summary>
    /// 負けトレードの累積損失 [アカウント通貨単位]
    /// </summary>
    double TotalLoss;
    
    /// <summary>
    /// 総損益 [アカウント通貨単位]
    /// </summary>
    double TotalProfitLoss;
    
    /// <summary>
    /// 勝率[%]
    /// </summary>
    double WinningPercentage;
    
    /// <summary>
    /// 敗率[%]
    /// </summary>
    double LosingPercentage;
    
    /// <summary>
    /// ペイオフレシオ（平均利益÷平均損失）
    /// </summary>
    double PayoffRatio;
    
    /// <summary>
    /// 1回のトレードでの最大損失額 [アカウント通貨単位]
    /// </summary>
    double MaxLossPricePerTrade;
    
    /// <summary>
    /// 各トレードでのリスク割合の累積値
    /// </summary>
    double CumulativeRisk;
    
    /// <summary>
    /// 1回のトレードでリスクにさらす資金割合（平均値） e (0 < e <= 1)
    /// </summary>
    double RiskPerTrade;
    
    /// <summary>
    /// バルサラの破産確率
    /// </summary>
    double BarsalaBankruptcyProbability;
    
    /// <summary>
    /// 1トレードあたりの期待値 [アカウント通貨単位/回]
    /// </summary>
    double ExpectedValueParTrade;
    
    /// <summary>
    /// 1年間のトレード回数 [回/年]
    /// </summary>
    double TradeTimesYearly;
    
    /// <summary>
    /// 1年あたりの期待値 [アカウント通貨単位/年]
    /// </summary>
    double ExpectedValueYearly;
};
