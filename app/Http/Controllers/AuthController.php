<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Cache;
use App\Models\User;
use App\Services\EmailVerificationService;

class AuthController extends Controller
{
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
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'phone' => 'nullable|string|max:20',
            'password' => 'required|string|min:8|confirmed',
            'role' => 'required|in:client,commercant,grossiste,livreur,admin',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        // Générer et envoyer le code de validation
        $code = $this->emailVerificationService->generateCode();
        $sent = $this->emailVerificationService->sendVerificationCode($request->email, $code, $request->name);

        // En développement, on continue même si l'email échoue
        if (!$sent && config('app.env') !== 'local') {
            return response()->json(['message' => 'Erreur lors de l\'envoi du code de validation'], 500);
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
        $validator = Validator::make($request->all(), [
            'email' => 'required|email',
            'code' => 'required|string|size:6',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $storedCode = Cache::get('verification_code_' . $request->email);
        $registrationData = Cache::get('registration_data_' . $request->email);

        if (!$storedCode || !$registrationData) {
            return response()->json(['message' => 'Code expiré ou invalide'], 400);
        }

        if ($request->code !== $storedCode) {
            return response()->json(['message' => 'Code incorrect'], 400);
        }

        // Créer l'utilisateur
        $user = User::create($registrationData);

        // Supprimer les données temporaires
        Cache::forget('verification_code_' . $request->email);
        Cache::forget('registration_data_' . $request->email);

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'user' => $user,
            'token' => $token,
            'token_type' => 'Bearer',
            'message' => 'Inscription réussie',
        ], 201);
    }

    /**
     * Renvoyer le code de validation
     */
    public function resendCode(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $registrationData = Cache::get('registration_data_' . $request->email);

        if (!$registrationData) {
            return response()->json(['message' => 'Aucune inscription en cours pour cet email'], 400);
        }

        // Générer et envoyer un nouveau code
        $code = $this->emailVerificationService->generateCode();
        $sent = $this->emailVerificationService->sendVerificationCode($request->email, $code, $registrationData['name']);

        if (!$sent) {
            return response()->json(['message' => 'Erreur lors de l\'envoi du code de validation'], 500);
        }

        // Mettre à jour le code
        Cache::put('verification_code_' . $request->email, $code, now()->addMinutes(15));

        return response()->json([
            'message' => 'Nouveau code de validation envoyé',
        ], 200);
    }

    /**
     * Connexion d'un utilisateur
     */
    public function login(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email',
            'password' => 'required',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $user = User::where('email', $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json([
                'message' => 'Identifiants incorrects'
            ], 401);
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

        return response()->json([
            'message' => 'Déconnexion réussie'
        ]);
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
        $validator = Validator::make($request->all(), [
            'name' => 'sometimes|required|string|max:255',
            'email' => 'sometimes|required|string|email|max:255|unique:users,email,' . $request->user()->id,
            'phone' => 'nullable|string|max:20',
            'profile_photo' => 'nullable|string',
            'address' => 'nullable|string',
            'city' => 'nullable|string|max:255',
            'country' => 'nullable|string|max:255',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $user = $request->user();
        $user->update($request->only(['name', 'email', 'phone', 'profile_photo', 'address', 'city', 'country']));

        return response()->json([
            'message' => 'Profil mis à jour avec succès',
            'user' => $user
        ]);
    }

    /**
     * Mettre à jour la photo de profil
     */
    public function updateProfilePicture(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'profile_photo' => 'required|image|mimes:jpeg,png,jpg,gif|max:2048',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $user = $request->user();

        if ($request->hasFile('profile_photo')) {
            $path = $request->file('profile_photo')->store('profile-photos', 'public');
            $user->update(['profile_photo' => $path]);
        }

        return response()->json([
            'message' => 'Photo de profil mise à jour avec succès',
            'user' => $user
        ]);
    }
}
