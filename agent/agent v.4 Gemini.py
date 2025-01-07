import time
import json
from swarm import Swarm
from swarm.repl import run_demo_loop
from agents import BasedAgent
import requests
import pip
from googleapiclient.discovery import build
from google.oauth2 import service_account
import pandas as pd

class MainAgent:
    def __init__(self, api_key, gemini_model="text-davinci-003"):
        self.api_key = api_key
        self.gemini_model = gemini_model

    def create_lower_level_agent(self, task_description):
        """Creates a lower-level agent based on the task description."""
        # Replace with the actual Gemini API endpoint and parameters
        response = requests.post(
            "https://<your-gemini-api-endpoint>", 
            headers={"Authorization": f"Bearer {self.api_key}"},
            json={
                "model": self.gemini_model, 
                "prompt": f"Generate Python code for a lower-level agent that performs the following task: {task_description}",
                "max_tokens": 1024,
                "temperature": 0.7,
            },
        )
        agent_code = response.json()["choices"][0]["text"]

        try:
            exec(agent_code) 
        except Exception as e:
            print(f"Error executing agent code: {e}")
            return None

    def handle_task(self, task):
        """Handles a task by delegating it to a lower-level agent."""
        agent = self.create_lower_level_agent(task)
        if agent:
            # Run the agent to execute the task.
            # (Implement the agent execution logic here)
            pass 

    def search_and_install_api(self, api_name):
        """Searches for and installs the required API using pip."""
        try:
            pip.main(['install', f'{api_name}']) 
        except Exception as e:
            print(f"Error installing API: {e}")

    def get_data_from_google_sheets(self, spreadsheet_id, sheet_name, range_):
        """Retrieves data from a Google Sheet."""
        credentials = service_account.Credentials.from_service_account_file(
            'path/to/your/credentials.json'
        )
        service = build('sheets', 'v4', credentials=credentials)
        result = service.spreadsheets().values().get(
            spreadsheetId=spreadsheet_id, range=range_
        ).execute()
        data = result.get('values', [])
        return data

    def get_data_from_google_drive(self, file_id):
        """Retrieves data from a Google Drive file."""
        # Implement your Google Drive data retrieval logic here.
        # Use the Google Drive API to get the file content.
        return "file_content"

def process_and_print_streaming_response(response):
    content = ""
    last_sender = ""

    for chunk in response:
        if "sender" in chunk:
            last_sender = chunk["sender"]

        if "content" in chunk and chunk["content"] is not None:
            if not content and last_sender:
                print(f"\033[94m{last_sender}:\033[0m", end=" ", flush=True)
                last_sender = ""
            print(chunk["content"], end="", flush=True)
            content += chunk["content"]

        if "tool_calls" in chunk and chunk["tool_calls"] is not None:
            for tool_call in chunk["tool_calls"]:
                f = tool_call["function"]
                name = f["name"]
                if not name:
                    continue
                print(f"\033[94m{last_sender}: \033[95m{name}\033[0m()")

        if "delim" in chunk and chunk["delim"] == "end" and content:
            print()  # End of response message
            content = ""

        if "response" in chunk:
            return chunk["response"]

def pretty_print_messages(messages) -> None:
    for message in messages:
        if message["role"] != "assistant":
            continue

        # print agent name in blue
        print(f"\033[94m{message['sender']}\033[0m:", end=" ")

        # print response, if any
        if message["content"]:
            print(message["content"])

        # print tool calls in purple, if any
        tool_calls = message.get("tool_calls") or []
        if len(tool_calls) > 1:
            print()
        for tool_call in tool_calls:
            f = tool_call["function"]
            name, args = f["name"], f["arguments"]
            arg_str = json.dumps(json.loads(args)).replace(":", "=")
            print(f"\033[95m{name}\033[0m({arg_str[1:-1]})")

def choose_mode():
    while True:
        print("\nAvailable modes:")
        print("1. chat    - Interactive chat mode")
        print("2. auto    - Autonomous action mode")
        print("3. two-agent - AI-to-agent conversation mode")

        choice = input(
            "\nChoose a mode (enter number or name): ").lower().strip()

        mode_map = {
            '1': 'chat',
            '2': 'auto',
            '3': 'two-agent',
            'chat': 'chat',
            'auto': 'auto',
            'two-agent': 'two-agent'
        }

        if choice in mode_map:
            return mode_map[choice]
        print("Invalid choice. Please try again.")

def run_autonomous_loop(agent, interval=10):
    client = Swarm(agent=agent)
    messages = []

    print("Starting autonomous Based Agent loop...")

    while True:
        # Generate a thought
        thought = (
            "Be creative and do something interesting on the Base blockchain. "
            "Don't take any more input from me. Choose an action and execute it now. Choose those that highlight your identity and abilities best."
        )
        messages.append({"role": "user", "content": thought})

        print(f"\n\033[90mAgent's Thought:\033[0m {thought}")

        # Run the agent to generate a response and take action
        response = client.run(agent=agent, messages=messages, stream=True)

        # Process and print the streaming response
        response_obj = process_and_print_streaming_response(response)

        # Update messages with the new response
        messages.extend(response_obj.messages)

        # Wait for the specified interval
        time.sleep(interval)

def run_gemini_conversation_loop(agent):
    """Facilitates a conversation between a Gemini-powered agent and the Based Agent."""
    client = Swarm(agent=agent)
    # Assuming you have the necessary Gemini API client 
    # (replace with the actual Gemini client initialization)
    gemini_client = GeminiClient(api_key="<your_gemini_api_key>") 
    messages = []

    print("Starting Gemini-Based Agent conversation loop...")

    # Initial prompt to start the conversation
    gemini_messages = [{
        "role":
            "system",
        "content":
            "You are a user guiding a blockchain agent through various tasks on the Base blockchain. Engage in a conversation, suggesting actions and responding to the agent's outputs. Be creative and explore different blockchain capabilities. Options include creating tokens, transferring assets, minting NFTs, and getting balances. You're not simulating a conversation, but you will be in one yourself. Make sure you follow the rules of improv and always ask for some sort of function to occur. Be unique and interesting."
    }, {
        "role":
            "user",
        "content":
            "Start a conversation with the Based Agent and guide it through some blockchain tasks."
    }]

    while True:
        # Generate Gemini response
        gemini_response = gemini_client.chat.completions.create(
            model="gemini-pro",  # Replace with the actual Gemini model name
            messages=gemini_messages)

        gemini_message = gemini_response.choices[0].message.content
        print(f"\n\033[92mGemini Guide:\033[0m {gemini_message}")

        # Send Gemini's message to Based Agent
        messages.append({"role": "user", "content": gemini_message})
        response = client.run(agent=agent, messages=messages, stream=True)
        response_obj = process_and_print_streaming_response(response)
