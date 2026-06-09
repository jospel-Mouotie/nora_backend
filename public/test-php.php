<?php
// public/test-php.php
echo "PHP Version: " . phpversion() . "\n";
echo "enable_post_data_reading: " . (ini_get('enable_post_data_reading') ? 'On' : 'Off') . "\n";
echo "post_max_size: " . ini_get('post_max_size') . "\n";
echo "max_input_vars: " . ini_get('max_input_vars') . "\n";

// Tester la réception du body
$raw = file_get_contents('php://input');
echo "Raw input length: " . strlen($raw) . "\n";
echo "Raw input: " . $raw . "\n";
echo "POST data: " . print_r($_POST, true) . "\n";
?>
