#include "IMoneyManagement.mqh"
#include "../../Domains/Entities/MoneyManagementParameters/FixedCapitalMoneyManagementParameters.mqh"

/// <summary>
/// 固定資金による資金管理クラス
/// </summary>
/// <remarks>
/// ロット数 = 口座残高[アカウント通貨単位] ÷ 1ロットあたりの固定ユニット数[アカウント通貨単位/ロット]
///   └ 1ロットあたりの固定ユニット数[アカウント通貨単位/ロット] = 最大ドローダウン (実際の額か予想額) ÷ ブロートーチリスク率
///     └ ブロートーチリスク率： あなたがどれくらいの痛みに耐えられるか、あるいは口座残高の何%を失っても落ち着いていられるか
///     └ 最大ドローダウンは、Nロット法を用いて1ロットの最大ドローダウンを求めればよろし
/// </remarks>
class FixedCapitalMoneyManagement : public IMoneyManagement
{    
public:
    /// <summary>
    /// コンストラクタ
    /// </summary>
    /// <param name="maxDrawdown">最大ドローダウン [アカウント通貨単位/ロット]</param>
    /// <param name="riskPercentage">ブロートーチリスク率 [%]</param>
    FixedCapitalMoneyManagement(const double max_drawdown, const double blowtorch_risk_percentage)
    {
        m_name = "固定資金法";
        FixedCapitalMoneyManagementParameters::MaxDrawdown = max_drawdown;
        FixedCapitalMoneyManagementParameters::BlowtorchRiskPercentage = blowtorch_risk_percentage;
        FixedCapitalMoneyManagementParameters::FixedUnitNumber = max_drawdown / (blowtorch_risk_percentage / 100.0);
    }
    
    /// <summary>
    /// 初期化
    /// </summary>
    /// <returns>初期化成否</returns>
    bool Init() override
    {
        if (FixedCapitalMoneyManagementParameters::MaxDrawdown <= 0 ||
            FixedCapitalMoneyManagementParameters::BlowtorchRiskPercentage <= 0)
        {
            Print("入力値が不正です。");
            return false;
        }
        
        return true;
    }
    
    /// <summary>
    /// エントリー時のロット数を計算
    /// </summary>
    /// <param name="params">資金管理用パラメータ</param>
    /// <returns>ロット数</returns>
    double CalculateLot(IMoneyManagementParameters &params) override
    {
        FixedCapitalMoneyManagementParameters *parameters = dynamic_cast<FixedCapitalMoneyManagementParameters *>(&params);
        
        double account_balance = parameters.AccountBalance;
        double lot_size = account_balance / parameters.FixedUnitNumber;
        return NormalizeLotSize(lot_size);
    }
    
    /// <summary>
    /// オーダー時に資金管理パラメータのインスタンスを作成
    /// </summary>
    IMoneyManagementParameters* CreateParametersInstance() override
    {
        return new FixedCapitalMoneyManagementParameters();
    }
    
    /// <summary>
    /// 売買シグナル発生時に資金管理パラメータを更新する処理
    /// </summary>
    void UpdateParametersOnSignaled(ENUM_ORDER_TYPE order_type, double sl_price, IMoneyManagementParameters &params) override
    {
        FixedCapitalMoneyManagementParameters *parameters = dynamic_cast<FixedCapitalMoneyManagementParameters *>(&params);
        parameters.StopLossPrice = sl_price;
        parameters.AccountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    }
    
    /// <summary>
    /// 手仕舞い時に資金管理パラメータを更新する処理
    /// </summary>
    void UpdateParametersOnEntryOut(ulong deal_ticket, IMoneyManagementParameters &params) override
    {
    }
};
