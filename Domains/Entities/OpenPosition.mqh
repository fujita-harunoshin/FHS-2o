#include "TradingRuleParameters/ITradingRuleParameters.mqh"
#include "MoneyManagementParameters/IMoneyManagementParameters.mqh"
#include "Indices.mqh"
#include "../../Services/TradingRules/ITradingRule.mqh"
#include "../../Services/MoneyManagement/IMoneyManagement.mqh"

/// <summary>
/// オープンポジション
/// </summary>
class OpenPosition
{
public:
    /// <summary>
    /// ポジションID
    /// </summary>
    ulong PositionId;

    /// <summary>
    /// 売買ルール
    /// </summary>
    ITradingRule* TradingRule;
    
    /// <summary>
    /// 売買ルール固有パラメータ
    /// </summary>
    ITradingRuleParameters* TradingRuleParameters;
    
    /// <summary>
    /// 資金管理
    /// </summary>
    IMoneyManagement* MoneyManagement;
    
    /// <summary>
    /// 資金管理固有パラメータ
    /// </summary>
    IMoneyManagementParameters* MoneyManagementParameters;
    
    /// <summary>
    /// 指標
    /// </summary>
    Indices *Indices;
    
    /// <summary>
    /// オーダー時の口座残高
    /// </summary>
    double AccountBalanceAtOrder;
public:
    OpenPosition(ulong position_id, ITradingRule* trading_rule, ITradingRuleParameters* trading_rule_parameters,
                IMoneyManagement* money_management, IMoneyManagementParameters* money_management_parameters,
                Indices *indices, double account_balance_at_order)
                : PositionId(position_id), TradingRule(trading_rule), TradingRuleParameters(trading_rule_parameters),
                  MoneyManagement(money_management), MoneyManagementParameters(money_management_parameters),
                  Indices(indices), AccountBalanceAtOrder(account_balance_at_order) {}
};
