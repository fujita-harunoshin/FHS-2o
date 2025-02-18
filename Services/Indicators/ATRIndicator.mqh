class ATRIndicator
{
public:
    /// <summary>
    /// ATRインジケーターのハンドルを生成
    /// </summary>
    /// <param name="symbol">銘柄名</param>
    /// <param name="timeframe">タイムフレーム</param>
    /// <param name="period">ATR計算の期間</param>
    /// <returns>生成されたハンドル。作成失敗時はINVALID_HANDLEを返す</returns>
    static int CreateHandle(const string symbol, const ENUM_TIMEFRAMES timeframe, const int period)
    {
        int handle = iATR(symbol, timeframe, period);
        if (handle == INVALID_HANDLE)
            Print("ATRIndicatorService::CreateHandle - ATRハンドルの生成に失敗しました。");

        return handle;
    }

    /// <summary>
    /// ATRインジケーターの最新値を取得します。
    /// </summary>
    /// <param name="handle">ATRインジケーターのハンドル</param>
    /// <param name="latestValue">取得した最新値を返す参照変数</param>
    /// <returns>取得に成功した場合はtrue、失敗した場合はfalse</returns>
    static bool GetLatestValue(const int handle, double &latestValue)
    {
        double buffer[1];
        if (CopyBuffer(handle, 0, 0, 1, buffer) != 1)
        {
            Print("ATRIndicatorService::GetLatestValue - バッファのコピーに失敗しました。");
            return false;
        }

        latestValue = buffer[0];
        return true;
    }
};
