<?php

namespace App\Traits;

use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Validator;

trait ApiResponse
{
    protected function successResponse($data = [], string $message = null, int $code = 200): JsonResponse
    {
        $response = [];

        if ($message !== null) {
            $response['message'] = $message;
        }

        if (is_array($data)) {
            $response = array_merge($response, $data);
        } else {
            $response['data'] = $data;
        }

        return response()->json($response, $code);
    }

    protected function createdResponse($data = [], string $message = null): JsonResponse
    {
        return $this->successResponse($data, $message, 201);
    }

    protected function errorResponse(string $message, int $code = 400): JsonResponse
    {
        return response()->json(['message' => $message], $code);
    }

    protected function notFoundResponse(string $entity = 'Resource'): JsonResponse
    {
        return $this->errorResponse($entity . ' non trouvé(e)', 404);
    }

    protected function unauthorizedResponse(string $message = 'Non autorisé'): JsonResponse
    {
        return $this->errorResponse($message, 403);
    }

    protected function serverErrorResponse(string $message = 'Erreur interne du serveur'): JsonResponse
    {
        return $this->errorResponse($message, 500);
    }

    /**
     * Validate request data. Returns a JsonResponse on failure, or null on success.
     */
    protected function validateRequestData(array $data, array $rules): ?JsonResponse
    {
        $validator = Validator::make($data, $rules);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        return null;
    }
}
