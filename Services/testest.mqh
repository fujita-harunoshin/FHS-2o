class testtest
{
    /// <summary>
    /// 1ロット・1pipの価格 [アカウント通貨単位]
    /// </summary>
    static double GetAccountCurrencyPricePerLotPip() { return GetQuoteCurrencyPricePerLotPip() * Utility::GetQuoteToAccountRate(_Symbol); }
};