#include "../Domains/Entities/Indices.mqh"
#include "../Domains/Entities/OpenPosition.mqh"
#include "TradingRules/ITradingRule.mqh"
#include "MoneyManagement/IMoneyManagement.mqh"
#include "Utility.mqh"

/// <summary>
/// 指標の更新、出力を担う
/// </summary>
class IndicesService
{
public:
    /// <summary>
    /// オーダー時に指標のインスタンスを作成
    /// </summary>
    Indices* CreateIndicesInstance(ITradingRule *trading_rule, IMoneyManagement *money_management)
    {
        Indices* indices = new Indices();
        indices.TradingRuleType = trading_rule.GetType();
        indices.TradingRuleName = trading_rule.GetName();
        indices.MoneyManagementType = money_management.GetType();
        indices.MoneyManagementName = money_management.GetName();
        indices.WinningPercentage = 0.0;
        indices.LosingPercentage = 0.0;
        indices.TotalTradeTimes = 0;
        indices.WinTradeTimes = 0;
        indices.LoseTradeTimes = 0;
        indices.TotalGain = 0.0;
        indices.TotalLoss = 0.0;
        indices.TotalProfitLoss = 0.0;
        indices.PayoffRatio = 0.0;
        indices.MaxLossPricePerTrade = 0.0;
        indices.CumulativeRisk = 0.0;
        indices.RiskPerTrade = 0.0;
        indices.BarsalaBankruptcyProbability = 0.0;
        indices.ExpectedValueParTrade = 0.0;
        indices.TradeTimesYearly = 0.0;
        indices.ExpectedValueYearly = 0.0;
        
        return indices;
    }

    /// <summary>
    /// ポジション発生時に指標を更新する処理
    /// </summary>
    /// <param name="deal_ticket">チケットID/param>
    /// <param name="params">売買ルールパラメータ</param>
    void UpdateIndicesOnEntryIn(ulong deal_ticket, Indices &indices, OpenPosition *open_position)
    {
        double entry_price = HistoryDealGetDouble(deal_ticket, DEAL_PRICE);
        double sl_price = HistoryDealGetDouble(deal_ticket, DEAL_SL);
        double loss_diff = MathAbs(entry_price - sl_price);
        double lot_size = HistoryDealGetDouble(deal_ticket, DEAL_VOLUME);
        double contract_size = Utility::GetContractSize();
        double conversion_rate = Utility::GetQuoteToAccountRate(_Symbol);
        double risk_amount = loss_diff * lot_size * contract_size * conversion_rate;
        double account_balance = open_position.AccountBalanceAtOrder;
        indices.CumulativeRisk += risk_amount / account_balance;
        indices.RiskPerTrade = indices.CumulativeRisk / indices.TotalTradeTimes;
    }
    
    /// <summary>
    /// ポジション更新毎に指標を更新する処理
    /// </summary>
    /// <param name="deal_ticket">チケットID/param>
    /// <param name="params">売買ルールパラメータ</param>
    void UpdateIndicesOnDealUpdate(ulong deal_ticket, Indices &indices)
    {
        return;
    }
    
    /// <summary>
    /// 手仕舞い時に指標を更新する処理
    /// </summary>
    /// <param name="deal_ticket">チケットID/param>
    /// <param name="params">売買ルールパラメータ</param>
    void UpdateIndicesOnEntryOut(ulong deal_ticket, Indices &indices)
    {
        double profit = HistoryDealGetDouble(deal_ticket, DEAL_PROFIT) * Utility::GetQuoteToAccountRate(_Symbol);
        
        indices.TotalTradeTimes++;
        if (profit > 0)
        {
            indices.WinTradeTimes++;
            indices.TotalGain += profit;
        }
        else if (profit < 0)
        {
            indices.LoseTradeTimes++;
            indices.TotalLoss += MathAbs(profit);
        }
        
        indices.TotalProfitLoss = indices.TotalGain - indices.TotalLoss;
        indices.WinningPercentage = (indices.TotalTradeTimes > 0) ? (indices.WinTradeTimes * 100 / indices.TotalTradeTimes) : 0.0;
        indices.LosingPercentage = (indices.TotalTradeTimes > 0) ? (indices.LoseTradeTimes * 100 / indices.TotalTradeTimes) : 0.0;
        
        if (indices.WinTradeTimes > 0 && indices.LoseTradeTimes > 0)
        {
            double average_win = indices.TotalGain / indices.WinTradeTimes;
            double average_lose = indices.TotalLoss / indices.LoseTradeTimes;
            indices.PayoffRatio = average_win / average_lose;
        }
        else if(indices.WinTradeTimes > 0 && indices.LoseTradeTimes == 0) indices.PayoffRatio = 1e6;
        else indices.PayoffRatio = 0.0;
        
        double loss_price = (profit < 0) ? -profit : 0.0;
        if (indices.MaxLossPricePerTrade < loss_price) indices.MaxLossPricePerTrade = loss_price;
    }
    
    /// <summary>
    /// 統計情報をチャート上に表示する
    /// </summary>
    void DisplayStatisticsOnChart(Indices &indices)
    {
        indices.BarsalaBankruptcyProbability = GetBarsalaBankruptcyProbability(&indices, 100);
        indices.ExpectedValueParTrade = (indices.TotalGain - indices.TotalLoss) / indices.TotalTradeTimes;
        indices.TradeTimesYearly = GetYearlyTradeCount(&indices);
        indices.ExpectedValueYearly = indices.ExpectedValueParTrade * indices.TradeTimesYearly;
    
        string text = "取引情報:\n";
        text += "勝率: " + DoubleToString(indices.WinningPercentage, 2) + "%\n";
        text += "敗率: " + DoubleToString(indices.LosingPercentage, 2) + "%\n";
        text += "ペイオフレシオ: " + DoubleToString(indices.PayoffRatio, 2) + "\n";
        text += "1回の取引のリスク割合: " + DoubleToString(indices.RiskPerTrade * 100, 2) + "%\n";
        text += "1回の取引の最大損失: " + DoubleToString(indices.MaxLossPricePerTrade, 2) + " [アカウント通貨]\n";
        text += "バルサラの破産確率: " + DoubleToString(indices.BarsalaBankruptcyProbability, 2) + "%\n";
        
        ObjectCreate(0, "StatsText", OBJ_LABEL, 0, 0, 0);
        ObjectSetInteger(0, "StatsText", OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetInteger(0, "StatsText", OBJPROP_XDISTANCE, 10);
        ObjectSetInteger(0, "StatsText", OBJPROP_YDISTANCE, 10);
        ObjectSetString(0, "StatsText", OBJPROP_TEXT, text);
    }

    /// <summary>
    /// 統計情報をログに出力する
    /// </summary>
    void LogStatistics(Indices &indices)
    {
        indices.BarsalaBankruptcyProbability = GetBarsalaBankruptcyProbability(&indices, 100);
        indices.ExpectedValueParTrade = (indices.TotalGain - indices.TotalLoss) / indices.TotalTradeTimes;
        indices.TradeTimesYearly = GetYearlyTradeCount(&indices);
        indices.ExpectedValueYearly = indices.ExpectedValueParTrade * indices.TradeTimesYearly;
    
        Print("\n〇取引情報-------------------------------------------------------------------------");
        Print("勝率: ", DoubleToString(indices.WinningPercentage, 2), "%", ", 敗率: ", DoubleToString(indices.LosingPercentage, 2), "%");
        Print("総損益: ", DoubleToString(indices.TotalProfitLoss, 0), " [アカウント通貨]\n",
              "総利益: ", DoubleToString(indices.TotalGain, 0), " [アカウント通貨]\n",
              "総損失: ", DoubleToString(indices.TotalLoss, 0), " [アカウント通貨]");
        Print("ペイオフレシオ: ", DoubleToString(indices.PayoffRatio, 2));
        Print("1回の取引のリスク割合: ", DoubleToString(indices.RiskPerTrade * 100, 2), "%");
        Print("1回の取引の最大損失: ", DoubleToString(indices.MaxLossPricePerTrade, 2), " [アカウント通貨]");
        Print("バルサラの破産確率: ", DoubleToString(indices.BarsalaBankruptcyProbability, 2), "%");
        Print("1取引あたりの期待値: ", DoubleToString(indices.ExpectedValueParTrade, 2), " [アカウント通貨単位/回]");
        Print("年間のトレード回数: ", indices.TradeTimesYearly, " [回/年]");
        Print("1年あたりの期待値: ", DoubleToString(indices.ExpectedValueYearly, 2), " [アカウント通貨単位/年]");
        Print("---------------------------------------------------------------------------------\n");
    }
    
private:
    /// </summary>
    /// バルサラの破産確率[%]を計算するゲッターメソッド
    /// </summary>
    /// <remarks>
    /// 【前提パラメータ】
    ///   ・勝率 p = m_winningPercentage/100  
    ///   ・ペイオフレシオ POR = m_payoffRatio  
    ///   ・1回のリスク割合 e = m_riskPerTrade  
    ///
    /// 【特性方程式】
    ///   f(x) = p * x^(1+POR) - x + (1-p) = 0, (0<x<1)
    ///
    /// 破産確率 q は、求得した解 y に対して、
    ///   q = y^(1/e)
    /// として計算する。
    ///
    /// 【注意】
    ///   EA内での処理負荷を軽減するため、ニュートン法の反復回数を固定（max_iter=10）として精度よりも速度を重視
    /// </remarks>
    double GetBarsalaBankruptcyProbability(Indices *indices, int iter)
    {
        // パラメータ変換
        double p = indices.WinningPercentage / 100.0;
        double k = indices.PayoffRatio;
        double e = indices.RiskPerTrade;
    
        // e の値が不正な場合は 100% とする
        if(e <= 0.0)
            return 1.0;
    
        // ニュートン法による解法（反復回数を固定して高速化）
        double tol = 1e-8;
        double x = 0.4;  // 初期値
        double f, fprime, x_new;
        
        for(int i = 0; i < iter; i++)
        {
            // f(x) = p*x^(1+k) - x + (1-p)
            f = p * MathPow(x, 1 + k) - x + (1 - p);
            // f'(x) = p*(1+k)*x^(k) - 1
            fprime = p * (1 + k) * MathPow(x, k) - 1;
            
            if(MathAbs(fprime) < tol)
                break;
            
            x_new = x - f / fprime;
            
            // x_new を (0,1) 内に補正
            if(x_new <= 0)
                x_new = tol;
            if(x_new >= 1)
                x_new = 1 - tol;
            
            if(MathAbs(x_new - x) < tol)
            {
                x = x_new;
                break;
            }
            
            x = x_new;
        }
        
        double y = x; // 特性方程式の解
        double q = MathPow(y, 1.0 / e);
        return NormalizeDouble(q * 100.0, 2);
    }
    
    /// <summary>
    /// 1年間のトレード回数 [回/年]ゲッター
    /// 不足時は予測値を返す
    /// </summary>
    int GetYearlyTradeCount(Indices *indices)
    {
        datetime yearStart = TimeCurrent() - 365 * 24 * 60 * 60;
        datetime now = TimeCurrent();

        if (!HistorySelect(yearStart, now))
        {
            Print("履歴の取得に失敗");
            return 0;
        }
    
        int totalTrades = indices.TotalTradeTimes;

        long firstTradeTime = now;
        for (int i = 0; i < totalTrades; i++)
        {
            ulong ticket = HistoryDealGetTicket(i);
            long dealTime = HistoryDealGetInteger(ticket, DEAL_TIME);
    
            if (dealTime < firstTradeTime)
            {
                firstTradeTime = dealTime;
            }
        }

        long actualDays = (now - firstTradeTime) / (24 * 60 * 60);

        if (actualDays < 365 && actualDays > 0)
        {
            double scaleFactor = 365.0 / actualDays;
            int estimatedTrades = int(totalTrades * scaleFactor);
            return estimatedTrades / 2;
        }

        return totalTrades / 2;
    }
};