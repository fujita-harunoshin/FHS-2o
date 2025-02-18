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
                            const int tenkan_period, const int kijun_period, const int senkou_span_B_period)
    {
        int handle = iIchimoku(symbol, timeframe, tenkan_period, kijun_period, senkou_span_B_period);
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
    /// 判定不能もしくはエラー時は 0 を返す
    /// </returns>
    static int GetThreeRolesSignal(const int handle)
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
    
    /// <summary>
    /// 転換線と基準線のクロス判定を行う
    /// 2本前と1本前のバーの転換線と基準線を比較し、
    /// 上抜け（アップクロス）の場合は 1、下抜け（ダウンクロス）の場合は -1、
    /// それ以外は 0 を返す
    /// </summary>
    /// <param name="handle">Ichimokuインジケーターのハンドル</param>
    /// <returns>上抜け：1、下抜け：-1、クロスなし：0</returns>
    static int GetTenkanKijunCrossSignalInt(const int handle)
    {
        double tenkan_old = 0.0, tenkan_recent = 0.0;
        double kijun_old  = 0.0, kijun_recent  = 0.0;

        // 転換線（バッファインデックス 0）の値を取得（2本前と1本前）
        if(CopyBuffer(handle, 0, 2, 1, &tenkan_old) != 1 ||
           CopyBuffer(handle, 0, 1, 1, &tenkan_recent) != 1)
        {
            Print("IchimokuIndicator::GetTenkanKijunCrossSignalInt - 転換線の取得に失敗しました。");
            return 0;
        }

        // 基準線（バッファインデックス 1）の値を取得（2本前と1本前）
        if(CopyBuffer(handle, 1, 2, 1, &kijun_old) != 1 ||
           CopyBuffer(handle, 1, 1, 1, &kijun_recent) != 1)
        {
            Print("IchimokuIndicator::GetTenkanKijunCrossSignalInt - 基準線の取得に失敗しました。");
            return 0;
        }

        // 2本前では転換線が基準線以下（または同値）で、
        // 直近では転換線が基準線を上回っている → 上抜け（アップクロス）
        if(tenkan_old <= kijun_old && tenkan_recent > kijun_recent)
            return 1;
        
        // 2本前では転換線が基準線以上（または同値）で、
        // 直近では転換線が基準線を下回っている → 下抜け（ダウンクロス）
        if(tenkan_old >= kijun_old && tenkan_recent < kijun_recent)
            return -1;

        // クロスが発生していない場合
        return 0;
    }
};
