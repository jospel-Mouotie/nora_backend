<?php

namespace Tests\Unit\Models;

use App\Models\User;
use PHPUnit\Framework\TestCase;

class UserTest extends TestCase
{
    public function test_fillable_contains_expected_fields(): void
    {
        $user = new User;

        $this->assertContains('name', $user->getFillable());
        $this->assertContains('email', $user->getFillable());
        $this->assertContains('password', $user->getFillable());
        $this->assertContains('role', $user->getFillable());
        $this->assertContains('phone', $user->getFillable());
        $this->assertContains('profile_photo', $user->getFillable());
        $this->assertContains('address', $user->getFillable());
        $this->assertContains('city', $user->getFillable());
        $this->assertContains('country', $user->getFillable());
    }

    public function test_hidden_contains_sensitive_fields(): void
    {
        $user = new User;

        $this->assertContains('password', $user->getHidden());
        $this->assertContains('remember_token', $user->getHidden());
    }

    public function test_casts_email_verified_at_as_datetime(): void
    {
        $user = new User;
        $casts = $user->getCasts();

        $this->assertEquals('datetime', $casts['email_verified_at']);
    }

    public function test_password_not_in_fillable_is_actually_present(): void
    {
        $user = new User;

        $this->assertContains('password', $user->getFillable());
    }

    public function test_user_uses_has_api_tokens_trait(): void
    {
        $user = new User;

        $this->assertTrue(
            method_exists($user, 'tokens'),
            'User should use HasApiTokens trait'
        );
    }

    public function test_user_uses_notifiable_trait(): void
    {
        $user = new User;

        $this->assertTrue(
            method_exists($user, 'notify'),
            'User should use Notifiable trait'
        );
    }

    public function test_user_uses_has_factory_trait(): void
    {
        $this->assertTrue(
            method_exists(User::class, 'factory'),
            'User should use HasFactory trait'
        );
    }
}
