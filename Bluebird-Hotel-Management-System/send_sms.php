<?php
require __DIR__ . '/vendor/autoload.php';  // Load the Twilio SDK

use Twilio\Rest\Client;

// Your Twilio credentials from the Twilio console
$account_sid = 'Twilio_sid';   // Twilio Account SID
$auth_token = 'Twilio_auth';     // Twilio Auth Token
$twilio_number = 'Twilio_number'; // Your Twilio phone number

// The recipient's phone number and the message
$to_number = 'To_number';  // Phone number to send SMS to
$message = 'Hello! This is a test message from PHP.';

// Create a Twilio client
$client = new Client($account_sid, $auth_token);

// Send the message
try {
    $client->messages->create(
        $to_number,   // The recipient's phone number
        [
            'from' => $twilio_number,  // Twilio phone number
            'body' => $message         // SMS message content
        ]
    );
    echo 'Message sent successfully!';
} catch (Exception $e) {
    echo 'Error: ' . $e->getMessage();
}
?>
