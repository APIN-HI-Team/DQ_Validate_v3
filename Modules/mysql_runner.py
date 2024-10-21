import os
import subprocess
import pandas as pd

from io import StringIO


class MySQLRunner:
    def __init__(self, user: str, host: str = 'localhost', database: str = '',
                 password_file: str = 'config.txt'):
        self.user = user
        self.host = host
        self.database = database

        # Attempt to retrieve the password from a key-value formatted text file
        self.password = self._get_password_from_file(password_file)

        # Ensure password is set, raise error if the password is missing or improperly formatted
        if not self.password:
            raise ValueError(
                f"MySQL password not set. Ensure the password is in the correct format in the file: {password_file}")

        # Cache the MySQL client path
        self.mysql_client_path = self._get_mysql_client_path()
        self.error_message = ""

    def _get_mysql_client_path(self) -> str:
        """Locate the MySQL client executable."""
        try:
            # Define common MySQL client paths for Windows, macOS, and Linux
            possible_paths = [
                r'C:\Program Files\MySQL\MySQL Server 5.7\bin\mysql.exe',  # Windows typical path
                r'C:\Program Files (x86)\MySQL\MySQL Server 5.7\bin\mysql.exe',  # 32-bit Windows
                '/usr/local/mysql/bin/mysql',  # macOS typical path
                '/usr/bin/mysql',  # Linux typical path
                '/usr/local/bin/mysql',  # Another common path on macOS/Linux
            ]

            # Loop through the paths to find an existing MySQL client executable
            for path in possible_paths:
                if os.path.exists(path):
                    return path

            # If no valid path is found
            self.error_message = "MySQL client not found in typical locations."
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
            # data = data[data['ip'] == 'APIN']
            return data
        except Exception as e:
            print(f"Error converting SQL output to DataFrame: {e}")
        return pd.DataFrame()

    def sql_error(self) -> str:
        """Return the last SQL error message."""
        return self.error_message

    def _get_password_from_file(self, file_path: str) -> str:
        """Read the password from an external text file in 'password=XXXX' format."""
        if file_path and os.path.exists(file_path):
            try:
                with open(file_path, 'r') as file:
                    for line in file:
                        line = line.strip()  # Remove any surrounding whitespace
                        if line.startswith("password="):
                            # Extract the value after 'password='
                            return line.split("=", 1)[1]
            except Exception as e:
                self.error_message = f"Error reading password from file: {e}"
        else:
            self.error_message = "Password file not found."
        return None
