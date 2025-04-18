/// <summary>
/// バーデータ
/// </summary>
class BarData
{
private:
    /// <summary>
    /// 直前バーの開始時間
    /// </summary>
    datetime m_lastBarTime;

public:
    /// <summary>
    /// コンストラクタ
    /// </summary>
    BarData()
    {
        m_lastBarTime = iTime(_Symbol, PERIOD_CURRENT, 1);
    }

    /// <summary>
    /// 新しいバーが形成されたかを判定
    /// </summary>
    bool IsNewBar()
    {
        datetime current_bar_time = iTime(_Symbol, PERIOD_CURRENT, 0);

        if (current_bar_time > m_lastBarTime)
        {
            m_lastBarTime = current_bar_time;
            return true;
        }

        return false;
    }
};
