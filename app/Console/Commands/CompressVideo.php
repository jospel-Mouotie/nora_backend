<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\Video;
use Illuminate\Support\Facades\Log;

class CompressVideo extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'video:compress {id}';

    /**
     * The description of the console command.
     *
     * @var string
     */
    protected $description = 'Compress a video using FFmpeg in the background';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $id = $this->argument('id');
        $video = Video::find($id);

        if (!$video) {
            $this->error("Video with ID {$id} not found.");
            Log::error("Video compression failed: ID {$id} not found.");
            return 1;
        }

        Log::info("Starting background compression for video ID: {$id}");

        $inputPath = $video->video_path;
        $processedPath = $this->compressVideoWithExec($inputPath);

        if ($processedPath) {
            $video->update([
                'processed_path' => str_replace('public/', '', $processedPath),
            ]);
            Log::info("Successfully compressed video ID: {$id}. Processed path: {$processedPath}");
            $this->info("Video ID {$id} compressed successfully.");
            return 0;
        }

        Log::error("Failed to compress video ID: {$id}");
        $this->error("Failed to compress video ID {$id}.");
        return 1;
    }

    /**
     * Compresser la vidéo avec FFmpeg
     */
    private function compressVideoWithExec(string $inputPath): ?string
    {
        $inputFullPath = storage_path('app/public/' . $inputPath);

        if (!file_exists($inputFullPath)) {
            Log::error('FFmpeg input file not found: ' . $inputFullPath);
            return null;
        }

        $outputFilename = 'videos/processed/' . uniqid() . '.mp4';
        $outputFullPath = storage_path('app/public/' . $outputFilename);

        $outputDir = dirname($outputFullPath);
        if (!file_exists($outputDir)) {
            mkdir($outputDir, 0755, true);
        }

        // Chemin FFmpeg
        $ffmpegPath = env('FFMPEG_PATH', 'C:\\ffmpeg-master-latest-win64-gpl-shared\\bin\\ffmpeg.exe');

        // Paramètres ultra-compatibles pour Android et iOS
        $command = sprintf(
            '"%s" -i "%s" -vf "scale=720:-2" -c:v libx264 -profile:v baseline -level 3.0 -pix_fmt yuv420p -crf 28 -preset slow -c:a aac -b:a 64k -movflags +faststart -y "%s" 2>&1',
            $ffmpegPath,
            $inputFullPath,
            $outputFullPath
        );

        Log::info('Background FFmpeg command: ' . $command);

        exec($command, $output, $returnCode);

        if ($returnCode === 0 && file_exists($outputFullPath) && filesize($outputFullPath) > 0) {
            Log::info('Background compression successful: ' . $outputFilename);
            return $outputFilename;
        }

        Log::error('Background compression failed. Return code: ' . $returnCode . '. Output: ' . implode("\n", $output));
        return null;
    }
}
