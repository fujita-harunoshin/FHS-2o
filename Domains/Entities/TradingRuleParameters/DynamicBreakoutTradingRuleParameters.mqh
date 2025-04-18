#include "ITradingRuleParameters.mqh"

/// <summary>
/// ダイナミックブレイクアウト売買ルールのパラメータ
/// </summary>
class DynamicBreakoutTradingRuleParameters : public ITradingRuleParameters
{
public:
    /// <summary>
    /// バー情報
    /// </summary>
    static BarData *BarDataInstance;

    /// <summary>
    /// あらかじめ生成したボリンジャーバンドハンドラーの配列（期間20〜60）
    /// 添字は (期間 - 20) でアクセスする
    /// </summary>
    static int BollingerBandHandles[41];
    
    /// <summary>
    /// 今日のボリンジャーバンドのハンドル
    /// </summary>
    static int BollingerBandHandleToday;
    
    /// <summary>
    /// あらかじめ生成したSMAハンドラーの配列（期間20〜60）
    /// 添字は (期間 - 20) でアクセスする
    /// </summary>
    static int SMAHandles[41];
    
    /// <summary>
    /// 昨日の終値
    /// </summary>
    static double PriceCloseYesterday;
    
    /// <summary>
    /// 昨日の終値標準偏差
    /// </summary>
    static double DeviationYesterday;
    
    /// <summary>
    /// 今日の終値標準偏差
    /// </summary>
    static double DeviationToday;
    
    /// <summary>
    /// 昨日のルックバック日数
    /// </summary>
    static int LookBackDaysYesterday;
    
    /// <summary>
    /// 今日ののルックバック日数
    /// </summary>
    static int LookBackDaysToday;

    /// <summary>
    /// 現在のバーでエントリー済みかのフラグ
    /// </summary>
    static bool EntriedCurrentBar;
    
    /// <summary>
    /// このルールでポジションを取り済みかのフラグ
    /// </summary>
    static bool HasPosition;
    
    /// <summary>
    /// オーダーシグナル発生時のルックバック日数
    /// </summary>
    int LookBackDaysAtSignal;
};

BarData *DynamicBreakoutTradingRuleParameters::BarDataInstance = new BarData();
double DynamicBreakoutTradingRuleParameters::PriceCloseYesterday = 0;
double DynamicBreakoutTradingRuleParameters::DeviationYesterday = 0;
double DynamicBreakoutTradingRuleParameters::DeviationToday = 0;
int DynamicBreakoutTradingRuleParameters::LookBackDaysYesterday = 0;
int DynamicBreakoutTradingRuleParameters::LookBackDaysToday = 0;
int DynamicBreakoutTradingRuleParameters::BollingerBandHandles[41] = {0};
int DynamicBreakoutTradingRuleParameters::BollingerBandHandleToday = 0;
int DynamicBreakoutTradingRuleParameters::SMAHandles[41] = {0};
bool DynamicBreakoutTradingRuleParameters::EntriedCurrentBar = false;
bool DynamicBreakoutTradingRuleParameters::HasPosition = false;
