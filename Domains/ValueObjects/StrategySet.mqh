#include "../Entities/Indices.mqh"
#include "../../Services/TradingRules/ITradingRule.mqh"
#include "../../Services/MoneyManagement/IMoneyManagement.mqh"

/// <summary>
/// 売買ルールと資金管理戦略と統計指標の組合せ
/// </summary>
class StrategySet
{
public:
    /// <summary>
    /// 売買ルール
    /// </summary>
    ITradingRule *TradingRule;
    
    /// <summary>
    /// 資金管理戦略
    /// </summary>
    IMoneyManagement *MoneyManagement;
    
    /// <summary>
    /// 統計指標
    /// </summary>
    Indices *Indices;
    
public:
    StrategySet(ITradingRule *trading_rule, IMoneyManagement *money_management, Indices *indices)
        : TradingRule(trading_rule), MoneyManagement(money_management), Indices(indices) {}
};
