<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\ProductVariant;
use App\Models\Stock;

class AddStockToVariantsSeeder extends Seeder
{
    public function run(): void
    {
        // Récupérer toutes les variantes de produits
        $variants = ProductVariant::all();
        
        $count = 0;
        foreach ($variants as $variant) {
            // Vérifier si la variante a déjà du stock
            if (!$variant->stock) {
                Stock::create([
                    'product_variant_id' => $variant->id,
                    'quantity' => rand(10, 50),
                    'reserved_quantity' => 0,
                ]);
                $count++;
            }
        }
        
        $this->command->info("✅ Stock ajouté à {$count} variantes de produits !");
    }
}
