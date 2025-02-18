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
    /// Ichimokuインジケーターのシグナルフラグを取得
    /// 三役好転の場合は 1、三役逆転の場合は -1、
    /// 判定不能もしくはエラー時は 0 を返す
    /// </summary>
    /// <param name="handle">Ichimokuインジケーターのハンドル</param>
    /// <param name="signal">結果を返す参照変数</param>
    /// <returns>取得に成功した場合はtrue、失敗した場合はfalse</returns>
    static bool GetThreeRolesSignal(const int handle, int &signal)
    {
        double tenkan_buffer[1], kijun_buffer[1];
        double senkou_A_buffer[1], senkou_B_buffer[1];
        double chikou_buffer[1];

        if(CopyBuffer(handle, 0, 0, 1, tenkan_buffer) != 1 ||
           CopyBuffer(handle, 1, 0, 1, kijun_buffer) != 1)
        {
            Print("IchimokuIndicator::GetSignalFlag - 転換線または基準線の取得に失敗しました。");
            return false;
        }

        if(CopyBuffer(handle, 2, 26, 1, senkou_A_buffer) != 1 ||
           CopyBuffer(handle, 3, 26, 1, senkou_B_buffer) != 1)
        {
            Print("IchimokuIndicator::GetSignalFlag - 先行スパンの取得に失敗しました。");
            return false;
        }

        if(CopyBuffer(handle, 4, 0, 1, chikou_buffer) != 1)
        {
            Print("IchimokuIndicator::GetSignalFlag - 遅行線の取得に失敗しました。");
            return false;
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
            signal = 1;
            return true;
        }
        // 三役逆転（非常に強い売りシグナル）の条件
        else if(tenkan < kijun &&
                current_price < senkouA && current_price < senkouB &&
                chikou < price26)
        {
            signal = -1;
            return true;
        }
        else
        {
            signal = 0;
            return true;
        }
    }
    
    /// <summary>
    /// 現在の転換線と基準線の状態をチェック
    /// 転換線が基準線を上回っている場合は「買い許可状態」の1、
    /// 転換線が基準線を下回っている場合は「売り許可状態」の-1
    /// 等しい場合は0
    /// この状態を基に、エグジットシグナルや新規エントリーの可否を判断
    /// </summary>
    /// <param name="handle">Ichimokuインジケーターのハンドル</param>
    /// <param name="state">結果を返す参照変数</param>
    /// <returns>取得に成功した場合はtrue、失敗した場合はfalse</returns>
    static bool GetTenkanKijunState(const int handle, int &state)
    {
        double tenkan[1], kijun[1];
    
        // 転換線（バッファインデックス 0）の値を取得
        if(CopyBuffer(handle, 0, 1, 1, tenkan) != 1)
        {
            Print("IchimokuIndicator::GetTenkanKijunCrossSignalInt - 転換線の取得に失敗しました。");
            return false;
        }
    
        // 基準線（バッファインデックス 1）の値を取得
        if(CopyBuffer(handle, 1, 1, 1, kijun) != 1)
        {
            Print("IchimokuIndicator::GetTenkanKijunCrossSignalInt - 基準線の取得に失敗しました。");
            return false;
        }

        if(tenkan[0] > kijun[0])
        {
            state = 1;
            return true;
        }
        
        if(tenkan[0] < kijun[0])
        {
            state = -1;
            return true;
        }

        state = 0;
        return true;
    }
};
