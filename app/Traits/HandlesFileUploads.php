<?php

namespace App\Traits;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

trait HandlesFileUploads
{
    /**
     * Upload a file from the request and return its storage path.
     */
    protected function uploadFile(Request $request, string $field, string $directory, string $disk = 'public'): ?string
    {
        if (!$request->hasFile($field)) {
            return null;
        }

        return $request->file($field)->store($directory, $disk);
    }

    /**
     * Delete a previously stored file.
     */
    protected function deleteStoredFile(?string $path, string $disk = 'public'): void
    {
        if ($path) {
            Storage::disk($disk)->delete($path);
        }
    }

    /**
     * Upload a new file and delete the old one. Returns the new path or null.
     */
    protected function replaceFile(Request $request, string $field, string $directory, ?string $oldPath, string $disk = 'public'): ?string
    {
        if (!$request->hasFile($field)) {
            return null;
        }

        $this->deleteStoredFile($oldPath, $disk);

        return $request->file($field)->store($directory, $disk);
    }
}
