#include "IMoneyManagement.mqh"
#include "../../Domains/Entities/MoneyManagementParameters/FixedRiskMoneyManagementParameters.mqh"

/// <summary>
/// 固定リスク額による資金管理クラス
/// </summary>
/// <remarks>
/// ロット数 = 固定リスク額 ÷ トレードリスク額
///  └ 固定リスク額[アカウント通貨単位] = 当初口座残高 ÷ ユニット数
///     └ ユニット数: 口座残高を一定の基準金額で割ることで得られる、資金の分割単位
///  └ トレードリスク額[アカウント通貨単位/ロット数]: 仕掛け値 - 損切の逆指値の差に手数料を足した金額
/// </remarks>
class FixedRiskMoneyManagement : public IMoneyManagement
{
public:
    /// <summary>
    /// コンストラクタ
    /// </summary>
    /// <param name="unit_number">ユニット数</param>
    FixedRiskMoneyManagement(const int unit_number)
    {
        m_name = "固定リスク額";
        FixedRiskMoneyManagementParameters::UnitNumber = unit_number;
        FixedRiskMoneyManagementParameters::FixedRiskAmount = AccountInfoDouble(ACCOUNT_BALANCE) / unit_number;
    }
    
    /// <summary>
    /// 初期化
    /// </summary>
    /// <returns>初期化成否</returns>
    bool Init() override
    {
        if (FixedRiskMoneyManagementParameters::UnitNumber == 0)
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
        FixedRiskMoneyManagementParameters *parameters = dynamic_cast<FixedRiskMoneyManagementParameters *>(&params);
        
        double trade_risk_amount = parameters.LossWidthPricePerLot + parameters.Cost;
        double lot_size = parameters.FixedRiskAmount / trade_risk_amount;

        return NormalizeLotSize(lot_size);
    }
    
    /// <summary>
    /// オーダー時に資金管理パラメータのインスタンスを作成
    /// </summary>
    IMoneyManagementParameters* CreateParametersInstance() override
    {
        return new FixedRiskMoneyManagementParameters();
    }
    
    /// <summary>
    /// 売買シグナル発生時に資金管理パラメータを更新する処理
    /// </summary>
    void UpdateParametersOnSignaled(ENUM_ORDER_TYPE order_type, double sl_price, IMoneyManagementParameters &params) override
    {
        FixedRiskMoneyManagementParameters *parameters = dynamic_cast<FixedRiskMoneyManagementParameters *>(&params);
        
        double spread = SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID);
        double current_price = (order_type == ORDER_TYPE_BUY)
                 ? SymbolInfoDouble(_Symbol, SYMBOL_ASK)
                 : SymbolInfoDouble(_Symbol, SYMBOL_BID);
        double commission = 0.0;
        if(!OrderCalcProfit(order_type, _Symbol, 1.0, current_price, current_price, commission)) commission = 0;
        
        double loss_diff = (order_type == ORDER_TYPE_BUY) ? (current_price - sl_price) : (sl_price - current_price);
        
        parameters.Cost = spread * Utility::GetContractSize() * Utility::GetQuoteToAccountRate(_Symbol) + commission;
        parameters.LossWidthPricePerLot = loss_diff * Utility::GetContractSize() * Utility::GetQuoteToAccountRate(_Symbol);
    }
    
    /// <summary>
    /// 手仕舞い時に資金管理パラメータを更新する処理
    /// </summary>
    void UpdateParametersOnEntryOut(ulong deal_ticket, IMoneyManagementParameters &params) override
    {
    }
};
