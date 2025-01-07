import time
import json
import os
import importlib
from swarm import Swarm
from swarm.repl import run_demo_loop
from openai import OpenAI
import requests

# Helper functions (included for completeness)
def choose_mode():
    while True:
        mode = input("Choose mode (chat, auto, two-agent): ").strip().lower()
        if mode in ['chat', 'auto', 'two-agent']:
            return mode
        print("Invalid mode. Please choose from: chat, auto, two-agent")


def process_and_print_streaming_response(response):
    for chunk in response:
        if hasattr(chunk.choices[0].delta, "content"):
            print(chunk.choices[0].delta.content, end="", flush=True)


def pretty_print_messages(messages):
    print(json.dumps(messages, indent=4))


def run_autonomous_loop(agent):  # Placeholder - implement your autonomous logic
    print("Autonomous loop not yet implemented.")


def run_openai_conversation_loop(agent):  # Placeholder
    print("OpenAI conversation loop not yet implemented.")


class MainAgent:
    def __init__(self, api_key):
        self.client = Swarm()
        self.openai_client = OpenAI(api_key=api_key)


    def create_lower_level_agent(self, task_description):
        prompt = f"""
        Write a Python function called `agent_function` that takes two arguments: `client` (a Swarm object) and `user_input` (a string). 
        The function should perform the following task: {task_description}.

        The `client` object has the following methods you can use:
        - `client.get_shared_data(key)`: Retrieves data from the shared store.
        - `client.set_shared_data(key, value)`: Stores data in the shared store.
        - `client.add_task(task)`: Adds a task to the task queue.
        - `client.get_task_queue()`: Retrieves the current task queue.

        Make sure to use the `client` object to interact with the Swarm.
        Return a string response based on the user input and the task.
        """

        try:
            response = self.openai_client.completions.create(
                model="text-davinci-003",  # Or a suitable model
                prompt=prompt,
                max_tokens=500,            # Adjust as needed
                temperature=0.7           # Adjust as needed
            )
            code = response.choices[0].text.strip()

            # Execute generated code in a safe manner (important!)
            exec(code, globals())
            return agent_function


        except openai.OpenAIError as e:
            print(f"OpenAI API error: {e}")
            return None
        except Exception as e:
            print(f"Error creating agent: {e}")
            return None



def main():
    api_key = os.environ.get("OPENAI_API_KEY")
    if not api_key:
        raise ValueError("OPENAI_API_KEY environment variable not set.")

    agent = MainAgent(api_key=api_key)
    mode = choose_mode()

    mode_functions = {
        'chat': lambda: run_demo_loop(agent),
        'auto': lambda: run_autonomous_loop(agent),
        'two-agent': lambda: run_openai_conversation_loop(agent)
    }

    print(f"\nStarting {mode} mode...")
    mode_functions[mode]()


if __name__ == "__main__":
    print("Starting Based Agent...")
    main()


# swarm.py (ensure this is in the correct location)
class Swarm:
    def __init__(self):
        self.shared_data = {}
        self.task_queue = []

    def get_shared_data(self, key):
        return self.shared_data.get(key)

    def set_shared_data(self, key, value):
        self.shared_data[key] = value

    def add_task(self, task):
        self.task_queue.append(task)

    def get_task_queue(self):
        return self.task_queue




# swarm/repl.py (Create this file within a 'swarm' directory)
def run_demo_loop(main_agent, initial_task="Start a conversation"):
    print("Demo loop running...")

    agent_function = main_agent.create_lower_level_agent(initial_task)
    if not agent_function:
        print("Failed to create initial agent. Exiting demo loop.")
        return


    while True:
        user_input = input("Enter text: ")
        print(f"User input: {user_input}")

        try:
            agent_response = agent_function(main_agent.client, user_input) # Pass client & user input
            print(agent_response)

        except Exception as e:
            print(f"Error during agent execution: {e}")

