<?php

namespace Tests\Unit\Models;

use App\Models\Cart;
use Carbon\Carbon;
use PHPUnit\Framework\TestCase;

class CartTest extends TestCase
{
    private function makeCart(array $attributes = []): Cart
    {
        $cart = new Cart;
        $cart->setRawAttributes($attributes);

        return $cart;
    }

    public function test_is_active_returns_true(): void
    {
        $cart = $this->makeCart(['status' => 'active']);

        $this->assertTrue($cart->isActive());
    }

    public function test_is_active_returns_false(): void
    {
        $cart = $this->makeCart(['status' => 'expired']);

        $this->assertFalse($cart->isActive());
    }

    public function test_is_expired_returns_true_when_past_expiry(): void
    {
        $cart = $this->makeCart([
            'expires_at' => Carbon::now()->subHour(),
        ]);

        $this->assertTrue($cart->isExpired());
    }

    public function test_is_expired_returns_false_when_future_expiry(): void
    {
        $cart = $this->makeCart([
            'expires_at' => Carbon::now()->addHour(),
        ]);

        $this->assertFalse($cart->isExpired());
    }

    public function test_is_expired_returns_false_when_no_expiry(): void
    {
        $cart = $this->makeCart(['expires_at' => null]);

        $this->assertFalse($cart->isExpired());
    }

    public function test_is_abandoned_returns_true(): void
    {
        $cart = $this->makeCart(['status' => 'abandoned']);

        $this->assertTrue($cart->isAbandoned());
    }

    public function test_is_abandoned_returns_false(): void
    {
        $cart = $this->makeCart(['status' => 'active']);

        $this->assertFalse($cart->isAbandoned());
    }

    public function test_fillable_contains_expected_fields(): void
    {
        $cart = new Cart;

        $this->assertContains('total_amount', $cart->getFillable());
        $this->assertContains('promotion_discount', $cart->getFillable());
        $this->assertContains('status', $cart->getFillable());
        $this->assertContains('expires_at', $cart->getFillable());
        $this->assertContains('user_id', $cart->getFillable());
    }

    public function test_casts_decimal_fields(): void
    {
        $cart = new Cart;
        $casts = $cart->getCasts();

        $this->assertEquals('decimal:2', $casts['total_amount']);
        $this->assertEquals('decimal:2', $casts['promotion_discount']);
    }

    public function test_casts_expires_at_as_datetime(): void
    {
        $cart = new Cart;
        $casts = $cart->getCasts();

        $this->assertEquals('datetime', $casts['expires_at']);
    }
}
