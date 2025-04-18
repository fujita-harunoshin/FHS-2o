/// <summary>
/// キングケルトナー・トゥルーレンジ移動平均（トゥルーレンジの平均値）のインジケーター
/// </summary>
class KingKeltnerTrueRangeAvarageIndicator
{
public:
    /// <summary>
    /// 期間Nで計算したキングケルトナー・トゥルーレンジ平均の取得
    /// </summary>
    /// <param name="value">計算結果の最新値を返す参照変数</param>
    /// <param name="period">計算期間（例：40）</param>
    /// <returns>取得に成功した場合は true、失敗した場合は false</returns>
    static bool GetLatestValue(double &value, int period)
    {
        MqlRates rates[];
        int bars_needed = period + 1;
        int copied = CopyRates(_Symbol, _Period, 0, bars_needed, rates);
        if (copied < bars_needed)
        {
            Print("十分なバーが取得できませんでした。必要バー数 = ", bars_needed, ", 取得バー数 = ", copied);
            return false;
        }

        double sum_true_range = 0.0;
        for (int i = 0; i < period; i++)
        {
            double current_high = rates[i].high;
            double current_low = rates[i].low;
            double prev_close = rates[i + 1].close;
            double max_val = MathMax(current_high, prev_close);
            double min_val = MathMin(current_low, prev_close);
            double true_range = max_val - min_val;
            sum_true_range += true_range;
        }

        value = sum_true_range / period;
        return true;
    }
};  
