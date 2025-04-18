#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>
#include "../Domains/Entities/TradingRuleParameters/ITradingRuleParameters.mqh"
#include "../Domains/Entities/MoneyManagementParameters/IMoneyManagementParameters.mqh"
#include "../Domains/Entities/Indices.mqh"
#include "../Domains/ValueObjects/StrategySet.mqh"
#include "../Services/TradingRules/ITradingRule.mqh"
#include "../Services/MoneyManagement/IMoneyManagement.mqh"
#include "../Services/IndicesService.mqh"
#include "../Services/OrderService.mqh"
#include "../Services/OpenPositionService.mqh"
#include "../Services/Utility.mqh"
#include "../Services/ErrorLogger.mqh"

#ifndef FHS_BASE_MQH
#define FHS_BASE_MQH

/// <summary>
/// 複数のストラテジー（売買ルール＋資金管理）をまとめて管理し、
/// OnTick で自動トレード判断を行うサービスクラス
/// </summary>
class FHSBase
{
private:
    /// <summary>
    /// マジックナンバー
    /// </summary>
    ulong m_magicNumber;
    
    /// <summary>
    /// ヘッジングモードの適否
    /// </summary>
    bool m_hedgingMode;

    /// <summary>
    /// ストラテジーセット（売買ルール＋資金管理+統計指標）の配列
    /// </summary>
    StrategySet *m_strategies[];

    /// <summary>
    /// 未約定注文サービス
    /// </summary>
    OrderService m_orderService;

    /// <summary>
    /// 未決済ポジションサービス
    /// </summary>
    OpenPositionService m_openPositionService;
    
    /// <summary>
    /// 指標サービス
    /// </summary>
    IndicesService m_indicesService;
    
    /// <summary>
    /// 手仕舞い時の指標出力の適否
    /// </summary>
    bool m_logIndicesOnDealOut;
    
    /// <summary>
    /// EA停止時の指標出力の適否
    /// </summary>
    bool m_logIndicesOnEAStop;
    
    /// <summary>
    /// 取引関数ラッパー
    /// </summary>
    CTrade m_cTrade;
    
    /// <summary>
    /// オープンポジションのプロパティにアクセスするためのクラス
    /// </summary>
    CPositionInfo m_cPosition;

public:
    /// <summary>
    /// コンストラクタ
    /// </summary>
    FHSBase()
    {
        ArrayResize(m_strategies, 0);
        m_magicNumber = 0;
    }

    /// <summary>
    /// 初期設定
    /// </summary>
    /// <param name="magic">マジックナンバー</param>
    /// <returns>初期化成否</returns>
    bool Init(ulong magic_number, bool log_indices_deal_out, bool log_indices_ea_stop)
    {
        m_magicNumber = magic_number;
        m_hedgingMode = ((ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE) == ACCOUNT_MARGIN_MODE_RETAIL_HEDGING);
        m_orderService = new OrderService();
        m_openPositionService = new OpenPositionService();
        m_logIndicesOnDealOut = log_indices_deal_out;
        m_logIndicesOnEAStop = log_indices_ea_stop;
        m_cTrade.SetExpertMagicNumber(magic_number);

        if (!LoadHistory())
            return false;

        return true;
    }

    /// <summary>
    /// 終了処理
    /// </summary>
    /// <returns>初期化成否</returns>
    void Deinit()
    {
        if (m_logIndicesOnEAStop)
        {
            int count = ArraySize(m_strategies);
            for (int i = 0; i < count; i++)
            {
                StrategySet *strategy_set = m_strategies[i];
                if (strategy_set != NULL)
                {
                    Indices *indices = strategy_set.Indices;
                    m_indicesService.LogStatistics(indices);
                }
            }
        }
    
        ClearAllStrategies();
        m_orderService.ClearAll();
        m_openPositionService.ClearAll();
    }

    /// <summary>
    /// 新しいストラテジー(売買ルール + 資金管理 + 指標)を追加
    /// </summary>
    /// <param name="rule">売買ルール</param>
    /// <param name="money_mgmt">資金管理法</param>
    /// <param name="max_loss_price_default">フォルトの1回のトレードの最大損失額[アカウント通貨単位/ロット]</param>
    /// <returns>ストラテジーの追加成否</returns>
    bool AddStrategy(ITradingRule *trading_rule, IMoneyManagement *money_mgmt)
    {
        if (trading_rule == NULL || money_mgmt == NULL)
            return false;
        if (!trading_rule.Init() || !money_mgmt.Init())
            return false;   
        
        Indices *indices = m_indicesService.CreateIndicesInstance(trading_rule, money_mgmt);
        StrategySet *strategy_set = new StrategySet(trading_rule, money_mgmt, indices);

        int current_array_size = ArraySize(m_strategies);
        ArrayResize(m_strategies, current_array_size + 1);
        m_strategies[current_array_size] = strategy_set;

        return true;
    }

    /// <summary>
    /// 毎ティック呼ばれる処理 (エントリ/トレーリングストップ/エグジットを判定)
    /// </summary>
    void OnTick()
    {
        // 全てのストラテジーセットでパラメータ更新処理を回す
        int strategy_count = ArraySize(m_strategies);
        for (int i = 0; i < strategy_count; i++)
        {
            m_strategies[i].TradingRule.UpdateParametersOnTick();
        }
        
    
        // 全てのオープンポジションでトレーリングストップ処理->エグジット処理を回す
        if (m_hedgingMode)
        {
            uint position_count = PositionsTotal();
            for (uint i = 0; i < position_count; i++)
            {
                if (m_cPosition.SelectByIndex(i))
                {
                    ulong ticket_id = PositionGetInteger(POSITION_TICKET);
                    OpenPosition *open_position = m_openPositionService.GetOpenPositionById(ticket_id);
                    if(open_position == NULL) return;
                    
                    open_position.TradingRule.UpdateParametersBeforeTrail(ticket_id, open_position.TradingRuleParameters);
                    
                    ProcessTrailingStop(open_position);
                    ProcessExit(open_position);
                }
            }
        }
        else
        {
            if (PositionSelect(_Symbol))
            {
                ulong ticket_id = PositionGetInteger(POSITION_TICKET);
                OpenPosition *open_position = m_openPositionService.GetOpenPositionById(ticket_id);
                ProcessTrailingStop(open_position);
                ProcessExit(open_position);
            }
        }
        
        // 全てのストラテジーセットでエントリー処理を回す
        for (int i = 0; i < strategy_count; i++)
        {
            if (m_hedgingMode)
            {
                ProcessEntry(m_strategies[i]);
            }
            else
            {
                if (!PositionSelect(_Symbol))
                    ProcessEntry(m_strategies[i]);
            }
        }
        
        // 全てのオーダーで破棄チェック処理を回す
        uint order_count = OrdersTotal();
        for (int i = (int)order_count - 1; i >= 0; i--)
        {
            ulong ticket = OrderGetTicket(i);
            if(OrderSelect(ticket))
            {
                if (OrderGetInteger(ORDER_MAGIC) != (long)m_magicNumber ||
                    OrderGetString(ORDER_SYMBOL) != _Symbol)
                    continue;
                
                ulong ticket_id = OrderGetInteger(ORDER_TICKET);

                Order *order = m_orderService.GetOrderById(ticket_id);
                if (order == NULL) continue;
                
                if (order.TradingRule.CheckOrderCancelSignal(order.TradingRuleParameters))
                {
                    if (!m_cTrade.OrderDelete(ticket_id))
                    {
                        Print("ペンディングオーダーの破棄に失敗しました: ", ticket_id);
                    }
                }
            }
        }
    }

    /// <summary>
    /// トランザクション種別ごとの処理
    /// </summary>
    void OnTradeTransaction(const MqlTradeTransaction &trans, const MqlTradeRequest &request, const MqlTradeResult &result)
    {
        if (trans.type == TRADE_TRANSACTION_DEAL_ADD)
        {
            ulong deal_ticket = trans.deal;
            if (HistoryDealSelect(deal_ticket))
            {   
                ulong deal_magic = (ulong)HistoryDealGetInteger(deal_ticket, DEAL_MAGIC);
                string deal_symbol = HistoryDealGetString(deal_ticket, DEAL_SYMBOL);
                if (deal_magic != m_magicNumber || deal_symbol != _Symbol) return;
            
                int deal_entry = (int)HistoryDealGetInteger(deal_ticket, DEAL_ENTRY);
                
                if (deal_entry == DEAL_ENTRY_IN)
                {
                    ulong order_id = HistoryDealGetInteger(deal_ticket, DEAL_ORDER);
                    Order *order = m_orderService.GetOrderById(order_id);
                    if (order == NULL) return;

                    ulong position_id = HistoryDealGetInteger(deal_ticket, DEAL_POSITION_ID);
                    OpenPosition *open_position = new OpenPosition(
                        position_id,
                        order.TradingRule,
                        order.TradingRuleParameters,
                        order.MoneyManagement,
                        order.MoneyManagementParameters,
                        order.Indices,
                        order.AccountBalanceAtOrder);

                    open_position.TradingRule.UpdateParametersOnEntryIn(deal_ticket, open_position.TradingRuleParameters);
                    m_indicesService.UpdateIndicesOnEntryIn(deal_ticket, open_position.Indices, open_position);
                    m_openPositionService.AddPosition(open_position);
                    m_orderService.RemoveOrderById(order_id);
                }

                if (deal_entry == DEAL_ENTRY_OUT)
                {                    
                    ulong position_id = (ulong)HistoryDealGetInteger(deal_ticket, DEAL_POSITION_ID);
                    OpenPosition *open_position = m_openPositionService.GetOpenPositionById(position_id);
                    if (open_position == NULL) return;
                    
                    open_position.TradingRule.UpdateParametersOnEntryOut(deal_ticket, open_position.TradingRuleParameters);
                    open_position.MoneyManagement.UpdateParametersOnEntryOut(deal_ticket, open_position.MoneyManagementParameters);
                    m_indicesService.UpdateIndicesOnEntryOut(deal_ticket, open_position.Indices);
                    if (m_logIndicesOnDealOut)
                        m_indicesService.LogStatistics(open_position.Indices);
                    m_openPositionService.RemoveOpenPositionById(position_id);
                }
            }
        }
        else if (trans.type == TRADE_TRANSACTION_DEAL_UPDATE)
        {
            ulong deal_ticket = trans.deal;
            if (HistoryDealSelect(deal_ticket))
            {
                ulong deal_magic  = (ulong)HistoryDealGetInteger(deal_ticket, DEAL_MAGIC);
                string deal_symbol = HistoryDealGetString(deal_ticket, DEAL_SYMBOL);
                if (deal_magic != m_magicNumber || deal_symbol != _Symbol)
                    return;
                
                ulong position_id = HistoryDealGetInteger(deal_ticket, DEAL_POSITION_ID);
                OpenPosition *open_position = m_openPositionService.GetOpenPositionById(position_id);
                if (open_position == NULL) return;
                
                open_position.TradingRule.UpdateParametersOnDealUpdate(deal_ticket, open_position.TradingRuleParameters);
                m_indicesService.UpdateIndicesOnDealUpdate(deal_ticket, open_position.Indices);
            }
        }
        else if (trans.type == TRADE_TRANSACTION_ORDER_DELETE)
        {
            ulong order_ticket = trans.order;
            
            Order *order = m_orderService.GetOrderById(order_ticket);
            if (order != NULL)
            {
                m_orderService.RemoveOrderById(order_ticket);
                Print("ペンディングオーダーの破棄が実行されました: ", order_ticket);
            }
        }
    }

private:
    /// <summary>
    /// トレーリングストップ処理(ヘッジング・ネッティング共通)
    /// </summary>
    /// <param name="strategy_set">戦略セット</param>
    void ProcessTrailingStop(OpenPosition *open_position)
    {
        if (PositionGetInteger(POSITION_MAGIC) != (long)m_magicNumber || PositionGetString(POSITION_SYMBOL) != _Symbol) return;
        
        ulong ticket_id = PositionGetInteger(POSITION_TICKET);
        
        ITradingRule *trading_rule = open_position.TradingRule;
        ITradingRuleParameters *trading_rule_parameters = open_position.TradingRuleParameters;
        double current_tp_price = PositionGetDouble(POSITION_TP);
        double new_sl_price = PositionGetDouble(POSITION_SL);
        if (!trading_rule.CalculateTrailingStopLossPrice(trading_rule_parameters, new_sl_price)) return;
        
        if (!m_cTrade.PositionModify(ticket_id, new_sl_price, current_tp_price))
        {
            Print("トレーリングストップに失敗しました。");
        }
    }

    /// <summary>
    /// エグジット処理(ヘッジング・ネッティング共通)
    /// </summary>
    /// <param name="strategy_set">戦略セット</param>
    /// <remarks>
    /// PositionGetIntegerメソッドとCTradeクラスは、事前に選択された未決済ポジションにアクセスする
    /// 事前に選択するには、
    /// 　・ネッティング：PositionSelect(_Symbol)
    /// 　・ヘッジング：CPositionInfo.SelectByIndex(i)
    /// </remarks>
    void ProcessExit(OpenPosition *open_position)
    {
        if (PositionGetInteger(POSITION_MAGIC) != (long)m_magicNumber || PositionGetString(POSITION_SYMBOL) != _Symbol) return;
        
        ulong ticket_id = PositionGetInteger(POSITION_TICKET);

        ITradingRule *trading_rule = open_position.TradingRule;
        ITradingRuleParameters *trading_rule_parameters = open_position.TradingRuleParameters;
        
        bool exit = trading_rule.CheckExitSignal(trading_rule_parameters);
        if (exit)
        {
            if(!m_cTrade.PositionClose(_Symbol))
                Print("PositionCloseに失敗しました。");
        }
    }
   
    /// <summary>
    /// エントリー処理(ヘッジング・ネッティング共通)
    /// </summary>
    /// <param name="strategy_set">戦略セット</param>
    void ProcessEntry(StrategySet *strategy_set)
    {
        ITradingRule *trading_rule = strategy_set.TradingRule;
        IMoneyManagement *money_management = strategy_set.MoneyManagement;
        Indices *indices = strategy_set.Indices;
        ITradingRuleParameters *trading_rule_parameters = trading_rule.CreateParametersInstance();
        IMoneyManagementParameters *money_management_parameters = money_management.CreateParametersInstance();
        
        double entry_price = 0;
        ENUM_ORDER_TYPE order_type = trading_rule.CheckEntrySignal(trading_rule_parameters, entry_price);
        if (order_type == WRONG_VALUE)
        {
            delete trading_rule_parameters;
            delete money_management_parameters;
            return;
        }
        
        trading_rule.UpdateParametersOnSignaled(order_type, trading_rule_parameters);
        double sl_price  = trading_rule.CalculateStopLossPrice(trading_rule_parameters);
        double tp_price  = trading_rule.CalculateTakeProfitPrice(trading_rule_parameters);
        money_management.UpdateParametersOnSignaled(order_type, sl_price, money_management_parameters);
        double lot_size = money_management.CalculateLot(money_management_parameters);
        
        bool order_placed = false;
        
        if (order_type == ORDER_TYPE_BUY || order_type == ORDER_TYPE_SELL)
        {
            if (TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) && Bars(_Symbol, _Period) > 100 &&
                m_cTrade.PositionOpen(_Symbol, order_type, lot_size, entry_price, sl_price, tp_price))
            {
                order_placed = true;
            }
        }
        else if (order_type == ORDER_TYPE_BUY_LIMIT || order_type == ORDER_TYPE_SELL_LIMIT ||
                 order_type == ORDER_TYPE_BUY_STOP  || order_type == ORDER_TYPE_SELL_STOP)
        {
            if (TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) && Bars(_Symbol, _Period) > 100 &&
                m_cTrade.OrderOpen(_Symbol, order_type, lot_size, entry_price, entry_price, sl_price, tp_price, ORDER_TIME_GTC, 0, "Pending Order"))
            {
                order_placed = true;
            }
        }
        
        if (order_placed)
        {
            ulong order_id = m_cTrade.ResultOrder();
            Order *order = new Order(
                order_id,
                trading_rule,
                trading_rule_parameters,
                money_management,
                money_management_parameters,
                indices
            );
            m_orderService.AddOrder(order);
        }
        else
        {
            uint retcode = m_cTrade.ResultRetcode();
            ErrorLogger::LogOrderError(retcode, order_type, lot_size, entry_price, sl_price, tp_price);
            delete trading_rule_parameters;
            delete money_management_parameters;
        }
    }



    /// <summary>
    /// アカウント通貨とクォート通貨のヒストリカルデータをロード
    /// </summary>
    /// <returns>ロードの成否</returns>
    bool LoadHistory()
    {
        string account_currency = AccountInfoString(ACCOUNT_CURRENCY);
        string quote_currency = SymbolInfoString(_Symbol, SYMBOL_CURRENCY_PROFIT);
        string suffix = StringSubstr(_Symbol, StringFind(_Symbol, quote_currency) + StringLen(quote_currency));

        if (account_currency == quote_currency)
            return true;

        string conversion_pairs[] = {
            quote_currency + account_currency + suffix,
            account_currency + quote_currency + suffix,
            quote_currency + account_currency,
            account_currency + quote_currency};

        for (int i = 0; i < ArraySize(conversion_pairs); i++)
        {
            string conversion_pair = conversion_pairs[i];
            if (SymbolInfoInteger(conversion_pair, SYMBOL_SELECT))
            {
                if (!SymbolSelect(conversion_pair, true))
                    continue;

                datetime from_time = iTime(conversion_pair, PERIOD_M1, 0);
                datetime to_time = TimeCurrent();

                if (HistorySelect(from_time, to_time))
                    return true;
            }
        }

        Print("ヒストリカルデータをロードできません: " + account_currency + "&" + quote_currency);
        return false;
    }

    /// <summary>
    /// 登録されたストラテジーをすべて解放
    /// </summary>
    void ClearAllStrategies()
    {
        int count = ArraySize(m_strategies);
        for (int i = 0; i < count; i++)
        {
            StrategySet *strategy_set = m_strategies[i];
            if (strategy_set != NULL)
            {
                ITradingRule *trading_rule = strategy_set.TradingRule;
                IMoneyManagement *money_management = strategy_set.MoneyManagement;
                Indices *indices = strategy_set.Indices;

                if (trading_rule != NULL)
                    delete trading_rule;
                if (money_management != NULL)
                    delete money_management;
                if (indices != NULL)
                    delete indices;

                delete strategy_set;
                m_strategies[i] = NULL;
            }
        }
        ArrayResize(m_strategies, 0);
    }
};

#endif
