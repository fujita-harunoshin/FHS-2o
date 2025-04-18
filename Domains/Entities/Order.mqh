#include "TradingRuleParameters/ITradingRuleParameters.mqh"
#include "MoneyManagementParameters/IMoneyManagementParameters.mqh"
#include "Indices.mqh"
#include "../../Services/TradingRules/ITradingRule.mqh"
#include "../../Services/MoneyManagement/IMoneyManagement.mqh"

/// <summary>
/// オーダー
/// </summary>
class Order
{
public:
    /// <summary>
    /// オーダーID
    /// </summary>
    ulong OrderId;

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
    Order(ulong position_id, ITradingRule* trading_rule, ITradingRuleParameters* trading_rule_parameters,
            IMoneyManagement* money_management, IMoneyManagementParameters* money_management_parameters, Indices* indices)
            : OrderId(position_id), TradingRule(trading_rule), TradingRuleParameters(trading_rule_parameters),
              MoneyManagement(money_management), MoneyManagementParameters(money_management_parameters), Indices(indices)
    {
        AccountBalanceAtOrder = AccountInfoDouble(ACCOUNT_BALANCE);
    }
};
