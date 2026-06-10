<?php

namespace Tests\Unit\Models;

use App\Models\OrderItem;
use PHPUnit\Framework\TestCase;

class OrderItemTest extends TestCase
{
    private function makeOrderItem(array $attributes = []): OrderItem
    {
        $item = new OrderItem;
        foreach ($attributes as $key => $value) {
            $item->$key = $value;
        }

        return $item;
    }

    public function test_get_final_price_without_promotion(): void
    {
        $item = $this->makeOrderItem([
            'total_price' => 80.00,
            'promotion_discount' => 0,
        ]);

        $this->assertEquals(80.00, $item->getFinalPrice());
    }

    public function test_get_final_price_with_promotion(): void
    {
        $item = $this->makeOrderItem([
            'total_price' => 80.00,
            'promotion_discount' => 15.00,
        ]);

        $this->assertEquals(65.00, $item->getFinalPrice());
    }

    public function test_get_final_price_never_negative(): void
    {
        $item = $this->makeOrderItem([
            'total_price' => 5.00,
            'promotion_discount' => 20.00,
        ]);

        $this->assertEquals(0, $item->getFinalPrice());
    }

    public function test_has_promotion_returns_true(): void
    {
        $item = $this->makeOrderItem(['promotion_discount' => 10.00]);

        $this->assertTrue($item->hasPromotion());
    }

    public function test_has_promotion_returns_false(): void
    {
        $item = $this->makeOrderItem(['promotion_discount' => 0]);

        $this->assertFalse($item->hasPromotion());
    }

    public function test_get_unit_price_with_promotion_positive_quantity(): void
    {
        $item = $this->makeOrderItem([
            'quantity' => 4,
            'total_price' => 200.00,
            'promotion_discount' => 40.00,
            'unit_price' => 50.00,
        ]);

        $this->assertEquals(40.00, $item->getUnitPriceWithPromotion());
    }

    public function test_get_unit_price_with_promotion_zero_quantity(): void
    {
        $item = $this->makeOrderItem([
            'quantity' => 0,
            'total_price' => 0,
            'promotion_discount' => 0,
            'unit_price' => 30.00,
        ]);

        $this->assertEquals(30.00, $item->getUnitPriceWithPromotion());
    }

    public function test_get_unit_price_with_promotion_single_quantity(): void
    {
        $item = $this->makeOrderItem([
            'quantity' => 1,
            'total_price' => 100.00,
            'promotion_discount' => 10.00,
            'unit_price' => 100.00,
        ]);

        $this->assertEquals(90.00, $item->getUnitPriceWithPromotion());
    }

    public function test_fillable_contains_expected_fields(): void
    {
        $item = new OrderItem;

        $this->assertContains('quantity', $item->getFillable());
        $this->assertContains('unit_price', $item->getFillable());
        $this->assertContains('total_price', $item->getFillable());
        $this->assertContains('order_id', $item->getFillable());
        $this->assertContains('product_variant_id', $item->getFillable());
    }

    public function test_casts_decimal_fields(): void
    {
        $item = new OrderItem;
        $casts = $item->getCasts();

        $this->assertEquals('decimal:2', $casts['unit_price']);
        $this->assertEquals('decimal:2', $casts['total_price']);
        $this->assertEquals('decimal:2', $casts['promotion_discount']);
    }
}
