#include "IMoneyManagement.mqh"
#include "../../Domains/Entities/MoneyManagementParameters/FixedPercentageMoneyManagementParameters.mqh"


/// <summary>
/// 定率による資金管理クラス
/// </summary>
/// <remarks>
/// ロット数 = (定率 × 口座残高) ÷ (1ロットあたりの損失額)
///   定率: 資金の何パーセントをリスクにさらすか
///   口座残高[アカウント通貨単位]: 現在の資金
///   1ロットあたりの損失額[アカウント通貨単位/ロット]: 損切幅[pips] × 1ロット・1pipsあたりの金額[アカウント通貨単位/ロット・pips]
/// </remarks>
class FixedPercentageMoneyManagement : public IMoneyManagement
{    
public:
    /// <summary>
    /// コンストラクタ
    /// </summary>
    /// <param name="risk_percent">定率[%]</param>
    FixedPercentageMoneyManagement(const double risk_percent)
    {
        m_name = "定率法";
        FixedPercentageMoneyManagementParameters::RiskPercent = risk_percent;
    }
    
    /// <summary>
    /// 初期化
    /// </summary>
    /// <returns>初期化成否</returns>
    bool Init() override
    {
        if (FixedPercentageMoneyManagementParameters::RiskPercent == 0)
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
        FixedPercentageMoneyManagementParameters *parameters = dynamic_cast<FixedPercentageMoneyManagementParameters *>(&params);
        
        double risk_amount = parameters.AccountBalance * (parameters.RiskPercent * 0.01);
        double account_price_per_lot_pip = Utility::GetAccountCurrencyPricePerLotPip();
        double sl_width_price = parameters.StopLossWidthPips;
        double lot_size = risk_amount / (sl_width_price * account_price_per_lot_pip);
        
        return NormalizeLotSize(lot_size);
    }
    
    /// <summary>
    /// オーダー時に資金管理パラメータのインスタンスを作成
    /// </summary>
    IMoneyManagementParameters* CreateParametersInstance() override
    {
        return new FixedPercentageMoneyManagementParameters();
    }
    
    /// <summary>
    /// 売買シグナル発生時に資金管理パラメータを更新する処理
    /// </summary>
    void UpdateParametersOnSignaled(ENUM_ORDER_TYPE order_type, double sl_price, IMoneyManagementParameters &params) override
    {
        FixedPercentageMoneyManagementParameters *parameters = dynamic_cast<FixedPercentageMoneyManagementParameters *>(&params);
        
        double current_price = (order_type == ORDER_TYPE_BUY)
                 ? SymbolInfoDouble(_Symbol, SYMBOL_ASK)
                 : SymbolInfoDouble(_Symbol, SYMBOL_BID);
        double loss_diff = (order_type == ORDER_TYPE_BUY) ? (current_price - sl_price) : (sl_price - current_price);
        double sl_pips = Utility::PriceToPips(loss_diff);
        
        
        parameters.AccountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
        parameters.StopLossWidthPips = sl_pips;
    }

    /// <summary>
    /// 手仕舞い時に資金管理パラメータを更新する処理
    /// </summary>
    void UpdateParametersOnEntryOut(ulong deal_ticket, IMoneyManagementParameters &params) override
    {
    }
};
