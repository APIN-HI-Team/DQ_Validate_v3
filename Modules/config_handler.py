import os
from configparser import ConfigParser
from PySide6.QtCore import QDate

class ConfigHandler:
    def __init__(self, config_file=None):
        self.config_file = config_file or os.path.join(os.getcwd(), 'config.cfg')
        self.config = ConfigParser()
        self.reload_config()

    def reload_config(self):
        self.config.read(self.config_file)
        print("Config reloaded")

    def get_value(self, section, key):
        return self.config.get(section, key)

    def set_value(self, section, key, value):
        if section not in self.config:
            self.config.add_section(section)
        self.config.set(section, key, value)
        with open(self.config_file, 'w') as configfile:
            self.config.write(configfile)

    def set_default_date(self, section, key, date_widget):
        """Set the date in the date widget based on the config, update the config when the widget changes."""

        # Ensure the section exists in the config
        if not self.config.has_section(section):
            self.config.add_section(section)

        # Retrieve the date string from the config
        date_str = self.config.get(section, key, fallback=None)

        if date_str:
            date_obj = QDate.fromString(date_str, 'dd-MM-yyyy')
            if date_obj.isValid():
                date_widget.setDate(date_obj)
            else:
                print(f"Error: Invalid date format in config for {section}.{key}: {date_str}")
                self.set_date_to_current(date_widget, section, key)
                
                    
        else:
            self.set_date_to_current(date_widget, section, key)

        # Connect date change to update method
        date_widget.dateChanged.connect(lambda date: self.update_date_in_config(section, key, date))

    def set_date_to_current(self, date_widget, section, key):
        """Set the date widget to the current date and update the config."""
        
        current_date = QDate.currentDate() if section != 'start_date' else QDate.currentDate().addDays(-1)
 
        date_widget.setDate(current_date)
        self.config.set(section, key, current_date.toString('dd-MM-yyyy'))
        self.save_config()

    def update_date_in_config(self, section, key, date):
        """Update the config with the new date when the date widget changes."""

        date_str = date.toString('dd-MM-yyyy')
        self.config.set(section, key, date_str)
        self.save_config()

    def save_config(self):
        """Save the updated configuration to the file."""

        with open(self.config_file, 'w') as configfile:
            self.config.write(configfile)

    def set_linelistype(self, combo_box):
        """Set the linelist in the config file based on the selected text from the QComboBox."""

        selected_linelist = combo_box.currentText()  # Get the current selected text

        # Ensure 'linelist' section exists
        if not self.config.has_section('linelist'):
            self.config.add_section('linelist')

        # Set the linelist value if it doesn't already exist or is different
        if self.config.get('linelist', 'linelist', fallback=None) != selected_linelist:
            self.config.set('linelist', 'linelist', selected_linelist)
            self.save_config()
            print(f"Linelist set to '{selected_linelist}' from QComboBox.")

        # Update config on changes to QComboBox selection
        combo_box.currentTextChanged.connect(lambda: self.update_linelist(combo_box))

    def update_linelist(self, combo_box):
        """Update the linelist in the config file based on the QComboBox selection."""

        selected_linelist = combo_box.currentText()

        if self.config.get('linelist', 'linelist', fallback=None) != selected_linelist:
            self.config.set('linelist', 'linelist', selected_linelist)
            self.save_config()
            print(f"Linelist updated to '{selected_linelist}' from QComboBox.")
