#include "IMoneyManagementParameters.mqh"

/// <summary>
/// 固定ユニット法のパラメータ
/// </summary>
class FixedUnitsMoneyManagementParameters : public IMoneyManagementParameters
{
public:
    /// <summary>
    /// 固定ユニット数
    /// </summary>
    static int FixedUnitNumber;

    /// <summary>
    /// 口座残高 [アカウント通貨単位]
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

int FixedUnitsMoneyManagementParameters::FixedUnitNumber = 0;
