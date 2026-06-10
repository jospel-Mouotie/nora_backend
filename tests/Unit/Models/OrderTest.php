<?php

namespace Tests\Unit\Models;

use App\Models\Order;
use PHPUnit\Framework\TestCase;

class OrderTest extends TestCase
{
    private function makeOrder(array $attributes = []): Order
    {
        $order = new Order;
        foreach ($attributes as $key => $value) {
            $order->$key = $value;
        }

        return $order;
    }

    public function test_is_pending_returns_true(): void
    {
        $order = $this->makeOrder(['status' => 'pending']);

        $this->assertTrue($order->isPending());
    }

    public function test_is_pending_returns_false(): void
    {
        $order = $this->makeOrder(['status' => 'confirmed']);

        $this->assertFalse($order->isPending());
    }

    public function test_is_confirmed_returns_true(): void
    {
        $order = $this->makeOrder(['status' => 'confirmed']);

        $this->assertTrue($order->isConfirmed());
    }

    public function test_is_confirmed_returns_false(): void
    {
        $order = $this->makeOrder(['status' => 'pending']);

        $this->assertFalse($order->isConfirmed());
    }

    public function test_is_preparing_returns_true(): void
    {
        $order = $this->makeOrder(['status' => 'preparing']);

        $this->assertTrue($order->isPreparing());
    }

    public function test_is_ready_returns_true(): void
    {
        $order = $this->makeOrder(['status' => 'ready']);

        $this->assertTrue($order->isReady());
    }

    public function test_is_delivered_returns_true(): void
    {
        $order = $this->makeOrder(['status' => 'delivered']);

        $this->assertTrue($order->isDelivered());
    }

    public function test_is_cancelled_returns_true(): void
    {
        $order = $this->makeOrder(['status' => 'cancelled']);

        $this->assertTrue($order->isCancelled());
    }

    public function test_is_paid_returns_true(): void
    {
        $order = $this->makeOrder(['payment_status' => 'paid']);

        $this->assertTrue($order->isPaid());
    }

    public function test_is_paid_returns_false(): void
    {
        $order = $this->makeOrder(['payment_status' => 'pending']);

        $this->assertFalse($order->isPaid());
    }

    public function test_is_payment_pending_returns_true(): void
    {
        $order = $this->makeOrder(['payment_status' => 'pending']);

        $this->assertTrue($order->isPaymentPending());
    }

    public function test_is_payment_pending_returns_false(): void
    {
        $order = $this->makeOrder(['payment_status' => 'paid']);

        $this->assertFalse($order->isPaymentPending());
    }

    public function test_calculate_final_amount_basic(): void
    {
        $order = $this->makeOrder([
            'total_amount' => 100.00,
            'promotion_discount' => 10.00,
            'delivery_fee' => 5.00,
        ]);

        $this->assertEquals(95.00, $order->calculateFinalAmount());
    }

    public function test_calculate_final_amount_no_discount(): void
    {
        $order = $this->makeOrder([
            'total_amount' => 100.00,
            'promotion_discount' => 0,
            'delivery_fee' => 5.00,
        ]);

        $this->assertEquals(105.00, $order->calculateFinalAmount());
    }

    public function test_calculate_final_amount_never_negative(): void
    {
        $order = $this->makeOrder([
            'total_amount' => 10.00,
            'promotion_discount' => 50.00,
            'delivery_fee' => 0,
        ]);

        $this->assertEquals(0, $order->calculateFinalAmount());
    }

    public function test_calculate_final_amount_zero_totals(): void
    {
        $order = $this->makeOrder([
            'total_amount' => 0,
            'promotion_discount' => 0,
            'delivery_fee' => 0,
        ]);

        $this->assertEquals(0, $order->calculateFinalAmount());
    }

    public function test_calculate_final_amount_large_delivery_fee(): void
    {
        $order = $this->makeOrder([
            'total_amount' => 50.00,
            'promotion_discount' => 5.00,
            'delivery_fee' => 20.00,
        ]);

        $this->assertEquals(65.00, $order->calculateFinalAmount());
    }

    public function test_fillable_contains_expected_fields(): void
    {
        $order = new Order;

        $this->assertContains('order_number', $order->getFillable());
        $this->assertContains('total_amount', $order->getFillable());
        $this->assertContains('status', $order->getFillable());
        $this->assertContains('payment_status', $order->getFillable());
        $this->assertContains('user_id', $order->getFillable());
        $this->assertContains('shop_id', $order->getFillable());
    }

    public function test_casts_decimal_fields(): void
    {
        $order = new Order;
        $casts = $order->getCasts();

        $this->assertEquals('decimal:2', $casts['total_amount']);
        $this->assertEquals('decimal:2', $casts['promotion_discount']);
        $this->assertEquals('decimal:2', $casts['delivery_fee']);
        $this->assertEquals('decimal:2', $casts['final_amount']);
    }

    public function test_all_status_methods_are_mutually_exclusive(): void
    {
        $statuses = [
            'pending' => 'isPending',
            'confirmed' => 'isConfirmed',
            'preparing' => 'isPreparing',
            'ready' => 'isReady',
            'delivered' => 'isDelivered',
            'cancelled' => 'isCancelled',
        ];

        foreach ($statuses as $status => $method) {
            $order = $this->makeOrder(['status' => $status]);

            foreach ($statuses as $otherStatus => $otherMethod) {
                if ($status === $otherStatus) {
                    $this->assertTrue($order->$otherMethod(), "Expected $otherMethod to return true for status '$status'");
                } else {
                    $this->assertFalse($order->$otherMethod(), "Expected $otherMethod to return false for status '$status'");
                }
            }
        }
    }
}
