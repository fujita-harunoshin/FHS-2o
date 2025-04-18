/// <summary>
/// 単純移動平均（SMA）
/// </summary>
class SMAIndicator
{
public:
    /// <summary>
    /// SMAインジケーターのハンドルを生成
    /// </summary>
    /// <param name="symbol">銘柄名</param>
    /// <param name="timeframe">タイムフレーム</param>
    /// <param name="period">期間</param>
    /// <param name="shift">シフト本数</param>
    /// <returns>生成されたハンドル。作成失敗時はINVALID_HANDLEを返す</returns>
    static int CreateHandle(const string symbol, const ENUM_TIMEFRAMES timeframe, const int period, const int shift)
    {
        int handle = iMA(symbol, timeframe, period, shift, MODE_SMA, PRICE_CLOSE);
        if (handle == INVALID_HANDLE)
            Print("SMAIndicatorService::CreateHandle - SMAハンドルの生成に失敗しました。");

        return handle;
    }
    
    /// <summary>
    /// カスタムSMAインジケーターのハンドルを生成
    /// </summary>
    /// <param name="symbol">銘柄名</param>
    /// <param name="timeframe">タイムフレーム</param>
    /// <param name="period">期間</param>
    /// <param name="shift">シフト本数</param>
    /// <returns>生成されたハンドル。作成失敗時はINVALID_HANDLEを返す</returns>
    static int CreateHandleCustom(const string symbol, const ENUM_TIMEFRAMES timeframe, const int period, const int shift, ENUM_APPLIED_PRICE applied_price)
    {
        int handle = iMA(symbol, timeframe, period, shift, MODE_SMA, applied_price);
        if (handle == INVALID_HANDLE)
            Print("SMAIndicatorService::CreateHandle - SMAハンドルの生成に失敗しました。");

        return handle;
    }

    /// <summary>
    /// SMAインジケーターの最新値を取得
    /// </summary>
    /// <param name="handle">SMAインジケーターのハンドル</param>
    /// <param name="latestValue">取得した最新値を返す参照変数</param>
    /// <returns>取得に成功した場合はtrue、失敗した場合はfalse</returns>
    static bool GetLatestValue(const int handle, double &latestValue)
    {
        double buffer[1];
        if (CopyBuffer(handle, 0, 0, 1, buffer) != 1)
        {
            Print("SMAIndicatorService::GetLatestValue - バッファのコピーに失敗しました。");
            return false;
        }

        latestValue = buffer[0];
        return true;
    }
};
