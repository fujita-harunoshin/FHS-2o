#include "IMoneyManagementParameters.mqh"

/// <summary>
/// 固定ボラティリティ法のパラメータ
/// </summary>
class FixedVolatilityMoneyManagementParameters : public IMoneyManagementParameters
{
public:
    /// <summary>
    /// 定率[%]
    /// </summary>
    static double RiskPercent;

    /// <summary>
    /// ATR計算に用いる期間
    /// </summary>
    static int AtrPeriod;
    
    /// <summary>
    /// ATRハンドル
    /// </summary>
    static int AtrHandle;
    
    /// <summary>
    /// 口座残高 [アカウント通貨単位]
    /// </summary>
    double AccountBalance;
    
    /// <summary>
    /// ATRの値 [pips]
    /// </summary>
    double AtrPips;
};

double FixedVolatilityMoneyManagementParameters::RiskPercent = 0.0;
int FixedVolatilityMoneyManagementParameters::AtrPeriod = 0;
int FixedVolatilityMoneyManagementParameters::AtrHandle = 0;

