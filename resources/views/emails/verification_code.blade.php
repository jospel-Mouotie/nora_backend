<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Code de validation - Nora</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #f4f4f4;
            margin: 0;
            padding: 20px;
        }
        .container {
            max-width: 600px;
            margin: 0 auto;
            background-color: #ffffff;
            border-radius: 10px;
            overflow: hidden;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .header {
            background: linear-gradient(135deg, #4CAF50, #2196F3);
            color: white;
            padding: 30px;
            text-align: center;
        }
        .header h1 {
            margin: 0;
            font-size: 28px;
        }
        .content {
            padding: 40px;
            text-align: center;
        }
        .content h2 {
            color: #333;
            margin-bottom: 20px;
        }
        .content p {
            color: #666;
            line-height: 1.6;
            margin-bottom: 20px;
        }
        .code {
            background-color: #f0f0f0;
            border: 2px dashed #4CAF50;
            border-radius: 8px;
            padding: 20px;
            font-size: 36px;
            font-weight: bold;
            color: #4CAF50;
            letter-spacing: 5px;
            margin: 30px 0;
            display: inline-block;
        }
        .footer {
            background-color: #f4f4f4;
            padding: 20px;
            text-align: center;
            color: #999;
            font-size: 12px;
        }
        .footer a {
            color: #4CAF50;
            text-decoration: none;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Nora cmr</h1>
        </div>
        <div class="content">
            <h2>Bonjour {{ $name }},</h2>
            <p>Merci de vous être inscrit sur Nora !</p>
            <p>Veuillez utiliser le code de validation suivant pour confirmer votre adresse email :</p>
            <div class="code">{{ $code }}</div>
            <p>Ce code expire dans 15 minutes.</p>
            <p>Si vous n'avez pas demandé ce code, veuillez ignorer cet email.</p>
        </div>
        <div class="footer">
            <p>&copy; 2026 Nora cmr. Tous droits réservés.</p>
            <p>Cet email a été envoyé automatiquement, merci de ne pas y répondre.</p>
        </div>
    </div>
</body>
</html>
