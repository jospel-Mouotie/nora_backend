<?php

namespace Tests\Unit\Models;

use App\Models\CartItem;
use PHPUnit\Framework\TestCase;

class CartItemTest extends TestCase
{
    private function makeCartItem(array $attributes = []): CartItem
    {
        $item = new CartItem;
        foreach ($attributes as $key => $value) {
            $item->$key = $value;
        }

        return $item;
    }

    public function test_get_final_price_without_promotion(): void
    {
        $item = $this->makeCartItem([
            'total_price' => 50.00,
            'promotion_discount' => 0,
        ]);

        $this->assertEquals(50.00, $item->getFinalPrice());
    }

    public function test_get_final_price_with_promotion(): void
    {
        $item = $this->makeCartItem([
            'total_price' => 50.00,
            'promotion_discount' => 10.00,
        ]);

        $this->assertEquals(40.00, $item->getFinalPrice());
    }

    public function test_get_final_price_never_negative(): void
    {
        $item = $this->makeCartItem([
            'total_price' => 10.00,
            'promotion_discount' => 20.00,
        ]);

        $this->assertEquals(0, $item->getFinalPrice());
    }

    public function test_has_promotion_returns_true(): void
    {
        $item = $this->makeCartItem(['promotion_discount' => 5.00]);

        $this->assertTrue($item->hasPromotion());
    }

    public function test_has_promotion_returns_false_for_zero(): void
    {
        $item = $this->makeCartItem(['promotion_discount' => 0]);

        $this->assertFalse($item->hasPromotion());
    }

    public function test_get_unit_price_with_promotion_positive_quantity(): void
    {
        $item = $this->makeCartItem([
            'quantity' => 2,
            'total_price' => 100.00,
            'promotion_discount' => 20.00,
            'unit_price' => 50.00,
        ]);

        $this->assertEquals(40.00, $item->getUnitPriceWithPromotion());
    }

    public function test_get_unit_price_with_promotion_zero_quantity(): void
    {
        $item = $this->makeCartItem([
            'quantity' => 0,
            'total_price' => 0,
            'promotion_discount' => 0,
            'unit_price' => 25.00,
        ]);

        $this->assertEquals(25.00, $item->getUnitPriceWithPromotion());
    }

    public function test_get_unit_price_with_promotion_no_discount(): void
    {
        $item = $this->makeCartItem([
            'quantity' => 3,
            'total_price' => 75.00,
            'promotion_discount' => 0,
            'unit_price' => 25.00,
        ]);

        $this->assertEquals(25.00, $item->getUnitPriceWithPromotion());
    }

    public function test_fillable_contains_expected_fields(): void
    {
        $item = new CartItem;

        $this->assertContains('quantity', $item->getFillable());
        $this->assertContains('unit_price', $item->getFillable());
        $this->assertContains('total_price', $item->getFillable());
        $this->assertContains('cart_id', $item->getFillable());
        $this->assertContains('product_id', $item->getFillable());
    }

    public function test_casts_decimal_fields(): void
    {
        $item = new CartItem;
        $casts = $item->getCasts();

        $this->assertEquals('decimal:2', $casts['unit_price']);
        $this->assertEquals('decimal:2', $casts['total_price']);
        $this->assertEquals('decimal:2', $casts['promotion_discount']);
    }
}
