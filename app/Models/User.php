<?php

namespace App\Models;

use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use App\Models\Message;
use App\Models\Shop;
use App\Models\Cart;
use App\Models\Order;
use App\Models\Delivery;
use App\Models\ShopFollower;
use App\Models\ShopLike;
use App\Models\Video;
use App\Models\VideoLike;
use App\Models\VideoComment;
use App\Models\VideoView;
use App\Models\MBCoin;
use App\Models\MBReward;
use App\Models\MBShopPurchase;
use App\Models\UserInterest; // ✅ AJOUTER CETTE IMPORTATION

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'name',
        'email',
        'password',
        'role',
        'phone',
        'profile_photo',
        'wallet_balance',
        'address',
        'city',
        'country',
        'fcm_token',
        'fcm_token_updated_at',
        'last_login_at',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected $casts = [
        'email_verified_at' => 'datetime',
    ];

    // ✅ AJOUTER CETTE RELATION
    public function interests()
    {
        return $this->hasMany(UserInterest::class);
    }

    // ✅ Optionnel : Relation pour les intérêts actifs uniquement
    public function activeInterests()
    {
        return $this->hasMany(UserInterest::class)->where('is_active', true);
    }

    // ✅ Optionnel : Relation pour les intérêts à haute priorité
    public function highPriorityInterests()
    {
        return $this->hasMany(UserInterest::class)
                    ->where('is_active', true)
                    ->where('priority_level', '>=', 4);
    }

    // Relationships existants...
    public function shops()
    {
        return $this->hasMany(Shop::class);
    }

    public function shop()
    {
        return $this->hasOne(Shop::class);
    }

    public function followedShops()
    {
        return $this->hasMany(ShopFollower::class);
    }

    public function likedShops()
    {
        return $this->hasMany(ShopLike::class);
    }

    public function cart()
    {
        return $this->hasOne(Cart::class);
    }

    public function orders()
    {
        return $this->hasMany(Order::class);
    }

    public function deliveries()
    {
        return $this->hasMany(Delivery::class, 'delivery_person_id');
    }

    public function sentMessages()
    {
        return $this->hasMany(Message::class, 'sender_id');
    }

    public function receivedMessages()
    {
        return $this->hasMany(Message::class, 'receiver_id');
    }

    public function unreadMessages()
    {
        return $this->receivedMessages()->unread();
    }

    public function chatMessages($deliveryId)
    {
        return Message::where(function ($q) {
            $q->where('sender_id', $this->id)
              ->orWhere('receiver_id', $this->id);
        })->where('delivery_id', $deliveryId)->get();
    }

    // Video helpers
    public function publicVideos()
    {
        return $this->videos()->public()->ready()->published();
    }

    public function videoLikes()
    {
        return $this->hasMany(VideoLike::class);
    }

    public function videoComments()
    {
        return $this->hasMany(VideoComment::class);
    }

    public function videoViews()
    {
        return $this->hasMany(VideoView::class);
    }

    public function likedVideos()
    {
        return $this->belongsToMany(Video::class, 'video_likes');
    }

    public function getTotalVideoViewsAttribute()
    {
        return $this->videos()->sum('view_count');
    }

    public function getTotalVideoLikesAttribute()
    {
        return $this->videos()->sum('likes_count');
    }

    // MB helpers
    public function mbCoin()
    {
        return $this->hasOne(MBCoin::class);
    }

    public function mbRewards()
    {
        return $this->hasMany(MBReward::class);
    }

    public function mbShopPurchases()
    {
        return $this->hasMany(MBShopPurchase::class);
    }

    public function getAvailableMBRewardsAttribute()
    {
        return $this->mbRewards()->available()->count();
    }

    public function getClaimedMBRewardsAttribute()
    {
        return $this->mbRewards()->claimed()->count();
    }

    public function getTotalMBPurchasesAttribute()
    {
        return $this->mbShopPurchases()->count();
    }

    public function getTotalMBSpentAttribute()
    {
        return $this->mbShopPurchases()->completed()->sum('price_mb_coins');
    }

    // ✅ AJOUTER UNE MÉTHODE POUR RÉCUPÉRER LES INTÉRÊTS
    public function getInterestIds()
    {
        return $this->interests()
                    ->where('is_active', true)
                    ->pluck('category_id')
                    ->toArray();
    }

    // ✅ VÉRIFIER SI L'UTILISATEUR A DES INTÉRÊTS
    public function hasInterests()
    {
        return $this->interests()
                    ->where('is_active', true)
                    ->exists();
    }
}