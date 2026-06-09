@extends('layouts.app')

@section('content')
<div class="flex flex-col items-center justify-center min-h-screen bg-gray-900 text-white">
    <div class="w-full max-w-md">
        <video id="reelVideo" class="w-full rounded-lg" controls></video>
        <div class="mt-4 flex items-center justify-between">
            <div class="flex items-center space-x-2">
                <button id="likeBtn" class="focus:outline-none">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-red-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 15l7-7 7 7" />
                    </svg>
                </button>
                <span id="likesCount" class="text-sm">0</span>
            </div>
            <button id="shareBtn" class="bg-blue-600 hover:bg-blue-700 text-white px-3 py-1 rounded">Partager</button>
        </div>
        <div class="mt-4">
            <h2 class="text-lg font-semibold" id="videoTitle"></h2>
            <p class="text-sm text-gray-300" id="videoDescription"></p>
        </div>
        <div class="mt-6">
            <h3 class="text-md font-medium mb-2">Commentaires</h3>
            <div id="comments" class="space-y-2"></div>
            <textarea id="newComment" class="w-full p-2 bg-gray-800 border border-gray-700 rounded mt-2" rows="2" placeholder="Ajouter un commentaire..."></textarea>
            <button id="postComment" class="mt-2 bg-green-600 hover:bg-green-700 text-white px-4 py-1 rounded">Envoyer</button>
        </div>
    </div>
</div>
<script>
    const videoId = {{ $videoId }};
    const apiBase = '/api';
    async function loadVideo(){
        const res = await fetch(`${apiBase}/videos/${videoId}`);
        const data = await res.json();
        const video = data.video;
        document.getElementById('reelVideo').src = video.video_url;
        document.getElementById('videoTitle').textContent = video.title;
        document.getElementById('videoDescription').textContent = video.description;
        document.getElementById('likesCount').textContent = video.likes_count;
        loadComments();
    }
    async function loadComments(){
        const res = await fetch(`${apiBase}/videos/${videoId}/comments`);
        const data = await res.json();
        const container = document.getElementById('comments');
        container.innerHTML = '';
        data.comments.data.forEach(c=>{
            const div=document.createElement('div');
            div.className='p-2 bg-gray-800 rounded';
            div.textContent=c.content;
            container.appendChild(div);
        });
    }
    document.getElementById('postComment')?.addEventListener('click', async()=>{
        const content=document.getElementById('newComment').value;
        if(!content) return;
        await fetch(`${apiBase}/videos/${videoId}/comments`,{
            method:'POST',
            headers:{'Content-Type':'application/json','Accept':'application/json','X-CSRF-TOKEN':'{{ csrf_token() }}'},
            body: JSON.stringify({content})
        });
        document.getElementById('newComment').value='';
        loadComments();
    });
    loadVideo();
</script>
@endsection
