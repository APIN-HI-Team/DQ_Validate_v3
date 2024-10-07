# from PySide6 import QtCore
# import pandas as pd

# class DataFrameModel(QtCore.QAbstractTableModel):
#     # Custom roles
#     DtypeRole = QtCore.Qt.UserRole + 1000
#     ValueRole = QtCore.Qt.UserRole + 1001
    
#     # Signal to indicate DataFrame has changed
#     dataFrameChanged = QtCore.Signal()  
#     rowCountChanged = QtCore.Signal()

#     def __init__(self, dataframe=pd.DataFrame(), parent=None):
#         super().__init__(parent)
#         self._dataframe = self._clean_dataframe(dataframe)
#         self._row_count = len(self._dataframe)

#     @QtCore.Property(int, notify=rowCountChanged)
#     def row_count(self):
#         return self._row_count

#     def setDataFrame(self, dataframe: pd.DataFrame) -> None:
#         self.beginResetModel()  # Begin resetting the model
#         self._dataframe = self._clean_dataframe(dataframe)
#         new_row_count = len(self._dataframe)
#         if new_row_count != self._row_count:
#             self._row_count = new_row_count
#             self.rowCountChanged.emit() 
#         self.endResetModel()  # End resetting the model
#         self.dataFrameChanged.emit()  # Emit signal when data is updated

#     @QtCore.Property(pd.DataFrame, fget=lambda self: self._dataframe, fset=lambda self, value: self.setDataFrame(value))
#     def dataFrame(self) -> pd.DataFrame:
#         return self._dataframe

#     def _clean_dataframe(self, dataframe):
#         if dataframe is None:
#             return None  # Or return an empty dataframe depending on the use case
#         return dataframe.fillna('')  # Replace None values with empty strings


#     @QtCore.Slot(int, QtCore.Qt.Orientation, result=str)
#     def headerData(self, section: int, orientation: QtCore.Qt.Orientation, role: int = QtCore.Qt.DisplayRole) -> str:
#         if role == QtCore.Qt.DisplayRole:
#             if orientation == QtCore.Qt.Horizontal:
#                 if section < len(self._dataframe.columns):
#                     return str(self._dataframe.columns[section])  # Display column headers
#             elif orientation == QtCore.Qt.Vertical:
#                 if section < len(self._dataframe):
#                     return str(section + 1)  # Customize row index to start from 1
#         return ""

#     def rowCount(self, parent: QtCore.QModelIndex = QtCore.QModelIndex()) -> int:
#         if parent.isValid():
#             return 0
#         if self._dataframe is None:
#             return 0
#         return len(self._dataframe)

#     def columnCount(self, parent: QtCore.QModelIndex = QtCore.QModelIndex()) -> int:
#         if parent.isValid():
#             return 0
#         if self._dataframe is None:
#             return 0
#         return len(self._dataframe.columns)

#     def data(self, index: QtCore.QModelIndex, role: int = QtCore.Qt.DisplayRole) -> str:
#         if not index.isValid() or not (0 <= index.row() < self.rowCount() and 0 <= index.column() < self.columnCount()):
#             return None

#         row = index.row()
#         col = index.column()
        
#         val = self._dataframe.iat[row, col]  # Access element using .iat for performance
        
#         if role == QtCore.Qt.DisplayRole:
#             return str(val)  # Return the value as a string for display
#         elif role == DataFrameModel.ValueRole:
#             return val  # Return the actual value
#         elif role == DataFrameModel.DtypeRole:
#             return str(self._dataframe.dtypes[col])  # Return the column's data type
#         elif role == QtCore.Qt.DecorationRole and col == 2:
#             # Return image path for the image column (assuming column 2 for images)
#             return self._dataframe.iat[row, col]
#         return None

#     def roleNames(self) -> dict:
#         return {
#             QtCore.Qt.DisplayRole: b'display',
#             DataFrameModel.DtypeRole: b'dtype',
#             DataFrameModel.ValueRole: b'value',
#             QtCore.Qt.DecorationRole: b'icon'
        
#         }
    



from PySide6 import QtCore
import pandas as pd

class DataFrameModel(QtCore.QAbstractTableModel):
    # Custom roles
    DtypeRole = QtCore.Qt.UserRole + 1000
    ValueRole = QtCore.Qt.UserRole + 1001
    
    # Signal to indicate DataFrame has changed
    dataFrameChanged = QtCore.Signal()  
    rowCountChanged = QtCore.Signal()

    def __init__(self, dataframe=None, parent=None):
        super().__init__(parent)
        self._dataframe = self._clean_dataframe(dataframe)
        self._row_count = len(self._dataframe)

    @QtCore.Property(int, notify=rowCountChanged)
    def row_count(self):
        return self._row_count

    def setDataFrame(self, dataframe: pd.DataFrame) -> None:
        self.beginResetModel()  # Begin resetting the model
        self._dataframe = self._clean_dataframe(dataframe)
        new_row_count = len(self._dataframe)
        if new_row_count != self._row_count:
            self._row_count = new_row_count
            self.rowCountChanged.emit() 
        self.endResetModel()  # End resetting the model
        self.dataFrameChanged.emit()  # Emit signal when data is updated

    @QtCore.Property(pd.DataFrame, fget=lambda self: self._dataframe, fset=lambda self, value: self.setDataFrame(value))
    def dataFrame(self) -> pd.DataFrame:
        return self._dataframe

    def _clean_dataframe(self, dataframe):
        """
        Clean the input dataframe by replacing None values and ensuring a valid DataFrame is returned.
        If the input is None, return an empty DataFrame.
        """
        if dataframe is None or not isinstance(dataframe, pd.DataFrame):
            return pd.DataFrame()  # Return empty dataframe
        return dataframe.fillna('')  # Replace None/NaN values with empty strings

    @QtCore.Slot(int, QtCore.Qt.Orientation, result=str)
    def headerData(self, section: int, orientation: QtCore.Qt.Orientation, role: int = QtCore.Qt.DisplayRole) -> str:
        if role == QtCore.Qt.DisplayRole:
            if orientation == QtCore.Qt.Horizontal:
                if section < len(self._dataframe.columns):
                    return str(self._dataframe.columns[section])  # Display column headers
            elif orientation == QtCore.Qt.Vertical:
                if section < len(self._dataframe):
                    return str(section + 1)  # Customize row index to start from 1
        return ""

    def rowCount(self, parent: QtCore.QModelIndex = QtCore.QModelIndex()) -> int:
        if parent.isValid():
            return 0
        if self._dataframe is None:
            return 0
        return len(self._dataframe)

    def columnCount(self, parent: QtCore.QModelIndex = QtCore.QModelIndex()) -> int:
        if parent.isValid():
            return 0
        if self._dataframe is None:
            return 0
        return len(self._dataframe.columns)

    def data(self, index: QtCore.QModelIndex, role: int = QtCore.Qt.DisplayRole) -> str:
        if not index.isValid() or not (0 <= index.row() < self.rowCount() and 0 <= index.column() < self.columnCount()):
            return None

        row = index.row()
        col = index.column()
        
        val = self._dataframe.iat[row, col]  # Access element using .iat for performance
        
        if role == QtCore.Qt.DisplayRole:
            return str(val)  # Return the value as a string for display
        elif role == DataFrameModel.ValueRole:
            return val  # Return the actual value
        elif role == DataFrameModel.DtypeRole:
            return str(self._dataframe.dtypes[col])  # Return the column's data type
        elif role == QtCore.Qt.DecorationRole and col == 2:
            # Return image path for the image column (assuming column 2 for images)
            return self._dataframe.iat[row, col]
        return None

    def roleNames(self) -> dict:
        return {
            QtCore.Qt.DisplayRole: b'display',
            DataFrameModel.DtypeRole: b'dtype',
            DataFrameModel.ValueRole: b'value',
            QtCore.Qt.DecorationRole: b'icon'
        }
