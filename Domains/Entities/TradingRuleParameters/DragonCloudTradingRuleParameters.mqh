#include "ITradingRuleParameters.mqh"
#include "../CalendarEventDetail.mqh"

/// <summary>
/// ドラゴンクラウド売買ルールクラスのパラメータ
/// </summary>
class DragonCloudTradingRuleParameters : public ITradingRuleParameters
{
public:
    /// <summary>
    /// 時間情報
    /// </summary>
    static TimeData *TimeDataInstance;

    /// <summary>
    /// イベント情報
    /// </summary>
    static CalendarEventDetail Events[];

    /// <summary>
    /// 売買シグナル発生時の価格
    /// </summary>
    double PriceAtSignal;
};

TimeData *DragonCloudTradingRuleParameters::TimeDataInstance = new TimeData();
CalendarEventDetail DragonCloudTradingRuleParameters::Events[] = {};
