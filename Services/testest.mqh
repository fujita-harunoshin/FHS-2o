class testest
{
public:
    /// <summary>
    /// pointを価格[クォート通貨単位]に換算する関数
    /// </summary>
    /// <param name="pips">pips</param>
    static double PointToPrice(double point)
    {
        return point * _Point;
    }
};
