#include "IMoneyManagementParameters.mqh"

/// <summary>
/// 固定リスク額法のパラメータ
/// </summary>
class FixedRiskMoneyManagementParameters : public IMoneyManagementParameters
{
public:
    /// <summary>
    /// ユニット数
    /// </summary>
    static int UnitNumber;

    /// <summary>
    /// 固定リスク額 [アカウント通貨単位]
    /// </summary>
    static double FixedRiskAmount;

    /// <summary>
    /// 口座残高
    /// </summary>
    double AccountBalance;
    
    /// <summary>
    /// 1ロットあたりの損切価格 [アカウント通貨単位/ロット]
    /// </summary>
    double LossWidthPricePerLot;
    
    /// <summary>
    /// 1取引のコスト [アカウント通貨単位]
    /// </summary>
    double Cost;
};

int FixedRiskMoneyManagementParameters::UnitNumber = 0;
double FixedRiskMoneyManagementParameters::FixedRiskAmount = 0.0;
