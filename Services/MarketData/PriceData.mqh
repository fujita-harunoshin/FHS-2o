/// <summary>
/// 価格データ
/// </summary>
class PriceData
{
public:
    /// <summary>
    /// 指定シフト位置の始値を取得（デフォルトは最新バー：shift=0）
    /// </summary>
    static double GetOpenPrice(const int shift = 0)
    {
        return iOpen(_Symbol, _Period, shift);
    }

    /// <summary>
    /// 指定シフト位置の終値を取得（デフォルトは最新バー：shift=0）
    /// </summary>
    static double GetClosePrice(const int shift = 0)
    {
        return iClose(_Symbol, _Period, shift);
    }

    /// <summary>
    /// 指定シフト位置の高値を取得（デフォルトは最新バー：shift=0）
    /// </summary>
    static double GetHighPrice(const int shift = 0)
    {
        return iHigh(_Symbol, _Period, shift);
    }

    /// <summary>
    /// 指定シフト位置の安値を取得（デフォルトは最新バー：shift=0）
    /// </summary>
    static double GetLowPrice(const int shift = 0)
    {
        return iLow(_Symbol, _Period, shift);
    }

    /// <summary>
    /// 直近 N 期間の高値の配列を取得する
    /// </summary>
    /// <param name="period">期間</param>
    /// <param name="highs">高値配列（参照渡し）</param>
    /// <param name="shift">取得開始シフト位置（0: 最新バー、1: 直前の完結済みバー など）</param>
    static bool GetHighPrices(const int period, double &highs[], int shift = 0)
    {
        int copied = CopyHigh(_Symbol, _Period, shift, period, highs);
        if (copied < period)
        {
            Print("十分な高値が取得できませんでした。取得バー数 = ", copied);
            return false;
        }
        ArraySetAsSeries(highs, true);
        return true;
    }

    /// <summary>
    /// 直近 N 期間の安値の配列を取得する
    /// </summary>
    static bool GetLowPrices(const int period, double &lows[], int shift = 0)
    {
        int copied = CopyLow(_Symbol, _Period, shift, period, lows);
        if (copied < period)
        {
            Print("十分な安値が取得できませんでした。取得バー数 = ", copied);
            return false;
        }
        ArraySetAsSeries(lows, true);
        return true;
    }

    /// <summary>
    /// 直近 N 期間の始値の配列を取得する
    /// </summary>
    static bool GetOpenPrices(const int period, double &opens[], int shift = 0)
    {
        int copied = CopyOpen(_Symbol, _Period, shift, period, opens);
        if (copied < period)
        {
            Print("十分な始値が取得できませんでした。取得バー数 = ", copied);
            return false;
        }
        ArraySetAsSeries(opens, true);
        return true;
    }

    /// <summary>
    /// 直近 N 期間の終値の配列を取得する
    /// </summary>
    static bool GetClosePrices(const int period, double &closes[], int shift = 0)
    {
        int copied = CopyClose(_Symbol, _Period, shift, period, closes);
        if (copied < period)
        {
            Print("十分な終値が取得できませんでした。取得バー数 = ", copied);
            return false;
        }
        ArraySetAsSeries(closes, true);
        return true;
    }

    /// <summary>
    /// 直近N期間の最高値を取得
    /// </summary>
    /// <returns>直近N期間</returns>
    static double GetHighestPrice(const int period)
    {
        int index_highest = iHighest(_Symbol, _Period, MODE_HIGH, period, 0);
        return iHigh(_Symbol, _Period, index_highest);
    }

    /// <summary>
    /// 直近N期間の最安値を取得
    /// </summary>
    /// <returns>直近N期間</returns>
    static double GetLowestPrice(const int period)
    {
        int index_lowest = iLowest(_Symbol, _Period, MODE_LOW, period, 0);
        return iLow(_Symbol, _Period, index_lowest);
    }

    /// <summary>
    /// 直近N期間の完結済みバーの最高値を取得
    /// </summary>
    /// <returns>直近N期間</returns>
    static double GetHighestPriceCompletedBar(const int period)
    {
        int index_highest = iHighest(_Symbol, _Period, MODE_HIGH, period, 1);
        return iHigh(_Symbol, _Period, index_highest);
    }

    /// <summary>
    /// 直近N期間の完結済みバーの最安値を取得
    /// </summary>
    /// <returns>直近N期間</returns>
    static double GetLowestPriceCompletedBar(const int period)
    {
        int index_lowest = iLowest(_Symbol, _Period, MODE_LOW, period, 1);
        return iLow(_Symbol, _Period, index_lowest);
    }
};
