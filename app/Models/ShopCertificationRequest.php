<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ShopCertificationRequest extends Model
{
    use HasFactory;

    protected $fillable = [
        'shop_id',
        'status',
        'payment_method',
        'transaction_id',
        'admin_comment',
    ];

    public function shop()
    {
        return $this->belongsTo(Shop::class);
    }
}
