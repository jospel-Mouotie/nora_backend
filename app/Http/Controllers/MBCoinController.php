<?php

namespace App\Http\Controllers;

use App\Models\MBCoin;
use App\Models\MBCoinTransaction;
use App\Services\NotificationService;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\DB;

class MBCoinController extends Controller
{
    protected $notificationService;

    public function __construct(NotificationService $notificationService)
    {
        $this->notificationService = $notificationService;
    }

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
            'wallet_balance' => auth()->user()->wallet_balance,
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
            return response()->json(['error' => $e->getMessage()], 500);
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
            return response()->json(['error' => $e->getMessage()], 500);
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
            return response()->json(['error' => $e->getMessage()], 500);
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

    /**
     * Obtenir les paramètres globaux (taux et pourcentage)
     */
    public function getSettings(): JsonResponse
    {
        return response()->json([
            'rate' => doubleval(\App\Models\Setting::get('mbcoin_rate', 0)),
            'percentage' => doubleval(\App\Models\Setting::get('mbcoin_max_convert_percentage', 100)),
        ]);
    }

    /**
     * Mettre à jour les paramètres globaux (taux et pourcentage) par l'admin
     */
    public function setSettings(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'rate' => 'required|numeric|min:0',
            'percentage' => 'required|numeric|min:0|max:100',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $oldRate = doubleval(\App\Models\Setting::get('mbcoin_rate', 0));
        $newRate = doubleval($request->rate);
        $percentage = doubleval($request->percentage);

        \App\Models\Setting::set('mbcoin_rate', $newRate, 'mbcoins');
        \App\Models\Setting::set('mbcoin_max_convert_percentage', $percentage, 'mbcoins');

        // Envoyer une notification FCM à tous les utilisateurs si le taux est modifié
        if ($newRate > 0 && $newRate != $oldRate) {
            try {
                $userIds = \App\Models\User::pluck('id')->toArray();
                if (!empty($userIds)) {
                    $this->notificationService->sendToMultiple(
                        $userIds,
                        'mbcoin_rate_updated',
                        'Taux de conversion MB Coins mis à jour !',
                        "1 MB Coin vaut désormais " . $newRate . " FCFA avec " . $percentage . "% convertible. Convertissez vos gains !"
                    );
                }
            } catch (\Exception $e) {
                \Illuminate\Support\Facades\Log::warning('Erreur envoi notification taux MBCoins: ' . $e->getMessage());
            }
        }

        return response()->json([
            'message' => 'Paramètres mis à jour avec succès',
            'rate' => $newRate,
            'percentage' => $percentage,
        ]);
    }

    /**
     * Réclamer des MB Coins pour une action spécifique (visionnage, like, commentaire, login)
     */
    public function earnCoins(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'action' => 'required|in:view,like,comment,daily_login',
            'video_id' => 'required_if:action,view,like,comment|exists:videos,id',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $userId = auth()->id();
        $action = $request->action;
        $videoId = $request->video_id;

        $mbCoin = MBCoin::firstOrCreate(
            ['user_id' => $userId],
            ['balance' => 0, 'total_earned' => 0, 'total_spent' => 0, 'total_withdrawn' => 0]
        );

        $rewards = [
            'view' => 1.0,
            'like' => 0.5,
            'comment' => 0.5,
            'daily_login' => 2.0,
        ];

        $amount = $rewards[$action];
        $description = '';
        $source = 'activity';

        if ($action === 'daily_login') {
            $alreadyClaimed = MBCoinTransaction::where('mb_coin_id', $mbCoin->id)
                ->where('source', 'daily_login')
                ->whereDate('created_at', today())
                ->exists();

            if ($alreadyClaimed) {
                return response()->json(['error' => 'Récompense journalière déjà réclamée aujourd\'hui'], 400);
            }

            $description = 'Récompense de connexion journalière';
            $source = 'daily_login';
        } else {
            $alreadyEarned = MBCoinTransaction::where('mb_coin_id', $mbCoin->id)
                ->where('source', $action)
                ->where('source_id', $videoId)
                ->exists();

            if ($alreadyEarned) {
                return response()->json(['error' => 'Vous avez déjà reçu une récompense pour cette action sur cette vidéo'], 400);
            }

            $video = \App\Models\Video::find($videoId);
            $videoTitle = $video ? $video->title : 'Vidéo';

            if ($action === 'view') {
                $description = "Visionnage de la vidéo: {$videoTitle}";
                $source = 'view';
            } elseif ($action === 'like') {
                $description = "Like sur la vidéo: {$videoTitle}";
                $source = 'like';
            } elseif ($action === 'comment') {
                $description = "Commentaire sur la vidéo: {$videoTitle}";
                $source = 'comment';
            }
        }

        try {
            $transaction = $mbCoin->earn($amount, $description, $source, $videoId);

            return response()->json([
                'message' => 'Coins gagnés avec succès !',
                'earned' => $amount,
                'balance' => $mbCoin->fresh()->balance,
                'transaction' => $transaction,
            ]);
        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }

    /**
     * Convertir des MB Coins en Franc CFA (FCFA)
     */
    public function convertCoins(Request $request): JsonResponse
    {
        $rate = doubleval(\App\Models\Setting::get('mbcoin_rate', 0));
        if ($rate <= 0) {
            return response()->json(['error' => 'La conversion de MB Coins n\'est pas activée actuellement.'], 400);
        }

        $percentage = doubleval(\App\Models\Setting::get('mbcoin_max_convert_percentage', 100));
        
        $mbCoin = MBCoin::where('user_id', auth()->id())->firstOrFail();
        
        // Calculer la limite max convertible basée sur le total gagné et ce qui a déjà été converti
        $totalEarned = $mbCoin->total_earned;
        $maxConvertibleCoins = $totalEarned * ($percentage / 100.0);
        
        $alreadyConvertedCoins = $mbCoin->transactions()
            ->where('source', 'conversion')
            ->sum('amount');
            
        $remainingConvertibleCoins = max(0, $maxConvertibleCoins - $alreadyConvertedCoins);
        
        $validator = Validator::make($request->all(), [
            'amount' => 'required|numeric|min:1|max:' . min($mbCoin->balance, $remainingConvertibleCoins),
        ], [
            'amount.max' => 'Vous ne pouvez pas convertir plus que votre solde disponible (' . $mbCoin->balance . ' MB) et votre limite de conversion restante (' . $remainingConvertibleCoins . ' MB).',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $coinsToConvert = $request->amount;
        $cashValue = $coinsToConvert * $rate;

        try {
            DB::transaction(function () use ($mbCoin, $coinsToConvert, $cashValue) {
                // Débiter les MB Coins
                $mbCoin->spend(
                    $coinsToConvert,
                    "Conversion de {$coinsToConvert} MB Coins en {$cashValue} FCFA",
                    'conversion'
                );

                // Ajouter au portefeuille de l'utilisateur
                $user = auth()->user();
                $user->increment('wallet_balance', $cashValue);
            });

            return response()->json([
                'message' => 'Conversion réussie !',
                'converted_coins' => $coinsToConvert,
                'cash_received' => $cashValue,
                'new_mb_balance' => $mbCoin->fresh()->balance,
                'new_wallet_balance' => auth()->user()->fresh()->wallet_balance,
            ]);
        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }
}
