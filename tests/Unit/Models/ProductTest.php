<?php

namespace Tests\Unit\Models;

use App\Models\Product;
use Carbon\Carbon;
use PHPUnit\Framework\TestCase;

class ProductTest extends TestCase
{
    private function makeProduct(array $attributes = []): Product
    {
        $product = new Product;
        $product->setRawAttributes($attributes);

        return $product;
    }

    public function test_is_in_promotion_returns_true_when_active_and_within_date_range(): void
    {
        $product = $this->makeProduct([
            'in_promotion' => true,
            'promotion_start' => Carbon::now()->subDay(),
            'promotion_end' => Carbon::now()->addDay(),
        ]);

        $this->assertTrue($product->isInPromotion());
    }

    public function test_is_in_promotion_returns_false_when_flag_is_off(): void
    {
        $product = $this->makeProduct([
            'in_promotion' => false,
            'promotion_start' => Carbon::now()->subDay(),
            'promotion_end' => Carbon::now()->addDay(),
        ]);

        $this->assertFalse($product->isInPromotion());
    }

    public function test_is_in_promotion_returns_false_when_before_start_date(): void
    {
        $product = $this->makeProduct([
            'in_promotion' => true,
            'promotion_start' => Carbon::now()->addDay(),
            'promotion_end' => Carbon::now()->addDays(2),
        ]);

        $this->assertFalse($product->isInPromotion());
    }

    public function test_is_in_promotion_returns_false_when_after_end_date(): void
    {
        $product = $this->makeProduct([
            'in_promotion' => true,
            'promotion_start' => Carbon::now()->subDays(2),
            'promotion_end' => Carbon::now()->subDay(),
        ]);

        $this->assertFalse($product->isInPromotion());
    }

    public function test_get_promotional_price_returns_promo_price_when_in_promotion(): void
    {
        $product = $this->makeProduct([
            'price' => 100.00,
            'promotion_price' => 75.00,
            'in_promotion' => true,
            'promotion_start' => Carbon::now()->subDay(),
            'promotion_end' => Carbon::now()->addDay(),
        ]);

        $this->assertEquals(75.00, $product->getPromotionalPrice());
    }

    public function test_get_promotional_price_returns_regular_price_when_not_in_promotion(): void
    {
        $product = $this->makeProduct([
            'price' => 100.00,
            'promotion_price' => 75.00,
            'in_promotion' => false,
        ]);

        $this->assertEquals(100.00, $product->getPromotionalPrice());
    }

    public function test_get_promotion_percentage_returns_percentage_when_active(): void
    {
        $product = $this->makeProduct([
            'in_promotion' => true,
            'promotion_percentage' => 25,
            'promotion_start' => Carbon::now()->subDay(),
            'promotion_end' => Carbon::now()->addDay(),
        ]);

        $this->assertEquals(25, $product->getPromotionPercentage());
    }

    public function test_get_promotion_percentage_returns_zero_when_not_in_promotion(): void
    {
        $product = $this->makeProduct([
            'in_promotion' => false,
            'promotion_percentage' => 25,
        ]);

        $this->assertEquals(0, $product->getPromotionPercentage());
    }

    public function test_get_promotion_percentage_returns_zero_when_percentage_is_null(): void
    {
        $product = $this->makeProduct([
            'in_promotion' => true,
            'promotion_percentage' => null,
            'promotion_start' => Carbon::now()->subDay(),
            'promotion_end' => Carbon::now()->addDay(),
        ]);

        $this->assertEquals(0, $product->getPromotionPercentage());
    }

    public function test_get_images_array_returns_empty_when_null(): void
    {
        $product = $this->makeProduct(['images' => null]);

        $this->assertEquals([], $product->getImagesArray());
    }

    public function test_images_cast_returns_array(): void
    {
        $images = ['img1.jpg', 'img2.jpg'];
        $product = $this->makeProduct(['images' => json_encode($images)]);

        $this->assertEquals($images, $product->images);
    }

    public function test_set_images_array_encodes_to_json(): void
    {
        $product = $this->makeProduct();
        $images = ['photo1.png', 'photo2.png'];

        $product->setImagesArray($images);

        $this->assertEquals(json_encode($images), $product->images);
    }

    public function test_fillable_contains_expected_fields(): void
    {
        $product = new Product;

        $this->assertContains('name', $product->getFillable());
        $this->assertContains('price', $product->getFillable());
        $this->assertContains('promotion_price', $product->getFillable());
        $this->assertContains('shop_id', $product->getFillable());
        $this->assertContains('category_id', $product->getFillable());
    }

    public function test_casts_price_as_decimal(): void
    {
        $product = new Product;
        $casts = $product->getCasts();

        $this->assertEquals('decimal:2', $casts['price']);
        $this->assertEquals('decimal:2', $casts['promotion_price']);
    }

    public function test_casts_booleans(): void
    {
        $product = new Product;
        $casts = $product->getCasts();

        $this->assertEquals('boolean', $casts['is_active']);
        $this->assertEquals('boolean', $casts['in_promotion']);
    }
}
