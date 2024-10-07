import subprocess
from io import StringIO
import time


import pandas as pd

# from cryptography.fernet import Fernet

from Modules.config_handler import ConfigHandler


# def get_mysql_password():
#     with open('key.key', 'rb') as key_file:
#         key = key_file.read()

#     cipher = Fernet(key)

#     with open('password.enc', 'rb') as enc_file:
#         encrypted_password = enc_file.read()

#     return cipher.decrypt(encrypted_password).decode('utf-8')

class MySQLRunner:
    def __init__(self, user: str, host: str = 'localhost', database: str = '', password: str = 'Nu66et'):
        self.user = user
        self.host = host
        self.password = password
        self.database = database
        self.error_message = ""
        self.mysql_client_path = self.get_mysql_client_path()  # Cache the MySQL client path
    
    def get_mysql_client_path(self) -> str:
        """Locate the MySQL client executable."""
        try:
            result = subprocess.run(['where', 'mysql'], capture_output=True, text=True)  # 'which' for Linux/macOS
            if result.returncode == 0:
                return result.stdout.strip()
            else:
                self.error_message = "MySQL client not found."
                return None
        except Exception as e:
            self.error_message = f"Error finding MySQL client path: {e}"
            return None

    def get_mysql_version(self) -> str:
        """Fetch the MySQL version using the command-line client."""
        if not self.mysql_client_path:
            return None

        command = [self.mysql_client_path, "--version"]
        try:
            process = subprocess.run(command, capture_output=True, text=True)
            if process.returncode == 0:
                version = process.stdout.strip()
                print(f"MySQL version: {version}")  # Print the version here
                return version
            else:
                self.error_message = f"Error fetching MySQL version: {process.stderr}"
                print(self.error_message)  # Print error message if failed
                return None
        except Exception as e:
            self.error_message = f"Error executing MySQL version command: {e}"
            print(self.error_message)  # Print exception message if failed
            return None


    def execute_sql_file_and_read_to_pandas(self, sql_file_path: str) -> pd.DataFrame:
        """Executes an SQL file and reads the results into a Pandas DataFrame."""
        if not self.mysql_client_path:
            print("MySQL client path is not available.")
            return None

        command = [
            self.mysql_client_path,
            
            f"--host={self.host}",
            f"--user={self.user}",
            f"--password={self.password}",
            f"--database={self.database}",
            "--batch",
            "--raw",
            f"--execute=source {sql_file_path}"
        ]

        try:
            # Execute the command and capture output
            process = subprocess.run(command, capture_output=True, text=True)
            output = process.stdout

            if process.returncode != 0:
                self.error_message = process.stderr
                print(f"Error executing SQL: {self.error_message}")
                return None

            if not output.strip():
                print("No output from SQL file execution.")
                return None

            output_lines = [line for line in output.splitlines() if line.strip() and not line.startswith('--------------')]
            cleaned_output = '\n'.join(output_lines)

            if cleaned_output:
                headers = cleaned_output.splitlines()[0]
                column_names = [col.strip() for col in headers.split('\t')]

                cleaned_output = '\n'.join(cleaned_output.splitlines()[1:])

                df = pd.read_csv(StringIO(cleaned_output), sep='\t', header=None, engine='python', encoding='utf-8')

                if not df.empty and len(df.columns) == len(column_names):
                    df.columns = column_names
                df = df.loc[:, ~df.columns.duplicated()]

                return df
            else:
                print("No valid data found.")
                return None

        except Exception as e:
            print(f"Error reading results into DataFrame: {e}")
            return None

    def sql_error(self) -> str:
        """Return the last SQL error message."""
        return self.error_message