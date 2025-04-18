#include "IMoneyManagement.mqh"
#include "../../Domains/Entities/MoneyManagementParameters/FixedVolatilityMoneyManagementParameters.mqh"
#include "../Indicators/ATRIndicator.mqh"

/// <summary>
/// 固定ボラティリティによる資金管理クラス
/// </summary>
/// <remarks>
/// ロット数 = (口座残高[アカウント通貨単位]　× 定率[%] × 0.01) ÷ 固定ボラティリティ[アカウント通貨単位/ロット]
/// </remarks>
class FixedVolatilityMoneyManagement : public IMoneyManagement
{
public:
    /// <summary>
    /// コンストラクタ
    /// </summary>
    /// <param name="risk_percent">定率[%]</param>
    /// <param name="atr_days">ATR計算に用いる期間</param>
    FixedVolatilityMoneyManagement(double risk_percent, int atr_period)
    {
        m_name = "固定ボラティリティ";
        FixedVolatilityMoneyManagementParameters::RiskPercent = risk_percent;
        FixedVolatilityMoneyManagementParameters::AtrPeriod = atr_period;
        FixedVolatilityMoneyManagementParameters::AtrHandle = ATRIndicator::CreateHandle(_Symbol, _Period, atr_period);
    }

    /// <summary>
    /// 初期化
    /// </summary>
    /// <returns>初期化成否</returns>
    bool Init() override
    {
        if (FixedVolatilityMoneyManagementParameters::AtrHandle == INVALID_HANDLE) return false;
        
        return true;
    }
    
    /// <summary>
    /// エントリー時のロット数を計算
    /// </summary>
    /// <param name="params">資金管理用パラメータ</param>
    /// <returns>ロット数</returns>
    double CalculateLot(IMoneyManagementParameters &params) override
    {
        FixedVolatilityMoneyManagementParameters *parameters = dynamic_cast<FixedVolatilityMoneyManagementParameters *>(&params);
        
        double risk_amount = parameters.AccountBalance * (parameters.RiskPercent * 0.01);
        double atr_pips = parameters.AtrPips;
        double fixed_volatility = atr_pips * Utility::GetQuoteCurrencyPricePerLotPip() * Utility::GetQuoteToAccountRate(_Symbol);
        
        if (fixed_volatility <= 0)
        {
            Print("固定ボラティリティが不正です: ", fixed_volatility);
            return 0;
        }
        
        double lot_size = risk_amount / fixed_volatility;
        return NormalizeLotSize(lot_size);
    }
    
    /// <summary>
    /// オーダー時に資金管理パラメータのインスタンスを作成
    /// </summary>
    IMoneyManagementParameters* CreateParametersInstance() override
    {
        return new FixedVolatilityMoneyManagementParameters();
    }
    
    /// <summary>
    /// 売買シグナル発生時に資金管理パラメータを更新する処理
    /// </summary>
    void UpdateParametersOnSignaled(ENUM_ORDER_TYPE order_type, double sl_price, IMoneyManagementParameters &params) override
    {
        FixedVolatilityMoneyManagementParameters *parameters = dynamic_cast<FixedVolatilityMoneyManagementParameters *>(&params);

        double atr_value;
        if (!ATRIndicator::GetLatestValue(parameters.AtrHandle, atr_value)) atr_value = 0;
        
        double atr_pips = Utility::PriceToPips(atr_value);
        
        parameters.AccountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
        parameters.AtrPips = atr_pips;
    }
    
    /// <summary>
    /// 手仕舞い時に資金管理パラメータを更新する処理
    /// </summary>
    void UpdateParametersOnEntryOut(ulong deal_ticket, IMoneyManagementParameters &params) override
    {
    }
};
