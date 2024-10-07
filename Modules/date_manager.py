import os
import sys
import re
import logging
from datetime import datetime, timedelta
from PySide6.QtCore import QDate
from Modules.config_handler import ConfigHandler

logger = logging.getLogger()
logger.setLevel(logging.INFO)
stream_handler = logging.StreamHandler(sys.stdout)
stream_handler.setFormatter(logging.Formatter(
    '%(asctime)s - %(levelname)s - %(message)s'))
logger.addHandler(stream_handler)


class DateManager:
    def __init__(self,config):
        self.config_handler = config
      
    def update_date_parameter_in_script(self, start_date, end_date):
        # List of section-key pairs to retrieve values for
        section_key_pairs = [
            ("Patient_Linelist", "patient_linelist"),
            ("HTS", "hts"),
            ("LIMS_EMR", "lims_emr")
        ]

        # Precompile regex for replacing @startDate and @endDate
        start_date_regex = re.compile(r"@startDate\s*:=\s*'[^']*';")
        end_date_regex = re.compile(r"@endDate\s*:=\s*'[^']*';")

        # Loop through each section and key, retrieve and update the script
        for section, key in section_key_pairs:
            try:
                # Get the script file path from the configuration handler
                script_file_path = self.config_handler.get_value(section, key)

                if script_file_path:
                    logging.info(f"Processing script for {section} - {key}: {script_file_path}")

                    # Read, modify, and write back the SQL script
                    with open(script_file_path, 'r+') as file:
                        sql_script = file.read()

                        # Replace @startDate and @endDate for the relevant sections
                        if section in ["Patient_Linelist", "HTS", "LIMS_EMR"]:
                            updated_script = start_date_regex.sub(f"@startDate := '{start_date}';", sql_script)
                            updated_script = end_date_regex.sub(f"@endDate := '{end_date}';", updated_script)

                            # Only write back if changes were made
                            if updated_script != sql_script:
                                file.seek(0)
                                file.write(updated_script)
                                file.truncate()  # Ensure the file is not longer than the updated content
                                logging.info(f"Updated start date and end date in script for {section}.")
                            else:
                                logging.info(f"No changes needed in script for {section}.")
                else:
                    logging.warning(f"Script file path for {section} - {key} not found in config.")

            except Exception as e:
                logging.error(f"Error processing script for {section} - {key}: {str(e)}")        
      
    
    
