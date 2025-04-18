#include "IMoneyManagementParameters.mqh"

/// <summary>
/// ウィリアムズの固定リスク率法のパラメータ
/// </summary>
class WilliamsFixedRiskMoneyManagementParameters : public IMoneyManagementParameters
{
public:
    /// <summary>
    /// リスク率[%]
    /// </summary>
    static double RiskPercent;
    
    /// <summary>
    /// 1回のトレードでの最大損失額 [アカウント通貨単位]
    /// </summary>
    static double ActualMaxLossPerLot;

    /// <summary>
    /// 口座残高 [アカウント通貨単位]
    /// </summary>
    double AccountBalance;
};

double WilliamsFixedRiskMoneyManagementParameters::RiskPercent = 0.0;
double WilliamsFixedRiskMoneyManagementParameters::ActualMaxLossPerLot = 0.0;
