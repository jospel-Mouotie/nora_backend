<?php

namespace App\Http\Controllers;

use App\Models\Review;
use App\Models\Shop;
use App\Models\Delivery;
use Illuminate\Http\Request;
use App\Traits\ApiResponse;

class ReviewController extends Controller
{
    use ApiResponse;

    public function store(Request $request)
    {
        if ($error = $this->validateRequestData($request->all(), [
            'reviewable_id' => 'required|integer',
            'reviewable_type' => 'required|string|in:shop,delivery',
            'rating' => 'required|integer|min:1|max:5',
            'comment' => 'nullable|string|max:1000',
        ])) {
            return $error;
        }

        $type = $request->reviewable_type === 'shop' ? Shop::class : Delivery::class;

        // Check if exists
        $model = $type::find($request->reviewable_id);
        if (!$model) {
            return $this->notFoundResponse($request->reviewable_type);
        }

        $review = Review::updateOrCreate(
            [
                'user_id' => auth()->id(),
                'reviewable_id' => $request->reviewable_id,
                'reviewable_type' => $type,
            ],
            [
                'rating' => $request->rating,
                'comment' => $request->comment,
            ]
        );

        return $this->createdResponse(['review' => $review], 'Review saved');
    }

    public function index(Request $request)
    {
        if ($error = $this->validateRequestData($request->all(), [
            'reviewable_id' => 'required|integer',
            'reviewable_type' => 'required|string|in:shop,delivery',
        ])) {
            return $error;
        }

        $type = $request->reviewable_type === 'shop' ? Shop::class : Delivery::class;

        $reviews = Review::where('reviewable_id', $request->reviewable_id)
            ->where('reviewable_type', $type)
            ->with('user:id,name,photo')
            ->orderBy('created_at', 'desc')
            ->paginate(20);

        return response()->json(['reviews' => $reviews]);
    }
}
