#include "../Domains/Entities/Order.mqh"

/// <summary>
/// 未約定注文サービス
/// </summary>
class OrderService
{
private:
    /// <summary>
    /// 未約定注文一覧
    /// </summary>
    Order *m_orders[];
    
public:
    /// <summary>
    /// 未約定注文追加
    /// </summary>
    /// <param name="order">未約定オーダー</param>
    void AddOrder(Order *order)
    {
        int orders_size = ArraySize(m_orders);
        ArrayResize(m_orders, orders_size + 1);
        m_orders[orders_size] = order;
    }
    
    /// <summary>
    /// 未約定注文取得
    /// </summary>
    /// <param name="order">注文ID</param>
    /// <returns>未約定オーダー</returns>
    Order* GetOrderById(ulong order_id)
    {
        for (int i = 0; i < ArraySize(m_orders); i++)
            if(m_orders[i].OrderId == order_id) return m_orders[i];
        return NULL;
    }
    
    /// <summary>
    /// 約定済み注文削除
    /// </summary>
    /// <param name="order_id">注文ID</param>
    void RemoveOrderById(ulong order_id)
    {
        int index;
        
        for (index = 0; index < ArraySize(m_orders); index++)
            if (m_orders[index].OrderId == order_id) break;
        
        if (index == ArraySize(m_orders)) return;
        
        delete m_orders[index];
        m_orders[index] = NULL;
        
        for (int i = index; i < ArraySize(m_orders)-1; i++)
            m_orders[i] = m_orders[i+1];
        
        ArrayResize(m_orders, ArraySize(m_orders)-1);
    }
    
    /// <summary>
    /// 全注文削除
    /// </summary>
    void ClearAll()
    {
        for (int i = 0; i < ArraySize(m_orders); i++)
        {
            if(m_orders[i] == NULL) continue;
            
            delete m_orders[i].TradingRuleParameters;
            delete m_orders[i].MoneyManagementParameters;
            delete m_orders[i];
            m_orders[i] = NULL;
        }
        ArrayResize(m_orders, 0);
    }
};
