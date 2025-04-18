#include "IMoneyManagement.mqh"
#include "../../Domains/Entities/MoneyManagementParameters/NLotMoneyManagementParameters.mqh"

/// <summary>
/// Nロットによる資金管理クラス
/// </summary>
/// <remarks>
/// ロット数固定
/// </remarks>
class NLotMoneyManagement : public IMoneyManagement
{
public:
    /// <summary>
    /// コンストラクタ
    /// </summary>
    /// <param name="lot_number">ロット数</param>
    NLotMoneyManagement(const double lot_number)
    {
        m_name = "Nロット法";
        NLotMoneyManagementParameters::LotNumber = lot_number;
    }
    
    /// <summary>
    /// 初期化
    /// </summary>
    /// <returns>初期化成否</returns>
    bool Init() override
    {
        if (NLotMoneyManagementParameters::LotNumber == 0)
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
        double lot_number = NLotMoneyManagementParameters::LotNumber;
        return NormalizeLotSize(lot_number);
    }
    
    /// <summary>
    /// オーダー時に資金管理パラメータのインスタンスを作成
    /// </summary>
    IMoneyManagementParameters* CreateParametersInstance() override
    {
        return new NLotMoneyManagementParameters();
    }
    
    /// <summary>
    /// 売買シグナル発生時に資金管理パラメータを更新する処理
    /// </summary>
    void UpdateParametersOnSignaled(ENUM_ORDER_TYPE order_type, double sl_price, IMoneyManagementParameters &params) override
    {
        NLotMoneyManagementParameters *parameters = dynamic_cast<NLotMoneyManagementParameters *>(&params);
        parameters.StopLossPrice = sl_price;
    }
    
    /// <summary>
    /// 手仕舞い時に資金管理パラメータを更新する処理
    /// </summary>
    void UpdateParametersOnEntryOut(ulong deal_ticket, IMoneyManagementParameters &params) override
    {
    }
};
