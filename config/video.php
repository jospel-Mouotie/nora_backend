<?php

return [
    /*
    |--------------------------------------------------------------------------
    | Video Configuration
    |--------------------------------------------------------------------------
    |
    | Configuration pour le traitement et streaming des vidéos
    |
    */

    'ffmpeg' => [
        'binary' => env('FFMPEG_BINARY', '/usr/bin/ffmpeg'),
        'ffprobe' => env('FFPROBE_BINARY', '/usr/bin/ffprobe'),
        'timeout' => env('FFMPEG_TIMEOUT', 3600), // 1 heure
    ],

    'upload' => [
        'max_file_size' => env('VIDEO_MAX_FILE_SIZE', 512000), // 500MB en KB
        'allowed_formats' => ['mp4', 'mov', 'avi', 'wmv', 'flv', 'webm'],
        'storage_path' => 'videos',
        'thumbnail_path' => 'video-thumbnails',
        'processed_path' => 'videos/processed',
    ],

    'processing' => [
        'quality' => [
            'low' => ['bitrate' => 500, 'resolution' => '480p'],
            'medium' => ['bitrate' => 1000, 'resolution' => '720p'],
            'high' => ['bitrate' => 2000, 'resolution' => '1080p'],
        ],
        'thumbnail_time' => 10, // seconde à laquelle prendre la miniature
        'auto_generate_thumbnail' => true,
    ],

    'streaming' => [
        'enable_range_requests' => true,
        'cache_control' => 'public, max-age=3600',
        'chunk_size' => 1024 * 1024, // 1MB
    ],

    'view_tracking' => [
        'minimum_duration' => 1.4, // secondes minimum pour compter comme vue
        'unique_view_period' => 24, // heures avant de compter une nouvelle vue
        'track_geolocation' => env('TRACK_VIDEO_GEOLOCATION', false),
    ],

    'engagement' => [
        'enable_comments' => true,
        'enable_likes' => true,
        'auto_approve_comments' => true,
        'max_comment_length' => 1000,
    ],

    'limits' => [
        'max_videos_per_user_per_day' => 10,
        'max_video_duration_minutes' => 60,
        'max_comments_per_video' => 1000,
    ],
];
