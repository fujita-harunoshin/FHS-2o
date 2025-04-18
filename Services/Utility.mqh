class Utility
{
public:
    /// <summary>
    /// 価格[クォート通貨単位]をpipsに換算する関数
    /// </summary>
    /// <param name="price">価格</param>
    static double PriceToPips(double price)
    {
        double pips = 0;

        int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);

        if(digits == 3 || digits == 5)
            pips = price * MathPow(10, digits) / 10;

        if(digits == 2 || digits == 4)
            pips = price * MathPow(10, digits);

        pips = NormalizeDouble(pips, 1);
        return pips;
    }
    
    /// <summary>
    /// pipsを価格[クォート通貨単位]に換算する関数
    /// </summary>
    /// <param name="pips">pips</param>
    static double PipsToPrice(double pips)
    {
        double price = 0;

        int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);

        if(digits == 3 || digits == 5)
            price = pips / MathPow(10, digits) * 10;
        

        if(digits == 2 || digits == 4)
            price = pips / MathPow(10, digits);

        price = NormalizeDouble(price, digits);
        return price ;
    }
    
    /// <summary>
    /// pointを価格[クォート通貨単位]に換算する関数
    /// </summary>
    /// <param name="pips">pips</param>
    static double PointToPrice(double point)
    {
        return point * _Point;
    }
    
    /// <summary>
    /// 任意のシンボルのクォート通貨からアカウント通貨への変換レート [アカウント通貨単位/クォート通貨単位]
    /// </summary>
    /// <param name="symbol">シンボル</param>
    static double GetQuoteToAccountRate(string symbol)
    {
        string account_currency = AccountInfoString(ACCOUNT_CURRENCY);
        
        string quote_currency = SymbolInfoString(symbol, SYMBOL_CURRENCY_PROFIT);
        
        if (account_currency == quote_currency)
            return 1.0;
        
        string suffix = StringSubstr(symbol, StringFind(symbol, quote_currency) + StringLen(quote_currency));
        
        string conversion_pair = quote_currency + account_currency + suffix;
        if (SymbolSelect(conversion_pair, true))
            return SymbolInfoDouble(conversion_pair, SYMBOL_BID);
        
        conversion_pair = account_currency + quote_currency + suffix;
        if (SymbolSelect(conversion_pair, true))
            return 1.0 / SymbolInfoDouble(conversion_pair, SYMBOL_ASK);
        
        conversion_pair = quote_currency + account_currency;
        if (SymbolSelect(conversion_pair, true))
            return SymbolInfoDouble(conversion_pair, SYMBOL_BID);
        
        conversion_pair = account_currency + quote_currency;
        if (SymbolSelect(conversion_pair, true))
            return 1.0 / SymbolInfoDouble(conversion_pair, SYMBOL_ASK);

        Print("通貨変換レートが取得できません: " + quote_currency + " → " + account_currency);
        return 0.0;
    }
    
    /// <summary>
    /// コントラクトサイズ取得
    /// </summary>
    static double GetContractSize() { return SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE); }
    
    /// <summary>
    /// 1ロット・1pipの価格 [クォート通貨単位]
    /// </summary>
    static double GetQuoteCurrencyPricePerLotPip() { return Utility::PipsToPrice(1) * GetContractSize(); }
    
    /// <summary>
    /// 1ロット・1pipの価格 [アカウント通貨単位]
    /// </summary>
    static double GetAccountCurrencyPricePerLotPip() { return GetQuoteCurrencyPricePerLotPip() * Utility::GetQuoteToAccountRate(_Symbol); }
};
