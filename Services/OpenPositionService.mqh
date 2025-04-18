#include "../Domains/Entities/OpenPosition.mqh"

/// <summary>
/// 未決済ポジション管理
/// </summary>
class OpenPositionService
{
private:
    /// <summary>
    /// 未決済ポジション一覧
    /// </summary>
    OpenPosition *m_openPositions[];
    
public:
    /// <summary>
    /// 未決済ポジション追加
    /// </summary>
    /// <param name="open_position">未決済ポジション</param>
    void AddPosition(OpenPosition *open_position)
    {
        int open_positions_size = ArraySize(m_openPositions);
        ArrayResize(m_openPositions, open_positions_size + 1);
        m_openPositions[open_positions_size] = open_position;
    }
    
    /// <summary>
    /// 未決済ポジション取得
    /// </summary>
    /// <param name="open_position_id">ポジションID</param>
    /// <returns>未決済ポジション</returns>
    OpenPosition* GetOpenPositionById(ulong open_position_id)
    {
        for (int i = 0; i < ArraySize(m_openPositions); i++)
            if(m_openPositions[i].PositionId == open_position_id) return m_openPositions[i];
        return NULL;
    }
    
    /// <summary>
    /// 未決済ポジション削除
    /// </summary>
    /// <param name="open_position_id">">ポジションID</param>
    void RemoveOpenPositionById(ulong open_position_id)
    {
        int index;
        
        for (index = 0; index < ArraySize(m_openPositions); index++)
            if (m_openPositions[index].PositionId == open_position_id) break;
        
        if (index == ArraySize(m_openPositions)) return;
        
        delete m_openPositions[index].TradingRuleParameters;
        delete m_openPositions[index].MoneyManagementParameters;
        delete m_openPositions[index];
        m_openPositions[index] = NULL;
        
        for (int i = index; i < ArraySize(m_openPositions)-1; i++)
            m_openPositions[i] = m_openPositions[i+1];
        
        ArrayResize(m_openPositions, ArraySize(m_openPositions)-1);
    }
    
    /// <summary>
    /// 全ポジション削除
    /// </summary>
    void ClearAll()
    {
        for (int i = 0; i < ArraySize(m_openPositions); i++)
        {
            if(m_openPositions[i] == NULL) continue;
            
            delete m_openPositions[i].TradingRuleParameters;
            delete m_openPositions[i].MoneyManagementParameters;
            delete m_openPositions[i];
            m_openPositions[i] = NULL;
        }
        ArrayResize(m_openPositions, 0);
    }
};
