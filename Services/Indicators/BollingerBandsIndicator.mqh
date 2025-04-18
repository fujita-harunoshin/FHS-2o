/// <summary>
/// ボリンジャーバンド
/// </summary>
class BollingerBandsIndicator
{
public:
    /// <summary>
    /// ボリンジャーバンドインジケーターのハンドルを生成
    /// </summary>
    /// <param name="symbol">銘柄名</param>
    /// <param name="timeframe">タイムフレーム</param>
    /// <param name="period">期間</param>
    /// <param name="shift">シフト本数</param>
    /// <param name="deviation">標準偏差の数</param>
    /// <param name="applied_price">価格の種類かハンドル</param>
    /// <returns>生成されたハンドル。作成失敗時はINVALID_HANDLEを返す</returns>
    static int CreateHandle(const string symbol, const ENUM_TIMEFRAMES timeframe, const int period, const int shift, const double deviation, const ENUM_APPLIED_PRICE  applied_price)
    {
        int handle = iBands(symbol, timeframe, period, shift, deviation, applied_price);
        if (handle == INVALID_HANDLE)
            Print("BollingerBandsIndicator::CreateHandle - ボリンジャーバンドインジケーターの生成に失敗しました。");

        return handle;
    }

    /// <summary>
    /// ボリンジャーバンドインジケーターの最新値値を取得
    /// </summary>
    /// <param name="handle">SMAインジケーターのハンドル</param>
    /// <param name="buffer_number">バッファ番号は 0 - BASE_LINE、1 - UPPER_BAND、2 - LOWER_BAND</param>
    /// <param name="latestValue">取得した最新値を返す参照変数</param>
    /// <returns>取得に成功した場合はtrue、失敗した場合はfalse</returns>
    static bool GetLatestValue(const int handle, const int buffer_number, double &latestValue)
    {
        double buffer[1];
        if (CopyBuffer(handle, buffer_number, 0, 1, buffer) != 1)
        {
            Print("SMAIndicatorService::GetLatestValue - バッファのコピーに失敗しました。");
            return false;
        }

        latestValue = buffer[0];
        return true;
    }
};
