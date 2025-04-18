#include "../MarketData/PriceData.mqh"

/// <summary>
/// もみ合い市場指数(CMI)インジケーター
/// </summary>
class ChoppyMarketIndexIndicator
{
public:
    /// <summary>
    /// 最新のもみ合い市場指数取得
    /// </summary>
    /// <param name="value">計算結果を返す参照変数</param>
    /// <param name="period">計算期間（例：30）</param>
    /// <returns>取得に成功した場合は true、失敗した場合は false</returns>
    static bool GetLatestValue(double &value, int period)
    {
        double highest_price = PriceData::GetHighestPrice(period);
        double lowest_price = PriceData::GetLowestPrice(period);
        double denom = highest_price - lowest_price;
        if (denom == 0)
        {
            Print("CMI取得に失敗");
            return false;
        }
        
        double num = PriceData::GetClosePrice(period - 1) - PriceData::GetClosePrice(0);
        
        value = MathAbs(num)/denom * 100;
        return true;
    }
};  
