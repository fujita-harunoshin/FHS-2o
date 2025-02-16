#include <Trade/Trade.mqh>
#include "../../Domains/Entities/CalendarEventDetail.mqh"

// MQL_TESTING が未定義の場合、補完（MQLInfoInteger(MQL_TESTING) は 1 ならテスター中）
#ifndef MQL_TESTING
   #define MQL_TESTING 6
#endif

class EconomicCalendarData
{
public:
    /// <summary>
    /// 本日のイベント情報を取得するメソッド
    /// </summary>
    /// <param name="symbol">通貨ペア文字列 (例："EURUSD")</param>
    /// <param name="events[]">結果を格納する参照渡しのイベント配列</param>
    /// <returns>取得したイベント数</returns>
    static int GetTodayEvents(const string symbol, CalendarEventDetail &details[])
    {
        datetime now = TimeCurrent();
        MqlDateTime date_time;
        TimeToStruct(now, date_time);
        date_time.hour = 0;
        date_time.min  = 0;
        date_time.sec  = 0;
        datetime today_start = StructToTime(date_time);
        
        if(MQLInfoInteger(MQL_TESTING) == 1)
        {
            return GenerateFixedEvents(symbol, today_start, details);
        }
        else
        {
            // 通常時は実際の経済指標カレンダー情報から取得する
            string base_currency = StringSubstr(symbol, 0, 3);
            string quote_currency = StringSubstr(symbol, 3, 3);
            datetime tomorrow_start = today_start + 86400;
    
            MqlCalendarEvent events_base[];
            MqlCalendarEvent events_quote[];
            int count_base = CalendarEventByCurrency(base_currency, events_base);
            if(count_base < 0)
            {
                Print("経済指標カレンダー情報取得エラー。 通貨: ", base_currency, "、 エラーコード: ", GetLastError());
                count_base = 0;
            }
    
            int count_quote = CalendarEventByCurrency(quote_currency, events_quote);
            if(count_quote < 0)
            {
                Print("経済指標カレンダー情報取得エラー。 通貨: ", quote_currency, "、 エラーコード: ", GetLastError());
                count_quote = 0;
            }
    
            ArrayResize(details, 0);
            int count_combined = 0;
    
            // base_currencyのイベントについて、詳細情報を取得して当日イベントかチェック
            for(int i = 0; i < count_base; i++)
            {
                MqlCalendarValue val;
                if(CalendarValueById(events_base[i].id, val))
                {
                    if(val.time >= today_start && val.time < tomorrow_start)
                    {
                        CalendarEventDetail detail;
                        detail.event = events_base[i];
                        detail.value = val;
                        ArrayResize(details, count_combined + 1);
                        details[count_combined] = detail;
                        count_combined++;
                    }
                }
                else
                {
                    Print("CalendarValueByIdエラー。 イベントID: ", events_base[i].id, "、エラーコード: ", GetLastError());
                }
            }
    
            // quote_currencyのイベントについても同様に処理
            for(int i = 0; i < count_quote; i++)
            {
                MqlCalendarValue val;
                if(CalendarValueById(events_quote[i].id, val))
                {
                    if(val.time >= today_start && val.time < tomorrow_start)
                    {
                        CalendarEventDetail detail;
                        detail.event = events_quote[i];
                        detail.value = val;
                        ArrayResize(details, count_combined + 1);
                        details[count_combined] = detail;
                        count_combined++;
                    }
                }
                else
                {
                    Print("CalendarValueByIdエラー。 イベントID: ", events_quote[i].id, "、エラーコード: ", GetLastError());
                }
            }
    
            return count_combined;
        }
    }

    /// <summary>
    /// イベント直前かどうかを判定するメソッド
    /// </summary>
    /// <param name="events[]">本日のイベント配列</param>
    /// <returns>イベント直前（10分以内）なら true、そうでなければ false</returns>
    static bool IsEventImminent(const CalendarEventDetail &details[])
    {
        const int PRE_EVENT_THRESHOLD = 600; // 10分（600秒）
        datetime now = TimeCurrent();
        for(int i = 0; i < ArraySize(details); i++)
        {
            int diff = int(details[i].value.time - now);
            if(diff > 0 && diff <= PRE_EVENT_THRESHOLD)
            return true;
        }
        return false;
    }

    /// <summary>
    /// イベント直後の売買停止判定メソッド
    /// </summary>
    /// <param name="events[]">本日のイベント配列</param>
    /// <returns>売買可能なら true、直後の停止期間中なら false</returns>
    static bool IsTradingAllowed(const CalendarEventDetail &details[])
    {
        datetime now = TimeCurrent();
        for(int i = 0; i < ArraySize(details); i++)
        {
            int wait_time = 0;

            switch(details[i].event.importance)
            {
                case 3:
                    wait_time = 1800; // 高重要度：30分
                    break;
                case 2:
                    wait_time = 1200; // 中重要度：20分
                    break;
                case 1:
                    wait_time = 600;  // 低重要度：10分
                    break;
                default:
                    wait_time = 600;
                    break;
            }
            
            if(now >= details[i].value.time && now < details[i].value.time + wait_time)
                return false;
        }
        return true;
    }
    
    /// <summary>
    /// 渡された CalendarEventDetail 配列の内容をクリアするメソッド
    /// </summary>
    /// <param name="details[]">クリア対象のイベント詳細配列</param>
    static void ClearEventsData(CalendarEventDetail &details[])
    {
        ArrayResize(details, 0);
    }

private:
    /// <summary>
    /// バックテスト用固定イベントデータを生成するメソッド
    /// </summary>
    /// <param name="symbol">通貨ペア文字列 (例:"EURUSD")</param>
    /// <param name="today_start">当日開始時刻（サーバー時間基準）</param>
    /// <param name="details[]">結果を格納する参照渡しのイベント詳細配列</param>
    /// <returns>生成したイベント数</returns>
    static int GenerateFixedEvents(const string symbol, const datetime today_start, CalendarEventDetail &details[])
    {
        int count = 0;
        // 米国が夏ならサーバー時刻はGMT+3、冬ならGMT+2
        bool isSummer = IsAmericanSummer();
        int server_offset = isSummer ? 3 : 2;
        
        // 〔例〕各市場の現地オープン時刻と現地オフセット（単位：時間）
        
        // 日本（東京市場）：現地 9:00 JST（GMT+9）
        if(StringFind(symbol, "JPY") != -1)
        {
            int local_open_seconds = 9 * 3600;
            int local_offset = 9;
            datetime event_time = today_start + local_open_seconds + (server_offset - local_offset) * 3600;
            
            CalendarEventDetail detail;
            detail.event.id = 2002;
            detail.event.importance = 2;
            detail.value.time = event_time;
            ArrayResize(details, count + 1);
            details[count] = detail;
            count++;
        }
        
        // 米国（ニューヨーク市場）：現地 9:30
        // ※ 米国は夏：EDT (GMT-4)、冬：EST (GMT-5)
        if(StringFind(symbol, "USD") != -1)
        {
            int local_open_seconds = 9 * 3600 + 30 * 60;
            int usd_local_offset = isSummer ? -4 : -5;
            datetime event_time = today_start + local_open_seconds + (server_offset - usd_local_offset) * 3600;
            
            CalendarEventDetail detail;
            detail.event.id = 2001;
            detail.event.importance = 3;
            detail.value.time = event_time;
            ArrayResize(details, count + 1);
            details[count] = detail;
            count++;
        }
        
        // 欧州（例：フランクフルト市場）：現地 9:00
        // ※ 夏：CEST (GMT+2)、冬：CET (GMT+1)
        if(StringFind(symbol, "EUR") != -1)
        {
            int local_open_seconds = 9 * 3600;
            int eur_local_offset = isSummer ? 2 : 1;
            datetime event_time = today_start + local_open_seconds + (server_offset - eur_local_offset) * 3600;
            
            CalendarEventDetail detail;
            detail.event.id = 2003;
            detail.event.importance = 3;
            detail.value.time = event_time;
            ArrayResize(details, count + 1);
            details[count] = detail;
            count++;
        }
        
        // 英国（ロンドン市場）：現地 8:00
        // ※ 夏：BST (GMT+1)、冬：GMT (GMT+0)
        if(StringFind(symbol, "GBP") != -1)
        {
            int local_open_seconds = 8 * 3600;
            int gbp_local_offset = isSummer ? 1 : 0;
            datetime event_time = today_start + local_open_seconds + (server_offset - gbp_local_offset) * 3600;
            
            CalendarEventDetail detail;
            detail.event.id = 2004;
            detail.event.importance = 2;
            detail.value.time = event_time;
            ArrayResize(details, count + 1);
            details[count] = detail;
            count++;
        }
        
        // カナダ（トロント市場）：現地 9:30
        // ※ 米国と同様、夏：GMT-4、冬：GMT-5
        if(StringFind(symbol, "CAD") != -1)
        {
            int local_open_seconds = 9 * 3600 + 30 * 60;
            int cad_local_offset = isSummer ? -4 : -5;
            datetime event_time = today_start + local_open_seconds + (server_offset - cad_local_offset) * 3600;
            
            CalendarEventDetail detail;
            detail.event.id = 2005;
            detail.event.importance = 1;
            detail.value.time = event_time;
            ArrayResize(details, count + 1);
            details[count] = detail;
            count++;
        }
        
        // 豪州（シドニー市場）：現地 10:00 AEST（GMT+10、ここでは固定とする）
        if(StringFind(symbol, "AUD") != -1)
        {
            int local_open_seconds = 10 * 3600;
            int aud_local_offset = 10; // AEST
            datetime event_time = today_start + local_open_seconds + (server_offset - aud_local_offset) * 3600;
            
            CalendarEventDetail detail;
            detail.event.id = 2006;
            detail.event.importance = 1;
            detail.value.time = event_time;
            ArrayResize(details, count + 1);
            details[count] = detail;
            count++;
        }
        
        // ニュージーランド（オークランド市場）：現地 10:00 NZST（GMT+12、ここでは固定とする）
        if(StringFind(symbol, "NZD") != -1)
        {
            int local_open_seconds = 10 * 3600;
            int nzd_local_offset = 12;
            datetime event_time = today_start + local_open_seconds + (server_offset - nzd_local_offset) * 3600;
            
            CalendarEventDetail detail;
            detail.event.id = 2007;
            detail.event.importance = 2;
            detail.value.time = event_time;
            ArrayResize(details, count + 1);
            details[count] = detail;
            count++;
        }
        
        return count;
    }

    /// <summary>
    /// 米国の夏時間（DST）かどうかを判定するヘルパー関数
    /// 米国DSTは、3月の第2日曜日～11月の第1日曜日
    /// </summary>
    static bool IsAmericanSummer()
    {
        datetime now = TimeCurrent();
        MqlDateTime tm;
        TimeToStruct(now, tm);
        int year = tm.year;
        
        // 3月1日0時（サーバー時刻基準）から
        string marchStr = IntegerToString(year) + ".03.01 00:00:00";
        datetime marchFirst = StringToTime(marchStr);
        
        // 最初の日曜日を探す
        MqlDateTime temp;
        while(true)
        {
            TimeToStruct(marchFirst, temp);
            if(temp.day_of_week == 0) // 0は日曜日
                break;
            marchFirst += 86400; // 1日分（秒）
        }
        // 第2日曜日
        datetime secondSundayMarch = marchFirst + 7 * 86400;
        
        // 11月1日0時（サーバー時刻基準）から、最初の日曜日を探す
        string novStr = IntegerToString(year) + ".11.01 00:00:00";
        datetime novFirst = StringToTime(novStr);
        while(true)
        {
            TimeToStruct(novFirst, temp);
            if(temp.day_of_week == 0)
                break;
            novFirst += 86400;
        }
        
        return (now >= secondSundayMarch && now < novFirst);
    }
};
