/// <summary>
/// 時間データ
/// </summary>
class TimeData
{
private:
    /// <summary>
    /// 直前日足バーの開始時間
    /// </summary>
    datetime m_lastDailyBarTime;

public:
    /// <summary>
    /// コンストラクタ
    /// </summary>
    TimeData()
    {
        m_lastDailyBarTime = iTime(_Symbol, PERIOD_D1, 1);
    }

    /// <summary>
    /// 新しい日足バーが形成されたかを判定
    /// </summary>
    bool IsNewDay()
    {
        datetime current_daily_bar_time = iTime(_Symbol, PERIOD_D1, 0);

        if (current_daily_bar_time > m_lastDailyBarTime)
        {
            m_lastDailyBarTime = current_daily_bar_time;
            return true;
        }

        return false;
    }
};
