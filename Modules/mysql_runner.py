import os
import subprocess
import pandas as pd

from io import StringIO


class MySQLRunner:
    def __init__(self, user: str, host: str = 'localhost', database: str = '', password: str = None):
        self.user = user
        self.host = host
        self.password = password or os.getenv('MYSQL_PASSWORD', 'Nu66et')  # Default or environment variable
        if not self.password:
            raise ValueError("MySQL password not set.")
        self.database = database
        self.mysql_client_path = self._get_mysql_client_path()  # Cache the MySQL client path
        self.error_message = ""
    
    def _get_mysql_client_path(self) -> str:
        """Locate the MySQL client executable."""
        try:
            result = subprocess.run(['where', 'mysql'], capture_output=True, text=True, check=True)  # 'which' for Linux/macOS
            return result.stdout.strip()
        except subprocess.CalledProcessError:
            self.error_message = "MySQL client not found."
        except Exception as e:
            self.error_message = f"Error finding MySQL client path: {e}"
        return None

    def get_mysql_version(self) -> str:
        """Fetch the MySQL version using the command-line client."""
        if not self.mysql_client_path:
            return None

        command = [self.mysql_client_path, "--version"]
        try:
            result = subprocess.run(command, capture_output=True, text=True, check=True)
            version = result.stdout.strip()
            print(f"MySQL version: {version}")
            return version
        except subprocess.CalledProcessError as e:
            self.error_message = f"Error fetching MySQL version: {e.stderr}"
        except Exception as e:
            self.error_message = f"Error executing MySQL version command: {e}"
        return None

    def execute_sql_file_and_read_to_pandas(self, sql_file_path: str) -> pd.DataFrame:
        """Executes an SQL file and reads the result into a Pandas DataFrame."""
        if not self.mysql_client_path:
            print("MySQL client path is not available.")
            return pd.DataFrame()  # Return an empty DataFrame

        # Read SQL file content
        try:
            with open(sql_file_path, 'r') as file:
                sql_content = file.read()
        except Exception as e:
            print(f"Error reading SQL file: {e}")
            return pd.DataFrame()

        # Build the MySQL command
        command = [
            self.mysql_client_path,
            f"--host={self.host}",
            f"--user={self.user}",
            f"--password={self.password}",
            f"--database={self.database}",
            "--batch", "--raw"
        ]

        try:
            # Execute the SQL command
            process = subprocess.run(command, input=sql_content, capture_output=True, text=True, check=True)
            return self._convert_output_to_dataframe(process.stdout)
        except subprocess.CalledProcessError as e:
            self.error_message = f"Error executing SQL: {e.stderr}"
        except Exception as e:
            self.error_message = f"Error executing SQL file: {e}"
        return pd.DataFrame()

    def _convert_output_to_dataframe(self, output: str) -> pd.DataFrame:
        """Converts the raw SQL result to a Pandas DataFrame."""
        try:
            # Use StringIO to convert the output to a file-like object
            data = pd.read_csv(StringIO(output), sep='\t', lineterminator='\n', on_bad_lines='skip')
            data = data[data['IP'] == 'APIN']
            return data
        except Exception as e:
            print(f"Error converting SQL output to DataFrame: {e}")
        return pd.DataFrame()

    def sql_error(self) -> str:
        """Return the last SQL error message."""
        return self.error_message
