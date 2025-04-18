#include "IMoneyManagement.mqh"
#include "../../Domains/Entities/MoneyManagementParameters/WilliamsFixedRiskMoneyManagementParameters.mqh"

/// <summary>
/// ウィリアムズの固定リスク率による資金管理クラス
/// </summary>
/// <remarks>
/// ロット数 = リスク額[アカウント通貨単位] ÷ 実際に被った最大損失[アカウント通貨単位/ロット]
///  └ リスク額[アカウント通貨単位]: 口座残高[アカウント通貨単位] × リスク率[%]　× 0.01 
///    └ リスク率[%]: 最大損失を被った場合に失う覚悟がある口座の金額
///  └ 最大損失[アカウント通貨単位/ロット]: 1回のトレードで被った損失最大
/// </remarks>
class WilliamsFixedRiskMoneyManagement : public IMoneyManagement
{
public:
    /// <summary>
    /// コンストラクタ
    /// </summary>
    /// <param name="risk_percent">リスク率[%]</param>
    /// <param name="default_max_loss">1回のトレードでの最大損失額初期値 [アカウント通貨単位]</summary>
    WilliamsFixedRiskMoneyManagement(double risk_percent, double default_max_loss)
    {
        m_name = "ウィリアムズの固定リスク率";
        WilliamsFixedRiskMoneyManagementParameters::RiskPercent = risk_percent;
        WilliamsFixedRiskMoneyManagementParameters::ActualMaxLossPerLot = default_max_loss;
    }
    
    /// <summary>
    /// 初期化
    /// </summary>
    /// <returns>初期化成否</returns>
    bool Init() override
    {
        if (WilliamsFixedRiskMoneyManagementParameters::RiskPercent <= 0 ||
            WilliamsFixedRiskMoneyManagementParameters::ActualMaxLossPerLot <= 0)
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
        WilliamsFixedRiskMoneyManagementParameters *parameters = dynamic_cast<WilliamsFixedRiskMoneyManagementParameters *>(&params);
        
        double account_balance = parameters.AccountBalance;
        double risk_amount = account_balance * (parameters.RiskPercent / 100.0);
        double actual_max_loss_per_lot = parameters.ActualMaxLossPerLot;
        Print(actual_max_loss_per_lot);
        double lot_size = risk_amount / actual_max_loss_per_lot;

        return NormalizeLotSize(lot_size);
    }
    
    /// <summary>
    /// オーダー時に資金管理パラメータのインスタンスを作成
    /// </summary>
    IMoneyManagementParameters* CreateParametersInstance() override
    {
        return new WilliamsFixedRiskMoneyManagementParameters();
    }
    
    /// <summary>
    /// 売買シグナル発生時に資金管理パラメータを更新する処理
    /// </summary>
    void UpdateParametersOnSignaled(ENUM_ORDER_TYPE order_type, double sl_price, IMoneyManagementParameters &params) override
    {
        WilliamsFixedRiskMoneyManagementParameters *parameters = dynamic_cast<WilliamsFixedRiskMoneyManagementParameters *>(&params);
        
        parameters.AccountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    }
    
    /// <summary>
    /// 手仕舞い時に資金管理パラメータを更新する処理
    /// </summary>
    void UpdateParametersOnEntryOut(ulong deal_ticket, IMoneyManagementParameters &params) override
    {
        WilliamsFixedRiskMoneyManagementParameters *parameters = dynamic_cast<WilliamsFixedRiskMoneyManagementParameters *>(&params);
        
        double lot_size = HistoryDealGetDouble(deal_ticket, DEAL_VOLUME);
        double profit = HistoryDealGetDouble(deal_ticket, DEAL_PROFIT) * Utility::GetQuoteToAccountRate(_Symbol);
        double loss_price_per_lot = (profit < 0) ? -profit / lot_size : 0.0;
        if (parameters.ActualMaxLossPerLot < loss_price_per_lot) parameters.ActualMaxLossPerLot = loss_price_per_lot;
    }
};
