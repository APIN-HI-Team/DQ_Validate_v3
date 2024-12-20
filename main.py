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
from PySide6.QtCore import (
    Qt,
    QMetaObject,
    QObject,
    Signal,
    Slot,
    Property,
    QThread,
    QTimer,
)

from Modules.mysql_runner import MySQLRunner
from Modules.config_handler import *
from Modules.date_manager import DateManager
from Modules.table_model import DataFrameModel


logger = logging.getLogger()
logger.setLevel(logging.INFO)
stream_handler = logging.StreamHandler(sys.stdout)
stream_handler.setFormatter(
    logging.Formatter("%(asctime)s - %(levelname)s - %(message)s")
)
logger.addHandler(stream_handler)


class Worker(QThread):
    taskStarted = Signal()
    taskFinished = Signal()
    dataReady = Signal(pd.DataFrame)
    errorOccurred = Signal(str)

    def __init__(self, runner: "MySQLRunner", parent=None):
        super().__init__(parent)
        self.runner = runner
        self._error_message = ""
        self.df = None
        self.sql_file = ""

    @Property(str, notify=errorOccurred)
    def error_message(self):
        return self._error_message

    def run(self):
        try:
            self.taskStarted.emit()

            # query = (
            #     "SET sql_mode = (SELECT REPLACE(@@sql_mode, 'ONLY_FULL_GROUP_BY', ''));"
            # )

            # if self.runner.configure_session(query):
            #     print("Session configured successfully.")
            # else:
            #     print("Failed to configure the session.")

            # Convert directly to Polars DataFrame
            self.df = self.runner.execute_sql_file_and_read_to_pandas(self.sql_file)

            if self.df is None or self.df.empty:
                raise ValueError("No data returned from SQL execution.")

            logging.info("Generated line list:\n%s", self.df)

            self.dataReady.emit(self.df)

        except Exception as e:
            self._error_message = self.runner.sql_error()
            logging.error("Worker error: %s", self.error_message)
            self.errorOccurred.emit(self.error_message)

        finally:
            if not self._error_message:  # Only emit if no error occurred
                self.taskFinished.emit()

    def set_sql_file(self, sql_file: str):
        self.sql_file = sql_file


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
    exportErrorLogSignal = Signal(str)

    def __init__(self):
        super().__init__()
        self.runner = MySQLRunner(
            # user="root", host="localhost", database="openmrs"
        )
        self.runner.get_mysql_version()

        self._location = ""

        self.config_handler = ConfigHandler("config.cfg")
        self.date_manager = DateManager(self.config_handler)

        self._initialize_models()

        self._location = self.load_location()

        self.worker = Worker(self.runner)
        self.worker.taskStarted.connect(self.on_task_started)
        self.worker.taskFinished.connect(self.on_task_finished)
        self.worker.dataReady.connect(self.handle_data_ready)
        self.worker.errorOccurred.connect(self.handle_error)

        self.project_folder = self.create_project_folder()
        self.create_location_sql_file()
        self.initialize_script_paths()

        self._file_path = ""

    def start_task(self, linelist_type):

        # Map linelist types to file paths
        linelist_map = {
            "Patient Linelist": ("Patient_Linelist", "patient_linelist"),
            "HTS Linelist": ("HTS", "hts"),
            "LIMS-EMR Linelist": ("LIMS_EMR", "lims_emr"),
        }
        result = linelist_map.get(linelist_type)
        if not result:
            logging.error(f"Invalid linelist type: {linelist_type}")
            return

        section, key = result
        sql_file_path = self.config_handler.get_value(section, key)

        print(f"file path: {sql_file_path}")

        # Start the worker task when the thread starts
        if not self.worker.isRunning():

            self.worker.set_sql_file(r"sql_scripts\correct_sql_groupby_error.sql")
            self.worker.set_sql_file(sql_file_path)
            self.worker.start()
        else:
            logging.warning("Worker thread is already running.")

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
        self.splashScreenVisible.emit(False)

    def load_location(self) -> str:
        try:
            location = self.runner.execute_sql_file_and_read_to_pandas(
                r"sql_scripts/location.sql"
            )
            if not location.empty:
                loc_name = location["name"][0]
                loc_city = location["city_village"][0]
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

        self.date_manager.update_date_parameter_in_script(
            self.start_date, self.end_date
        )

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
        if self.linelist_type == "Patient Linelist":
            self.df = self.df[self.df["IP"] == "APIN"]
        self._dataFrameModel.setDataFrame(self.df)
        self.cleanup_thread()

    @Slot(str)
    def handle_error(self, error_message: str):
        logging.error(f"Error occurred: {error_message}")
        self.errorOccurred.emit(error_message)
        self.cleanup_thread()

    def cleanup_thread(self):
        # Check if worker_thread exists and is not None
        if hasattr(self, "worker_thread") and self.worker_thread is not None:
            if self.worker_thread.isRunning():
                # Stop or join the thread
                self.worker_thread.quit()  # or self.worker_thread.join()

                self.worker_thread.wait()

    @Slot()
    def generate_linelist(self):
        logging.info("Generating linelist...")
        self.handleLinelistTypeChange(self.linelist_type)

    @Slot()
    def exportToCSV(self):
        if self._dataFrameModel and hasattr(self._dataFrameModel, "dataFrame"):
            try:
                # Define the file path for saving the CSV
                full_file_path = os.path.join(
                    self.downloads_path, f"{self.linelist_type}_{self.end_date}.csv"
                )

                # Export DataFrame to CSV
                self._dataFrameModel.dataFrame.to_csv(full_file_path, index=False)
                types = self._dataFrameModel.dataFrame

                # Log success message
                logging.info(f"Data exported successfully to {full_file_path}")

                self.exportSuccessSignal.emit(
                    f"Data exported successfully to {full_file_path}"
                )

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

        if not self.df.empty and self.linelist_type == "Patient Linelist":
            try:
                # Columns for data type conversion
                columns_to_convert = [
                    "ARTStartDate",
                    "Clinic_Visit_Lastdate",
                    "Date_Transfered_In",
                    "DateofCurrent_TBStatus",
                    "DateofCurrentViralLoad",
                    "DateofFirstTLD_Pickup",
                    "DateResultReceivedFacility",
                    "DOB",
                    "First_INH_Pickupdate",
                    "FirstCD4Date",
                    "HIVConfirmedDate",
                    "IPT_Screening_Date",
                    "Last_INH_Pickupdate",
                    "LastDateOfSampleCollection",
                    "LastPickupDateCal",
                    "LastWeightDate",
                    "Outcomes_Date",
                    "PBSDateCreated",
                    "Pharmacy_LastPickupdate",
                    "Pharmacy_LastPickupdate_PreviousQuarter",
                    "RecapturedDate",
                    "TBTreatmentStartDate",
                ]

                number_convert = [
                    "patient_id",
                    "Ageatstartofart",
                    "Ageinmonths",
                    "DaysOnART",
                    "DaysOfARVRefill",
                    "DaysofARVRefillPreviousQuarter",
                    "Current_Age",
                    "CurrentAge_Months",
                    "Whostage",
                    "PillBalance",
                    "Recapture_count",
                ]

                float_convert = ["CurrentViralLoad", "LastWeight"]

                string_convert = [
                    "IP",
                    "State",
                    "LGA",
                    "Datim_Code",
                    "FacilityName",
                    "PepID",
                    "PatientHospitalNo",
                    "PreviousID",
                    "Sex",
                    "KPType",
                    "RegimenLineAtARTStart",
                    "RegimenAtARTStart",
                    "CurrentRegimenLine",
                    "CurrentARTRegimen",
                    "DSD_Model",
                    "DSD_Model_Type",
                    "CurrentPregnancyStatus",
                    "Alphanumeric_Viral_Load_Result",
                    "ViralLoadIndication",
                    "Outcomes",
                    "cause_of_death",
                    "VA_Cause_of_Death",
                    "CurrentARTStatus_Pharmacy",
                    "CurrentARTStatus_Visit",
                    "TI",
                    "Surname",
                    "Firstname",
                    "Educationallevel",
                    "MaritalStatus",
                    "JobStatus",
                    "PhoneNo",
                    "Address",
                    "State_of_Residence",
                    "LGA_of_Residence",
                    "CurrentBP",
                    "FirstTLD_Pickup",
                    "FirstCD4",
                    "Indication_AHD",
                    "CD4_LFA_Result",
                    "Serology_for_CrAg_Result",
                    "CSF_for_CrAg_Result",
                    "CurrentINHReceived",
                    "Current_TB_Status",
                    "PBS",
                    "ValidBiometric",
                    "PBS_Recaptured",
                    "Are_you_coughing_currently",
                    "Do_you_have_fever",
                    "Are_you_losing_weight",
                    "Are_you_having_night_sweats",
                    "History_of_contacts_with_TB_patients",
                    "Sputum_AFB",
                    "Sputum_AFB_Result",
                    "GeneXpert",
                    "GeneXpert_Result",
                    "Chest_Xray",
                    "Chest_Xray_Result",
                    "Culture",
                    "Culture_Result",
                    "Is_Patient_Eligible_For_IPT",
                    "IPTOutcome",
                    "ReasonforstoppingIPT",
                    "Transitioned_Adult_Clinic",
                    "OTZ_Outcome",
                    "Positive_living",
                    "Treatment_Literacy",
                    "Adolescents_participation",
                    "Leadership_training",
                    "Peer_To_Peer_Mentoship",
                    "Role_of_OTZ",
                    "OTZ_Champion_Oreintation",
                ]

                # Create 'Unique_ID' column
                self.df.loc[:, "Unique_ID"] = (
                    self.df["Datim_Code"].astype(str)
                    + "_"
                    + self.df["PepID"].astype(str)
                )

                # Register temporary DataFrame in DuckDB
                temp_df = self.df[
                    [
                        "Unique_ID",
                        "State",
                        "LGA",
                        "Datim_Code",
                        "PepID",
                        "ARTStartDate",
                        "Surname",
                        "Firstname",
                    ]
                ]
                duck.register("new_unique_id_temp", temp_df)

                # Fetch DuckDB tables
                table_names_query = duck.execute("SHOW TABLES").fetchdf()
                table_names = set(table_names_query["name"])

                # Create or update 'unique_id' table in DuckDB
                if "unique_id" not in table_names:
                    duck.execute(
                        """
                        CREATE TABLE unique_id AS
                        SELECT DISTINCT Unique_ID, State, LGA, Datim_Code, PepID, ARTStartDate, Surname, Firstname
                        FROM new_unique_id_temp;
                    """
                    )
                    print("Unique Table Created Successfully!")
                else:
                    duck.execute(
                        """
                        INSERT INTO unique_id (Unique_ID, State, LGA, Datim_Code, PepID, ARTStartDate, Surname, Firstname)
                        SELECT DISTINCT Unique_ID, State, LGA, Datim_Code, PepID, ARTStartDate, Surname, Firstname
                        FROM new_unique_id_temp
                        WHERE Unique_ID NOT IN (SELECT Unique_ID FROM unique_id);
                    """
                    )
                    print("Unique Table Updated Successfully!")

                # Fetch data from DuckDB
                result_df = duck.execute("SELECT * FROM unique_id").fetchdf()

                # Filter unique IDs not present in DuckDB table
                id_df = result_df
                dff = id_df[
                    ~id_df["Unique_ID"].isin(self.df["Unique_ID"])
                    & id_df["Datim_Code"].isin(self.df["Datim_Code"])
                ]

                # Data type conversion
                self.df.loc[:, number_convert] = self.df[number_convert].apply(
                    pd.to_numeric, errors="coerce"
                )
                self.df.loc[:, float_convert] = self.df[float_convert].apply(
                    pd.to_numeric, errors="coerce"
                )
                self.df.loc[:, columns_to_convert] = self.df[columns_to_convert].apply(
                    pd.to_datetime, errors="coerce", format="%d/%m/%Y"
                )
                self.df.loc[:, string_convert] = (
                    self.df[string_convert].astype("object").fillna("").astype(str)
                )

                # Common filter conditions
                common_columns = [
                    "IP",
                    "State",
                    "LGA",
                    "Datim_Code",
                    "FacilityName",
                    "PepID",
                ]
                filter_conditions = {
                    0: {
                        "error_type": "Missing Age at Start of ART",
                        "condition": self.df["Ageatstartofart"].isna(),
                        "columns": common_columns + ["Ageatstartofart"],
                    },
                    1: {
                        "error_type": "Missing ART Commencement Date",
                        "condition": self.df["ARTStartDate"].isna(),
                        "columns": common_columns + ["ARTStartDate"],
                    },
                    2: {
                        "error_type": "Commenced ART before DOB",
                        "condition": self.df["DaysOnART"] < 0,
                        "columns": common_columns + ["Ageatstartofart"],
                    },
                    3: {
                        "error_type": "Missing or Future Drug Pickup Date",
                        "condition": self.df["Pharmacy_LastPickupdate"].isna(),
                        "columns": common_columns + ["Pharmacy_LastPickupdate"],
                    },
                    5: {
                        "error_type": "Males with Pregnancy Status",
                        "condition": (self.df["Sex"] == "M")
                        & self.df["CurrentPregnancyStatus"].isna(),
                        "columns": common_columns + ["Sex", "CurrentPregnancyStatus"],
                    },
                    6: {
                        "error_type": "Missing DOB",
                        "condition": self.df["DOB"].isna(),
                        "columns": common_columns + ["DOB"],
                    },
                    7: {
                        "error_type": "Missing Current Age",
                        "condition": (
                            self.df["Current_Age"].isna()
                            & self.df["CurrentAge_Months"].isna()
                        ),
                        "columns": common_columns + ["Current_Age"],
                    },
                    8: {
                        "error_type": "Missing Weight",
                        "condition": (self.df["CurrentARTStatus_Pharmacy"] == "Active")
                        & self.df["LastWeight"].isna(),
                        "columns": common_columns
                        + ["LastWeight", "CurrentARTStatus_Pharmacy"],
                    },
                }

                self.precomputed_filters = {
                    key: {
                        "error_type": filter_info["error_type"],
                        "error_df": self.df[filter_info["condition"]][
                            filter_info["columns"]
                        ],
                    }
                    for key, filter_info in filter_conditions.items()
                }
                self.precomputed_filters[4] = {
                    "error_type": "Missing Records",
                    "error_df": dff,
                }

                # Collect error information
                self.error_info_list = [
                    {
                        "Error_Type": info["error_type"],
                        "row_count": len(error_df),
                        "view": "",
                    }
                    for info in self.precomputed_filters.values()
                    if len(error_df := info["error_df"]) >= 0
                ]

                print(self.error_info_list)

                # Create DataFrame and update model
                error_info_df = pd.DataFrame(self.error_info_list)
                # logging.info(error_info_df)
                self._errorModel.setDataFrame(error_info_df)

                # Emit signal to update QML
                self.error_table_data_signal.emit("error_info", self.error_info_list)

            except Exception as e:
                logging.error(f"Error in update_errorAggregateTable: {e}")
                traceback.print_exc()
        else:
            logging.info("Error Identification code not yet generated")

    @Slot(str)
    def openFilteredDF(self, error_type: str):
        logging.info(f"Opening filtered DataFrame for error type: {error_type}")

        # Find the filter info with the matching error_type
        for index, filter_info in self.precomputed_filters.items():
            if filter_info["error_type"] == error_type:
                # Extract the DataFrame from the filter information
                filtered_df = filter_info.get("error_df")

                if filtered_df is None:
                    logging.error(f"No DataFrame found for error type: {error_type}")
                    return

                # Update the model and emit the signal
                self._errorDataFrameModel.setDataFrame(filtered_df)
                self.error_dataframe_signal.emit(filtered_df)

                self.filteredErrorDataFrame = filtered_df
                return

        # Log a warning if no matching error_type was found
        logging.warning(f"No filter defined for error type: {error_type}")

    @Slot()
    def exportErrorsToExcel(self):
        # Implement the logic to export the DataFrame to Excel
        try:
            downloads_path = os.path.join(os.path.expanduser("~"), "Downloads")
            full_file_path = os.path.join(
                downloads_path, f"Error_Log_{self.end_date}.xlsx"
            )

            # Initialize a flag to track if we have any valid sheets
            has_valid_sheets = False

            with pd.ExcelWriter(full_file_path, engine="openpyxl") as writer:
                for key, value in self.precomputed_filters.items():
                    df = value[
                        "error_df"
                    ]  # Assuming error_df is already a Pandas DataFrame

                    # Check if DataFrame is empty
                    if not df.empty:
                        # Excel sheet names must be 31 chars or less
                        sheet_name = value["error_type"][:31]
                        df.to_excel(writer, sheet_name=sheet_name, index=False)
                        has_valid_sheets = True  # Set flag to True
                        print(f"Written sheet '{sheet_name}' to the Excel workbook.")
                    else:
                        print(
                            f"Skipped empty DataFrame for error type '{value['error_type']}'."
                        )

            # Check if any sheets were written to the workbook
            if has_valid_sheets:
                self.exportErrorLogSignal.emit(
                    f"Errors exported successfully to {full_file_path}"
                )
                logging.info("Error exported Successfully !!!")
            else:
                error_message = "No valid data to export."
                logging.warning(error_message)
                self.exportErrorLogSignal.emit(error_message)

        except Exception as e:
            error_message = f"Error during export: {str(e)}"
            logging.error(error_message)
            self.exportErrorLogSignal.emit(error_message)

    ################### LINELIST SETTINGS####################

    def create_project_folder(self):
        """Creates the project folder for saving SQL scripts."""
        folder_path = os.path.join(os.getcwd(), "sql_scripts")
        os.makedirs(folder_path, exist_ok=True)
        return folder_path

    def create_location_sql_file(self):
        """Creates an SQL file named location.sql with the given SQL script and saves its path in the config."""
        try:
            # Define the SQL script
            sql_script = (
                "SELECT name, city_village FROM location WHERE location_id = 8;"
            )

            # Ensure the project folder is created
            folder_path = self.create_project_folder()

            # Define the file path for the SQL file
            file_path = os.path.join(folder_path, "location.sql")

            # Create the SQL file and write the script
            with open(file_path, "w") as file:
                file.write(sql_script)

            print(f"SQL file created successfully at {file_path}")

            # # Copy the file to the same folder (if necessary, e.g., for backup purposes)
            # backup_path = os.path.join(folder_path, 'location_backup.sql')
            # shutil.copy(file_path, backup_path)
            # print(f"Backup created successfully at {backup_path}")

            # Update the config handler with the file path (assuming config_handler is already set up)
            self.config_handler.set_value("Location", "Location", file_path)

        except Exception as e:
            print(f"Error creating or copying SQL file: {e}")

    @Slot(str, str)
    def selectFile(self, path, placeholder):
        print(f"File selected: {path}")
        print(f"Placeholder: {placeholder}")

        # Parse the file URL and get the path
        parsed_path = urlparse(path).path

        # On Windows, remove the leading slash if it exists (it's part of the URL format)
        if os.name == "nt":
            file_path = parsed_path.lstrip("/")
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
            print(f"File saved to: {destination_path}")

            # Map placeholders to config sections and keys
            config_map = {
                "ART LineList Script": ("Patient_Linelist", "Patient_Linelist"),
                "HTS LineList Script": ("HTS", "HTS"),
                "Lims-EMR Linelist Script": ("LIMS_EMR", "LIMS_EMR"),
            }

            # Update config if the script type matches one of the placeholders
            if script_type := config_map.get(placeholder):
                section, key = script_type
                self.config_handler.set_value(section, key, destination_path)

        except Exception as e:
            print(f"Error saving file: {e}")

    def initialize_script_paths(self):
        """Initialize script paths from the config."""
        try:
            section_key_map = {
                "Patient_Linelist": ("patient_linelist", "ART LineList Script"),
                "HTS": ("hts", "HTS LineList Script"),
                "LIMS_EMR": ("lims_emr", "Lims-EMR Linelist Script"),
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
        base_dir = os.path.dirname(
            os.path.abspath(__file__)
        )  # Adjust the base directory as needed
        return os.path.relpath(path, base_dir)

    def get_value_based_on_placeholder(self, placeholder):
        """Fetch the value from the config based on the placeholder."""
        # Mapping placeholder to keys and corresponding sections
        placeholder_to_config = {
            "ART LineList Script": ("Patient_Linelist", "patient_linelist"),
            "HTS LineList Script": ("HTS", "hts"),
            "Lims-EMR Linelist Script": ("LIMS_EMR", "lims_emr"),
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
    core.splashScreenVisible.connect(
        lambda visible: engine.rootObjects()[0].showSplashScreen(visible)
    )

    engine.rootContext().setContextProperty("core", core)
    qml_file = Path(__file__).resolve().parent / "main.qml"
    engine.load(qml_file)
    if not engine.rootObjects():
        sys.exit(-1)

    core.initialize()

    sys.exit(app.exec())
