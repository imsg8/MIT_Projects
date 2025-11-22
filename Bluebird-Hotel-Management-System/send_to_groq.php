<?php
// require 'send_sms.php';  // Load your Twilio SMS function
require 'vendor/autoload.php';  // Load the Groq PHP library

use LucianoTonet\GroqPHP\Groq;

header('Content-Type: application/json');

// Configure Groq API client
$groq = new Groq('Groq_API');  // Replace with your actual API key

// Receive message from the client
$request = json_decode(file_get_contents('php://input'), true);
$temp = "Processed";
$prompt_message = "You are a chatbot for a hotel helper. People will use you for their requests in the hotel; they can request food, utilities, and many more. You always require the room number to process the request. If the room number is not mentioned, tell them to add the room number and reply again. In your reply, respond only with the room number and the request. The reply should be in a proper sentence format.";
$user_message =$prompt_message . ' '.$request['message'] ?? ''; // Use null coalescing to avoid undefined index notice

if (empty($user_message)) {
    echo json_encode(['reply' => 'Please provide a message.']);
    exit;
}

try {
    $response = $groq->chat()->completions()->create([
        'model' => 'llama3-8b-8192',
        'messages' => [
            [
                'role' => 'user',
                'content' => $user_message
            ]
        ],
    ]);

    // Check if response has the expected structure
    if (isset($response['choices'][0]['message']['content'])) {
        $bot_reply = $response['choices'][0]['message']['content'];
    } else {
        throw new Exception('Invalid response structure: ' . json_encode($response));
    }
} catch (Exception $e) {
    // Log the error and return a friendly message
    error_log('Groq API Error: ' . $e->getMessage());
    $bot_reply = 'Sorry, there was an error processing your request.';
}

// Send the reply as an SMS (uncomment if needed)
$phone_number = 'To_number';  // Set recipient phone number here
sendSMS($phone_number, $bot_reply);  // Call the Twilio SMS function

// Send the reply back to the GUI
echo json_encode(['reply' => $temp.' '.$bot_reply]);

// // Twilio SMS function
function sendSMS($to_number, $message) {
    $account_sid = 'Twilio_sid';
    $auth_token = 'Twilio_auth';
    $twilio_number = 'Twilio_number';

    $client = new \Twilio\Rest\Client($account_sid, $auth_token);
    try {
        $client->messages->create($to_number, ['from' => $twilio_number, 'body' => $message]);
        return true;
    } catch (Exception $e) {
        error_log('Twilio SMS Error: ' . $e->getMessage());
        return false;
    }
}
?>
