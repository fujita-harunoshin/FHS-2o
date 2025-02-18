#include "../MarketData/PriceData.mqh"

class IchimokuIndicator
{
public:
    /// <summary>
    /// Ichimokuインジケーターのハンドルを生成
    /// </summary>
    /// <param name="symbol">銘柄名</param>
    /// <param name="timeframe">タイムフレーム</param>
    /// <param name="tenkanPeriod">転換線の期間</param>
    /// <param name="kijunPeriod">基準線の期間</param>
    /// <param name="senkouSpanBPeriod">先行スパンBの期間</param>
    /// <returns>生成されたハンドル。作成失敗時はINVALID_HANDLEを返す</returns>
    static int CreateHandle(const string symbol, const ENUM_TIMEFRAMES timeframe,
                            const int tenkanPeriod, const int kijunPeriod, const int senkouSpanBPeriod)
    {
        int handle = iIchimoku(symbol, timeframe, tenkanPeriod, kijunPeriod, senkouSpanBPeriod);
        if(handle == INVALID_HANDLE)
            Print("IchimokuIndicator::CreateHandle - Ichimokuハンドルの生成に失敗しました。");
        
        return handle;
    }

    /// <summary>
    /// Ichimokuインジケーターのシグナルフラグを取得します。
    /// </summary>
    /// <param name="handle">Ichimokuインジケーターのハンドル</param>
    /// <returns>
    /// 三役好転の場合は 1、三役逆転の場合は -1、
    /// 判定不能もしくはエラー時は 0 を返します。
    /// </returns>
    static int GetSignalFlag(const int handle)
    {
        double tenkan_buffer[1], kijun_buffer[1];
        double senkou_A_buffer[1], senkou_B_buffer[1];
        double chikou_buffer[1];

        if(CopyBuffer(handle, 0, 0, 1, tenkan_buffer) != 1 ||
           CopyBuffer(handle, 1, 0, 1, kijun_buffer) != 1)
        {
            Print("IchimokuIndicator::GetSignalFlag - 転換線または基準線の取得に失敗しました。");
            return 0;
        }

        if(CopyBuffer(handle, 2, 26, 1, senkou_A_buffer) != 1 ||
           CopyBuffer(handle, 3, 26, 1, senkou_B_buffer) != 1)
        {
            Print("IchimokuIndicator::GetSignalFlag - 先行スパンの取得に失敗しました。");
            return 0;
        }

        if(CopyBuffer(handle, 4, 0, 1, chikou_buffer) != 1)
        {
            Print("IchimokuIndicator::GetSignalFlag - 遅行線の取得に失敗しました。");
            return 0;
        }

        double tenkan = tenkan_buffer[0];
        double kijun = kijun_buffer[0];
        double senkouA = senkou_A_buffer[0];
        double senkouB = senkou_B_buffer[0];
        double chikou = chikou_buffer[0];

        double current_price = PriceData::GetClosePrice(0);
        double price26 = PriceData::GetClosePrice(26);

        // 三役好転（非常に強い買いシグナル）の条件
        if(tenkan > kijun &&
           current_price > senkouA && current_price > senkouB &&
           chikou > price26)
        {
            return 1;
        }
        // 三役逆転（非常に強い売りシグナル）の条件
        else if(tenkan < kijun &&
                current_price < senkouA && current_price < senkouB &&
                chikou < price26)
        {
            return -1;
        }
        else
        {
            return 0;
        }
    }
};
