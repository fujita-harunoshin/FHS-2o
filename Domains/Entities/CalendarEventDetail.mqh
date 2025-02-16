/// <summary>
/// イベントと詳細情報をまとめた構造体
/// </summary>
struct CalendarEventDetail
{
    /// <summary>
    /// イベントの説明を担う構造体
    /// </summary>
    MqlCalendarEvent event;
    
    /// <summary>
    /// イベントの値を担う構造体
    /// </summary>
    MqlCalendarValue value;
};
