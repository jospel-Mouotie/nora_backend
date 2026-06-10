<?php

namespace App\Services;

use Illuminate\Support\Facades\Mail;
use App\Mail\VerificationCodeMail;

class EmailVerificationService
{
    /**
     * Générer un code de validation
     */
    public function generateCode(): string
    {
        return str_pad(random_int(0, 999999), 6, '0', STR_PAD_LEFT);
    }

    /**
     * Envoyer le code de validation par email
     *
     * @throws \RuntimeException if the email fails to send
     */
    public function sendVerificationCode(string $email, string $code, string $name): bool
    {
        try {
            Mail::to($email)->send(new VerificationCodeMail($code, $name));
            return true;
        } catch (\Exception $e) {
            \Log::error('Erreur envoi email: ' . $e->getMessage(), [
                'email' => $email,
                'trace' => $e->getTraceAsString(),
            ]);
            throw new \RuntimeException('Impossible d\'envoyer le code de validation par email', 0, $e);
        }
    }

    /**
     * Vérifier le code de validation
     */
    public function verifyCode(string $email, string $code, string $storedCode): bool
    {
        return $code === $storedCode;
    }
}
