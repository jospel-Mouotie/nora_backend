<?php

namespace Tests\Unit\Models;

use App\Models\Category;
use PHPUnit\Framework\TestCase;

class CategoryTest extends TestCase
{
    private function makeCategory(array $attributes = []): Category
    {
        $category = new Category;
        foreach ($attributes as $key => $value) {
            $category->$key = $value;
        }

        return $category;
    }

    public function test_is_root_returns_true_when_parent_id_is_null(): void
    {
        $category = $this->makeCategory(['parent_id' => null]);

        $this->assertTrue($category->isRoot());
    }

    public function test_is_root_returns_false_when_parent_id_is_set(): void
    {
        $category = $this->makeCategory(['parent_id' => 1]);

        $this->assertFalse($category->isRoot());
    }

    public function test_get_full_path_single_category(): void
    {
        $category = $this->makeCategory([
            'name' => 'Electronics',
            'parent_id' => null,
        ]);
        // Simulate no parent loaded
        $category->setRelation('parent', null);

        $this->assertEquals('Electronics', $category->getFullPath());
    }

    public function test_get_full_path_with_parent(): void
    {
        $parent = $this->makeCategory([
            'name' => 'Clothing',
            'parent_id' => null,
        ]);
        $parent->setRelation('parent', null);

        $child = $this->makeCategory([
            'name' => 'T-Shirts',
            'parent_id' => 1,
        ]);
        $child->setRelation('parent', $parent);

        $this->assertEquals('Clothing > T-Shirts', $child->getFullPath());
    }

    public function test_get_full_path_three_levels(): void
    {
        $grandparent = $this->makeCategory([
            'name' => 'Clothing',
            'parent_id' => null,
        ]);
        $grandparent->setRelation('parent', null);

        $parent = $this->makeCategory([
            'name' => 'Men',
            'parent_id' => 1,
        ]);
        $parent->setRelation('parent', $grandparent);

        $child = $this->makeCategory([
            'name' => 'T-Shirts',
            'parent_id' => 2,
        ]);
        $child->setRelation('parent', $parent);

        $this->assertEquals('Clothing > Men > T-Shirts', $child->getFullPath());
    }

    public function test_get_descendant_ids_leaf_node(): void
    {
        $category = $this->makeCategory();
        $category->id = 5;
        $category->setRelation('children', collect([]));

        $this->assertEquals([5], $category->getDescendantIds());
    }

    public function test_get_descendant_ids_with_children(): void
    {
        $child1 = $this->makeCategory();
        $child1->id = 2;
        $child1->setRelation('children', collect([]));

        $child2 = $this->makeCategory();
        $child2->id = 3;
        $child2->setRelation('children', collect([]));

        $parent = $this->makeCategory();
        $parent->id = 1;
        $parent->setRelation('children', collect([$child1, $child2]));

        $ids = $parent->getDescendantIds();

        $this->assertContains(1, $ids);
        $this->assertContains(2, $ids);
        $this->assertContains(3, $ids);
        $this->assertCount(3, $ids);
    }

    public function test_fillable_contains_expected_fields(): void
    {
        $category = new Category;

        $this->assertContains('name', $category->getFillable());
        $this->assertContains('slug', $category->getFillable());
        $this->assertContains('description', $category->getFillable());
        $this->assertContains('is_active', $category->getFillable());
        $this->assertContains('parent_id', $category->getFillable());
    }

    public function test_casts_is_active_as_boolean(): void
    {
        $category = new Category;
        $casts = $category->getCasts();

        $this->assertEquals('boolean', $casts['is_active']);
    }
}
