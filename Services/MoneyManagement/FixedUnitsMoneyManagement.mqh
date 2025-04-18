#include "IMoneyManagement.mqh"
#include "../../Domains/Entities/MoneyManagementParameters/FixedUnitsMoneyManagementParameters.mqh"

/// <summary>
/// 固定ユニットによる資金管理クラス
/// </summary>
/// <remarks>
/// ロット数 = リスク額[口座通貨単位] ÷ トレードリスク額[口座通貨単位／ロット]
///   └ リスク額[口座通貨単位] = 口座残高 ÷ 固定ユニット数
///   └ トレードリスク額[アカウント通貨単位/ロット数]: 仕掛け値 - 損切の逆指値の差に手数料を足した金額
///
/// 例えば、各トレードのリスクを667ドルに固定とする場合、
/// 20,000ドルの口座残高で30ユニットなら1トレードあたり667ドル、
/// 口座残高が増えると、リスク額も増加するためトレードできるロット数も増えます。
/// （例：口座残高が41,000ドルなら 41,000/30 ≒ 1366.7 ドルのリスク量となり、1366.7÷667 ≒ 2ロット）
//// </remarks>
class FixedUnitsMoneyManagement : public IMoneyManagement
{    
public:
    /// <summary>
    /// コンストラクタ
    /// </summary>
    /// <param name="fixed_unit_number">固定ユニット数</param>
    FixedUnitsMoneyManagement(const int fixed_unit_number)
    {
        m_name = "固定ユニット";
        FixedUnitsMoneyManagementParameters::FixedUnitNumber = fixed_unit_number;
    }
    
    /// <summary>
    /// 初期化
    /// </summary>
    /// <returns>初期化成否</returns>
    bool Init() override
    {   
        if (FixedUnitsMoneyManagementParameters::FixedUnitNumber <= 0)
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
        FixedUnitsMoneyManagementParameters *parameters = dynamic_cast<FixedUnitsMoneyManagementParameters *>(&params);
        
        double risk_per_trade = parameters.AccountBalance / parameters.FixedUnitNumber;
        double trade_risk_amount = parameters.LossWidthPricePerLot + parameters.Cost;
        double lot_size = risk_per_trade / trade_risk_amount;

        return NormalizeLotSize(lot_size);
    }
    
    /// <summary>
    /// オーダー時に資金管理パラメータのインスタンスを作成
    /// </summary>
    IMoneyManagementParameters* CreateParametersInstance() override
    {
        return new FixedUnitsMoneyManagementParameters();
    }
    
    /// <summary>
    /// 売買シグナル発生時に資金管理パラメータを更新する処理
    /// </summary>
    void UpdateParametersOnSignaled(ENUM_ORDER_TYPE order_type, double sl_price, IMoneyManagementParameters &params) override
    {
        FixedUnitsMoneyManagementParameters *parameters = dynamic_cast<FixedUnitsMoneyManagementParameters *>(&params);
        
        double spread = SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID);
        double current_price = (order_type == ORDER_TYPE_BUY)
                 ? SymbolInfoDouble(_Symbol, SYMBOL_ASK)
                 : SymbolInfoDouble(_Symbol, SYMBOL_BID);
        double commission = 0.0;
        if(!OrderCalcProfit(order_type, _Symbol, 1.0, current_price, current_price, commission)) commission = 0;
        
        double loss_diff = (order_type == ORDER_TYPE_BUY) ? (current_price - sl_price) : (sl_price - current_price);
        
        parameters.AccountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
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
