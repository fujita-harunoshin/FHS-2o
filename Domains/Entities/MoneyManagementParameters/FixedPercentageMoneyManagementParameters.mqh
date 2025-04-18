#include "IMoneyManagementParameters.mqh"

/// <summary>
/// 定率法のパラメータ
/// </summary>
class FixedPercentageMoneyManagementParameters : public IMoneyManagementParameters
{
public:
    /// <summary>
    /// 定率[%]
    /// </summary>
    static double RiskPercent;

    /// <summary>
    /// 口座残高 [アカウント通貨単位]
    /// </summary>
    double AccountBalance;
    
    /// <summary>
    /// 損切幅 [pips]
    /// </summary>
    double StopLossWidthPips;
};

double FixedPercentageMoneyManagementParameters::RiskPercent = 0.0;
