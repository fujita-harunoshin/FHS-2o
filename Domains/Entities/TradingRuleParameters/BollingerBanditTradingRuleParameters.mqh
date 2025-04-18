#include "ITradingRuleParameters.mqh"

/// <summary>
/// ボリンジャーバンディット売買ルールのパラメータ
/// </summary>
class BollingerBanditTradingRuleParameters : public ITradingRuleParameters
{
public:
    /// <summary>
    /// ボリンジャーバンドハンドル
    /// </summary>
    static int BollingerBandsHandle;
    
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
    /// トレーリングストップ用バー情報
    /// </summary>
    BarData *BarDataForTrail;
    
    /// <summary>
    /// ストップの計算に用いるMA期間（初期50 → 最低10）
    /// </summary>
    int CurrentMAPeriod;
    
    /// <summary>
    /// あらかじめ生成したSMAハンドラーの配列（期間10〜50）
    /// 添字は (期間 - 10) でアクセスする
    /// </summary>
    static int SMAHandles[41];
    
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

int BollingerBanditTradingRuleParameters::BollingerBandsHandle = INVALID_HANDLE;
BarData *BollingerBanditTradingRuleParameters::BarDataForOrder = new BarData();
int BollingerBanditTradingRuleParameters::SMAHandles[41] = {0};
bool BollingerBanditTradingRuleParameters::EntriedCurrentBar = false;
bool BollingerBanditTradingRuleParameters::HasPosition = false;
