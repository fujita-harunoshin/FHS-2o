#include "IMoneyManagement.mqh"
#include "../../Domains/Entities/MoneyManagementParameters/FixedRatioMoneyManagementParameters.mqh"

/// <summary>
/// 固定比率による資金管理クラス
/// </summary>
/// <remarks>
/// ロット数を最小枚数増やせる次の水準を計算する
/// 次の口座水準 = 現在の口座水準[アカウント通貨単位] + (現在のロット数[ロット]　× デルタ[アカウント通貨単位/ロット])
///   └ デルタ = 最大ドローダウン[アカウント通貨単位/ロット] + 当初証拠金 [アカウント通貨単位/ロット]
/// ↑ あってんのか？あと売買ルールの期待値がプラスじゃないと上手く行ってるかわからん。モックでも作る？
/// </remarks>
class FixedRatioMoneyManagement : public IMoneyManagement
{    
public:
    /// <summary>
    /// コンストラクタ
    /// </summary>
    /// <param name="max_drawdown">最大ドローダウン[アカウント通貨単位/ロット]</param>
    FixedRatioMoneyManagement(const double max_drawdown)
    {
        m_name = "固定比率法";
        FixedRatioMoneyManagementParameters parameters = new FixedRatioMoneyManagementParameters();
        double initial_margin = SymbolInfoDouble(_Symbol, SYMBOL_MARGIN_INITIAL);
        parameters.MaxDrawdown = max_drawdown;
        parameters.Delta = max_drawdown + initial_margin;
        parameters.CurrentThreshold = AccountInfoDouble(ACCOUNT_BALANCE);
        parameters.CurrentLotSize = 0.0;
        parameters.MinLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    }
    
    /// <summary>
    /// 初期化
    /// </summary>
    /// <returns>初期化成否</returns>
    bool Init() override
    {
        if (FixedRatioMoneyManagementParameters::MaxDrawdown == 0)
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
        FixedRatioMoneyManagementParameters *parameters = dynamic_cast<FixedRatioMoneyManagementParameters *>(&params);
        return parameters.CurrentLotSize;
    }
    
    /// <summary>
    /// オーダー時に資金管理パラメータのインスタンスを作成
    /// </summary>
    IMoneyManagementParameters* CreateParametersInstance() override
    {
        return new FixedRatioMoneyManagementParameters();
    }
    
    /// <summary>
    /// 売買シグナル発生時に資金管理パラメータを更新する処理
    /// </summary>
    void UpdateParametersOnSignaled(ENUM_ORDER_TYPE order_type, double sl_price, IMoneyManagementParameters &params) override
    {
        FixedRatioMoneyManagementParameters *parameters = dynamic_cast<FixedRatioMoneyManagementParameters *>(&params);
        
        double current_balance = AccountInfoDouble(ACCOUNT_BALANCE);
        Print(parameters.MinLot);
        Print(parameters.CurrentThreshold);
        while (current_balance >= parameters.CurrentThreshold + (parameters.Delta * parameters.MinLot))
        {
            parameters.CurrentLotSize += parameters.MinLot;
            parameters.CurrentThreshold += (parameters.MinLot * parameters.Delta);
        }
        
        parameters.CurrentLotSize = NormalizeLotSize(parameters.CurrentLotSize);
    }
    
    /// <summary>
    /// 手仕舞い時に資金管理パラメータを更新する処理
    /// </summary>
    void UpdateParametersOnEntryOut(ulong deal_ticket, IMoneyManagementParameters &params) override
    {
    }
};
