#include "ITradingRuleParameters.mqh"

/// <summary>
/// スーパーコンボ売買ルールのパラメータ
/// </summary>
class SuperComboTradingRuleParameters : public ITradingRuleParameters
{
public:
    /// <summary>
    /// バー情報
    /// </summary>
    static BarData *BarDataInstance;
    
    /// <summary>
    /// バー情報
    /// </summary>
    static TimeData *TimeDataInstance;
    
    /// <summary>
    /// 完結済みバーn本の「高値 - 安値」の平均
    /// </summary>
    static double AverageRange;
    
    /// <summary>
    /// 結済みバーn本の|始値 - 終値|の平均
    /// </summary>
    static double AverageOCRange;
    
    /// <summary>
    /// 今日のトレードの可否
    /// </summary>
    static bool CanTradeToday;
    
    /// <summary>
    /// 今日が買いに適した日かのフラグ
    /// </summary>
    static bool BuyEasierDay;
    
    /// <summary>
    /// 今日が売りに適した日かのフラグ
    /// </summary>
    static bool SellEasierDay;
    
    /// <summary>
    /// ブレイクアウトの買いエントリー水準
    /// </summary>
    static double BuyBreakOutPoint;
    
    /// <summary>
    /// ブレイクアウトの売りエントリー水準
    /// </summary>
    static double SellBreakOutPoint;
    
    /// <summary>
    /// ダマしブレイクアウトの上ブレイクアウト水準
    /// </summary>
    static double LongBreakOutPoint;
    
    /// <summary>
    /// ダマしブレイクアウトの下ブレイクアウト水準
    /// </summary>
    static double ShortBreakOutPoint;
    
    /// <summary>
    /// 下へのダマしブレイクアウト発生時の買いエントリー水準
    /// </summary>
    static double BuyFailedBreakOutPoint;
    
    /// <summary>
    /// 上へのダマしブレイクアウト発生時の売りエントリー水準
    /// </summary>
    static double SellFailedBreakOutPoint;
    
    /// <summary>
    /// 本日のバーの本数
    /// </summary>
    static int BarCount;
    
    /// <summary>
    /// 日中足の高値
    /// </summary>
    static double HighIntra;
    
    /// <summary>
    /// 日中足の安値
    /// </summary>
    static double LowIntra;
    
    /// <summary>
    /// 日中足の安値
    /// </summary>
    static bool BuysToday;
    
    static bool SellsToday;
    
    /// <summary>
    /// +2 : ロングポジションからショートへ反転
    /// -2 : ショートポジションからロングへ反転
    /// </summary>
    static int CurrentTradeType;
    
    
    
    
    
    
    
    
    
    
    
    
    
    /// <summary>
    /// ATRハンドル
    /// </summary>
    static int AtrHandle;
    
    /// <summary>
    /// 現在のバーでエントリー済みかのフラグ
    /// </summary>
    static bool EntriedCurrentBar;
    
    /// <summary>
    /// このルールでポジションを取り済みかのフラグ
    /// </summary>
    static bool HasPosition;
    
    /// <summary>
    /// オーダーシグナル発生時のレート [クォート通貨単位]
    /// </summary>
    double PriceAtSignal;
    
    /// <summary>
    /// ATRの値 [クォート通貨単位]
    /// </summary>
    double AtrValue;
    
    /// <summary>
    /// キングケルトナー移動平均の値
    /// </summary>
    double MoveAverage;
    
    /// <summary>
    /// エントリー価格 [クォート通貨単位]
    /// </summary>
    double EntryPrice;
    
    /// <summary>
    /// 初期の損切ライン [クォート通貨単位]
    /// </summary>
    double InitialStopLossPrice;
    
    /// <summary>
    /// トレーリングストップ計算前の現在価格 [クォート通貨単位]
    /// </summary>
    double CurrentPriceBeforeTrail;
    
    /// <summary>
    /// 現在の損切ライン [クォート通貨単位]
    /// </summary>
    double CurrentStopLossPrice;
};

BarData *SuperComboTradingRuleParameters::BarDataInstance = new BarData();
TimeData *SuperComboTradingRuleParameters::TimeDataInstance = new TimeData();

double SuperComboTradingRuleParameters::AverageRange = 0.0;
double SuperComboTradingRuleParameters::AverageOCRange = 0.0;

bool SuperComboTradingRuleParameters::CanTradeToday = false;
bool SuperComboTradingRuleParameters::BuyEasierDay = false;
bool SuperComboTradingRuleParameters::SellEasierDay = false;
double SuperComboTradingRuleParameters::BuyBreakOutPoint = 0.0;
double SuperComboTradingRuleParameters::SellBreakOutPoint = 0.0;
double SuperComboTradingRuleParameters::LongBreakOutPoint = 0.0;
double SuperComboTradingRuleParameters::ShortBreakOutPoint = 0.0;
double SuperComboTradingRuleParameters::BuyFailedBreakOutPoint = 0.0;
double SuperComboTradingRuleParameters::SellFailedBreakOutPoint = 0.0;

int SuperComboTradingRuleParameters::AtrHandle = 0;
bool SuperComboTradingRuleParameters::EntriedCurrentBar = false;
bool SuperComboTradingRuleParameters::HasPosition = false;
