<?php

namespace Tests\Unit\Models;

use App\Models\Shop;
use PHPUnit\Framework\TestCase;

class ShopTest extends TestCase
{
    public function test_fillable_contains_expected_fields(): void
    {
        $shop = new Shop;

        $this->assertContains('name', $shop->getFillable());
        $this->assertContains('description', $shop->getFillable());
        $this->assertContains('address', $shop->getFillable());
        $this->assertContains('phone', $shop->getFillable());
        $this->assertContains('email', $shop->getFillable());
        $this->assertContains('status', $shop->getFillable());
        $this->assertContains('certifiee', $shop->getFillable());
        $this->assertContains('user_id', $shop->getFillable());
    }

    public function test_casts_certifiee_as_boolean(): void
    {
        $shop = new Shop;
        $casts = $shop->getCasts();

        $this->assertEquals('boolean', $casts['certifiee']);
    }

    public function test_casts_certifiee_at_as_datetime(): void
    {
        $shop = new Shop;
        $casts = $shop->getCasts();

        $this->assertEquals('datetime', $casts['certifiee_at']);
    }
}
