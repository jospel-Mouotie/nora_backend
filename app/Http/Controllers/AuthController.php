<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Cache;
use App\Models\User;
use App\Services\EmailVerificationService;
use App\Traits\ApiResponse;
use App\Traits\HandlesFileUploads;

class AuthController extends Controller
{
    use ApiResponse, HandlesFileUploads;

    protected $emailVerificationService;

    public function __construct(EmailVerificationService $emailVerificationService)
    {
        $this->emailVerificationService = $emailVerificationService;
    }

    /**
     * Inscription d'un nouvel utilisateur
     */
    public function register(Request $request)
    {
        if ($error = $this->validateRequestData($request->all(), [
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'phone' => 'nullable|string|max:20',
            'password' => 'required|string|min:8|confirmed',
            'role' => 'required|in:client,commercant,grossiste,livreur,admin',
        ])) {
            return $error;
        }

        // Générer et envoyer le code de validation
        $code = $this->emailVerificationService->generateCode();
        $sent = $this->emailVerificationService->sendVerificationCode($request->email, $code, $request->name);

        // En développement, on continue même si l'email échoue
        if (!$sent && config('app.env') !== 'local') {
            return $this->serverErrorResponse('Erreur lors de l\'envoi du code de validation');
        }

        // Stocker le code et les données temporaires
        Cache::put('verification_code_' . $request->email, $code, now()->addMinutes(15));
        Cache::put('registration_data_' . $request->email, [
            'name' => $request->name,
            'email' => $request->email,
            'phone' => $request->phone,
            'password' => Hash::make($request->password),
            'role' => $request->role,
        ], now()->addMinutes(15));

        $response = [
            'message' => 'Code de validation envoyé à votre email',
            'email' => $request->email,
        ];

        if (config('app.env') === 'local') {
            $response['code'] = $code;
        }

        return response()->json($response, 200);
    }

    /**
     * Valider le code de confirmation et créer le compte
     */
    public function verifyCode(Request $request)
    {
        if ($error = $this->validateRequestData($request->all(), [
            'email' => 'required|email',
            'code' => 'required|string|size:6',
        ])) {
            return $error;
        }

        $storedCode = Cache::get('verification_code_' . $request->email);
        $registrationData = Cache::get('registration_data_' . $request->email);

        if (!$storedCode || !$registrationData) {
            return $this->errorResponse('Code expiré ou invalide', 400);
        }

        if ($request->code !== $storedCode) {
            return $this->errorResponse('Code incorrect', 400);
        }

        // Créer l'utilisateur
        $user = User::create($registrationData);

        // Supprimer les données temporaires
        Cache::forget('verification_code_' . $request->email);
        Cache::forget('registration_data_' . $request->email);

        $token = $user->createToken('auth_token')->plainTextToken;

        return $this->createdResponse([
            'user' => $user,
            'token' => $token,
            'token_type' => 'Bearer',
        ], 'Inscription réussie');
    }

    /**
     * Renvoyer le code de validation
     */
    public function resendCode(Request $request)
    {
        if ($error = $this->validateRequestData($request->all(), [
            'email' => 'required|email',
        ])) {
            return $error;
        }

        $registrationData = Cache::get('registration_data_' . $request->email);

        if (!$registrationData) {
            return $this->errorResponse('Aucune inscription en cours pour cet email', 400);
        }

        // Générer et envoyer un nouveau code
        $code = $this->emailVerificationService->generateCode();
        $sent = $this->emailVerificationService->sendVerificationCode($request->email, $code, $registrationData['name']);

        if (!$sent) {
            return $this->serverErrorResponse('Erreur lors de l\'envoi du code de validation');
        }

        // Mettre à jour le code
        Cache::put('verification_code_' . $request->email, $code, now()->addMinutes(15));

        return $this->successResponse([], 'Nouveau code de validation envoyé');
    }

    /**
     * Connexion d'un utilisateur
     */
    public function login(Request $request)
    {
        if ($error = $this->validateRequestData($request->all(), [
            'email' => 'required|email',
            'password' => 'required',
        ])) {
            return $error;
        }

        $user = User::where('email', $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return $this->errorResponse('Identifiants incorrects', 401);
        }

        // Mettre à jour last_login_at
        $user->update(['last_login_at' => now()]);

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'user' => $user,
            'token' => $token,
            'token_type' => 'Bearer',
        ]);
    }

    /**
     * Déconnexion d'un utilisateur
     */
    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return $this->successResponse([], 'Déconnexion réussie');
    }

    /**
     * Enregistrer ou mettre à jour le token FCM de l'utilisateur
     */
    public function updateFcmToken(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'fcm_token' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $user = $request->user();
        $user->update([
            'fcm_token' => $request->fcm_token,
            'fcm_token_updated_at' => now(),
        ]);

        return response()->json(['message' => 'Token FCM mis à jour avec succès']);
    }

    /**
     * Supprimer le token FCM (lors de la déconnexion)
     */
    public function removeFcmToken(Request $request)
    {
        $user = $request->user();
        $user->update([
            'fcm_token' => null,
            'fcm_token_updated_at' => null,
        ]);

        return response()->json(['message' => 'Token FCM supprimé']);
    }

    /**
     * Obtenir les informations de l'utilisateur connecté
     */
    public function me(Request $request)
    {
        return response()->json($request->user());
    }

    /**
     * Mettre à jour le profil de l'utilisateur
     */
    public function updateProfile(Request $request)
    {
        if ($error = $this->validateRequestData($request->all(), [
            'name' => 'sometimes|required|string|max:255',
            'email' => 'sometimes|required|string|email|max:255|unique:users,email,' . $request->user()->id,
            'phone' => 'nullable|string|max:20',
            'profile_photo' => 'nullable|string',
            'address' => 'nullable|string',
            'city' => 'nullable|string|max:255',
            'country' => 'nullable|string|max:255',
        ])) {
            return $error;
        }

        $user = $request->user();
        $user->update($request->only(['name', 'email', 'phone', 'profile_photo', 'address', 'city', 'country']));

        return $this->successResponse(
            ['user' => $user],
            'Profil mis à jour avec succès'
        );
    }

    /**
     * Mettre à jour la photo de profil
     */
    public function updateProfilePicture(Request $request)
    {
        if ($error = $this->validateRequestData($request->all(), [
            'profile_photo' => 'required|image|mimes:jpeg,png,jpg,gif|max:2048',
        ])) {
            return $error;
        }

        $user = $request->user();

        if ($path = $this->uploadFile($request, 'profile_photo', 'profile-photos')) {
            $user->update(['profile_photo' => $path]);
        }

        return $this->successResponse(
            ['user' => $user],
            'Photo de profil mise à jour avec succès'
        );
    }
}
