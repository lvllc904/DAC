import openai  # Make sure to include this import

class MainAgent:
    # ... (other methods)

    def create_lower_level_agent(self, task_description):
        # Create a prompt for the OpenAI API
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
                max_tokens=500,  # Adjust as needed
                temperature=0.7,    # Adjust as needed
            )

            code = response.choices[0].text.strip()
            # Use exec() with caution - ensure appropriate safeguards in a production environment.
            # Consider using a safer evaluation method if dealing with untrusted input.
            exec(code, globals()) # Execute the generated code to define agent_function

            return agent_function # Return the created agent function


        except openai.OpenAIError as e:  # Handle OpenAI API errors
            print(f"OpenAI API error: {e}")
            return None
        except Exception as e: # Handle other errors
            print(f"Error creating agent: {e}")
            return None

