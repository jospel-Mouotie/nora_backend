<?php

namespace App\Http\Controllers;

use App\Models\MBCoin;
use App\Models\MBCoinTransaction;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\DB;

class MBCoinController extends Controller
{
    /**
     * Obtenir le solde MB Coins de l'utilisateur
     */
    public function getBalance(): JsonResponse
    {
        $mbCoin = MBCoin::firstOrCreate(
            ['user_id' => auth()->id()],
            ['balance' => 0, 'total_earned' => 0, 'total_spent' => 0, 'total_withdrawn' => 0]
        );

        return response()->json([
            'balance' => $mbCoin->balance,
            'formatted_balance' => $mbCoin->formatted_balance,
            'total_earned' => $mbCoin->total_earned,
            'total_spent' => $mbCoin->total_spent,
            'total_withdrawn' => $mbCoin->total_withdrawn,
            'last_earned_at' => $mbCoin->last_earned_at,
            'last_spent_at' => $mbCoin->last_spent_at,
        ]);
    }

    /**
     * Obtenir l'historique des transactions
     */
    public function getTransactions(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'type' => 'nullable|in:credit,debit,withdrawal,refund',
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date|after_or_equal:start_date',
            'limit' => 'nullable|integer|min:1|max:100',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $mbCoin = MBCoin::where('user_id', auth()->id())->firstOrFail();
        
        $query = $mbCoin->transactions();

        if ($request->type) {
            $query->where('type', $request->type);
        }

        if ($request->start_date) {
            $query->whereDate('created_at', '>=', $request->start_date);
        }

        if ($request->end_date) {
            $query->whereDate('created_at', '<=', $request->end_date);
        }

        $transactions = $query->orderBy('created_at', 'desc')
            ->paginate($request->limit ?? 20);

        return response()->json([
            'transactions' => $transactions,
            'summary' => [
                'total_credits' => $mbCoin->transactions()->credits()->sum('amount'),
                'total_debits' => $mbCoin->transactions()->debits()->sum('amount'),
                'total_withdrawals' => $mbCoin->transactions()->withdrawals()->sum('amount'),
            ]
        ]);
    }

    /**
     * Demander un retrait de MB Coins
     */
    public function requestWithdrawal(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'amount' => 'required|numeric|min:10|max:10000',
            'method' => 'required|in:bank_transfer,mobile_money,crypto',
            'details' => 'required|array',
            'details.account_name' => 'required|string|max:255',
            'details.account_number' => 'required|string|max:255',
            'details.bank_name' => 'nullable|string|max:255',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $mbCoin = MBCoin::where('user_id', auth()->id())->firstOrFail();

        if ($mbCoin->balance < $request->amount) {
            return response()->json(['error' => 'Solde insuffisant'], 400);
        }

        // Vérifier les limites de retrait
        $todayWithdrawals = $mbCoin->transactions()
            ->withdrawals()
            ->whereDate('created_at', today())
            ->sum('amount');

        $dailyLimit = 1000; // Limite quotidienne de 1000 MB

        if ($todayWithdrawals + $request->amount > $dailyLimit) {
            return response()->json(['error' => 'Limite de retrait quotidien dépassée'], 400);
        }

        try {
            $transaction = $mbCoin->withdraw($request->amount, $request->method, $request->details);

            return response()->json([
                'message' => 'Demande de retrait soumise avec succès',
                'transaction' => $transaction->load('mbCoin'),
                'estimated_processing_time' => '24-48 heures',
            ]);

        } catch (\Exception $e) {
            \Log::error('Error processing withdrawal: ' . $e->getMessage(), ['user_id' => auth()->id(), 'trace' => $e->getTraceAsString()]);
            return response()->json(['error' => 'Une erreur est survenue lors du traitement du retrait'], 500);
        }
    }

    /**
     * Obtenir les statistiques MB Coins
     */
    public function getStats(Request $request): JsonResponse
    {
        $mbCoin = MBCoin::where('user_id', auth()->id())->firstOrFail();
        
        $period = $request->period ?? 30; // jours
        $startDate = now()->subDays($period);

        $stats = [
            'current_balance' => $mbCoin->balance,
            'total_earned' => $mbCoin->total_earned,
            'total_spent' => $mbCoin->total_spent,
            'total_withdrawn' => $mbCoin->total_withdrawn,
            'earnings_period' => $mbCoin->getEarningsByPeriod($period),
            'spending_period' => $mbCoin->getSpendingByPeriod($period),
            'transactions_count_period' => $mbCoin->transactions()
                ->where('created_at', '>=', $startDate)
                ->count(),
            'last_transactions' => $mbCoin->getRecentTransactions(5),
            'earnings_by_source' => $mbCoin->transactions()
                ->credits()
                ->where('created_at', '>=', $startDate)
                ->selectRaw('source, SUM(amount) as total')
                ->groupBy('source')
                ->get(),
            'spending_by_source' => $mbCoin->transactions()
                ->debits()
                ->where('created_at', '>=', $startDate)
                ->selectRaw('source, SUM(amount) as total')
                ->groupBy('source')
                ->get(),
        ];

        return response()->json(['stats' => $stats]);
    }

    /**
     * Ajouter des MB Coins (admin seulement)
     */
    public function addCoins(Request $request): JsonResponse
    {
        $this->authorize('manage-mb-coins');

        $validator = Validator::make($request->all(), [
            'user_id' => 'required|exists:users,id',
            'amount' => 'required|numeric|min:0.01|max:10000',
            'description' => 'required|string|max:255',
            'source' => 'nullable|string|max:50',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $mbCoin = MBCoin::firstOrCreate(
            ['user_id' => $request->user_id],
            ['balance' => 0, 'total_earned' => 0, 'total_spent' => 0, 'total_withdrawn' => 0]
        );

        try {
            $transaction = $mbCoin->earn(
                $request->amount,
                $request->description,
                $request->source ?? 'admin',
                null
            );

            return response()->json([
                'message' => 'MB Coins ajoutés avec succès',
                'transaction' => $transaction,
            ]);

        } catch (\Exception $e) {
            \Log::error('Error adding coins: ' . $e->getMessage(), ['user_id' => $request->user_id, 'trace' => $e->getTraceAsString()]);
            return response()->json(['error' => 'Une erreur est survenue lors de l\'ajout des MB Coins'], 500);
        }
    }

    /**
     * Retirer des MB Coins (admin seulement)
     */
    public function removeCoins(Request $request): JsonResponse
    {
        $this->authorize('manage-mb-coins');

        $validator = Validator::make($request->all(), [
            'user_id' => 'required|exists:users,id',
            'amount' => 'required|numeric|min:0.01|max:10000',
            'description' => 'required|string|max:255',
            'source' => 'nullable|string|max:50',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $mbCoin = MBCoin::where('user_id', $request->user_id)->firstOrFail();

        if ($mbCoin->balance < $request->amount) {
            return response()->json(['error' => 'Solde insuffisant'], 400);
        }

        try {
            $transaction = $mbCoin->spend(
                $request->amount,
                $request->description,
                $request->source ?? 'admin',
                null
            );

            return response()->json([
                'message' => 'MB Coins retirés avec succès',
                'transaction' => $transaction,
            ]);

        } catch (\Exception $e) {
            \Log::error('Error removing coins: ' . $e->getMessage(), ['user_id' => $request->user_id, 'trace' => $e->getTraceAsString()]);
            return response()->json(['error' => 'Une erreur est survenue lors du retrait des MB Coins'], 500);
        }
    }

    /**
     * Obtenir le classement des utilisateurs MB Coins
     */
    public function getLeaderboard(Request $request): JsonResponse
    {
        $period = $request->period ?? 'all'; // all, week, month, year
        
        $query = MBCoin::with('user')
            ->orderBy('balance', 'desc');

        switch ($period) {
            case 'week':
                $query->whereHas('transactions', function ($q) {
                    $q->where('created_at', '>=', now()->subWeek());
                });
                break;
            case 'month':
                $query->whereHas('transactions', function ($q) {
                    $q->where('created_at', '>=', now()->subMonth());
                });
                break;
            case 'year':
                $query->whereHas('transactions', function ($q) {
                    $q->where('created_at', '>=', now()->subYear());
                });
                break;
        }

        $leaderboard = $query->limit(100)->get();

        $userRank = null;
        $currentUserMB = null;
        
        if (auth()->check()) {
            $currentUserMB = MBCoin::where('user_id', auth()->id())->first();
            if ($currentUserMB) {
                $userRank = $leaderboard->search(function ($item) use ($currentUserMB) {
                    return $item->id === $currentUserMB->id;
                }) + 1;
            }
        }

        return response()->json([
            'leaderboard' => $leaderboard->map(function ($item) {
                return [
                    'user' => $item->user,
                    'balance' => $item->balance,
                    'formatted_balance' => $item->formatted_balance,
                    'total_earned' => $item->total_earned,
                ];
            }),
            'user_rank' => $userRank,
            'user_balance' => $currentUserMB ? $currentUserMB->balance : null,
            'period' => $period,
        ]);
    }

    /**
     * Obtenir les transactions récentes (pour le dashboard)
     */
    public function getRecentActivity(): JsonResponse
    {
        $mbCoin = MBCoin::where('user_id', auth()->id())->firstOrFail();
        
        $recentTransactions = $mbCoin->getRecentTransactions(10);
        
        return response()->json([
            'recent_transactions' => $recentTransactions,
            'summary' => [
                'today_earnings' => $mbCoin->transactions()
                    ->credits()
                    ->whereDate('created_at', today())
                    ->sum('amount'),
                'today_spending' => $mbCoin->transactions()
                    ->debits()
                    ->whereDate('created_at', today())
                    ->sum('amount'),
                'week_earnings' => $mbCoin->getEarningsByPeriod(7),
                'week_spending' => $mbCoin->getSpendingByPeriod(7),
            ]
        ]);
    }
}
