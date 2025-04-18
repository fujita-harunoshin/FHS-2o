#include "../../Domains/Entities/MoneyManagementParameters/IMoneyManagementParameters.mqh"
#include "../../Domains/Types/MoneyManagementType.mqh"

/// <summary>
/// 資金管理の抽象インターフェース
/// </summary>
class IMoneyManagement
{
protected:
    /// <summary>
    /// 売買ルール
    /// </summary>
    MONEY_MANAGEMENT_TYPE m_money_management;

    /// <summary>
    /// 売買ルール名
    /// </summary>
    string m_name;

public:
    /// <summary>
    /// 仮想デストラクタ
    /// </summary>
    virtual ~IMoneyManagement() {}
    
    /// <summary>
    /// 初期化
    /// </summary>
    /// <returns>初期化成否</returns>
    virtual bool Init() = 0;
    
    /// <summary>
    /// 資金管理戦略取得
    /// </summary>
    /// <returns>資金管理戦略名</returns>
    MONEY_MANAGEMENT_TYPE GetType() { return m_money_management; }

    /// <summary>
    /// 資金管理戦略名取得
    /// </summary>
    /// <returns>資金管理戦略名</returns>
    string GetName() { return m_name; }

    /// <summary>
    /// エントリー時のロット数を計算
    /// </summary>
    /// <param name="money_management_params">資金管理パラメータ</param>
    /// <returns>ロット数</returns>
    virtual double CalculateLot(IMoneyManagementParameters &params) = 0;
    
    /// <summary>
    /// オーダー時に資金管理パラメータのインスタンスを作成
    /// </summary>
    virtual IMoneyManagementParameters* CreateParametersInstance() = 0;
    
    /// <summary>
    /// 売買シグナル発生時に資金管理パラメータを更新する処理
    /// </summary>
    virtual void UpdateParametersOnSignaled(ENUM_ORDER_TYPE order_type, double sl_price, IMoneyManagementParameters &params) = 0;
    
    /// <summary>
    /// 手仕舞い時に資金管理パラメータを更新する処理
    /// </summary>
    virtual void UpdateParametersOnEntryOut(ulong deal_ticket, IMoneyManagementParameters &params) = 0;

protected:
    /// <summary>
    /// ロットサイズをシンボルの最小・最大ロットに基づいて正規化
    /// </summary>
    /// <param name="lot">ロットサイズ</param>
    /// <returns>正規化されたロットサイズ</returns>
    double NormalizeLotSize(double lot_size)
    {
        double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
        double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
        double max_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    
        lot_size = step * NormalizeDouble(lot_size / step, 0);
        
        if (lot_size < min_lot) lot_size = min_lot;
        
        if (lot_size > max_lot) lot_size = max_lot;
    
        return lot_size;
    }
};