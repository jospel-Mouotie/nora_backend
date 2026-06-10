<?php

namespace App\Http\Controllers;

use App\Models\Shop;
use App\Models\ShopCertificationRequest;
use Illuminate\Http\Request;
use App\Traits\ApiResponse;

class ShopCertificationController extends Controller
{
    use ApiResponse;

    public function requestCertification(Request $request, $shopId)
    {
        $shop = Shop::where('user_id', auth()->id())->findOrFail($shopId);

        if ($shop->certifiee) {
            return $this->errorResponse('Shop is already certified', 400);
        }

        $existingReq = ShopCertificationRequest::where('shop_id', $shopId)->whereIn('status', ['pending', 'paid'])->first();
        if ($existingReq) {
            return $this->errorResponse('A certification request is already in progress', 400);
        }

        $certRequest = ShopCertificationRequest::create([
            'shop_id' => $shopId,
            'status' => 'pending',
        ]);

        return $this->createdResponse(
            ['request' => $certRequest],
            'Certification requested'
        );
    }

    public function payCertification(Request $request, $requestId)
    {
        $certRequest = ShopCertificationRequest::whereHas('shop', function ($q) {
            $q->where('user_id', auth()->id());
        })->findOrFail($requestId);

        if ($certRequest->status !== 'pending') {
            return $this->errorResponse('Cannot pay for this request', 400);
        }

        if ($error = $this->validateRequestData($request->all(), [
            'payment_method' => 'required|string',
            'transaction_id' => 'required|string',
        ])) {
            return $error;
        }

        $certRequest->update([
            'status' => 'paid',
            'payment_method' => $request->payment_method,
            'transaction_id' => $request->transaction_id,
        ]);

        return $this->successResponse(
            ['request' => $certRequest],
            'Payment recorded, waiting for admin approval'
        );
    }

    public function adminPendingRequests()
    {
        $requests = ShopCertificationRequest::whereIn('status', ['pending', 'paid'])
            ->with('shop.user')
            ->orderBy('created_at', 'asc')
            ->paginate(20);

        return response()->json(['requests' => $requests]);
    }

    public function adminValidate(Request $request, $requestId)
    {
        $certRequest = ShopCertificationRequest::findOrFail($requestId);
        $certRequest->update(['status' => 'approved', 'admin_comment' => $request->admin_comment]);

        $shop = $certRequest->shop;
        $shop->update([
            'certifiee' => true,
            'certifiee_at' => now(),
        ]);

        return $this->successResponse([], 'Shop certification approved');
    }

    public function adminReject(Request $request, $requestId)
    {
        $certRequest = ShopCertificationRequest::findOrFail($requestId);
        $certRequest->update([
            'status' => 'rejected',
            'admin_comment' => $request->admin_comment
        ]);

        return $this->successResponse([], 'Shop certification rejected');
    }
}
