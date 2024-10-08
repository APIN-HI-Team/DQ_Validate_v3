# This Python file uses the following encoding: utf-8
import sys
import sys
import os
import io
import traceback
import logging
import shutil
from urllib.parse import urlparse
import polars as pl
import pandas as pd
import duckdb as duck
from pathlib import Path
from functools import partial

from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtCore import Qt,QMetaObject,QObject,Signal,Slot,Property,QThread,QTimer

from Modules.mysql_runner import MySQLRunner
from Modules.config_handler import *
from Modules.date_manager import DateManager
from Modules.table_model import DataFrameModel



class UnicodeLogger(io.StringIO):
    def write(self, s):
        try:
            super().write(s)
        except UnicodeEncodeError:
            pass

logger = logging.getLogger()
logger.setLevel(logging.INFO)
stream_handler = logging.StreamHandler(sys.stdout)
stream_handler.setFormatter(logging.Formatter(
            '%(asctime)s - %(levelname)s - %(message)s'))
logger.addHandler(stream_handler)




class Worker(QObject):
    taskStarted = Signal()
    taskFinished = Signal()
    dataReady = Signal(pd.DataFrame)

    errorOccurred = Signal(str)

    def __init__(self, runner: MySQLRunner):
        super().__init__()
       
        self.runner = runner
        self._error_message = ""
        
    @Property(str, notify=errorOccurred)
    def error_message(self):
        return self._error_message    

    # @Slot()
    def run(self, sql_file: str):
        try:
            self.taskStarted.emit()

            # Convert directly to Polars DataFrame
            self.df = self.runner.execute_sql_file_and_read_to_pandas(sql_file)

            if self.df is None or self.df.empty:
                raise ValueError("No data returned from SQL execution.")

            logging.info('Generated line list:\n%s', self.df)
            
            self.dataReady.emit(self.df)

        except Exception as e:
            self._error_message = self.runner.sql_error()
            logging.error("Worker error: %s", self.error_message)
            self.errorOccurred.emit(self.error_message.split("': ")[1].strip())

        finally:
            self.taskFinished.emit()


class Core(QObject):
    locationChanged = Signal(str)
    errorDataReady = Signal(pl.DataFrame)
    error_table_data_signal = Signal(str, object)
    error_dataframe_signal = Signal(object)

    errorMessageUpdated = Signal(str)

    taskStarted = Signal()
    taskFinished = Signal()
    errorOccurred = Signal(str)
    
    splashScreenVisible = Signal(bool)
    linelistTypeChanged = Signal(str)

    setScriptPath = Signal(str, str)

    exportSuccessSignal = Signal(str) 


    def __init__(self):
        super().__init__() 
        self.runner = MySQLRunner(user='root', host='localhost', database='openmrs')
        self.runner.get_mysql_version()

        self._location = ""
      
        self.config_handler = ConfigHandler('config.cfg')
        self.date_manager = DateManager(self.config_handler)
       
        self._initialize_models()

       
        self._location = self.load_location()
           
        
        self.worker_thread = QThread(self)
        self.worker = Worker(self.runner)

        self.project_folder = self.create_project_folder()
        self.create_location_sql_file()
        self.initialize_script_paths()
        
        self._file_path = ""
        
        
        
    def start_task(self, linelist_type):
        
        # Ensure no existing worker or thread is running
        if self.worker_thread.isRunning():
            logging.warning("Thread is already running. Please wait.")
            # self.cleanup_thread()
            return
        
        # Map linelist types to file paths
        linelist_map = {
            "Patient Linelist": ("Patient_Linelist", "patient_linelist"),
            "HTS Linelist": ("HTS", "hts"),
            "LIMS-EMR Linelist": ("LIMS_EMR", "lims_emr")
        }
        result = linelist_map.get(linelist_type)
        if not result:
            logging.error(f"Invalid linelist type: {linelist_type}")
            return
        
        section, key = result
        sql_file_path = self.config_handler.get_value(section, key)

        print(f'file path: {sql_file_path}')

        # Initialize the worker and move it to the thread
        # self.worker = Worker(self.runner)
        self.worker.moveToThread(self.worker_thread)

        # Connect worker signals to appropriate slots
        self.worker.taskStarted.connect(self.on_task_started)
        self.worker.taskFinished.connect(self.on_task_finished)
        self.worker.dataReady.connect(self.handle_data_ready)
        self.worker.errorOccurred.connect(self.handle_error)

        # Start the worker task when the thread starts
        self.worker_thread.started.connect(self.worker.run(sql_file_path))
        
         # Start the thread
        self.worker_thread.start()
       

    def _initialize_models(self):
        empty_df = pd.DataFrame()
        self._dataFrameModel = DataFrameModel(empty_df)
        self._errorModel = DataFrameModel(empty_df)
        self._errorDataFrameModel = DataFrameModel(empty_df)
        
        
        self.linelist_type = ""
        self.start_date = ""
        self.end_date = ""
        self.downloads_path = os.path.join(os.path.expanduser("~"), "Downloads")

    

    def initialize(self):
        self.splashScreenVisible.emit(True)
        QTimer.singleShot(3000, self.perform_initialization)

    def perform_initialization(self):
        # self.config_handler = ConfigHandler('config.cfg')
        # self.date_manager = DateManager(self.config_handler)
        # self._location = self.load_location()
        self.splashScreenVisible.emit(False)


    def load_location(self) -> str:
        try:
            location = self.runner.execute_sql_file_and_read_to_pandas(
                r'sql_scripts/location.sql')
            if not location.empty:
                loc_name = location['name'][0]
                loc_city = location['city_village'][0]
                location_str = f"{loc_name} - {loc_city}"
                self.locationChanged.emit(location_str)
                return location_str
            else:
                logging.warning("No data returned from location query.")
        except Exception as e:
            logging.error(f"Error loading location: {e}")
        return ""

    @Property(str, notify=locationChanged)
    def location(self) -> str:
        return self._location

   

    @Slot(str, int)  # Ensure this matches the QML signal
    def onDateChanged(self, date_str, instance_id):
        print(f"Date changed: {date_str}, Instance ID: {instance_id}")
        if instance_id == 1:
            self.start_date = date_str
        else:
            self.end_date = date_str
            
        self.date_manager.update_date_parameter_in_script(self.start_date,self.end_date)

    
    @Slot(str)
    def getComBoBoxSelection(self, selection):
        print(f"Selection:{selection}")
        self.linelist_type = selection
        self.linelistTypeChanged.emit(selection)

    @Slot(str)
    def handleLinelistTypeChange(self, linelist_type):
        self.start_task(linelist_type)
   
    @Slot()
    def on_task_started(self):
        logging.info("Task started")
        self.taskStarted.emit()

    @Slot()
    def on_task_finished(self):
        logging.info("Task finished")
        self.taskFinished.emit()
        self.cleanup_thread()

    @Slot(pd.DataFrame)
    def handle_data_ready(self, df: pd.DataFrame):
        logging.info("Data received")
        self.df = df
        self._dataFrameModel.setDataFrame(self.df)
        self.cleanup_thread()

    @Slot(str)
    def handle_error(self, error_message: str):
        logging.error(f"Error occurred: {error_message}")
        self.errorOccurred.emit(error_message)
        self.cleanup_thread()

    
    def cleanup_thread(self):
        if self.worker_thread.isRunning():
            self.worker_thread.quit()
            self.worker_thread.wait()

    @Slot()
    def generate_linelist(self):
        logging.info("Generating linelist...")
        self.handleLinelistTypeChange(self.linelist_type)

   
    @Slot()
    def exportToCSV(self):
        if self._dataFrameModel and hasattr(self._dataFrameModel, 'dataFrame'):
            try:
                # Define the file path for saving the CSV
                full_file_path = os.path.join(self.downloads_path, f'{self.linelist_type}_{self.end_date}.csv')

                # Export DataFrame to CSV
                self._dataFrameModel.dataFrame.to_csv(full_file_path, index=False)
                types = self._dataFrameModel.dataFrame
                  
                # Log success message
                logging.info(f"Data exported successfully to {full_file_path}")

                self.exportSuccessSignal.emit(f"Data exported successfully to {full_file_path}")


            except Exception as e:
                # Log any errors that occur during the export
                logging.error(f"Failed to export data to CSV: {str(e)}")
        else:
            logging.warning("No data available for export.")
          

    @Property(QObject, constant=True)
    def dataFrameModel(self):
        return self._dataFrameModel

    @Property(QObject, constant=True)
    def errorModel(self):
        return self._errorModel

    @Property(QObject, constant=True)
    def errorDataFrameModel(self):
        return self._errorDataFrameModel

    @Slot()
    def update_errorAggregateTable(self):
        logging.info("Updating error aggregate table...")
        self.df_ = pl.from_pandas(self.df)
        if not self.df_.is_empty() and self.linelist_type == "Patient Linelist":
            try:

                # Columns for data type conversion
                columns_to_convert = [
                    "ARTStartDate", "Clinic_Visit_Lastdate", "Date_Transfered_In", "DateofCurrent_TBStatus",
                    "DateofCurrentViralLoad", "DateofFirstTLD_Pickup", "DateResultReceivedFacility", "DOB", "First_INH_Pickupdate",
                    "FirstCD4Date", "HIVConfirmedDate", "IPT_Screening_Date", "Last_INH_Pickupdate", "LastDateOfSampleCollection",
                    "LastPickupDateCal", "LastWeightDate", "Outcomes_Date", "PBSDateCreated", "Pharmacy_LastPickupdate",
                    "Pharmacy_LastPickupdate_PreviousQuarter", "RecapturedDate", "TBTreatmentStartDate"
                ]

                number_convert = ["patient_id", "Ageatstartofart", "Ageinmonths", "DaysOnART", "DaysOfARVRefill",
                                  "DaysofARVRefillPreviousQuarter", "Current_Age", "CurrentAge_Months", "Whostage", "PillBalance",
                                  "Recapture_count"]

                float_convert = ["CurrentViralLoad", "LastWeight"]

                string_convert = ["IP", "State", "LGA", "Datim_Code", "FacilityName", "PepID", "PatientHospitalNo", "PreviousID",
                                  "Sex", "KPType", "RegimenLineAtARTStart", "RegimenAtARTStart", "CurrentRegimenLine",
                                  "CurrentARTRegimen", "CurrentOIDrug", "DSD_Model", "DSD_Model_Type", "CurrentPregnancyStatus",
                                  "Alphanumeric_Viral_Load_Result", "ViralLoadIndication", "Outcomes", "cause_of_death",
                                  "VA_Cause_of_Death", "CurrentARTStatus_Pharmacy", "CurrentARTStatus_Visit", "TI", "Surname",
                                  "Firstname", "Educationallevel", "MaritalStatus", "JobStatus", "PhoneNo", "Address",
                                  "State_of_Residence", "LGA_of_Residence", "CurrentBP", "FirstTLD_Pickup", "FirstCD4",
                                  "Indication_AHD", "CD4_LFA_Result", "Serology_for_CrAg_Result", "CSF_for_CrAg_Result",
                                  "Notes", "CurrentINHReceived", "Current_TB_Status", "PBS", "ValidBiometric", "PBS_Recaptured",
                                  "Are_you_coughing_currently", "Do_you_have_fever", "Are_you_losing_weight",
                                  "Are_you_having_night_sweats", "History_of_contacts_with_TB_patients", "Sputum_AFB",
                                  "Sputum_AFB_Result", "GeneXpert", "GeneXpert_Result", "Chest_Xray", "Chest_Xray_Result",
                                  "Culture", "Culture_Result", "Is_Patient_Eligible_For_IPT", "IPTOutcome",
                                  "ReasonforstoppingIPT", "Transitioned_Adult_Clinic", "OTZ_Outcome", "Positive_living",
                                  "Treatment_Literacy", "Adolescents_participation", "Leadership_training",
                                  "Peer_To_Peer_Mentoship", "Role_of_OTZ", "OTZ_Champion_Oreintation"]

                # Create 'Unique_ID' column
                self.df_ = self.df_.with_columns(
                    (pl.col("Datim_Code").cast(pl.Utf8) + pl.lit('_') +
                     pl.col("PepID").cast(pl.Utf8)).alias("Unique_ID")
                )

                # Register temporary DataFrame in DuckDB
                temp_df = self.df_.select(
                    'Unique_ID', 'State', 'LGA', 'Datim_Code', 'PepID', 'ARTStartDate', 'Surname', 'Firstname')
                duck.register("new_unique_id_temp", temp_df)

                # Fetch DuckDB tables
                table_names_query = duck.execute("SHOW TABLES").fetchdf()
                table_names = set(table_names_query["name"])

                # Create or update 'unique_id' table in DuckDB
                if 'unique_id' not in table_names:
                    duck.execute("""
                        CREATE TABLE unique_id AS
                        SELECT DISTINCT Unique_ID, State, LGA, Datim_Code, PepID, ARTStartDate, Surname, Firstname
                        FROM new_unique_id_temp;
                    """)
                    print("Unique Table Created Successfully!")
                else:
                    duck.execute("""
                        INSERT INTO unique_id (Unique_ID, State, LGA, Datim_Code, PepID, ARTStartDate, Surname, Firstname)
                        SELECT DISTINCT Unique_ID, State, LGA, Datim_Code, PepID, ARTStartDate, Surname, Firstname
                        FROM new_unique_id_temp
                        WHERE Unique_ID NOT IN (SELECT Unique_ID FROM unique_id);
                    """)
                    print("Unique Table Updated Successfully!")

                # Fetch data from DuckDB
                result_df = duck.execute("SELECT * FROM unique_id").fetchdf()
                id_df = pl.from_pandas(result_df)

                # Filter unique IDs not present in DuckDB table
                dff = id_df.filter(~pl.col("Unique_ID").is_in(self.df_["Unique_ID"])).filter(
                    pl.col("Datim_Code").is_in(self.df_['Datim_Code'])
                )
                # print(dff)

                # Data type conversion
                # self.df_ = self.df_.with_columns(
                #     [pl.col(col).str.strptime(pl.Date, "%d/%m/%Y", strict=False).alias(col) for col in columns_to_convert] +
                #     [pl.col(col).cast(pl.Int64, strict=False).alias(col) for col in number_convert] +
                #     [pl.col(col).cast(pl.Utf8).alias(col)
                #      for col in string_convert] +  [pl.col(col).cast(pl.Float64, strict=False).alias(col) for col in float_convert]
                # )

                # Common filter conditions
                common_columns = ["IP", "State", "LGA",
                                  "Datim_Code", "FacilityName", "PepID"]
                filter_conditions = {
                    0: {'error_type': "Missing Age at Start of ART", 'condition': pl.col('Ageatstartofart').is_null(), 'columns': common_columns + ["Ageatstartofart"]},
                    1: {'error_type': "Missing ART Commencement Date", 'condition': pl.col('ARTStartDate').is_null(), 'columns': common_columns + ["ARTStartDate"]},
                    2: {'error_type': "Commenced ART before DOB", 'condition': pl.col('DaysOnART') < 0, 'columns': common_columns + ["Ageatstartofart"]},
                    3: {'error_type': "Missing or Future Drug Pickup Date", 'condition': pl.col('Pharmacy_LastPickupdate').is_null(), 'columns': common_columns + ["Pharmacy_LastPickupdate"]},
                    5: {'error_type': "Males with Pregnancy Status", 'condition': (pl.col('Sex') == 'M') & (pl.col('CurrentPregnancyStatus').is_not_null()), 'columns': common_columns + ["Sex", "CurrentPregnancyStatus"]},
                    6: {'error_type': "Missing DOB", 'condition': pl.col('DOB').is_null(), 'columns': common_columns + ["DOB"]},
                    7: {'error_type': "Missing Current Age", 'condition': pl.col('Current_Age').is_null(), 'columns': common_columns + ["Current_Age"]},
                    8: {'error_type': "Missing Weight", 'condition': (pl.col("CurrentARTStatus_Pharmacy") == "Active") & pl.col('LastWeight').is_null(), 'columns': common_columns + ["LastWeight", "CurrentARTStatus_Pharmacy"]}
                }

                self.precomputed_filters = {key: {'error_type': filter_info['error_type'],
                                                  'error_df': self.df_.filter(filter_info['condition']).select(filter_info['columns'])}
                                            for key, filter_info in filter_conditions.items()}
                self.precomputed_filters[4] = {
                    'error_type': 'Missing Records', 'error_df': dff}

                # Collect error information
                self.error_info_list = [{'Error_Type': info['error_type'], 'row_count': len(info['error_df']), 'view': ""}
                                        for info in self.precomputed_filters.values() if len(info['error_df']) > 0]

                # Create DataFrame and update model
                error_info_df = pl.DataFrame(self.error_info_list)
                # logging.info(error_info_df)
                self._errorModel.setDataFrame(error_info_df.to_pandas())

                # Emit signal to update QML
                self.error_table_data_signal.emit(
                    'error_info', self.error_info_list)

            except Exception as e:
                logging.error(f"Error in update_errorAggregateTable: {e}")
                traceback.print_exc()
        else:
            logging.info("Error Identification code not yet generated")

    @Slot(str)
    def openFilteredDF(self, error_type: str):
        logging.info(
            f"Opening filtered DataFrame for error type: {error_type}")

        # Find the filter info with the matching error_type
        for index, filter_info in self.precomputed_filters.items():
            if filter_info['error_type'] == error_type:
                # Extract the DataFrame from the filter information
                filtered_df = filter_info.get('error_df')

                if filtered_df is None:
                    logging.error(
                        f"No DataFrame found for error type: {error_type}")
                    return

                # Update the model and emit the signal
                self._errorDataFrameModel.setDataFrame(filtered_df.to_pandas())
                self.error_dataframe_signal.emit(filtered_df.to_pandas())

                self.filteredErrorDataFrame = filtered_df
                return

        # Log a warning if no matching error_type was found
        logging.warning(f"No filter defined for error type: {error_type}")

    @Slot()
    def exportErrorsToExcel(self):
        # Implement the logic to export the DataFrame to Excel
        try:
            downloads_path = os.path.join(
                os.path.expanduser("~"), "Downloads")
            full_file_path = os.path.join(downloads_path, 'Error_Log.xlsx')

            with pd.ExcelWriter('Error_Log.xlsx', engine='openpyxl') as writer:
                for key, value in self.precomputed_filters.items():
                    df = value['error_df'].to_pandas()

                    # Check if DataFrame is empty
                    if not df.empty:
                        # Excel sheet names must be 31 chars or less
                        sheet_name = value['error_type'][:31]
                        df.to_excel(writer, sheet_name=sheet_name, index=False)
                        print(f"Written sheet '{
                              sheet_name}' to the Excel workbook.")
                    else:
                        print(f"Skipped empty DataFrame for error type '{
                              value['error_type']}'.")

        except Exception as e:
            logging.error(f"Error during export: {str(e)}")
      
    ################### LINELIST SETTINGS####################

    def create_project_folder(self):
        """Creates the project folder for saving SQL scripts."""
        folder_path = os.path.join(os.getcwd(), 'sql_scripts')
        os.makedirs(folder_path, exist_ok=True)
        return folder_path

    def create_location_sql_file(self):
        """Creates an SQL file named location.sql with the given SQL script and saves its path in the config."""
        try:
            # Define the SQL script
            sql_script = "SELECT name, city_village FROM location WHERE location_id = 8;"

            # Ensure the project folder is created
            folder_path = self.create_project_folder()

            # Define the file path for the SQL file
            file_path = os.path.join(folder_path, 'location.sql')

            # Create the SQL file and write the script
            with open(file_path, 'w') as file:
                file.write(sql_script)

            print(f"SQL file created successfully at {file_path}")

            # # Copy the file to the same folder (if necessary, e.g., for backup purposes)
            # backup_path = os.path.join(folder_path, 'location_backup.sql')
            # shutil.copy(file_path, backup_path)
            # print(f"Backup created successfully at {backup_path}")

            # Update the config handler with the file path (assuming config_handler is already set up)
            self.config_handler.set_value('Location', 'Location', file_path)

        except Exception as e:
            print(f"Error creating or copying SQL file: {e}")

    @Slot(str, str)
    def selectFile(self, path, placeholder):
        print(f'File selected: {path}')
        print(f'Placeholder: {placeholder}')

        # Parse the file URL and get the path
        parsed_path = urlparse(path).path

        # On Windows, remove the leading slash if it exists (it's part of the URL format)
        if os.name == 'nt':
            file_path = parsed_path.lstrip('/')
        else:
            file_path = parsed_path

        # Get the destination folder for the project
        destination_folder = self.create_project_folder()

        # Get the base file name and define the destination path
        file_name = os.path.basename(file_path)
        destination_path = os.path.join(destination_folder, file_name)

        # Try copying the file to the new location
        try:
            shutil.copy(file_path, destination_path)
            print(f'File saved to: {destination_path}')

            # Map placeholders to config sections and keys
            config_map = {
                'ART LineList Script': ('Patient_Linelist', 'Patient_Linelist'),
                'HTS LineList Script': ('HTS', 'HTS'),
                'Lims-EMR Linelist Script': ('LIMS_EMR', 'LIMS_EMR'),
            }

            # Update config if the script type matches one of the placeholders
            if script_type := config_map.get(placeholder):
                section, key = script_type
                self.config_handler.set_value(section, key, destination_path)

        except Exception as e:
            print(f'Error saving file: {e}')

    def initialize_script_paths(self):
        """Initialize script paths from the config."""
        try:
            section_key_map = {
                'Patient_Linelist': ('patient_linelist', 'ART LineList Script'),
                'HTS': ('hts', 'HTS LineList Script'),
                'LIMS_EMR': ('lims_emr', 'Lims-EMR Linelist Script')
            }

            # Track emitted paths to avoid duplicates
            sent_paths = set()

            for section, (key, label) in section_key_map.items():
                value = self.config_handler.get_value(section, key)
                if value and (label, value) not in sent_paths:
                    self.setScriptPath.emit(label, value)
                    sent_paths.add((label, value))

        except Exception as e:
            print(f"Error initializing script paths: {e}")

    @Slot(str)
    def initializeScriptPath(self, placeholder):
        """Slot to initialize the script path based on a placeholder."""
        value = self.get_value_based_on_placeholder(placeholder)
        if value:
            # Convert to relative path
            relative_value = self.make_relative_path(value)
            self.setScriptPath.emit(placeholder, relative_value)
    
    def make_relative_path(self, path):
        """Convert an absolute path to a relative path."""
        base_dir = os.path.dirname(os.path.abspath(__file__))  # Adjust the base directory as needed
        return os.path.relpath(path, base_dir)
    
    def get_value_based_on_placeholder(self, placeholder):
        """Fetch the value from the config based on the placeholder."""
        # Mapping placeholder to keys and corresponding sections
        placeholder_to_config = {
            "ART LineList Script": ("Patient_Linelist", "patient_linelist"),
            "HTS LineList Script": ("HTS", "hts"),
            "Lims-EMR Linelist Script": ("LIMS_EMR", "lims_emr")
        }
    
        config_info = placeholder_to_config.get(placeholder)
        if config_info:
            section, key = config_info
            return self.config_handler.get_value(section, key)
        return None
    


if __name__ == "__main__":
    app = QGuiApplication(sys.argv)
    engine = QQmlApplicationEngine()

    core = Core()
    core.splashScreenVisible.connect(lambda visible: engine.rootObjects()[0].showSplashScreen(visible))

    engine.rootContext().setContextProperty("core", core)
    qml_file = Path(__file__).resolve().parent / "main.qml"
    engine.load(qml_file)
    if not engine.rootObjects():
        sys.exit(-1)

    core.initialize()

    sys.exit(app.exec())
