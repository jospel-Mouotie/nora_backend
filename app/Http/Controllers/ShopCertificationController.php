<?php

namespace App\Http\Controllers;

use App\Models\Shop;
use App\Models\ShopCertificationRequest;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class ShopCertificationController extends Controller
{
    public function requestCertification(Request $request, $shopId)
    {
        $shop = Shop::where('user_id', auth()->id())->findOrFail($shopId);

        if ($shop->certifiee) {
            return response()->json(['error' => 'Shop is already certified'], 400);
        }

        $existingReq = ShopCertificationRequest::where('shop_id', $shopId)->whereIn('status', ['pending', 'paid'])->first();
        if ($existingReq) {
            return response()->json(['error' => 'A certification request is already in progress'], 400);
        }

        $certRequest = ShopCertificationRequest::create([
            'shop_id' => $shopId,
            'status' => 'pending',
        ]);

        return response()->json(['message' => 'Certification requested', 'request' => $certRequest], 201);
    }

    public function payCertification(Request $request, $requestId)
    {
        $certRequest = ShopCertificationRequest::whereHas('shop', function ($q) {
            $q->where('user_id', auth()->id());
        })->findOrFail($requestId);

        if ($certRequest->status !== 'pending') {
            return response()->json(['error' => 'Cannot pay for this request'], 400);
        }

        $validator = Validator::make($request->all(), [
            'payment_method' => 'required|string',
            'transaction_id' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $certRequest->update([
            'status' => 'paid',
            'payment_method' => $request->payment_method,
            'transaction_id' => $request->transaction_id,
        ]);

        return response()->json(['message' => 'Payment recorded, waiting for admin approval', 'request' => $certRequest]);
    }

    public function adminPendingRequests(Request $request)
    {
        if ($request->user()->role !== 'admin') {
            return response()->json(['message' => 'Non autorisé'], 403);
        }

        $requests = ShopCertificationRequest::whereIn('status', ['pending', 'paid'])
            ->with('shop.user')
            ->orderBy('created_at', 'asc')
            ->paginate(20);

        return response()->json(['requests' => $requests]);
    }

    public function adminValidate(Request $request, $requestId)
    {
        if ($request->user()->role !== 'admin') {
            return response()->json(['message' => 'Non autorisé'], 403);
        }

        $certRequest = ShopCertificationRequest::findOrFail($requestId);
        $certRequest->update(['status' => 'approved', 'admin_comment' => $request->admin_comment]);

        $shop = $certRequest->shop;
        $shop->update([
            'certifiee' => true,
            'certifiee_at' => now(),
        ]);

        return response()->json(['message' => 'Shop certification approved']);
    }

    public function adminReject(Request $request, $requestId)
    {
        if ($request->user()->role !== 'admin') {
            return response()->json(['message' => 'Non autorisé'], 403);
        }

        $certRequest = ShopCertificationRequest::findOrFail($requestId);
        $certRequest->update([
            'status' => 'rejected',
            'admin_comment' => $request->admin_comment
        ]);

        return response()->json(['message' => 'Shop certification rejected']);
    }
}
