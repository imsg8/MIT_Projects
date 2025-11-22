// // Initialize DOM elements
// const userInput = document.getElementById("user-input");
// const chatMessages = document.getElementById("chat-messages");
// const sendBtn = document.getElementById("send-btn");
// const closeBtn = document.getElementById("close-chat");

// // Handle send button click
// sendBtn.addEventListener("click", sendMessage);

// // Handle enter key press to send message
// userInput.addEventListener("keypress", function(e) {
//     if (e.key === 'Enter') {
//         sendMessage();
//     }
// });

// // Handle closing the chat
// closeBtn.addEventListener("click", function() {
//     document.querySelector(".chatbot-container").style.display = "none";
// });

// function sendMessage() {
//     const message = userInput.value.trim();
//     if (message === "") return;

//     // Add user message to the chat
//     appendMessage(message, "user-message");

//     // Clear input field
//     userInput.value = "";

//     // Send message to Groq API and get the response (placeholder for now)
//     getBotResponse(message);
// }

// function appendMessage(text, className) {
//     const messageDiv = document.createElement("div");
//     messageDiv.classList.add("message", className);
//     messageDiv.textContent = text;
//     chatMessages.appendChild(messageDiv);

//     // Scroll to the bottom
//     chatMessages.scrollTop = chatMessages.scrollHeight;
// }

// async function getBotResponse(userMessage) {
//     try {
//         const response = await fetch("https://api.groq.com/v1/chat", {
//             method: "POST",
//             headers: {
//                 "Content-Type": "application/json",
//                 "Authorization": "Bearer YOUR_API_KEY"
//             },
//             body: JSON.stringify({ message: userMessage })
//         });

//         const data = await response.json();
//         appendMessage(data.reply, "bot-message");

//     } catch (error) {
//         appendMessage("Error connecting to the server.", "bot-message");
//     }
// }

const responses = {
    "hello": "Hi there! How can I assist you today?",
    "coding hubs": "Here you will get Notes, Ebooks, project source Code, Interview questions. visit Coding Hubs.<a href='https://thecodinghubs.com' target='_blank'>Visit Website</a>",
    "how are you": "I'm just a bot, but I'm here to help you!",
    "need help": "How I can help you today?",
    "bye": "Goodbye! Have a great day!",
    "default": "I'm sorry, I didn't understand that. Want to connect with expert?",
    "expert": "Great! Please wait a moment while we connect you with an expert.",
    "no": "Okay, if you change your mind just let me know!"
};

document.getElementById('chatbot-toggle-btn').addEventListener('click', toggleChatbot);
document.getElementById('close-btn').addEventListener('click', toggleChatbot);
document.getElementById('send-btn').addEventListener('click', sendMessage);
document.getElementById('user-input').addEventListener('keypress', function(e) {
    if (e.key === 'Enter') {
        sendMessage();
    }
});

function toggleChatbot() {
    const chatbotPopup = document.getElementById('chatbot-popup');
    chatbotPopup.style.display = chatbotPopup.style.display === 'none' ? 'block' : 'none';
}

function sendMessage() {
    const userInput = document.getElementById('user-input').value.trim();
    if (userInput !== '') {
        appendMessage('user', userInput);
        respondToUser(userInput.toLowerCase());
        document.getElementById('user-input').value = '';
    }
}

function respondToUser(userInput) {
    const response = responses[userInput] || responses["default"];
    setTimeout(function() {
        appendMessage('bot', response);
    }, 500);
}

function appendMessage(sender, message) {
    const chatBox = document.getElementById('chat-box');
    const messageElement = document.createElement('div');
    messageElement.classList.add(sender === 'user' ? 'user-message' : 'bot-message');
    messageElement.innerHTML = message;
    chatBox.appendChild(messageElement);
    chatBox.scrollTop = chatBox.scrollHeight;
    if (sender === 'bot' && message === responses["default"]) {
        const buttonYes = document.createElement('button');
        buttonYes.textContent = '✔ Yes';
        buttonYes.onclick = function() {
            appendMessage('bot', responses["expert"]);
        };
        const buttonNo = document.createElement('button');
        buttonNo.textContent = '✖ No';
        buttonNo.onclick = function() {
            appendMessage('bot', responses["no"]);
        };
        const buttonContainer = document.createElement('div');
        buttonContainer.classList.add('button-container');
        buttonContainer.appendChild(buttonYes);
        buttonContainer.appendChild(buttonNo);
        chatBox.appendChild(buttonContainer);
    }
}