#include "IMoneyManagementParameters.mqh"

/// <summary>
/// 固定比率法のパラメータ
/// </summary>
class FixedRatioMoneyManagementParameters : public IMoneyManagementParameters
{
public:
    /// <summary>
    /// 最大ドローダウン[アカウント通貨単位/ロット]
    /// </summary>
    static double MaxDrawdown;

    /// <summary>
    /// デルタ = 最大ドローダウン[アカウント通貨単位/ロット] + 当初証拠金[アカウント通貨単位/ロット]
    /// </summary>
    static double Delta;
    
    /// <summary>
    /// 次回ロット増加に必要な口座水準 [アカウント通貨単位]
    /// </summary>
    static double CurrentThreshold;
    
    /// <summary>
    /// 現在のロット数 [ロット]
    /// </summary>
    static double CurrentLotSize;
    
    /// <summary>
    /// 最小ロット数 [ロット]
    /// </summary>
    static double MinLot;
};

double FixedRatioMoneyManagementParameters::MaxDrawdown = 0.0;
double FixedRatioMoneyManagementParameters::Delta = 0.0;
double FixedRatioMoneyManagementParameters::CurrentThreshold = 0.0;
double FixedRatioMoneyManagementParameters::CurrentLotSize = 0.0;
double FixedRatioMoneyManagementParameters::MinLot = 0.0;
