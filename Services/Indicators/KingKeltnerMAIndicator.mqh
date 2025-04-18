#include "../MarketData/PriceData.mqh"

/// <summary>
/// キングケルトナー移動平均(高値、安値、終値の平均の移動平均)
/// </summary>
class KingKeltnerMAIndicator
{
public:
    /// <summary>
    /// 期間 N で計算したキングケルトナー移動平均の取得
    /// </summary>
    /// <param name="value">取得した最新値を返す参照変数</param>
    /// <param name="period">計算期間</param>
    /// <param name="shift">取得開始シフト位置（0: 最新バー、1: 直前の完結済みバーなど）</param>
    /// <returns>取得に成功した場合は true、失敗した場合は false</returns>
    static bool GetLatestValue(double &value, int period, int shift = 0)
    {
        double highs[], lows[], closes[];
        if (!PriceData::GetHighPrices(period, highs, shift))
            return false;
        if (!PriceData::GetLowPrices(period, lows, shift))
            return false;
        if (!PriceData::GetClosePrices(period, closes, shift))
            return false;

        double sum = 0.0;
        for (int i = 0; i < period; i++)
        {
            sum += (highs[i] + lows[i] + closes[i]) / 3.0;
        }

        value = sum / period;
        return true;
    }
};
