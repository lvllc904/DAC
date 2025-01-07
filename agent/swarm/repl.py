# swarm.py

class Swarm:
    def __init__(self):
        self.shared_data = {}  # For shared state
        self.task_queue = []   # For task management


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
            agent_response = agent_function(main_agent.client, user_input) # Pass Swarm client & user input
            print(agent_response)

        except Exception as e:
            print(f"Error during agent execution: {e}")

