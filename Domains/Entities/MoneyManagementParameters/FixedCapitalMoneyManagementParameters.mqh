#include "IMoneyManagementParameters.mqh"

/// <summary>
/// 固定資金法のパラメータ
/// </summary>
class FixedCapitalMoneyManagementParameters : public IMoneyManagementParameters
{
public:
    /// <summary>
    /// 最大ドローダウン [アカウント通貨単位/ロット]
    /// </summary>
    static double MaxDrawdown;
    
    /// <summary>
    /// ブロートーチリスク率 [%]
    /// </summary>
    static double BlowtorchRiskPercentage;

    /// <summary>
    /// 1ロットあたりの固定ユニット数 [アカウント通貨単位/ロット]
    /// </summary>
    static double FixedUnitNumber;

    /// <summary>
    /// 口座残高
    /// </summary>
    double AccountBalance;
};

double FixedCapitalMoneyManagementParameters::MaxDrawdown = 0.0;
double FixedCapitalMoneyManagementParameters::BlowtorchRiskPercentage = 0.0;
double FixedCapitalMoneyManagementParameters::FixedUnitNumber = 0.0;
