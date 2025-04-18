#include "ITradingRuleParameters.mqh"

/// <summary>
/// サーモスタット売買ルールのパラメータ
/// </summary>
class ThermostatTradingRuleParameters : public ITradingRuleParameters
{
public:
    /// <summary>
    /// サーモスタット売買ルールのモードを保持
    /// -1:不正
    /// 0:トレンドフォローモード
    /// 1:短期スイングモード
    /// </summary>
    static int Mode;

    /// <summary>
    /// ボリンジャーバンドハンドル
    /// </summary>
    static int BollingerBandsHandle;
    
    /// <summary>
    /// ATRインジケータハンドル
    /// </summary>
    static int ATRHandle;
    
    /// <summary>
    /// あらかじめ生成したSMAハンドラーの配列（期間10〜50）
    /// 添字は (期間 - 10) でアクセスする
    /// </summary>
    static int SMAHandles[41];
    
    /// <summary>
    /// レンジモードの損切ライン計算用SMAのハンドル
    /// </summary>
    static int SMAHandleForRangeHigh;
    
    /// <summary>
    /// レンジモードの損切ライン計算用SMAのハンドル
    /// </summary>
    static int SMAHandleForRangeLow;
    
    /// <summary>
    /// オーダー用バー情報
    /// </summary>
    static BarData *BarDataForOrder;
    
    /// <summary>
    /// 現在のバーでエントリー済みかのフラグ
    /// </summary>
    static bool EntriedCurrentBar;
    
    /// <summary>
    /// このルールでポジションを取り済みかのフラグ
    /// </summary>
    static bool HasPosition;
    
    /// <summary>
    /// このチケットの初期のモードを保持
    /// 市場の状態が変化したとき、適切な損切手法選択するために使用
    /// </summary>
    int ModeInitial;
    
    /// <summary>
    /// このチケットのモードを保持
    /// 市場の状態の変化を検知するために使用
    /// </summary>
    int ModeCurrent;
    
    /// <summary>
    /// トレーリングストップ用バー情報
    /// </summary>
    BarData *BarDataForTrail;
    
    /// <summary>
    /// ストップの計算に用いるMA期間（初期50 → 最低10）
    /// </summary>
    int CurrentMAPeriod;
    
    /// <summary>
    /// ストップ用SMAのハンドル
    /// </summary>
    int SMAHandle;
    
    /// <summary>
    /// オーダーシグナル発生時のレート [クォート通貨単位]
    /// </summary>
    double PriceAtSignal;
    
    /// <summary>
    /// 損切ライン [クォート通貨単位]
    /// </summary>
    double ProtectiveStop;
    
    /// <summary>
    /// トレーリングストップ計算前の現在価格 [クォート通貨単位]
    /// </summary>
    double CurrentPriceBeforeTrail;
};

int ThermostatTradingRuleParameters::Mode = 0;
int ThermostatTradingRuleParameters::BollingerBandsHandle = INVALID_HANDLE;
int ThermostatTradingRuleParameters::ATRHandle = INVALID_HANDLE;
int ThermostatTradingRuleParameters::SMAHandles[41] = {0};
int ThermostatTradingRuleParameters::SMAHandleForRangeHigh = 0;
int ThermostatTradingRuleParameters::SMAHandleForRangeLow = 0;
BarData *ThermostatTradingRuleParameters::BarDataForOrder = new BarData();
bool ThermostatTradingRuleParameters::EntriedCurrentBar = false;
bool ThermostatTradingRuleParameters::HasPosition = false;
