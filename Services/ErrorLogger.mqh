/// <summary>
/// エラーのログ出力
/// </summary>
class ErrorLogger
{
public:
    /// <summary>
    /// 注文エラーをログに出力
    /// </summary>
    /// <param name="retcode">レットコード</param>
    /// <param name="signal">エントリーシグナル</param>
    /// <param name="lot_size">ロット数</param>
    /// <param name="entry_price">エントリー価格</param>
    /// <param name="sl_price">損切ライン</param>
    /// <param name="tp_price">利確ライン</param>
    static void LogOrderError(uint retcode, ENUM_ORDER_TYPE signal, double lot_size, double entry_price, double sl_price, double tp_price)
    {
        string error_message = "注文失敗: ";
        switch(retcode)
        {
            case TRADE_RETCODE_REJECT:            error_message += "ブローカーにより拒否"; break;
            case TRADE_RETCODE_INVALID_VOLUME:    error_message += "無効なロット数"; break;
            case TRADE_RETCODE_NO_MONEY:          error_message += "残高不足"; break;
            case TRADE_RETCODE_MARKET_CLOSED:     error_message += "市場が閉まっている"; break;
            case TRADE_RETCODE_PRICE_CHANGED:     error_message += "価格が変動した"; break;
            case TRADE_RETCODE_INVALID_PRICE:     error_message += "無効な価格"; break;
            case TRADE_RETCODE_LOCKED:            error_message += "注文がロックされている"; break;
            case TRADE_RETCODE_LONG_ONLY:         error_message += "売り注文不可 (LONG ONLY)"; break;
            case TRADE_RETCODE_TOO_MANY_REQUESTS: error_message += "リクエスト過多"; break;
            default:                              error_message += "その他のエラー"; break;
        }
        PrintFormat("%s (retcode=%u) - シグナル:%s, ロットサイズ:%f, 現在価格:%f, ストップロス:%f, テイクプロフィット:%f",
                    error_message, retcode, EnumToString(signal), lot_size, entry_price, sl_price, tp_price);
    }
   
    /// <summary>
    /// Deinit理由のログに出力
    /// </summary>
    /// <param name="reason">EAが終了した理由</param>
    static void LogDeinitReason(const int reason)
    {
        switch (reason)
        {
            case REASON_REMOVE:        Print("EAがチャートから削除されました。"); break;
            case REASON_RECOMPILE:     Print("EAが再コンパイルされました。"); break;
            case REASON_CHARTCHANGE:   Print("チャートの通貨ペアまたは時間足が変更されました。"); break;
            case REASON_CHARTCLOSE:    Print("チャートが閉じられました。"); break;
            case REASON_PARAMETERS:    Print("EAのパラメータが変更されました。"); break;
            case REASON_ACCOUNT:       Print("口座が変更されました。"); break;
            case REASON_TEMPLATE:      Print("テンプレートが適用されました。");break;
            case REASON_INITFAILED:    Print("EAの初期化に失敗しました。");break;
            default:                   Print("未知の理由で終了しました。"); break;
        }
    }
};
