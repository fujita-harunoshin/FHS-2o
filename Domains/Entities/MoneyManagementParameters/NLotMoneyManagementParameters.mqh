#include "IMoneyManagementParameters.mqh"

/// <summary>
/// Nロット資金管理のパラメータ
/// </summary>
class NLotMoneyManagementParameters : public IMoneyManagementParameters
{
public:
    /// <summary>
    /// ロット数
    /// </summary>
    static double LotNumber;
};

double NLotMoneyManagementParameters::LotNumber = 0.0;
