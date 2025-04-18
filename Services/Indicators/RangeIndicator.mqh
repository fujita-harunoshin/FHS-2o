/// <summary>
/// レンジ計算のインジケーター
/// </summary>
class RangeIndicator
{
public:
    /// <summary>
    /// 完結済みバーn本のアベレージレンジ(高値-安値の平均)計算
    /// </summary>
    /// <param name="value">計算結果の最新値を返す参照変数</param>
    /// <param name="time_frame">タイムフレーム</param>
    /// <param name="period">計算期間</param>
    /// <returns>取得に成功した場合は true、失敗した場合は false</returns>
    static bool CalculateAverageRangeCompleted(double &value, ENUM_TIMEFRAMES time_frame, int period)
    {
        MqlRates rates[];
        int bars_needed = period;
        int copied = CopyRates(_Symbol, time_frame, 1, bars_needed, rates);
        if (copied < bars_needed)
        {
            Print("CalculateAverageRange: 十分なバーが取得できませんでした。必要バー数 = ", bars_needed, ", 取得バー数 = ", copied);
            return false;
        }
        
        double sum_range = 0.0;
        for (int i = 0; i < period; i++)
        {
            double high = rates[i].high;
            double low = rates[i].low;
            sum_range += (high - low);
        }
        
        value = sum_range / period;
        return true;
    }
    
    /// <summary>
    /// 完結済みバーn本のアベレージOCレンジ(始値-終値の平均)計算
    /// </summary>
    /// <param name="value">計算結果の最新値を返す参照変数</param>
    /// <param name="time_frame">タイムフレーム</param>
    /// <param name="period">計算期間</param>
    /// <returns>取得に成功した場合は true、失敗した場合は false</returns>
    static bool CalculateAverageOCRangeCompleted(double &value, ENUM_TIMEFRAMES time_frame, int period)
    {
        MqlRates rates[];
        int bars_needed = period;
        int copied = CopyRates(_Symbol, time_frame, 1, bars_needed, rates);
        if (copied < bars_needed)
        {
            Print("CalculateAverageOCRangeCompleted: 十分なバーが取得できませんでした。必要バー数 = ", bars_needed, ", 取得バー数 = ", copied);
            return false;
        }
        
        double sum_range = 0.0;
        for (int i = 0; i < period; i++)
        {
            double open = rates[i].open;
            double close = rates[i].close;
            sum_range += MathAbs(open - close);
        }
        
        value = sum_range / period;
        return true;
    }
};  
